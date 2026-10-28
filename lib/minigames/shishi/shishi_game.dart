import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle, FontWeight, TextDirection;

import '../../balance/balance.dart';
import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../../ui/fx/sfx.dart';
import '../../ui/theme/palette.dart';
import '../common/grade.dart';
import '../common/minigame_screen.dart';

/// Cómo terminó una ronda según lo lleno que quedó el bambú (0 a 1; más de 1
/// es que rebalsó).
Grade? shishiGrade(double fill, BalanceSection b) {
  if (fill > 1) return null;
  if (fill >= b.d('perfectFrom')) return Grade.perfect;
  if (fill >= b.d('greatFrom')) return Grade.great;
  if (fill >= b.d('goodFrom')) return Grade.good;
  return null;
}

/// Shishi-odoshi: mientras se mantiene apretado, el agua llena el bambú; hay
/// que soltar justo antes de que rebalse. El chorro cambia de fuerza en cada
/// ronda y late un poco (nunca es igual), y al soltar todavía cae lo que
/// quedaba en el caño: hay que anticiparse. Al final de cada ronda el bambú
/// golpea la piedra.
class ShishiGame extends FlameGame with TapCallbacks {
  final void Function(RunOutcome) finish;
  final BalanceSection b = Balance.instance.section('shishi');
  ShishiGame(this.finish);

  final _rng = Random();
  int _round = 0, _points = 0, _perfects = 0;
  double _fill = 0;
  double _flow = 0, _phase = 0;
  double _drip = 0; // agua que queda en el caño al soltar
  bool _holding = false;
  bool _over = false;

  /// Animación del golpe: el bambú baja, vuelca y vuelve.
  double _tip = 0;
  bool _tipping = false;
  bool _spilled = false;
  double _t = 0;
  final _splash = <(Offset, Offset, double)>[];

