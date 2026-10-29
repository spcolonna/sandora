import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight, TextPainter, TextSpan, TextAlign;

import '../../balance/balance.dart';
import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../../ui/fx/sfx.dart';
import '../../ui/theme/palette.dart';
import '../common/grade.dart';
import '../common/minigame_screen.dart';
import 'lantern_rules.dart';

/// Río: se ponen piedras en la corriente (tocar pone o saca, arrastrar mueve)
/// y se toca la linterna para soltarla. Las piedras la desvían hasta su
/// muelle. Si pasa de largo o se apaga, vuelve arriba con las piedras como
/// estaban.
class LanternsGame extends FlameGame with TapCallbacks, DragCallbacks {
  final void Function(RunOutcome) finish;
  final LanternRules rules = LanternRules(Balance.instance.section('lanterns'));
  LanternsGame(this.finish);

  final _rng = Random();
  late LanternSetup _lantern = rules.setup(_rng);
  final _stones = <Offset>[];
  final _scores = <double>[];
  int _misses = 0;
  final _streak = Streak();

  /// Viaje en curso (null mientras se ponen piedras) y desde cuándo.
  LanternRun? _run;
  double _runT = 0;
  double _t = 0;
  bool _over = false;
  String _note = '';
  double _noteAt = -10;
  int? _dragging;
  double _outAt = -10;

  Rect get _river => Rect.fromLTRB(size.x * 0.08, size.y * 0.16, size.x * 0.92, size.y * 0.86);
  Offset _toScreen(Offset p) => Offset(_river.left + p.dx * _river.width, _river.top + p.dy * _river.height);
  Offset _toRiver(Offset s) => Offset((s.dx - _river.left) / _river.width, (s.dy - _river.top) / _river.height);
  double get _stoneR => rules.stoneRadius * _river.width;

