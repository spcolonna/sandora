import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight, TextPainter, TextSpan, TextAlign;

import '../../balance/balance.dart';
import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../../ui/fx/sfx.dart';
import '../../ui/theme/palette.dart';
import '../common/grade.dart';
import '../common/minigame_screen.dart';
import 'rain_chart.dart';

/// Lluvia en vasijas: la cámara sube del meditador al alero, llueve, y cada
/// gota se toca cuando llega a su vasija. Las notas están en pentatónica, así
/// que cualquier secuencia de aciertos suena bien. Sin sonido se juega
/// mirando: cada gota proyecta un anillo que se cierra sobre su vasija.
class RainGame extends FlameGame with TapCallbacks {
  final void Function(RunOutcome) finish;
  final BalanceSection b = Balance.instance.rain;

  RainGame(this.finish);

  static const leadIn = 3.2;
  static const panSeconds = 1.8;

  late final int vessels;
  late final List<RainNote> notes;
  late final RainJudge judge;
  late final double fall;

  double _t = 0;
  double _view = 1; // 1: mirando al meditador; 0: mirando al alero
  double? _outroAt;
  bool _finished = false;
  final _wobble = <int, double>{};
  final _rng = Random();
  final _bgDrops = <_Drop>[]; // lluvia decorativa

