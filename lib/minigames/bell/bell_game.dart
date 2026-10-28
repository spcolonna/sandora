import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight, TextPainter, TextSpan, TextAlign, LinearGradient;

import '../../balance/balance.dart';
import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../../ui/fx/sfx.dart';
import '../../ui/theme/palette.dart';
import '../common/grade.dart';
import '../common/minigame_screen.dart';
import 'bell_rules.dart';

/// Campana del templo: se tira el tronco colgado hacia atrás hasta la marca
/// y se suelta. Cinco golpes, cada uno con su fuerza; entre golpe y golpe hay
/// que esperar a que la campana se apague.
class BellGame extends FlameGame with DragCallbacks {
  final void Function(RunOutcome) finish;
  final BellRules rules = BellRules(Balance.instance.section('bell'));
  BellGame(this.finish);

  late final List<double> _targets = rules.targets(Random());
  final _scores = <double>[];
  double _t = 0;

  /// Cuánto está tirado el tronco (0 en reposo, 1 al máximo) y su velocidad
  /// mientras vuela hacia la campana o vuelve.
  double _pull = 0, _vel = 0;
  bool _holding = false, _flying = false, _over = false;

  /// Fuerza con que se soltó (la del golpe).
  double _released = 0;
  double _lastForce = 0, _lastHit = -100;
  Grade? _lastGrade;

  double get _ring => rules.ringAfter(_lastForce, _t - _lastHit);
  int get _strike => _scores.length;

  // Geometría.
  Offset get _bell => Offset(size.x * 0.66, size.y * 0.36);
  double get _bellR => size.x * 0.2;
  double get _maxPull => size.x * 0.24;
  double get _logLen => size.x * 0.22;
  double get _logY => _bell.dy + _bellR * 0.35;

  /// Punta del tronco: en reposo apenas toca la campana.
  double get _tipX => _bell.dx - _bellR * 0.92 - _pull * _maxPull;

