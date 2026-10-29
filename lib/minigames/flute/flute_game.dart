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
import 'flute_rules.dart';

/// Bosque de bambú: las ráfagas llegan desde la derecha, cada una por la fila
/// de un hueco de la flauta. Mientras pasa por la flauta, hay que tapar ese
/// hueco (mantener el dedo en su fila). Cualquier hueco suena: la melodía es
/// pentatónica y nunca desafina.
class FluteGame extends FlameGame with TapCallbacks {
  final void Function(RunOutcome) finish;
  final FluteRules rules = FluteRules(Balance.instance.section('flute'));
  FluteGame(this.finish);

  late final List<Gust> _song = rules.song(Random());
  final _held = [for (var i = 0; i < FluteRules.holes; i++) <(double, double)>[]];

  /// Dedos apoyados: hueco que tapan y desde cuándo.
  final _fingers = <int, (int, double)>{};
  final _scores = <double>[];
  double _t = 0;
  bool _over = false;
  Grade? _lastGrade;
  final _streak = Streak();
  double _gradeAt = -10;
  int _gradeHole = 0;

  double get _speed => size.x * rules.b.d('speed');
  double get _fluteX => size.x * 0.2;
  double _holeY(int i) => size.y * (0.72 - 0.15 * i);
  bool _covered(int hole) => _fingers.values.any((f) => f.$1 == hole);

  @override
  Color backgroundColor() => const Color(0xFFDDE3C8);

  @override
  void update(double dt) {
    super.update(dt);
    if (_over) return;
    _t += dt;
    // Se juzga cada ráfaga cuando terminó de pasar.
    while (_scores.length < _song.length) {
      final g = _song[_scores.length];
      if (_t < g.start + g.length) break;
      final v = rules.coverage(g, [..._held[g.hole], ..._open(g.hole)]);
      _scores.add(v);
      final grade = rules.grade(v);
      final streak = _streak.hit(grade);
      if (grade != null) {
        _lastGrade = grade;
        _gradeAt = _t;
        _gradeHole = g.hole;
        celebrate(
          world,
          Vector2(_fluteX, _holeY(g.hole)),
          grade,
          sound: false,
          scale: 0.8,
          streak: streak,
          streakNote: false,
        );
      }
    }
    if (_scores.length == _song.length && _t > _song.last.start + _song.last.length + 1) _end();
  }

  /// Lo que lleva tapado el hueco [hole] y todavía no se soltó.
  Iterable<(double, double)> _open(int hole) => [
    for (final (h, from) in _fingers.values)
      if (h == hole) (from, _t),
  ];

