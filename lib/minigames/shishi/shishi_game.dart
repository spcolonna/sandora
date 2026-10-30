import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flame/game.dart';
import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle, FontWeight, TextDirection;

import '../../balance/balance.dart';
import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../../ui/fx/sfx.dart';
import '../../ui/garden/scene_art.dart';
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
/// vuelca el agua en el cuenco y al volver golpea la piedra.
class ShishiGame extends FlameGame with TapCallbacks {
  final void Function(RunOutcome) finish;
  final BalanceSection b = Balance.instance.section('shishi');
  ShishiGame(this.finish);

  final _rng = Random();
  int _round = 0, _points = 0, _perfects = 0;
  final _streak = Streak();
  double _fill = 0;
  double _flow = 0, _phase = 0;
  double _drip = 0; // agua que queda en el caño al soltar
  bool _holding = false;
  bool _over = false;

  /// Vuelco: el bambú baja, derrama, vuelve y golpea la piedra.
  double _tip = 0;
  bool _tipping = false;
  bool _clacked = false;
  double _t = 0;

  /// Gotas sueltas (salpicadura del rebalse y lo que cae al cuenco).
  final _drops = <(Offset, Offset, double)>[];

  /// Ondas en el cuenco: tiempo de vida de cada una.
  final _ripples = <double>[];

  static const _tipTime = 1.3;

