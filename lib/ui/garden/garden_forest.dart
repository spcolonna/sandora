import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/palette.dart';
import 'scene_art.dart';

/// Lugares de la vista del bosque: el arte pintado si está y, si no, con código.

/// Bosquecillo de bambú: cañas con nudos y matas de hojas arriba.
void paintBambooGrove(Canvas canvas, Rect r) {
  final art = SceneArt.instance['obj_bamboo_grove'];
  if (art != null) {
    _groundShadow(canvas, r, 0.7);
    drawArtIn(canvas, art, r);
    return;
  }
  final rng = Random(21);
  final w = r.width, h = r.height;
  canvas.drawOval(
    Rect.fromLTRB(r.left + w * 0.04, r.bottom - h * 0.06, r.right - w * 0.04, r.bottom + h * 0.03),
    Paint()..color = Palette.ink.withValues(alpha: 0.12),
  );
  const culms = 9;
  for (var i = 0; i < culms; i++) {
    // Las del fondo, más claras y finas.
    final back = i.isEven;
    final x = r.left + w * (0.08 + 0.84 * (i + rng.nextDouble() * 0.6) / culms);
    final top = r.top + h * (back ? 0.02 : 0.1) + rng.nextDouble() * h * 0.08;
    final cw = w * (back ? 0.035 : 0.05);
    final lean = (rng.nextDouble() - 0.5) * w * 0.06;
    final green = back ? const Color(0xFF8FAE6A) : const Color(0xFF6C9450);
    final cane = Path()
      ..moveTo(x - cw / 2, r.bottom)
      ..lineTo(x + lean - cw * 0.4, top)
      ..lineTo(x + lean + cw * 0.4, top)
      ..lineTo(x + cw / 2, r.bottom)
      ..close();
    canvas.drawPath(cane, Paint()..color = green);
    final node = Paint()
      ..color = const Color(0xFF4F7039)
      ..strokeWidth = 1.4;
    for (var y = r.bottom - h * 0.12; y > top + h * 0.05; y -= h * (0.11 + rng.nextDouble() * 0.03)) {
      final f = (r.bottom - y) / (r.bottom - top);
      final cx = x + lean * f;
      canvas.drawLine(Offset(cx - cw * 0.5, y), Offset(cx + cw * 0.5, y), node);
    }
    // Hojas finas en abanico.
    final leaf = Paint()..color = (back ? const Color(0xFF7FA05A) : const Color(0xFF557C3E)).withValues(alpha: 0.9);
    for (var k = 0; k < 5; k++) {
      final base = Offset(x + lean * 0.95, top + h * (0.04 + k * 0.05));
      final a = (k.isEven ? -1 : 1) * (0.5 + rng.nextDouble() * 0.6);
      canvas.save();
      canvas.translate(base.dx, base.dy);
      canvas.rotate(a);
      canvas.drawOval(Rect.fromLTWH(0, -h * 0.012, w * 0.13, h * 0.024), leaf);
      canvas.restore();
    }
  }
}

/// Casita de té: tarima, paredes de shoji, techo oscuro y un farolito.
void paintTeahouse(Canvas canvas, Rect r, Offset lamp) {
  final art = SceneArt.instance['obj_tea_house'];
  if (art != null) {
    _groundShadow(canvas, r, 0.95);
    drawArtIn(canvas, art, r);
    _hangingLamp(canvas, lamp, r.height * 0.07);
    return;
  }
  final w = r.width, h = r.height;
  canvas.drawOval(
    Rect.fromLTRB(r.left, r.bottom - h * 0.05, r.right, r.bottom + h * 0.04),
    Paint()..color = Palette.ink.withValues(alpha: 0.14),
  );
  final dark = Paint()..color = const Color(0xFF5E3D28);
  // Tarima de madera.
  canvas.drawRect(Rect.fromLTRB(r.left + w * 0.04, r.bottom - h * 0.14, r.right - w * 0.04, r.bottom), dark);
  canvas.drawRect(
    Rect.fromLTRB(r.left + w * 0.02, r.bottom - h * 0.17, r.right - w * 0.02, r.bottom - h * 0.12),
    Paint()..color = Palette.wood,
  );
  // Paredes de papel con su reja.
  final wall = Rect.fromLTRB(r.left + w * 0.12, r.top + h * 0.42, r.right - w * 0.12, r.bottom - h * 0.17);
  canvas.drawRect(wall, Paint()..color = Palette.paper);
  final grid = Paint()
    ..color = Palette.wood
    ..strokeWidth = 1.2;
  for (var i = 1; i < 6; i++) {
    final x = wall.left + wall.width * i / 6;
    canvas.drawLine(Offset(x, wall.top), Offset(x, wall.bottom), grid);
  }
  for (var i = 1; i < 3; i++) {
    final y = wall.top + wall.height * i / 3;
    canvas.drawLine(Offset(wall.left, y), Offset(wall.right, y), grid);
  }
  for (final x in [wall.left, wall.center.dx, wall.right]) {
    canvas.drawRect(Rect.fromLTRB(x - w * 0.02, wall.top, x + w * 0.02, wall.bottom), dark);
  }
  // Noren (cortina) en la entrada.
  final noren = Rect.fromLTRB(
    wall.center.dx - w * 0.14,
    wall.top,
    wall.center.dx + w * 0.14,
    wall.top + wall.height * 0.4,
  );
  canvas.drawRect(noren, Paint()..color = const Color(0xFF3F5A6E));
  canvas.drawLine(
    Offset(noren.center.dx, noren.top + noren.height * 0.25),
    Offset(noren.center.dx, noren.bottom),
    Paint()
      ..color = Palette.paper
      ..strokeWidth = 1.5,
  );
  // Techo con aleros curvos.
  final roof = Path()
    ..moveTo(r.left, r.top + h * 0.46)
    ..quadraticBezierTo(r.left + w * 0.1, r.top + h * 0.38, r.left + w * 0.2, r.top + h * 0.12)
    ..lineTo(r.right - w * 0.2, r.top + h * 0.12)
    ..quadraticBezierTo(r.right - w * 0.1, r.top + h * 0.38, r.right, r.top + h * 0.46)
    ..close();
  canvas.drawPath(roof, Paint()..color = const Color(0xFF3B3836));
  canvas.drawRect(
    Rect.fromLTRB(r.left + w * 0.18, r.top + h * 0.06, r.right - w * 0.18, r.top + h * 0.13),
    Paint()..color = const Color(0xFF2A2725),
  );
  // Farolito colgado del alero (se enciende de noche).
  canvas.drawLine(Offset(lamp.dx, r.top + h * 0.42), lamp, dark..strokeWidth = 1.2);
  canvas.drawOval(
    Rect.fromCenter(center: lamp, width: w * 0.07, height: h * 0.09),
    Paint()..color = const Color(0xFFD8643F),
  );
}