  int get _rounds => b.i('rounds');

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _newRound();
  }

  void _newRound() {
    _fill = 0;
    _drip = 0;
    _spilled = false;
    // Cada ronda el chorro es otro, y más rápido a medida que avanza.
    final k = _round / max(1, _rounds - 1);
    _flow = b.d('flowMin') + (b.d('flowMax') - b.d('flowMin')) * (0.3 * k + 0.7 * _rng.nextDouble());
    _phase = _rng.nextDouble() * 2 * pi;
  }

  bool get _canPour => !_over && !_tipping;

  @override
  void onTapDown(TapDownEvent event) {
    if (!_canPour) return;
    _holding = true;
  }

  @override
  void onTapUp(TapUpEvent event) => _release();

  @override
  void onTapCancel(TapCancelEvent event) => _release();

  void _release() {
    if (!_holding) return;
    _holding = false;
    if (!_canPour || _fill <= 0.02) return;
    // Lo que queda en el caño sigue cayendo un ratito (azar).
    _drip = b.d('dripMin') + _rng.nextDouble() * (b.d('dripMax') - b.d('dripMin'));
  }

  double get _rate => _flow * (1 + b.d('pulse') * sin(_t * 3.1 + _phase) + 0.5 * b.d('pulse') * sin(_t * 7.3));

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    for (var i = 0; i < _splash.length; i++) {
      final (p, v, life) = _splash[i];
      _splash[i] = (p + v * dt, v + Offset(0, 900 * dt), life - dt);
    }
    _splash.removeWhere((s) => s.$3 <= 0);
    if (_tipping) {
      _tip += dt / 0.9;
      if (_tip >= 1) {
        _tipping = false;
        _tip = 0;
        _round++;
        if (_round >= _rounds) {
          _end();
        } else {
          _newRound();
        }
      }
      return;
    }
    if (_over) return;
    if (_holding) {
      _fill += _rate * dt;
    } else if (_drip > 0) {
      final d = min(_drip, dt);
      _drip -= d;
      _fill += _rate * d;
      if (_drip <= 0) _judge();
    }
    if (_fill > 1 && !_spilled) {
      // Rebalsó: el agua se derrama y el bambú vuelca antes de tiempo.
      _spilled = true;
      _holding = false;
      _drip = 0;
      _judge();
    }
  }

  void _judge() {
    final grade = shishiGrade(_fill, b);
    final c = _tubeTip();
    if (grade != null) {
      _points += grade.points;
      if (grade == Grade.perfect) _perfects++;
      celebrate(world, Vector2(c.dx, c.dy - 30), grade);
    } else {
      Haptics.light();
      for (var i = 0; i < 14; i++) {
        _splash.add((
          c,
          Offset((_rng.nextDouble() - 0.3) * 260, -_rng.nextDouble() * 260),
          0.5 + _rng.nextDouble() * 0.4,
        ));
      }
    }
    // El golpe del bambú sobre la piedra: más lleno, más fuerte.
    SoundBoard.instance.play(Sfx.stackPlace, volume: 0.35 + 0.5 * min(1, _fill));
    _tipping = true;
  }

  void _end() {
    _over = true;
    final record = _points > Progress.instance.best('shishi');
    Progress.instance.setBest('shishi', _points);
    final stars = starsFor(_points.toDouble(), b.list('stars'));
    finish(
      RunOutcome(
        score: _points,
        stars: stars,
        headline: tr('shishi.result', {'n': _perfects, 'total': _rounds}),
        record: record,
      ),
    );
  }

  // --- Dibujo ---

  Offset get _pivot => Offset(size.x * 0.52, size.y * 0.5);
  double get _len => size.x * 0.62;

  /// Ángulo del bambú: con la boca arriba mientras se llena; vuelca al
  /// llenarse (y vuelve).
  double get _angle {
    final rest = -0.42 + 0.25 * min(1, _fill);
    if (!_tipping) return rest;
    final k = sin(pi * _tip);
    return rest + (0.95 - rest) * k;
  }

  Offset _tubeTip() {
    final a = _angle;
    return _pivot + Offset(-cos(a), sin(a)) * _len * 0.55;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Offset.zero & Size(size.x, size.y),
      Paint()
        ..shader = Gradient.linear(Offset.zero, Offset(0, size.y), [const Color(0xFFD9E6DA), const Color(0xFFEDE5D0)]),
    );
    final ground = size.y * 0.72;
    canvas.drawRect(Rect.fromLTWH(0, ground, size.x, size.y - ground), Paint()..color = Palette.moss);
    // Piedra donde golpea el bambú y el cuenco que recibe el agua.
    final stone = Rect.fromCenter(center: Offset(size.x * 0.84, ground - 6), width: size.x * 0.2, height: 28);
    canvas.drawOval(stone, Paint()..color = Palette.stoneDark);
    final bowl = Rect.fromCenter(center: Offset(size.x * 0.2, ground), width: size.x * 0.3, height: 40);
    canvas.drawOval(bowl, Paint()..color = Palette.stoneDark);
    canvas.drawOval(bowl.deflate(7), Paint()..color = Palette.water);
    // Poste.
    final post = Paint()..color = const Color(0xFF6E7F45);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(_pivot.dx - 10, _pivot.dy - 6, _pivot.dx + 10, ground),
        const Radius.circular(4),
      ),
      post,
    );
    // Caño de arriba, el chorro y lo que gotea al soltar.
    final mouth = _tubeTip();
    final feed = Rect.fromLTWH(size.x * 0.02, mouth.dy - size.y * 0.13, size.x * 0.21, 22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(feed, const Radius.circular(11)),
      Paint()..color = const Color(0xFF9DB06A),
    );
    final pouring = _holding || _drip > 0;
    if (pouring && !_tipping) {
      final w = 3 + 6 * (_rate / b.d('flowMax')).clamp(0.2, 1.4);
      final from = Offset(feed.right - 8, feed.bottom - 4);
      canvas.drawLine(
        from,
        Offset(from.dx, mouth.dy),
        Paint()
          ..color = Palette.water.withValues(alpha: _holding ? 0.85 : 0.5)
          ..strokeWidth = _holding ? w : w * 0.5
          ..strokeCap = StrokeCap.round,
      );
    }
    _paintBamboo(canvas);
    final drop = Paint()..color = Palette.water;
    for (final (p, _, life) in _splash) {
      canvas.drawCircle(p, 3 + 2 * life, drop..color = Palette.water.withValues(alpha: min(1, life * 2)));
    }
    // Rondas: puntitos abajo.
    for (var i = 0; i < _rounds; i++) {
      final c = Offset(size.x / 2 + (i - (_rounds - 1) / 2) * 18, size.y * 0.86);
      canvas.drawCircle(c, 5, Paint()..color = i < _round ? Palette.moss : Palette.ink.withValues(alpha: 0.15));
    }
    if (_round == 0 && _fill == 0 && !_holding) {
      final tp = TextPainter(
        text: TextSpan(
          text: tr('shishi.hint'),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Palette.ink),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.x - 60);
      tp.paint(canvas, Offset((size.x - tp.width) / 2, size.y * 0.14));
    }
    super.render(canvas);
  }

  void _paintBamboo(Canvas canvas) {
    canvas.save();
    canvas.translate(_pivot.dx, _pivot.dy);
    canvas.rotate(-_angle);
    final h = 30.0;
    final tube = Rect.fromLTWH(-_len * 0.55, -h / 2, _len, h);
    final rr = RRect.fromRectAndRadius(tube, const Radius.circular(12));
    canvas.drawRRect(rr, Paint()..color = const Color(0xFF9DB06A));
    // Agua adentro: crece desde la boca hacia el centro.
    final fill = min(1.0, _fill);
    if (fill > 0) {
      canvas.save();
      canvas.clipRRect(rr.deflate(4));
      canvas.drawRect(
        Rect.fromLTWH(tube.left, -h / 2, _len * 0.55 * fill, h),
        Paint()..color = Palette.water.withValues(alpha: 0.75),
      );
      canvas.restore();
    }
    // Marca del punto justo (lo que se aprende a mirar).
    final mark = tube.left + _len * 0.55 * b.d('perfectFrom');
    canvas.drawLine(
      Offset(mark, -h / 2 - 4),
      Offset(mark, -h / 2 + 3),
      Paint()
        ..color = Palette.ink.withValues(alpha: 0.35)
        ..strokeWidth = 2,
    );
    final node = Paint()..color = const Color(0xFF6E7F45);
    for (final x in [-0.25, 0.1, 0.32]) {
      canvas.drawRect(Rect.fromLTWH(_len * x, -h / 2, 3, h), node);
    }
    canvas.drawOval(
      Rect.fromCenter(center: Offset(tube.left + 4, 0), width: 10, height: h),
      Paint()..color = const Color(0xFF55633A),
    );
    canvas.restore();
    canvas.drawCircle(_pivot, 6, Paint()..color = Palette.wood);
  }
}
