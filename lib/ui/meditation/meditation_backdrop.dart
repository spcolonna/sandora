import 'dart:math';

import 'package:flutter/material.dart';

import '../garden/garden_scene.dart';
import '../garden/scene_art.dart';
import '../theme/palette.dart';

/// El patio pintado visto desde la tarima, para meditar: las mismas capas del
/// jardín, que respiran con el jugador (se acercan apenas al inhalar) y se
/// apagan hacia la noche durante la sesión, con los faroles y luciérnagas.
class MeditationBackdrop extends CustomPainter {
  /// Segundos desde que se abrió la pantalla (anima luciérnagas y hojas).
  final ValueNotifier<double> clock;

  /// 0: luz de la tarde; 1: noche cerrada.
  final double night;

  /// 0 a 1: luz cálida del amanecer al terminar.
  final double dawn;

  /// 0 a 1: cuánto aire hay (inhalar lo sube, exhalar lo baja).
  final double Function() breath;

  MeditationBackdrop({required this.clock, required this.night, required this.dawn, required this.breath})
    : super(repaint: clock);

  static bool get available => GardenLayout.hasCourtArt;

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Offset.zero & size;
    // El lienzo del patio cubre la pantalla con su proporción, centrado.
    final cw = max(size.width, size.height * GardenLayout.courtAspect);
    final canvasSize = Size(cw, cw / GardenLayout.courtAspect);
    final origin = Offset((size.width - cw) / 2, (size.height - canvasSize.height) / 2);
    final center = canvasSize.center(Offset.zero);
    final z = 1.06 + 0.035 * breath();

    canvas.save();
    canvas.clipRect(screen);
    canvas.translate(origin.dx, origin.dy);
    canvas.saveLayer(Offset.zero & canvasSize, Paint());
    void layer(String name, double depth) {
      final img = SceneArt.instance[name];
      if (img == null) return;
      final s = 1 + (z - 1) * depth;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(s);
      canvas.translate(-center.dx, -center.dy);
      drawArt(canvas, img, Offset.zero & canvasSize);
      canvas.restore();
    }

    layer('bg_court_sky', 0.15);
    layer('bg_court_far', 0.3);
    layer('bg_court_wall', 0.7);
    layer('bg_court_ground', 1);
    // Los objetos del patio, de atrás para adelante, a la altura del suelo.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(z);
    canvas.translate(-center.dx, -center.dy);
    final deck = GardenLayout.courtObjects[Place.meditation]!.$1;
    final objects = [
      for (final o in [...GardenLayout.courtObjects.values, ...GardenLayout.courtProps])
        if (GardenLayout.courtRect(o, canvasSize) case final r?) (r, o.$1),
    ]..sort((a, b) => a.$1.bottom.compareTo(b.$1.bottom));
    for (final (r, name) in objects) {
      final img = SceneArt.instance[name]!;
      if (name == deck) {
        canvas.save();
        canvas.translate(r.left + r.right, 0);
        canvas.scale(-1, 1);
        drawArt(canvas, img, r);
        canvas.restore();
      } else {
        drawArt(canvas, img, r);
      }
    }
    canvas.restore();
    layer('bg_court_side_left', 1.5);
    layer('bg_court_side_right', 1.5);
    // La hora: noche azul encima de todo y, al terminar, el amanecer.
    canvas.drawRect(
      Offset.zero & canvasSize,
      Paint()
        ..color = const Color(0xFF141C34).withValues(alpha: 0.74 * night)
        ..blendMode = BlendMode.srcATop,
    );
    canvas.drawRect(
      Offset.zero & canvasSize,
      Paint()
        ..color = const Color(0xFFE8955A).withValues(alpha: 0.2 * dawn)
        ..blendMode = BlendMode.srcATop,
    );
    canvas.restore();