  int _holeAt(double y) {
    var best = 0;
    for (var i = 1; i < FluteRules.holes; i++) {
      if ((y - _holeY(i)).abs() < (y - _holeY(best)).abs()) best = i;
    }
    return best;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_over) return;
    final hole = _holeAt(event.localPosition.y);
    if (!_covered(hole)) SoundBoard.instance.play(Sfx.fluteNote, variant: hole + 1, volume: 0.7);
    _fingers[event.pointerId] = (hole, _t);
    Haptics.light();
  }

  @override
  void onTapUp(TapUpEvent event) => _lift(event.pointerId);

  @override
  void onTapCancel(TapCancelEvent event) => _lift(event.pointerId);

  void _lift(int pointer) {
    final f = _fingers.remove(pointer);
    if (f != null) _held[f.$1].add((f.$2, _t));
  }

  void _end() {
    _over = true;
    final harmony = _scores.isEmpty ? 0.0 : _scores.reduce((a, v) => a + v) / _scores.length;
    final pct = (harmony * 100).round();
    final record = pct > Progress.instance.best('flute');
    Progress.instance.setBest('flute', pct);
    final stars = starsFor(harmony, rules.b.list('stars'));
    Future.delayed(const Duration(milliseconds: 1600), () {
      finish(RunOutcome(score: pct, stars: stars, headline: tr('flute.result', {'n': pct}), record: record));
    });
  }

  @override
  void render(Canvas canvas) {
    _drawGrove(canvas);
    _drawGusts(canvas);
    _drawFlute(canvas);
    super.render(canvas);
    _drawHud(canvas);
  }

  /// Cañas al fondo, borrosas.
  void _drawGrove(Canvas canvas) {
    final rng = Random(9);
    for (var i = 0; i < 14; i++) {
      final x = rng.nextDouble() * size.x, w = 10 + rng.nextDouble() * 16;
      canvas.drawRect(
        Rect.fromLTWH(x, 0, w, size.y),
        Paint()..color = const Color(0xFF8FAE6A).withValues(alpha: 0.12 + rng.nextDouble() * 0.12),
      );
    }
  }

  /// Ráfagas: cintas de viento que avanzan hacia la flauta por su fila.
  void _drawGusts(Canvas canvas) {
    // Una guía tenue por fila, para saber a qué hueco va cada ráfaga.
    final lane = Paint()
      ..color = Palette.ink.withValues(alpha: 0.07)
      ..strokeWidth = 2;
    for (var i = 0; i < FluteRules.holes; i++) {
      canvas.drawLine(Offset(_fluteX, _holeY(i)), Offset(size.x, _holeY(i)), lane);
    }
    for (var i = _scores.length; i < _song.length; i++) {
      final g = _song[i];
      final head = _fluteX + (g.start - _t) * _speed;
      if (head > size.x + 20) break;
      final tail = head + g.length * _speed;
      final y = _holeY(g.hole);
      final passing = head <= _fluteX && _fluteX <= tail;
      final good = passing && _covered(g.hole);
      final path = Path()..moveTo(max(head, _fluteX), y);
      for (var x = max(head, _fluteX); x <= tail; x += 6) {
        path.lineTo(x, y + sin(x / 18 + _t * 4) * 4);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 20
          ..color = const Color(0xFF8FAE6A).withValues(alpha: 0.35),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 14
          ..color = good ? Palette.lantern : const Color(0xFFFFFFFF).withValues(alpha: 0.9),
      );
      // Una hoja en la punta de la ráfaga.
      if (head > _fluteX) {
        canvas.save();
        canvas.translate(head, y);
        canvas.rotate(-0.4 + sin(_t * 3 + i) * 0.2);
        canvas.drawOval(const Rect.fromLTWH(-12, -4, 18, 8), Paint()..color = const Color(0xFF6C9450));
        canvas.restore();
      }
    }
  }

  /// La flauta vertical con sus cuatro huecos.
  void _drawFlute(Canvas canvas) {
    final top = _holeY(FluteRules.holes - 1) - size.y * 0.12, bottom = _holeY(0) + size.y * 0.1;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTRB(_fluteX - 16, top, _fluteX + 16, bottom),
      const Radius.circular(12),
    );
    canvas.drawRRect(body.shift(const Offset(3, 4)), Paint()..color = Palette.ink.withValues(alpha: 0.15));
    canvas.drawRRect(body, Paint()..color = const Color(0xFFD9C27E));
    final node = Paint()
      ..color = const Color(0xFFA88E4E)
      ..strokeWidth = 3;
    for (final y in [top + 24, bottom - 24, (_holeY(1) + _holeY(2)) / 2]) {
      canvas.drawLine(Offset(_fluteX - 16, y), Offset(_fluteX + 16, y), node);
    }
    for (var i = 0; i < FluteRules.holes; i++) {
      final c = Offset(_fluteX, _holeY(i));
      // El hueco que viene pide atención: un anillo que crece al acercarse.
      final next = _song.skip(_scores.length).where((g) => g.hole == i).firstOrNull;
      if (next != null) {
        final until = next.start - _t;
        if (until < 1.2 && until > -next.length) {
          final a = until > 0 ? 1 - until / 1.2 : 1.0;
          canvas.drawCircle(
            c,
            16 + 6 * a,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = Palette.lantern.withValues(alpha: 0.8 * a),
          );
        }
      }
      canvas.drawCircle(c, 8, Paint()..color = const Color(0xFF3B2E22));
      if (_covered(i)) canvas.drawCircle(c, 12, Paint()..color = const Color(0xFFE7C3A8));
    }
  }

  void _drawHud(Canvas canvas) {
    final done = _scores.length, total = _song.length;
    _text(canvas, tr('flute.progress', {'n': done, 'total': total}), Offset(size.x / 2, size.y * 0.08), 20);
    final String msg;
    if (_over) {
      final h = _scores.isEmpty ? 0.0 : _scores.reduce((a, v) => a + v) / _scores.length;
      msg = tr('flute.result', {'n': (h * 100).round()});
    } else if (_t < _song.first.start) {
      msg = tr('flute.hint');
    } else if (_t - _gradeAt < 1 && _lastGrade != null) {
      msg = tr('grade.${_lastGrade!.name}');
    } else {
      msg = '';
    }
    if (msg.isNotEmpty) {
      final y = _t - _gradeAt < 1 && !_over ? _holeY(_gradeHole) - 34 : size.y * 0.88;
      _text(canvas, msg, Offset(_t - _gradeAt < 1 && !_over ? _fluteX + 70 : size.x / 2, y), 17);
    }
  }

  void _text(Canvas canvas, String s, Offset center, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(color: Palette.ink.withValues(alpha: 0.85), fontSize: fontSize, fontWeight: FontWeight.w600),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.x - 48);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }
}
