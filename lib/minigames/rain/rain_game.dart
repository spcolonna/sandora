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
import '../../ui/garden/scene_art.dart';
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
  late final List<RainGust> gusts;
  late final RainJudge judge;
  late final double fall;

  double _t = 0;
  double _view = 1; // 1: mirando al meditador; 0: mirando al alero
  double? _outroAt;
  bool _finished = false;
  final _wobble = <int, double>{};

  /// Último toque en cada vasija, para el doble toque que la vacía.
  final _lastTap = <int, double>{};

  /// Desde cuándo se avisa cómo vaciar una vasija que rebalsa (solo la primera vez).
  double? _overflowHintAt;
  final _rng = Random();
  final _bgDrops = <_Drop>[]; // lluvia decorativa
  bool _windSound = false;

  @override
  Color backgroundColor() => const Color(0xFF7F95A0);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    final best = Progress.instance.rainBest;
    vessels = (b.i('vesselsStart') + (best >= 600 ? 2 : (best >= 300 ? 1 : 0))).clamp(3, b.i('vesselsMax'));
    final seed = DateTime.now().millisecondsSinceEpoch;
    notes = buildRainChart(b, vessels: vessels, seed: seed, leadIn: leadIn);
    gusts = rainGusts(b, seed: seed, leadIn: leadIn);
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
        SoundBoard.instance.stopLoop(Ambience.wind);
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
    final wind = _windNow;
    if (wind != 0 && !_windSound) {
      _windSound = true;
      SoundBoard.instance.loop(Ambience.wind, volume: 0.25, fade: const Duration(milliseconds: 600));
    } else if (wind == 0 && _windSound) {
      _windSound = false;
      SoundBoard.instance.stopLoop(Ambience.wind, fade: const Duration(milliseconds: 800));
    }
    for (final d in _bgDrops) {
      d.y += d.v * dt;
      d.x += wind * 260 * dt;
      if (d.y > size.y * 2) d.y = -20;
      if (d.x < -20) d.x += size.x + 40;
      if (d.x > size.x + 20) d.x -= size.x + 40;
    }
  }

  /// Viento ahora (-1 a 1), con subida y bajada suaves.
  double get _windNow {
    for (final g in gusts) {
      final e = _t - g.start;
      if (e < 0 || e > g.length) continue;
      return g.dir * sin(pi * e / g.length).clamp(0.0, 1.0);
    }
    return 0;
  }

  /// Ráfaga que viene (para avisar), o null.
  RainGust? get _gustComing =>
      gusts.where((g) => _t >= g.start - b.d('windWarning') && _t < g.start + g.length).firstOrNull;

  static double _ease(double x) => x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2;

  @override
  void onTapDown(TapDownEvent event) {
    if (_outroAt != null || _t < panSeconds * 0.8) return;
    final p = event.canvasPosition;
    // Toda la columna de la vasija bajo el alero cuenta: el blanco es enorme.
    if (p.y < size.y * 0.35) return;
    final i = (p.x / colW).floor().clamp(0, vessels - 1);
    final last = _lastTap[i];
    _lastTap[i] = _t;
    if (last != null && _t - last < b.d('doubleTapMs') / 1000 && judge.empty(i)) {
      // Vaciada: el agua sobrante se derrama y suena limpia otra vez.
      _wobble[i] = 1;
      _lastTap.remove(i);
      SoundBoard.instance.play(Sfx.good, volume: 0.4);
      _splash(Vector2(vesselX(i), rimY), Grade.perfect);
      return;
    }
    final spilling = judge.overflowing[i];
    final note = judge.tap(i, _t);
    _wobble[i] = 1;
    if (!spilling && judge.overflowing[i]) _overflowHintAt ??= _t;
    if (note == null) {
      SoundBoard.instance.play(Sfx.uiTap, volume: 0.2);
      return;
    }
    // Rebalsando, la nota suena apagada.
    final muffle = spilling ? 0.35 : 1.0;
    SoundBoard.instance.play(Sfx.rainNote, variant: i + 1, volume: (0.5 + 0.1 * note.grade!.index) * muffle);
    final at = Vector2(vesselX(i), rimY);
    _splash(at, note.grade!);
    celebrate(world, at, note.grade!, sound: false);
  }

  void _splash(Vector2 at, Grade g) {
    final crown = SceneArt.instance['fx_rain_splash'];
    if (crown != null) {
      // La corona de agua sale del borde, crece y se apaga.
      world.add(
        ParticleSystemComponent(
          position: at,
          particle: ComputedParticle(
            lifespan: 0.45,
            renderer: (canvas, p) {
              final w = vesselR * (1.1 + 0.2 * g.index) * (0.7 + 0.5 * p.progress);
              final h = w * crown.height / crown.width;
              drawArt(
                canvas,
                crown,
                Rect.fromLTWH(-w / 2, -h * 0.85, w, h),
                paint: Paint()..color = Color.fromRGBO(255, 255, 255, 0.9 * (1 - p.progress)),
              );
            },
          ),
        ),
      );
    }
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
    final roof = SceneArt.instance['bg_rain_roof'];
    if (roof != null) {
      // Arriba, el alero pintado; abajo, el piso de la galería espejado y más
      // grande (más cerca), hasta el meditador.
      final screen = Rect.fromLTWH(0, 0, size.x, size.y);
      drawArtCover(canvas, roof, screen);
      final k = size.y / roof.height;
      final srcW = size.x / k;
      final floor = Rect.fromLTWH((roof.width - srcW) / 2, roof.height * 0.76, srcW, roof.height * 0.24);
      // Franjas del piso a su tamaño, una espejada y otra no, sin costuras.
      final stripH = floor.height * k;
      for (var j = 0; size.y + j * stripH < size.y * 2; j++) {
        final top = size.y + j * stripH;
        canvas.save();
        if (j.isEven) {
          canvas.translate(0, top + stripH);
          canvas.scale(1, -1);
        } else {
          canvas.translate(0, top);
        }
        canvas.drawImageRect(
          roof,
          floor,
          Rect.fromLTWH(0, 0, size.x, stripH),
          Paint()..filterQuality = FilterQuality.medium,
        );
        canvas.restore();
      }
      canvas.drawRect(
        Rect.fromLTWH(0, size.y, size.x, size.y),
        Paint()
          ..shader = Gradient.linear(Offset(0, size.y), Offset(0, size.y * 2), [
            const Color(0x00000000),
            const Color(0x66000000),
          ]),
      );
      _drawRainLines(canvas, size.y * 0.74);
      return;
    }
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
    _drawRainLines(canvas, size.y * 2);
  }

  /// Lluvia de fondo, hasta [bottom].
  void _drawRainLines(Canvas canvas, double bottom) {
    final p = Paint()
      ..color = const Color(0x55E6F3F5)
      ..strokeWidth = 1.2;
    final slant = -1.5 + _windNow * 9;
    for (final d in _bgDrops) {
      if (d.y < bottom) canvas.drawLine(Offset(d.x, d.y), Offset(d.x - slant, d.y + 14), p);
    }
  }

  void _drawEave(Canvas canvas) {
    if (SceneArt.instance['bg_rain_roof'] != null) return;
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
    final level = judge.level(i);
    final img = SceneArt.instance['obj_rain_vessel_0${i % 5 + 1}'];
    if (img != null) {
      // Ancho (en radios), altura de la boca y ancho del agua, como fracción
      // de la imagen: la boca queda justo en el borde donde caen las gotas.
      const fit = [(2.4, 0.17, 0.5), (2.3, 0.17, 0.55), (2.6, 0.26, 0.65), (2.0, 0.15, 0.4), (2.6, 0.25, 0.72)];
      final (k, mouthY, mouthW) = fit[i % 5];
      final w = r * k, h = w * img.height / img.width;
      drawArt(canvas, img, Rect.fromLTWH(x - w / 2, rimY - h * mouthY, w, h));
      // El agua brilla más a medida que se llena.
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, rimY), width: w * mouthW * 0.85, height: w * mouthW * 0.24),
        Paint()..color = const Color(0xFFCDEBF0).withValues(alpha: 0.5 * level),
      );
      if (judge.overflowing[i]) _drawSpill(canvas, x, w * mouthW / 2, h * (1 - mouthY));
      return;
    }
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
    // El agua sube con los aciertos; rebalsando, desborda por los costados.
    final water = Color.lerp(const Color(0xFF2C4650), const Color(0xFF5C9EA8), level)!;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, rimY + 2 - 3 * level), width: r * 1.3, height: r * 0.28),
      Paint()..color = water,
    );
    if (judge.overflowing[i]) _drawSpill(canvas, x, r * 0.8, r * 1.6);
  }

  /// Agua que desborda por los dos lados de la boca ([half] desde el centro)
  /// y cae [depth] hasta el piso, donde hace un charco.
  void _drawSpill(Canvas canvas, double x, double half, double depth) {
    final drip = Paint()..color = const Color(0xFF8FC6D0).withValues(alpha: 0.85);
    for (final side in [-1.0, 1.0]) {
      for (var k = 0; k < 3; k++) {
        final fallK = ((_t * 0.9 + k / 3 + (side > 0 ? 0.5 : 0)) % 1);
        final dx = x + side * (half + half * 0.55 * sin(fallK * pi * 0.6));
        canvas.drawCircle(Offset(dx, rimY + depth * 0.94 * fallK), 2.6 * (1 - fallK * 0.5), drip);
      }
    }
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, rimY + depth), width: half * 2.8, height: half * 0.4),
      Paint()..color = const Color(0xFF8FC6D0).withValues(alpha: 0.35),
    );
  }

  void _drawNotes(Canvas canvas) {
    final drop = Paint()..color = const Color(0xFFE6F3F5);
    final dropArt = SceneArt.instance['fx_rain_drop'];
    for (final n in notes) {
      if (n.judged) continue;
      final spawn = n.time - fall;
      if (_t < spawn) continue;
      final p = ((_t - spawn) / fall).clamp(0.0, 1.2);
      // Con viento entra de costado y llega igual a su vasija.
      final x = vesselX(n.vessel) - n.wind * colW * b.d('windDrift') * pow(1 - p.clamp(0.0, 1.0), 1.4);
      // Caída con aceleración suave, como gravedad.
      final y = eaveY + (rimY - eaveY) * (0.35 * p + 0.65 * p * p);
      canvas.save();
      canvas.translate(x, y);
      if (n.wind != 0) canvas.rotate(-n.wind * 0.35 * (1 - p).clamp(0.2, 1.0));
      if (dropArt != null) {
        // La gota pintada tiene la estela arriba: la panza queda en (x, y).
        const w = 11.0;
        final h = w * dropArt.height / dropArt.width;
        drawArt(canvas, dropArt, Rect.fromLTWH(-w / 2, 8 - h, w, h));
      } else {
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 9, height: 15), drop);
      }
      canvas.restore();
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
    if (SceneArt.instance['bg_rain_roof'] != null) {
      // Sobre el piso de la galería: solo un almohadón.
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, base), width: 190, height: 34),
        Paint()..color = const Color(0xFF3A4660),
      );
    } else {
      canvas.drawRect(Rect.fromLTWH(0, base, size.x, size.y * 0.3), Paint()..color = const Color(0xFF4A3426));
    }
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
    final hintAt = _overflowHintAt;
    if (hintAt != null && _t - hintAt < 4 && judge.overflowing.contains(true)) {
      _text(canvas, tr('rain.overflow'), Offset(size.x / 2, size.y * 0.88), 16);
    }
    final gust = _gustComing;
    if (gust != null) {
      // Aviso: líneas de viento que cruzan y el texto mientras se acerca.
      final a = (_t < gust.start ? 0.2 : 0.35) * (0.6 + 0.4 * sin(_t * 6));
      final line = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: a)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var k = 0; k < 7; k++) {
        final r = Random(k);
        final y = size.y * (0.22 + 0.4 * r.nextDouble());
        final x = (gust.dir * (_t * 220 + k * 110)) % (size.x + 160) - 80;
        canvas.drawLine(Offset(x, y), Offset(x + gust.dir * 46, y), line);
      }
      if (_t < gust.start) _text(canvas, tr('leaves.wind'), Offset(size.x / 2, size.y * 0.33), 18);
    }
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