  @override
  Color backgroundColor() => const Color(0xFF8DA36C);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final run = _run;
    if (run == null) return;
    _runT += dt;
    if (_runT / LanternRules.step >= run.path.length - 1) _arrive(run.end);
  }

  Offset get _lanternAt {
    final run = _run;
    if (run == null) return _toScreen(Offset(_lantern.startX, 0));
    return _toScreen(run.path[min(run.path.length - 1, (_runT / LanternRules.step).floor())]);
  }

  int? _stoneAt(Offset screen) {
    for (var i = 0; i < _stones.length; i++) {
      if ((_toScreen(_stones[i]) - screen).distance < _stoneR * 1.6) return i;
    }
    return null;
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_over || _run != null) return;
    final at = event.localPosition.toOffset();
    if ((at - _lanternAt).distance < 40) {
      _release();
      return;
    }
    final hit = _stoneAt(at);
    if (hit != null) {
      _stones.removeAt(hit);
      Haptics.light();
      return;
    }
    final p = _toRiver(at);
    if (!rules.canPlace(p)) return;
    if (_stones.length >= rules.maxStones) {
      _say(tr('lanterns.full'));
      return;
    }
    _stones.add(p);
    SoundBoard.instance.play(Sfx.stackPlace, volume: 0.35);
    Haptics.light();
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_run == null && !_over) _dragging = _stoneAt(event.localPosition.toOffset());
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final i = _dragging;
    if (i == null) return;
    final p = _toRiver(event.localEndPosition.toOffset());
    if (rules.canPlace(p)) _stones[i] = p;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _dragging = null;
  }

  void _release() {
    _run = rules.simulate(_lantern, _stones);
    _runT = 0;
    _dragging = null;
  }

  void _say(String s) {
    _note = s;
    _noteAt = _t;
  }

  void _arrive(LanternEnd end) {
    _run = null;
    switch (end) {
      case LanternEnd.docked:
        final v = rules.value(_stones.length);
        _scores.add(v);
        final g = v >= 1
            ? Grade.perfect
            : v >= 0.75
            ? Grade.great
            : Grade.good;
        final dock = _toScreen(Offset(_lantern.dockX, 1));
        celebrate(world, Vector2(dock.dx, dock.dy), g, streak: _streak.hit(g));
        _say(tr('grade.${g.name}'));
        _next();
      case LanternEnd.missed:
        _misses++;
        _streak.miss();
        if (_misses >= rules.b.i('tries')) {
          _scores.add(0);
          _say(tr('lanterns.gone'));
          _next();
        } else {
          _say(tr('lanterns.missed'));
        }
      case LanternEnd.out:
        _outAt = _t;
        Haptics.light();
        _say(tr('lanterns.out'));
    }
  }

  void _next() {
    _misses = 0;
    _stones.clear();
    if (_scores.length >= rules.lanterns) {
      _end();
    } else {
      _lantern = rules.setup(_rng);
    }
  }

  void _end() {
    _over = true;
    final harmony = _scores.reduce((a, v) => a + v) / _scores.length;
    final pct = (harmony * 100).round();
    final record = pct > Progress.instance.best('lanterns');
    Progress.instance.setBest('lanterns', pct);
    final stars = starsFor(harmony, rules.b.list('stars'));
    Future.delayed(const Duration(milliseconds: 1800), () {
      finish(RunOutcome(score: pct, stars: stars, headline: tr('lanterns.result', {'n': pct}), record: record));
    });
  }

  @override
  void render(Canvas canvas) {
    _drawRiver(canvas);
    _drawDock(canvas);
    _drawStones(canvas);
    if (!_over) _drawLantern(canvas);
    super.render(canvas);
    _drawHud(canvas);
  }

  /// El agua, con flechitas que muestran hacia dónde empuja la corriente.
  void _drawRiver(Canvas canvas) {
    final r = _river;
    canvas.drawRRect(
      RRect.fromRectAndRadius(r.inflate(10), const Radius.circular(18)),
      Paint()..color = const Color(0xFFB8A784),
    );
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(14)), Paint()..color = Palette.water);
    final arrow = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.28)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final speed = rules.b.d('speed');
    final shift = (_t * 0.25) % 0.1;
    for (var y = 0.05 + shift; y < 1; y += 0.1) {
      final dx = rules.drift(y, _lantern.phase);
      final dir = Offset(dx * r.width, speed * r.height);
      final u = dir / dir.distance * 12;
      for (var x = 0.15; x < 0.9; x += 0.175) {
        final c = _toScreen(Offset(x, y));
        canvas.drawLine(c - u, c + u, arrow);
        // Punta: dos rayitas hacia atrás, a 30° de cada lado.
        final back = -u / 2;
        for (final a in [0.5, -0.5]) {
          canvas.drawLine(
            c + u,
            c + u + Offset(back.dx * cos(a) - back.dy * sin(a), back.dx * sin(a) + back.dy * cos(a)),
            arrow,
          );
        }
      }
    }
  }

  /// El muelle de esta linterna: tablones y un farolito.
  void _drawDock(Canvas canvas) {
    final c = _toScreen(Offset(_lantern.dockX, 1));
    final half = rules.dockHalf * _river.width;
    final deck = Rect.fromLTRB(c.dx - half, c.dy - 6, c.dx + half, size.y * 0.93);
    canvas.drawRect(deck, Paint()..color = Palette.wood);
    final seam = Paint()
      ..color = const Color(0xFF5E3D28)
      ..strokeWidth = 1;
    for (var x = deck.left + 8; x < deck.right; x += 8) {
      canvas.drawLine(Offset(x, deck.top), Offset(x, deck.bottom), seam);
    }
    canvas.drawCircle(
      Offset(c.dx, c.dy - 2),
      half * 1.3,
      Paint()..color = Palette.lantern.withValues(alpha: 0.18 + 0.08 * sin(_t * 2)),
    );
  }

  void _drawStones(Canvas canvas) {
    for (final s in _stones) {
      final c = _toScreen(s);
      canvas.drawCircle(c + const Offset(2, 3), _stoneR, Paint()..color = Palette.ink.withValues(alpha: 0.25));
      canvas.drawCircle(c, _stoneR, Paint()..color = Palette.stone);
      canvas.drawCircle(c - Offset(_stoneR * 0.3, _stoneR * 0.3), _stoneR * 0.35, Paint()..color = Palette.stoneLight);
    }
  }

  void _drawLantern(Canvas canvas) {
    final c = _lanternAt;
    // Recién apagada vuelve arriba oscura y se enciende de nuevo.
    final lit = _t - _outAt > 0.9;
    if (lit) {
      canvas.drawCircle(
        c,
        34,
        Paint()
          ..color = Palette.lantern.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
    final s = 13.0;
    canvas.drawRect(
      Rect.fromCenter(center: c + Offset(0, s * 0.8), width: s * 2.2, height: s * 0.45),
      Paint()..color = Palette.wood,
    );
    canvas.drawRect(
      Rect.fromCenter(center: c, width: s * 1.6, height: s * 1.6),
      Paint()..color = lit ? const Color(0xFFF6DDA8) : Palette.stoneLight,
    );
    canvas.drawRect(
      Rect.fromCenter(center: c, width: s * 1.6, height: s * 1.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Palette.wood,
    );
    // Esperando: un anillo que late invita a tocarla.
    if (_run == null) {
      canvas.drawCircle(
        c,
        24 + 4 * sin(_t * 3),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Palette.paper.withValues(alpha: 0.7),
      );
    }
  }

  void _drawHud(Canvas canvas) {
    final n = min(_scores.length + 1, rules.lanterns);
    _text(
      canvas,
      tr('lanterns.progress', {'n': n, 'total': rules.lanterns, 'stones': _stones.length, 'max': rules.maxStones}),
      Offset(size.x / 2, size.y * 0.07),
      18,
    );
    final String msg;
    if (_over) {
      msg = tr('lanterns.result', {'n': (_scores.reduce((a, v) => a + v) / _scores.length * 100).round()});
    } else if (_t - _noteAt < 2.2) {
      msg = _note;
    } else if (_run == null && _scores.isEmpty && _misses == 0) {
      msg = tr('lanterns.hint');
    } else {
      msg = '';
    }
    if (msg.isNotEmpty) _text(canvas, msg, Offset(size.x / 2, size.y * 0.12), 16, maxWidth: size.x - 150);
  }

  void _text(Canvas canvas, String s, Offset center, double fontSize, {double? maxWidth}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(color: Palette.ink.withValues(alpha: 0.9), fontSize: fontSize, fontWeight: FontWeight.w600),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth ?? size.x - 48);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }
}
