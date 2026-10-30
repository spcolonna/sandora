import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight, TextPainter, TextSpan, TextAlign;

import '../../balance/balance.dart';
import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../../ui/fx/sfx.dart';
import '../../ui/garden/scene_art.dart';
import '../../ui/theme/palette.dart';
import '../common/grade.dart';
import '../common/minigame_screen.dart';
import 'matcha_rules.dart';

/// Casa de té: se bate el matcha en zigzag siguiendo el ritmo de la cuenta
/// que se mece sobre el cuenco. Con cada batida a tiempo crece la espuma.
class MatchaGame extends FlameGame with DragCallbacks {
  final void Function(RunOutcome) finish;
  final MatchaRules rules = MatchaRules(Balance.instance.section('matcha'));
  MatchaGame(this.finish);

  /// Segundos de partida; empieza con la primera batida.
  double _t = 0;
  bool _started = false, _over = false;
  double _sum = 0;

  // Batidor: dónde está y sus cambios de dirección.
  Offset? _whisk;
  final _tracker = WhiskTracker();
  Grade? _lastGrade;
  final _streak = Streak();
  double _gradeAt = -10;

  /// Burbujas de la espuma, en orden de aparición (ángulo, radio, tamaño).
  late final List<(double, double, double)> _bubbles = () {
    final rng = Random(7);
    return [for (var i = 0; i < 260; i++) (rng.nextDouble() * 2 * pi, sqrt(rng.nextDouble()), 0.6 + rng.nextDouble())];
  }();

  double get _foam => rules.foam(_sum);
  Offset get _bowl => Offset(size.x / 2, size.y * 0.52);
  double get _bowlR => size.x * 0.36;

  @override
  Color backgroundColor() => const Color(0xFFD8C7A6);

  @override
  void update(double dt) {
    super.update(dt);
    if (!_started || _over) return;
    final before = rules.tempoAt(_t);
    _t += dt;
    if (_t >= rules.duration) {
      _end();
    } else if (rules.tempoAt(_t) != before) {
      Haptics.light();
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_over) return;
    _whisk = event.localPosition.toOffset();
    _started = true;
    _tracker.start(_whisk!.dx, _t);
    SoundBoard.instance.loop(Ambience.rake, volume: 0.25, fade: const Duration(milliseconds: 300));
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_over || _whisk == null) return;
    _whisk = event.localEndPosition.toOffset();
    final stroke = _tracker.move(_whisk!.dx, _t);
    if (stroke == null || stroke.interval < 0.04) return;
    final v = rules.strokeValue(stroke.interval, stroke.reach / (_bowlR * 2), rules.tempoAt(_t));
    _sum += v;
    final g = rules.grade(v);
    if (g != null && _t - _gradeAt > 1.2) {
      _lastGrade = g;
      _gradeAt = _t;
      // La espuma brilla en el tazón con cada buen batido.
      celebrate(world, Vector2(_bowl.dx, _bowl.dy), g, sound: false, label: false, scale: 0.8, streak: _streak.hit(g));
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _whisk = null;
    SoundBoard.instance.stopLoop(Ambience.rake, fade: const Duration(milliseconds: 300));
  }

  void _end() {
    _over = true;
    _whisk = null;
    SoundBoard.instance.stopLoop(Ambience.rake);
    final foam = _foam;
    final pct = (foam * 100).round();
    final record = pct > Progress.instance.best('matcha');
    Progress.instance.setBest('matcha', pct);
    final stars = starsFor(foam, rules.b.list('stars'));
    final g = rules.grade(foam);
    if (g != null) celebrate(world, Vector2(_bowl.dx, _bowl.dy), g);
    Future.delayed(const Duration(milliseconds: 2000), () {
      finish(RunOutcome(score: pct, stars: stars, headline: tr('matcha.result', {'n': pct}), record: record));
    });
  }

  @override
  void render(Canvas canvas) {
    _drawMat(canvas);
    _drawBowl(canvas);
    if (!_over) _drawPendulum(canvas);
    _drawWhisk(canvas);
    super.render(canvas);
    _drawHud(canvas);
  }