    // Faroles encendidos a medida que oscurece.
    final glow = (night * 1.3).clamp(0.0, 1.0);
    if (glow > 0) {
      for (final c0 in GardenLayout.court(canvasSize).lanterns) {
        final c = center + (c0 - center) * z;
        final r = cw * 0.12 * (1 + 0.06 * sin(clock.value * 1.7 + c.dx));
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = RadialGradient(
              colors: [
                Palette.lantern.withValues(alpha: 0.5 * glow),
                Palette.lantern.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: c, radius: r)),
        );
        canvas.drawCircle(c, 3.5, Paint()..color = const Color(0xFFFFE2A8).withValues(alpha: glow));
      }
    }
    canvas.restore();

    _fireflies(canvas, size, glow);
    // Viñeta: los bordes se pierden y la mirada va al centro.
    canvas.drawRect(
      screen,
      Paint()
        ..shader = RadialGradient(
          radius: 0.95,
          colors: [
            const Color(0x00000000),
            const Color(0xFF0B0F1C).withValues(alpha: 0.25 + 0.4 * night),
          ],
          stops: const [0.55, 1],
        ).createShader(screen),
    );
  }

  /// Luciérnagas que flotan despacio por el patio cuando ya es de noche.
  void _fireflies(Canvas canvas, Size size, double glow) {
    if (glow <= 0) return;
    final t = clock.value;
    for (var i = 0; i < 14; i++) {
      final r = Random(i * 31 + 7);
      final bx = r.nextDouble(), by = 0.45 + 0.45 * r.nextDouble();
      final sp = 0.05 + 0.08 * r.nextDouble(), ph = r.nextDouble() * pi * 2;
      final x = size.width * (bx + 0.06 * sin(t * sp * 2 + ph));
      final y = size.height * (by + 0.04 * sin(t * sp * 3 + ph * 2));
      // Cada una se enciende y apaga a su ritmo.
      final blink = (0.5 + 0.5 * sin(t * (0.6 + r.nextDouble()) + ph)).clamp(0.0, 1.0);
      final a = glow * blink * blink;
      if (a < 0.02) continue;
      final c = Offset(x, y);
      canvas.drawCircle(
        c,
        9,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFE8F0A0).withValues(alpha: 0.45 * a),
              const Color(0x00E8F0A0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: 9)),
      );
      canvas.drawCircle(c, 1.6, Paint()..color = const Color(0xFFFFF8D0).withValues(alpha: a));
    }
  }

  @override
  bool shouldRepaint(MeditationBackdrop old) => old.night != night || old.dawn != dawn;
}

/// Guía de respiración: un ensō de tinta clara, pintado a pincel, que se abre
/// al inhalar y se cierra al exhalar, con una luz tibia adentro.
class BreathRing extends CustomPainter {
  final ValueNotifier<double> clock;
  final double Function() breath;

  BreathRing({required this.clock, required this.breath}) : super(repaint: clock);

  @override
  void paint(Canvas canvas, Size size) {
    final open = breath();
    final c = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;
    final r = maxR * (0.45 + 0.5 * open);
    // Penumbra detrás del ensō: el patio queda atrás y la palabra se lee.
    canvas.drawCircle(
      c,
      maxR * 1.4,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFF0B0F1C).withValues(alpha: 0.42), const Color(0x000B0F1C)],
        ).createShader(Rect.fromCircle(center: c, radius: maxR * 1.4)),
    );
    // La luz de adentro crece con el aire.
    canvas.drawCircle(
      c,
      r * 1.25,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Palette.lantern.withValues(alpha: 0.10 + 0.16 * open),
            Palette.lantern.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.25)),
    );
    // El trazo: varias pasadas finas que se abren y se afinan como un pincel,
    // con la apertura del ensō arriba a la derecha.
    const gap = 0.32;
    final start = -pi / 2 + gap / 2 + 0.25;
    for (var k = 0; k < 7; k++) {
      final f = k / 6;
      final rr = r + (f - 0.5) * maxR * 0.06;
      final path = Path();
      const steps = 90;
      for (var s = 0; s <= steps; s++) {
        final u = s / steps;
        final a = start + u * (2 * pi - gap);
        // El grosor baja hacia el final del trazo: las pasadas externas terminan antes.
        if (u > 1 - 0.35 * (f - 0.5).abs() * 2) break;
        final wob = 1 + 0.012 * sin(a * 5 + k);
        final p = c + Offset(cos(a), sin(a)) * rr * wob;
        s == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.2
          ..color = Palette.sandLight.withValues(alpha: (0.22 + 0.22 * open) * (1 - (f - 0.5).abs())),
      );
    }
  }

  @override
  bool shouldRepaint(BreathRing old) => false;
}