  @override
  Color backgroundColor() => const Color(0xFFDCCFB4);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_flying) {
      // Vuela hacia la campana, más rápido cuanto más se tiró.
      _vel += dt * (6 + 14 * _released);
      _pull -= _vel * dt;
      if (_pull <= 0) _hit();
    } else if (!_holding && _pull != 0) {
      // Rebote y vuelta al reposo, amortiguado.
      _vel += (-_pull * 30 - _vel * 6) * dt;
      _pull += _vel * dt;
      if (_pull.abs() < 0.002 && _vel.abs() < 0.01) _pull = _vel = 0;
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_over || _flying || _pull.abs() > 0.02) return;
    _holding = true;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_holding) return;
    _pull = (_pull - event.localDelta.x / _maxPull).clamp(0.0, 1.0);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_holding) return;
    _holding = false;
    if (_pull < 0.05) {
      _pull = 0;
      return;
    }
    _released = _pull;
    _flying = true;
    _vel = 0;
  }

  void _hit() {
    _flying = false;
    _pull = 0;
    // Rebota un poco hacia atrás.
    _vel = 0.6 + _released;
    final score = rules.strikeScore(_released, _targets[_strike], _ring);
    _scores.add(score);
    _lastForce = _released;
    _lastHit = _t;
    _lastGrade = rules.grade(score);
    SoundBoard.instance.play(Sfx.bell, volume: 0.3 + 0.6 * _released);
    Haptics.medium();
    if (_lastGrade != null) celebrate(world, Vector2(_bell.dx, _bell.dy), _lastGrade!, sound: false);
    if (_strike >= rules.strikes) _end();
  }

  void _end() {
    _over = true;
    final harmony = _scores.reduce((a, v) => a + v) / _scores.length;
    final pct = (harmony * 100).round();
    final record = pct > Progress.instance.best('bell');
    Progress.instance.setBest('bell', pct);
    final stars = starsFor(harmony, rules.b.list('stars'));
    Future.delayed(const Duration(milliseconds: 2200), () {
      finish(RunOutcome(score: pct, stars: stars, headline: tr('bell.result', {'n': pct}), record: record));
    });
  }

  @override
  void render(Canvas canvas) {
    _drawFrame(canvas);
    _drawRings(canvas);
    _drawBell(canvas);
    if (!_over) _drawGauge(canvas);
    _drawLog(canvas);
    super.render(canvas);
    _drawHud(canvas);
  }

  /// Las vigas del campanario.
  void _drawFrame(Canvas canvas) {
    final wood = Paint()..color = Palette.wood;
    canvas.drawRect(Rect.fromLTWH(0, size.y * 0.08, size.x, 16), wood);
    for (final x in [size.x * 0.06, size.x * 0.92]) {
      canvas.drawRect(Rect.fromLTWH(x, size.y * 0.08, 14, size.y * 0.62), wood);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, size.y * 0.7, size.x, size.y * 0.3),
      Paint()..color = Palette.stone.withValues(alpha: 0.5),
    );
  }

  /// Ondas que salen de la campana mientras resuena.
  void _drawRings(Canvas canvas) {
    final ring = _ring;
    if (ring < 0.02) return;
    final since = _t - _lastHit;
    for (var k = 0; k < 4; k++) {
      final f = ((since * 0.8 + k / 4) % 1);
      canvas.drawCircle(
        _bell,
        _bellR * (1 + 1.6 * f),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = Palette.lantern.withValues(alpha: 0.5 * ring * (1 - f)),
      );
    }
  }

  /// La campana de bronce (bonshō), que tiembla un poco al sonar.
  void _drawBell(Canvas canvas) {
    final shake = sin(_t * 40) * 2.5 * _ring;
    final c = _bell + Offset(shake, 0);
    final r = _bellR;
    canvas.drawLine(
      Offset(c.dx, size.y * 0.08),
      c - Offset(0, r * 1.3),
      Paint()
        ..color = Palette.stoneDark
        ..strokeWidth = 5,
    );
    final body = RRect.fromRectAndCorners(
      Rect.fromCenter(center: c, width: r * 1.9, height: r * 2.5),
      topLeft: Radius.circular(r * 0.9),
      topRight: Radius.circular(r * 0.9),
      bottomLeft: Radius.circular(r * 0.12),
      bottomRight: Radius.circular(r * 0.12),
    );
    final bronze = Color.lerp(const Color(0xFF5E5240), const Color(0xFF8E7A4E), 0.5 + 0.5 * _ring)!;
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: [Color.lerp(bronze, Palette.ink, 0.3)!, bronze, Color.lerp(bronze, Palette.ink, 0.4)!],
        ).createShader(body.outerRect),
    );
    // Bandas y botones del bronce.
    final band = Paint()..color = Palette.ink.withValues(alpha: 0.25);
    for (final f in [0.3, 0.62]) {
      final y = body.top + body.height * f;
      canvas.drawRect(Rect.fromLTRB(body.left, y - 2, body.right, y + 2), band);
    }
    for (var i = 0; i < 4; i++) {
      for (var j = 0; j < 3; j++) {
        canvas.drawCircle(
          Offset(c.dx - r * 0.6 + i * r * 0.4, body.top + body.height * (0.1 + j * 0.06)),
          2.4,
          Paint()..color = Palette.ink.withValues(alpha: 0.3),
        );
      }
    }
    // El punto donde pega el tronco.
    canvas.drawCircle(Offset(c.dx - r * 0.55, _logY), r * 0.14, Paint()..color = Palette.ink.withValues(alpha: 0.2));
  }

  /// El tronco (shumoku) colgado de dos sogas.
  void _drawLog(Canvas canvas) {
    final tip = _tipX;
    final log = Rect.fromLTRB(tip - _logLen, _logY - 13, tip, _logY + 13);
    final rope = Paint()
      ..color = const Color(0xFFB59A6A)
      ..strokeWidth = 2.5;
    for (final f in [0.25, 0.75]) {
      final x = log.left + log.width * f;
      // Las sogas cuelgan de un punto fijo: al tirar, se inclinan.
      final anchor = Offset(_bell.dx - _bellR * 0.92 - _logLen * (1 - f), size.y * 0.08 + 16);
      canvas.drawLine(anchor, Offset(x, log.top), rope);
    }
    canvas.drawRRect(RRect.fromRectAndRadius(log, const Radius.circular(12)), Paint()..color = Palette.wood);
    canvas.drawRRect(
      RRect.fromRectAndRadius(log.deflate(4).translate(0, -3), const Radius.circular(10)),
      Paint()..color = const Color(0xFFA9774F),
    );
    canvas.drawCircle(Offset(log.right - 4, log.center.dy), 10, Paint()..color = const Color(0xFF6D4630));
  }

  /// Debajo del tronco: hasta dónde tirar este golpe (la banda) y cuánto se
  /// está tirando (la marca).
  void _drawGauge(Canvas canvas) {
    final y = _logY + 40;
    final x0 = _bell.dx - _bellR * 0.92;
    double xAt(double pull) => x0 - pull * _maxPull;
    canvas.drawLine(
      Offset(xAt(0), y),
      Offset(xAt(1), y),
      Paint()
        ..color = Palette.ink.withValues(alpha: 0.2)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    final target = _targets[min(_strike, _targets.length - 1)];
    final half = rules.b.d('zoneWidth') * 0.5;
    canvas.drawLine(
      Offset(xAt(target - half), y),
      Offset(xAt(target + half), y),
      Paint()
        ..color = Palette.lantern
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(xAt(target), y), 3, Paint()..color = Palette.paper);
    if (_holding || _flying) {
      canvas.drawCircle(Offset(xAt(_pull.clamp(0, 1)), y), 8, Paint()..color = Palette.ink);
    }
  }

  void _drawHud(Canvas canvas) {
    // Golpes: un punto por cada uno, lleno los ya dados.
    for (var i = 0; i < rules.strikes; i++) {
      final c = Offset(size.x / 2 + (i - (rules.strikes - 1) / 2) * 22, size.y * 0.76);
      canvas.drawCircle(
        c,
        6,
        Paint()
          ..color = i < _strike ? Palette.lantern : Palette.ink.withValues(alpha: 0.2)
          ..style = i < _strike ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    final String msg;
    if (_over) {
      msg = tr('bell.result', {'n': (_scores.reduce((a, v) => a + v) / _scores.length * 100).round()});
    } else if (_strike == 0 && _pull == 0 && !_holding) {
      msg = tr('bell.hint');
    } else if (_t - _lastHit < 1.2 && _lastGrade != null) {
      msg = tr('grade.${_lastGrade!.name}');
    } else if (!_holding && !_flying && _ring > rules.quiet) {
      msg = tr('bell.wait');
    } else {
      msg = '';
    }
    if (msg.isNotEmpty) _text(canvas, msg, Offset(size.x / 2, size.y * 0.86), 17);
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