  @override
  Color backgroundColor() => const Color(0xFF7F95A0);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    final best = Progress.instance.rainBest;
    vessels = (b.i('vesselsStart') + (best >= 600 ? 2 : (best >= 300 ? 1 : 0))).clamp(3, b.i('vesselsMax'));
    notes = buildRainChart(b, vessels: vessels, seed: DateTime.now().millisecondsSinceEpoch, leadIn: leadIn);
    judge = RainJudge(notes, b);
    fall = b.d('fallSeconds');
    SoundBoard.instance.loop(Ambience.rain, volume: 0.35);
  }

  // Geometría (en píxeles de pantalla, con la vista en el alero).
  double get eaveY => size.y * 0.17;
  double get rimY => size.y * 0.70;
  double get colW => size.x / vessels;
  double get vesselR => min(colW * 0.36, 48);
  double vesselX(int i) => colW * (i + 0.5);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_outroAt == null) {
      _view = 1 - _ease((_t / panSeconds).clamp(0, 1));
      judge.expire(_t);
      final last = notes.isEmpty ? 0 : notes.last.time;
      if (judge.done && _t > last + 0.8) _outroAt = _t;
    } else {
      final p = ((_t - _outroAt!) / panSeconds).clamp(0.0, 1.0);
      _view = _ease(p);
      if (!_finished && _t - _outroAt! > panSeconds + 1.6) {
        _finished = true;
        SoundBoard.instance.stopLoop(Ambience.rain);
        final acc = judge.accuracy;
        final record = Progress.instance.setRainScore(judge.score);
        finish(
          RunOutcome(
            score: judge.score,
            stars: starsFor(acc, b.list('stars')),
            headline: '${tr('rain.depth')}\n${(acc * 100).round()}%',
            record: record,
          ),
        );
      }
    }
    for (final k in _wobble.keys.toList()) {
      _wobble[k] = max(0, _wobble[k]! - dt * 2);
    }
    // Lluvia de fondo, solo decorativa.
    if (_bgDrops.length < 70) {
      _bgDrops.add(_Drop(_rng.nextDouble() * size.x, -_rng.nextDouble() * size.y, 500 + _rng.nextDouble() * 300));
    }
    for (final d in _bgDrops) {
      d.y += d.v * dt;
      if (d.y > size.y * 2) d.y = -20;
    }
  }

  static double _ease(double x) => x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2;

  @override
  void onTapDown(TapDownEvent event) {
    if (_outroAt != null || _t < panSeconds * 0.8) return;
    final p = event.canvasPosition;
    // Toda la columna de la vasija bajo el alero cuenta: el blanco es enorme.
    if (p.y < size.y * 0.35) return;
    final i = (p.x / colW).floor().clamp(0, vessels - 1);
    final note = judge.tap(i, _t);
    _wobble[i] = 1;
    if (note == null) {
      SoundBoard.instance.play(Sfx.uiTap, volume: 0.2);
      return;
    }
    SoundBoard.instance.play(Sfx.rainNote, variant: i + 1, volume: 0.5 + 0.1 * note.grade!.index);
    final at = Vector2(vesselX(i), rimY);
    _splash(at, note.grade!);
    celebrate(world, at, note.grade!, sound: false);
  }

  void _splash(Vector2 at, Grade g) {
    world.add(
      ParticleSystemComponent(
        position: at,
        particle: Particle.generate(
          count: 5 + 3 * g.index,
          lifespan: 0.75,
          // Gotitas que suben poco y vuelven a caer despacio, apagándose.
          generator: (_) => AcceleratedParticle(
            speed: Vector2((_rng.nextDouble() - 0.5) * 90, -60 - _rng.nextDouble() * 70),
            acceleration: Vector2(0, 260),
            child: ComputedParticle(
              renderer: (canvas, p) => canvas.drawCircle(
                Offset.zero,
                2.2,
                Paint()..color = const Color(0xFFE6F3F5).withValues(alpha: 0.8 * (1 - p.progress * p.progress)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final off = _view * size.y;
    canvas.save();
    canvas.translate(0, -off);
    _drawBackdrop(canvas);
    _drawMeditator(canvas);
    _drawEave(canvas);
    for (var i = 0; i < vessels; i++) {
      _drawVessel(canvas, i);
    }
    _drawNotes(canvas);
    canvas.restore();
    super.render(canvas);
    _drawHud(canvas, off);
  }

  void _drawBackdrop(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y * 2);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(0, size.y * 2),
          [const Color(0xFF6F8794), const Color(0xFF9DB0AE), const Color(0xFF55606A)],
          [0, 0.5, 1],
        ),
    );
    final p = Paint()
      ..color = const Color(0x55E6F3F5)
      ..strokeWidth = 1.2;
    for (final d in _bgDrops) {
      canvas.drawLine(Offset(d.x, d.y), Offset(d.x - 1.5, d.y + 14), p);
    }
  }

  void _drawEave(Canvas canvas) {
    final y = eaveY;
    final wood = Paint()..color = const Color(0xFF4A3426);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, y - 14), Paint()..color = const Color(0xFF3B4146));
    // Tejas: semicírculos a lo largo del borde.
    final tile = Paint()..color = const Color(0xFF555D63);
    for (var x = 0.0; x < size.x + 20; x += 22) {
      canvas.drawCircle(Offset(x, y - 14), 11, tile);
    }
    canvas.drawRect(Rect.fromLTWH(0, y - 8, size.x, 10), wood);
    // Viga del techo del meditador (abajo).
    canvas.drawRect(Rect.fromLTWH(0, size.y * 1.08, size.x, 16), wood);
  }

  void _drawVessel(Canvas canvas, int i) {
    final x = vesselX(i);
    final r = vesselR * (1 + 0.045 * sin((_wobble[i] ?? 0) * pi * 2) * (_wobble[i] ?? 0));
    final body = Path()
      ..moveTo(x - r * 0.75, rimY)
      ..quadraticBezierTo(x - r * 1.35, rimY + r * 0.9, x - r * 0.6, rimY + r * 1.6)
      ..lineTo(x + r * 0.6, rimY + r * 1.6)
      ..quadraticBezierTo(x + r * 1.35, rimY + r * 0.9, x + r * 0.75, rimY)
      ..close();
    final hue = [Palette.wood, Palette.water, Palette.moss, Palette.lantern, Palette.stoneDark][i % 5];
    canvas.drawPath(body, Paint()..color = Color.lerp(hue, Palette.ink, 0.25)!);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, rimY), width: r * 1.6, height: r * 0.42),
      Paint()..color = Color.lerp(hue, Palette.ink, 0.55)!,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, rimY + 2), width: r * 1.3, height: r * 0.28),
      Paint()..color = const Color(0xFF2C4650),
    );
  }

  void _drawNotes(Canvas canvas) {
    final drop = Paint()..color = const Color(0xFFE6F3F5);
    for (final n in notes) {
      if (n.judged) continue;
      final spawn = n.time - fall;
      if (_t < spawn) continue;
      final p = ((_t - spawn) / fall).clamp(0.0, 1.2);
      final x = vesselX(n.vessel);
      // Caída con aceleración suave, como gravedad.
      final y = eaveY + (rimY - eaveY) * (0.35 * p + 0.65 * p * p);
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 9, height: 15), drop);
      // Anillo que se cierra justo sobre la vasija en el momento del acierto.
      final ringR = vesselR * (0.8 + 2.2 * (1 - p).clamp(0, 1));
      canvas.drawCircle(
        Offset(x, rimY),
        ringR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = Color.fromRGBO(255, 255, 255, (p * 0.8).clamp(0, 0.8)),
      );
    }
  }

  void _drawMeditator(Canvas canvas) {
    final cx = size.x / 2;
    final base = size.y * 1.78;
    final ink = Paint()..color = const Color(0xFF2B2F33);
    canvas.drawRect(Rect.fromLTWH(0, base, size.x, size.y * 0.3), Paint()..color = const Color(0xFF4A3426));
    final body = Path()
      ..moveTo(cx - 70, base)
      ..quadraticBezierTo(cx - 60, base - 70, cx - 22, base - 110)
      ..lineTo(cx + 22, base - 110)
      ..quadraticBezierTo(cx + 60, base - 70, cx + 70, base)
      ..close();
    canvas.drawPath(body, ink);
    canvas.drawCircle(Offset(cx, base - 132), 24, ink);
  }

  void _drawHud(Canvas canvas, double off) {
    if (_outroAt != null && _view > 0.95) {
      _text(canvas, '${tr('rain.depth')}\n${(judge.accuracy * 100).round()}%', Offset(size.x / 2, size.y * 0.3), 30);
      return;
    }
    if (_view > 0.1) return;
    if (judge.combo >= 3) {
      _text(canvas, tr('rain.combo', {'n': judge.combo}), Offset(size.x / 2, size.y * 0.27), 22);
    }
    if (_t < leadIn + 1.5) _text(canvas, tr('rain.hint'), Offset(size.x / 2, size.y * 0.88), 16);
    final last = notes.isEmpty ? 1.0 : notes.last.time;
    final p = (_t / last).clamp(0.0, 1.0);
    canvas.drawRect(Rect.fromLTWH(0, size.y - 4, size.x * p, 4), Paint()..color = const Color(0x88FFFFFF));
  }

  void _text(Canvas canvas, String s, Offset center, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(color: const Color(0xFFF7F0DE), fontSize: fontSize, fontWeight: FontWeight.w600),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.x - 48);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }
}

class _Drop {
  double x, y;
  final double v;
  _Drop(this.x, this.y, this.v);
}