/// Farolito de la casa de té: colgado del alero izquierdo de `obj_tea_house`
/// o, sin arte, del techo dibujado.
Offset teahouseLamp(Rect r) {
  final art = SceneArt.instance['obj_tea_house'];
  if (art == null) return Offset(r.left + r.width * 0.1, r.top + r.height * 0.52);
  final d = artRectIn(art, r);
  return Offset(d.left + d.width * 0.12, d.top + d.height * 0.58);
}

/// Sombra apoyada en el suelo, de [width] del ancho de [r].
void _groundShadow(Canvas canvas, Rect r, double width) {
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(r.center.dx, r.bottom - r.height * 0.01),
      width: r.width * width,
      height: r.height * 0.08,
    ),
    Paint()
      ..color = Palette.ink.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
  );
}

/// Farolito colgado de un cordel de [cord] de largo (se enciende de noche).
void _hangingLamp(Canvas canvas, Offset lamp, double cord) {
  canvas.drawLine(
    lamp - Offset(0, cord),
    lamp,
    Paint()
      ..color = const Color(0xFF5E3D28)
      ..strokeWidth = 1.2,
  );
  canvas.drawOval(
    Rect.fromCenter(center: lamp, width: cord * 0.5, height: cord * 0.7),
    Paint()..color = const Color(0xFFD8643F),
  );
}

/// Río que cruza el bosque, con piedras en las orillas y dos linternas.
void paintRiver(Canvas canvas, Rect r) {
  final w = r.width, h = r.height;
  // El cauce baja en curva: más alto a la izquierda.
  Path band(double grow) {
    final top = [0.18, 0.02, 0.22, 0.08];
    final bottom = [0.74, 0.62, 0.86, 0.7];
    final p = Path()..moveTo(r.left - 2, r.top + h * top[0] - grow);
    p.cubicTo(
      r.left + w * 0.33,
      r.top + h * top[1] - grow,
      r.left + w * 0.66,
      r.top + h * top[2] - grow,
      r.right + 2,
      r.top + h * top[3] - grow,
    );
    p.lineTo(r.right + 2, r.top + h * bottom[3] + grow);
    p.cubicTo(
      r.left + w * 0.66,
      r.top + h * bottom[2] + grow,
      r.left + w * 0.33,
      r.top + h * bottom[1] + grow,
      r.left - 2,
      r.top + h * bottom[0] + grow,
    );
    return p..close();
  }

  canvas.drawPath(band(h * 0.06), Paint()..color = const Color(0xFFB8A784));
  final water = band(0);
  canvas.drawPath(
    water,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF6FAAB2), Palette.water, Color(0xFF497F8C)],
      ).createShader(r),
  );
  // Rayitas de corriente.
  canvas.save();
  canvas.clipPath(water);
  final flow = Paint()
    ..color = Colors.white.withValues(alpha: 0.35)
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round;
  final rng = Random(4);
  for (var i = 0; i < 16; i++) {
    final o = Offset(r.left + rng.nextDouble() * w, r.top + h * (0.15 + rng.nextDouble() * 0.6));
    canvas.drawLine(o, o + Offset(w * (0.04 + rng.nextDouble() * 0.05), h * 0.01), flow);
  }
  canvas.restore();
  // Piedras de la orilla.
  final stone = Paint()..color = Palette.stone;
  for (final (x, y, s) in [(0.06, 0.8, 1.0), (0.14, 0.86, 0.7), (0.8, 0.1, 0.9), (0.9, 0.06, 0.6), (0.52, 0.9, 0.8)]) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(r.left + w * x, r.top + h * y), width: w * 0.07 * s, height: h * 0.1 * s),
      stone,
    );
  }
  // Dos linternas flotando.
  for (final (x, y) in [(0.3, 0.36), (0.64, 0.46)]) {
    final c = Offset(r.left + w * x, r.top + h * y);
    final s = w * 0.035;
    canvas.drawRect(
      Rect.fromCenter(center: c + Offset(0, s * 0.7), width: s * 1.8, height: s * 0.4),
      Paint()..color = Palette.wood,
    );
    canvas.drawRect(
      Rect.fromCenter(center: c, width: s * 1.3, height: s * 1.3),
      Paint()..color = const Color(0xFFF6DDA8),
    );
    canvas.drawRect(
      Rect.fromCenter(center: c, width: s * 1.3, height: s * 1.3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Palette.wood,
    );
  }
}