  int get _rounds => b.i('rounds');

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _newRound();
  }

  @override
  void onRemove() {
    SoundBoard.instance.stopLoop(Ambience.rain, fade: const Duration(milliseconds: 200));
    super.onRemove();
  }

  void _newRound() {
    _fill = 0;
    _drip = 0;
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
    // El chorro suena mientras cae (la lluvia suave hace de hilo de agua).
    SoundBoard.instance.loop(Ambience.rain, volume: 0.18, fade: const Duration(milliseconds: 150));
  }

  @override
  void onTapUp(TapUpEvent event) => _release();

  @override
  void onTapCancel(TapCancelEvent event) => _release();

  void _release() {
    if (!_holding) return;
    _holding = false;
    SoundBoard.instance.stopLoop(Ambience.rain, fade: const Duration(milliseconds: 350));
    if (!_canPour || _fill <= 0.02) return;
    // Lo que queda en el caño sigue cayendo un ratito (azar).
    _drip = b.d('dripMin') + _rng.nextDouble() * (b.d('dripMax') - b.d('dripMin'));
  }

  double get _rate => _flow * (1 + b.d('pulse') * sin(_t * 3.1 + _phase) + 0.5 * b.d('pulse') * sin(_t * 7.3));

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _updateDrops(dt);
    if (_tipping) {
      _updateTip(dt);
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
    if (_fill > 1) {
      // Rebalsó: el agua salta por la boca y el bambú vuelca antes de tiempo.
      _holding = false;
      _drip = 0;
      SoundBoard.instance.stopLoop(Ambience.rain, fade: const Duration(milliseconds: 200));
      _judge();
    }
  }

  void _updateDrops(double dt) {
    final bowl = _bowl;
    for (var i = 0; i < _drops.length; i++) {
      final (p, v, life) = _drops[i];
      var np = p + v * dt;
      var nl = life - dt;
      // Lo que cae en el cuenco se suma al agua y hace una onda.
      if (v.dy > 0 && bowl.contains(np) && np.dy > bowl.center.dy - 4) {
        if (_rng.nextDouble() < 0.25) _ripples.add(0);
        nl = 0;
      }
      if (np.dy > _ground) {
        np = Offset(np.dx, _ground);
        nl = min(nl, 0.1);
      }
      _drops[i] = (np, v + Offset(0, 1100 * dt), nl);
    }
    _drops.removeWhere((s) => s.$3 <= 0);
    for (var i = 0; i < _ripples.length; i++) {
      _ripples[i] += dt;
    }
    _ripples.removeWhere((r) => r > 1.2);
  }

  void _updateTip(double dt) {
    _tip += dt / _tipTime;
    // Mientras está volcado, el agua sale por la boca hacia el cuenco.
    if (_tip > 0.15 && _tip < 0.55 && _fill > 0) {
      final m = _tubeTip();
      for (var k = 0; k < 2; k++) {
        _drops.add((
          m + Offset(_rng.nextDouble() * 6 - 3, 0),
          Offset(-30 - _rng.nextDouble() * 60, 40 + _rng.nextDouble() * 60),
          1.2,
        ));
      }
    }
    // Al volver, el extremo cerrado golpea la piedra: el "toc".
    if (!_clacked && _tip >= 0.78) {
      _clacked = true;
      SoundBoard.instance.play(Sfx.stackPlace, volume: 0.45 + 0.4 * min(1, _fill));
      Haptics.medium();
    }
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
  }

  void _judge() {
    final grade = shishiGrade(_fill, b);
    final c = _tubeTip();
    if (grade != null) {
      _points += grade.points;
      if (grade == Grade.perfect) _perfects++;
      celebrate(world, Vector2(c.dx, c.dy - 40), grade, streak: _streak.hit(grade));
    } else if (_fill > 1) {
      _streak.miss();
      Haptics.light();
      for (var i = 0; i < 16; i++) {
        _drops.add((c, Offset((_rng.nextDouble() - 0.5) * 260, -60 - _rng.nextDouble() * 220), 1.2));
      }
    }
    _tipping = true;
    _clacked = false;
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

  double get _ground => size.y * 0.72;

  /// Bajo, para que el extremo cerrado apoye en una piedra chata.
  Offset get _pivot => Offset(size.x * 0.52, _ground - size.x * 0.12 - 64);
  double get _len => size.x * 0.62;
  static const _thick = 30.0;
  static const _restAngle = -0.42;
  static const _tipAngle = 0.6;

  /// Cuánto del vuelco va (0 arriba, 1 boca abajo): baja rápido, se queda
  /// derramando, vuelve acelerando y rebota apenas en la piedra.
  double get _tipK {
    final t = _tip;
    if (t < 0.18) return Curves.easeIn.transform(t / 0.18);
    if (t < 0.5) return 1;
    if (t < 0.78) return 1 - Curves.easeIn.transform((t - 0.5) / 0.28);
    return -0.12 * sin(pi * (t - 0.78) / 0.22);
  }

  /// Agua que se ve adentro: se vacía mientras está volcado.
  double get _shownFill {
    final f = min(1.0, _fill);
    if (!_tipping) return f;
    return f * (1 - ((_tip - 0.12) / 0.4).clamp(0.0, 1.0));
  }

  /// Ángulo del bambú: con la boca arriba mientras se llena (el agua lo va
  /// inclinando); vuelca con la boca hacia el cuenco.
  double get _angle {
    final rest = _restAngle + 0.25 * _shownFill;
    if (!_tipping) return rest;
    final k = _tipK;
    return k >= 0 ? rest + (_tipAngle - rest) * k : rest + k * 0.5;
  }

  Offset _along(double a, double along) => _pivot + Offset(cos(a), -sin(a)) * along;

  Offset _tubeTip([double? a]) => _along(a ?? _angle, -_len * 0.55);

  /// Caño fijo: su boca queda arriba de donde está la boca del bambú vacío.
  Offset get _spout {
    final m = _tubeTip(_restAngle);
    return Offset(m.dx + 6, m.dy - size.y * 0.13);
  }

  Rect get _bowl {
    final m = _tubeTip(_tipAngle);
    return Rect.fromCenter(center: Offset(m.dx - 10, _ground), width: size.x * 0.3, height: 40);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Offset.zero & Size(size.x, size.y),
      Paint()
        ..shader = Gradient.linear(Offset.zero, Offset(0, size.y), [const Color(0xFFD9E6DA), const Color(0xFFEDE5D0)]),
    );
    final ground = _ground;
    canvas.drawRect(Rect.fromLTWH(0, ground, size.x, size.y - ground), Paint()..color = Palette.moss);
    // Piedra donde apoya el extremo cerrado en reposo.
    final heel = _along(_restAngle, _len * 0.45) + const Offset(0, _thick / 2);
    final stone = Rect.fromLTRB(heel.dx - size.x * 0.11, heel.dy, heel.dx + size.x * 0.1, ground + 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(stone.shift(const Offset(0, 4)), Radius.circular(stone.width * 0.4)),
      Paint()..color = Palette.ink.withValues(alpha: 0.12),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(stone, Radius.circular(stone.width * 0.4)),
      Paint()..color = Palette.stoneDark,
    );
    canvas.drawOval(
      Rect.fromLTWH(stone.left + 8, stone.top + 5, stone.width * 0.5, 8),
      Paint()..color = const Color(0x22FFFFFF),
    );
    // Poste en horqueta.
    final post = Paint()..color = const Color(0xFF6E7F45);
    for (final dx in [-12.0, 12.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(_pivot.dx + dx - 5, _pivot.dy - 10, _pivot.dx + dx + 5, ground),
          const Radius.circular(3),
        ),
        post,
      );
    }
    _paintFeed(canvas);
    // El cuenco va delante del soporte del caño.
    _paintBowl(canvas);
    _paintBamboo(canvas);
    final drop = Paint();
    for (final (p, _, life) in _drops) {
      canvas.drawCircle(p, 2.5 + 1.5 * min(1, life), drop..color = Palette.water.withValues(alpha: min(1, life * 2)));
    }
    // Rondas: puntitos abajo.
    for (var i = 0; i < _rounds; i++) {
      final c = Offset(size.x / 2 + (i - (_rounds - 1) / 2) * 18, size.y * 0.86);
      canvas.drawCircle(c, 5, Paint()..color = i < _round ? Palette.paper : Palette.ink.withValues(alpha: 0.15));
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

  void _paintBowl(Canvas canvas) {
    final bowl = _bowl;
    final art = SceneArt.instance['obj_shishi_basin'];
    final Rect water;
    if (art != null) {
      // El cuenco pintado, con su agua donde estaba el óvalo.
      final w = bowl.width * 1.3, h = w * art.height / art.width;
      final dst = Rect.fromLTWH(bowl.center.dx - w / 2, bowl.center.dy - h * 0.19, w, h);
      canvas.drawOval(
        Rect.fromLTRB(dst.left + w * 0.05, dst.bottom - h * 0.12, dst.right - w * 0.05, dst.bottom + h * 0.04),
        Paint()..color = Palette.ink.withValues(alpha: 0.12),
      );
      drawArt(canvas, art, dst);
      water = Rect.fromLTRB(dst.left + w * 0.19, dst.top + h * 0.05, dst.right - w * 0.19, dst.top + h * 0.32);
    } else {
      canvas.drawOval(bowl.shift(const Offset(0, 5)), Paint()..color = Palette.ink.withValues(alpha: 0.12));
      canvas.drawOval(bowl, Paint()..color = Palette.stoneDark);
      water = bowl.deflate(7);
      canvas.drawOval(water, Paint()..color = Palette.water);
    }
    canvas.save();
    canvas.clipPath(Path()..addOval(water));
    for (final r in _ripples) {
      final k = r / 1.2;
      canvas.drawOval(
        Rect.fromCenter(center: water.center, width: water.width * (0.15 + 0.85 * k), height: water.height * k),
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.5 * (1 - k))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    canvas.restore();
  }

  /// Caño de bambú que llega desde la izquierda, con su soporte, y el chorro.
  void _paintFeed(Canvas canvas) {
    final spout = _spout;
    final from = Offset(-10, spout.dy - 18);
    final pipe = Paint()
      ..color = const Color(0xFF9DB06A)
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    // Soporte: dos palos cruzados.
    final cross = Offset.lerp(from, spout, 0.3)!;
    final stick = Paint()
      ..color = const Color(0xFF6E7F45)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(cross + const Offset(4, -16), Offset(cross.dx - 26, _ground), stick);
    canvas.drawLine(cross + const Offset(-4, -16), Offset(cross.dx + 26, _ground), stick);
    canvas.drawLine(from, spout, pipe);
    canvas.drawOval(
      Rect.fromCenter(center: spout + const Offset(2, 0), width: 9, height: 20),
      Paint()..color = const Color(0xFF55633A),
    );
    final pouring = (_holding || _drip > 0) && !_tipping;
    if (!pouring) return;
    final mouth = _tubeTip();
    final w = 3 + 6 * (_rate / b.d('flowMax')).clamp(0.2, 1.4);
    final top = spout + const Offset(4, 6);
    // El chorro ondula apenas.
    final path = Path()..moveTo(top.dx, top.dy);
    for (var s = 1; s <= 6; s++) {
      final y = top.dy + (mouth.dy - 6 - top.dy) * s / 6;
      path.lineTo(top.dx + sin(_t * 18 + s) * 0.8 * s / 6, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Palette.water.withValues(alpha: _holding ? 0.85 : 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _holding ? w : w * 0.5
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintBamboo(Canvas canvas) {
    canvas.save();
    canvas.translate(_pivot.dx, _pivot.dy);
    canvas.rotate(-_angle);
    const h = _thick;
    final tube = Rect.fromLTWH(-_len * 0.55, -h / 2, _len, h);
    final rr = RRect.fromRectAndRadius(tube, const Radius.circular(12));
    final art = SceneArt.instance['obj_shishi_bamboo'];
    if (art != null) {
      // El bambú pintado (boca a la izquierda), con su alto proporcional.
      final ah = _len * art.height / art.width;
      drawArt(canvas, art, Rect.fromLTWH(tube.left, -ah / 2, _len, ah));
    } else {
      canvas.drawRRect(
        rr,
        Paint()
          ..shader = Gradient.linear(Offset(0, -h / 2), Offset(0, h / 2), [
            const Color(0xFFB3C77E),
            const Color(0xFF8A9D58),
          ]),
      );
    }
    // Agua adentro: crece desde la boca hacia el centro.
    final fill = _shownFill;
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
    if (art == null) {
      final node = Paint()..color = const Color(0xFF6E7F45);
      for (final x in [-0.25, 0.1, 0.32]) {
        canvas.drawRect(Rect.fromLTWH(_len * x, -h / 2, 3, h), node);
      }
      // Boca cortada en bisel.
      canvas.drawOval(
        Rect.fromCenter(center: Offset(tube.left + 4, 0), width: 10, height: h),
        Paint()..color = const Color(0xFF55633A),
      );
    }
    canvas.restore();
    canvas.drawCircle(_pivot, 6, Paint()..color = Palette.wood);
  }
}