  /// Tatami: franjas de paja.
  void _drawMat(Canvas canvas) {
    final line = Paint()
      ..color = const Color(0xFFC4AF86)
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.y; y += 7) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), line);
    }
    canvas.drawRect(Rect.fromLTWH(0, size.y * 0.2, size.x, 10), Paint()..color = const Color(0xFF5E6B3A));
  }

  /// Cuenco (chawan) visto desde arriba, con el té y la espuma.
  void _drawBowl(Canvas canvas) {
    final c = _bowl, r = _bowlR;
    canvas.drawCircle(
      c + const Offset(0, 8),
      r * 1.18,
      Paint()
        ..color = Palette.ink.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    final art = SceneArt.instance['obj_tea_bowl'];
    canvas.save();
    if (art != null) {
      // Boca de `obj_tea_bowl` (fracciones): el té ocupa ese óvalo.
      final w = r * 2.58, h = w * art.height / art.width;
      drawArt(canvas, art, Rect.fromLTWH(c.dx - w * 0.519, c.dy - h * 0.429, w, h));
      final ky = h * 0.357 / (w * 0.403);
      canvas.translate(c.dx, c.dy);
      canvas.scale(1, ky);
      canvas.translate(-c.dx, -c.dy);
    } else {
      canvas.drawCircle(c, r * 1.18, Paint()..color = const Color(0xFF4B3A2E));
      canvas.drawCircle(
        c,
        r * 1.18,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = const Color(0xFF8A6F55),
      );
    }
    final foam = _foam;
    final tea = Color.lerp(const Color(0xFF6E8F2E), const Color(0xFF9DBB55), foam)!;
    // Más oscuro contra la pared del cuenco.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = Gradient.radial(
          c - Offset(r * 0.15, r * 0.2),
          r * 1.15,
          [Color.lerp(tea, const Color(0xFFFFFFFF), 0.12)!, tea, Color.lerp(tea, const Color(0xFF1E2A10), 0.35)!],
          [0, 0.6, 1],
        ),
    );
    // La espuma aparece de a poco: cada burbuja tiene su turno.
    final shown = (_bubbles.length * foam).round();
    final bubble = Paint()..color = const Color(0xFFD7E6A4).withValues(alpha: 0.85);
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFF8DA94A);
    for (var i = 0; i < shown; i++) {
      final (a, d, s) = _bubbles[i];
      final p = c + Offset(cos(a), sin(a)) * (d * r * 0.95);
      final br = r * 0.028 * s * (0.6 + 0.4 * foam);
      canvas.drawCircle(p, br, bubble);
      canvas.drawCircle(p, br, rim);
    }
    canvas.restore();
  }

  /// La cuenta que se mece al ritmo ideal: ir y volver son dos batidas.
  void _drawPendulum(Canvas canvas) {
    final tempo = rules.tempoAt(_t);
    final phase = _started ? _t * tempo * pi : 0.0;
    final y = size.y * 0.27, half = _bowlR * 0.8;
    canvas.drawLine(
      Offset(size.x / 2 - half, y),
      Offset(size.x / 2 + half, y),
      Paint()
        ..color = Palette.ink.withValues(alpha: 0.2)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(size.x / 2 - half * cos(phase), y), 9, Paint()..color = Palette.lantern);
  }

  /// El batidor de bambú (chasen), donde está el dedo.
  void _drawWhisk(Canvas canvas) {
    final w = _whisk;
    if (w == null) return;
    final tine = Paint()
      ..color = const Color(0xFFE6D3A3)
      ..strokeWidth = 2;
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * 2 * pi;
      canvas.drawLine(w, w + Offset(cos(a), sin(a)) * 22, tine);
    }
    canvas.drawCircle(w, 10, Paint()..color = const Color(0xFFCDB37C));
  }

  void _drawHud(Canvas canvas) {
    // Tiempo que queda: una barra fina.
    final left = _started ? 1 - _t / rules.duration : 1.0;
    final bar = Rect.fromLTWH(size.x * 0.2, size.y * 0.88, size.x * 0.6, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar, const Radius.circular(3)),
      Paint()..color = Palette.ink.withValues(alpha: 0.15),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bar.left, bar.top, bar.width * left.clamp(0, 1), bar.height),
        const Radius.circular(3),
      ),
      Paint()..color = Palette.mossDark,
    );
    _text(canvas, tr('matcha.foam', {'n': (_foam * 100).round()}), Offset(size.x / 2, size.y * 0.1), 24);
    final String msg;
    if (_over) {
      msg = tr('matcha.result', {'n': (_foam * 100).round()});
    } else if (!_started) {
      msg = tr('matcha.hint');
    } else if (_t - _gradeAt < 1 && _lastGrade != null) {
      msg = tr('grade.${_lastGrade!.name}');
    } else if (_t % rules.phaseSeconds < 1.5 && _t > 1) {
      final now = rules.tempoAt(_t), before = rules.tempoAt(_t - rules.phaseSeconds);
      msg = now > before ? tr('matcha.faster') : tr('matcha.slower');
    } else {
      msg = '';
    }
    if (msg.isNotEmpty) _text(canvas, msg, Offset(size.x / 2, size.y * 0.83), 17);
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
