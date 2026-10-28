import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/palette.dart';

/// Lugares de la vista del estanque, dibujados con código hasta tener arte.

/// Estanque con lotos y hojas flotando.
void paintPond(Canvas canvas, Rect r) {
  final water = Rect.fromCenter(center: r.center, width: r.width, height: r.height * 0.8);
  canvas.drawOval(water.inflate(6), Paint()..color = Palette.stoneDark.withValues(alpha: 0.5));
  canvas.drawOval(
    water,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF6FA9B0), Color(0xFF3F7F8C)],
      ).createShader(water),
  );
  // Piedras del borde.
  final rng = Random(7);
  for (var k = 0; k < 14; k++) {
    final a = 2 * pi * k / 14 + rng.nextDouble() * 0.2;
    final c = water.center + Offset(cos(a) * water.width / 2, sin(a) * water.height / 2);
    final s = 6 + rng.nextDouble() * 6;
    canvas.drawOval(
      Rect.fromCenter(center: c, width: s * 1.6, height: s),
      Paint()..color = (k.isEven ? Palette.stone : Palette.stoneLight),
    );
  }
  final pad = Paint()..color = Palette.moss;
  final lotus = Paint()..color = Palette.lotus;
  for (var k = 0; k < 6; k++) {
    final c = Offset(
      water.left + water.width * (0.2 + 0.6 * rng.nextDouble()),
      water.top + water.height * (0.25 + 0.5 * rng.nextDouble()),
    );
    final s = water.width * (0.05 + 0.03 * rng.nextDouble());
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(Rect.fromCenter(center: c, width: s * 2, height: s * 1.2), -pi / 2 + 0.3, 2 * pi - 0.6, false)
        ..close(),
      pad,
    );
    if (k.isEven) {
      for (var p = 0; p < 5; p++) {
        final a = -pi / 2 + (p - 2) * 0.45;
        canvas.drawOval(
          Rect.fromCenter(
            center: c + Offset(cos(a), sin(a)) * s * 0.35 - Offset(0, s * 0.2),
            width: s * 0.4,
            height: s * 0.7,
          ),
          lotus,
        );
      }
    }
  }
  // Brillo del agua.
  canvas.drawOval(
    Rect.fromCenter(
      center: water.center - Offset(water.width * 0.15, water.height * 0.2),
      width: water.width * 0.35,
      height: water.height * 0.1,
    ),
    Paint()..color = Colors.white.withValues(alpha: 0.18),
  );
}

/// Shishi-odoshi: caño de bambú que cae sobre una piedra, con su cuenco.
void paintShishi(Canvas canvas, Rect r) {
  final bamboo = Paint()..color = const Color(0xFF9DB06A);
  final dark = Paint()..color = const Color(0xFF6E7F45);
  final base = r.bottom - r.height * 0.12;
  // Cuenco de piedra con agua.
  final bowl = Rect.fromCenter(
    center: Offset(r.left + r.width * 0.3, base),
    width: r.width * 0.5,
    height: r.height * 0.16,
  );
  canvas.drawOval(bowl.shift(const Offset(0, 4)), Paint()..color = Palette.ink.withValues(alpha: 0.12));
  canvas.drawOval(bowl, Paint()..color = Palette.stoneDark);
  canvas.drawOval(bowl.deflate(5), Paint()..color = Palette.water);
  // Postes.
  final post = Rect.fromLTWH(r.left + r.width * 0.62, base - r.height * 0.45, r.width * 0.07, r.height * 0.45);
  canvas.drawRRect(RRect.fromRectAndRadius(post, const Radius.circular(3)), dark);
  // Caño inclinado, con la punta sobre el cuenco.
  canvas.save();
  canvas.translate(post.center.dx, post.top + 6);
  canvas.rotate(0.35);
  final tube = Rect.fromLTWH(-r.width * 0.5, -r.height * 0.05, r.width * 0.75, r.height * 0.1);
  canvas.drawRRect(RRect.fromRectAndRadius(tube, Radius.circular(r.height * 0.05)), bamboo);
  for (final x in [-0.25, 0.05]) {
    canvas.drawRect(Rect.fromLTWH(r.width * x, tube.top, 2.5, tube.height), dark);
  }
  canvas.restore();
  // Caño que alimenta desde arriba.
  final feed = Rect.fromLTWH(r.left + r.width * 0.7, r.top + r.height * 0.18, r.width * 0.28, r.height * 0.07);
  canvas.drawRRect(RRect.fromRectAndRadius(feed, Radius.circular(feed.height / 2)), bamboo);
  canvas.drawLine(
    Offset(feed.left + 2, feed.bottom - 2),
    Offset(feed.left + 2, post.top + r.height * 0.02),
    Paint()
      ..color = Palette.water.withValues(alpha: 0.6)
      ..strokeWidth = 2,
  );
}

/// Bonsái en su maceta, sobre una mesita.
void paintBonsai(Canvas canvas, Rect r) {
  final table = Rect.fromLTWH(r.left + r.width * 0.12, r.bottom - r.height * 0.18, r.width * 0.76, r.height * 0.06);
  final wood = Paint()..color = Palette.wood;
  canvas.drawRect(table, wood);
  for (final x in [table.left + 6, table.right - 12]) {
    canvas.drawRect(Rect.fromLTWH(x, table.bottom, 6, r.height * 0.12), wood);
  }
  final pot = Rect.fromCenter(
    center: Offset(r.center.dx, table.top - r.height * 0.06),
    width: r.width * 0.5,
    height: r.height * 0.12,
  );
  canvas.drawRRect(RRect.fromRectAndRadius(pot, const Radius.circular(4)), Paint()..color = const Color(0xFF7A4E3A));
  // Tronco con curva.
  final trunk = Paint()
    ..color = const Color(0xFF6B4A35)
    ..strokeWidth = r.width * 0.06
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final top = Offset(r.center.dx + r.width * 0.05, r.top + r.height * 0.35);
  canvas.drawPath(
    Path()
      ..moveTo(r.center.dx, pot.top)
      ..quadraticBezierTo(r.center.dx - r.width * 0.2, pot.top - r.height * 0.2, top.dx, top.dy),
    trunk,
  );
  // Copas en nubes, como un bonsái podado.
  final leaf = Paint()..color = Palette.moss;
  final leafDark = Paint()..color = Palette.mossDark;
  for (final (dx, dy, s) in [(-0.22, 0.38, 0.2), (0.2, 0.3, 0.22), (0.02, 0.16, 0.24)]) {
    final c = Offset(r.center.dx + r.width * dx, r.top + r.height * dy);
    canvas.drawOval(
      Rect.fromCenter(center: c + const Offset(0, 3), width: r.width * s * 1.8, height: r.width * s * 0.9),
      leafDark,
    );
    canvas.drawOval(Rect.fromCenter(center: c, width: r.width * s * 1.8, height: r.width * s * 0.85), leaf);
  }
}

/// Piedras con musgo: el musgo crece con lo pintado en el minijuego.
void paintMossRocks(Canvas canvas, Rect r, double cover) {
  final rocks = [
    Rect.fromLTWH(r.left + r.width * 0.05, r.top + r.height * 0.3, r.width * 0.5, r.height * 0.55),
    Rect.fromLTWH(r.left + r.width * 0.5, r.top + r.height * 0.45, r.width * 0.38, r.height * 0.4),
  ];
  for (final rock in rocks) {
    canvas.drawOval(rock.shift(const Offset(0, 5)), Paint()..color = Palette.ink.withValues(alpha: 0.12));
    canvas.drawOval(rock, Paint()..color = Palette.stoneDark);
    canvas.drawOval(rock.deflate(2), Paint()..color = Palette.stone);
    canvas.save();
    canvas.clipPath(Path()..addOval(rock));
    // El musgo cubre desde arriba según lo que se pintó (mínimo un poco),
    // en manchas redondas.
    final reach = rock.height * (0.2 + 0.7 * cover.clamp(0, 1));
    final moss = Paint()..color = const Color(0xFF86A85F);
    final rng = Random(rock.left.round());
    for (var k = 0; k < 14; k++) {
      final c = Offset(rock.left + rock.width * rng.nextDouble(), rock.top + reach * rng.nextDouble());
      canvas.drawCircle(c, rock.width * (0.08 + 0.08 * rng.nextDouble()), moss);
    }
    canvas.restore();
  }
}

/// Camino de piedras planas con hojas caídas.
void paintLeafPath(Canvas canvas, Rect r) {
  final step = Paint()..color = Palette.stoneLight;
  for (var k = 0; k < 4; k++) {
    final c = Offset(r.left + r.width * (0.15 + 0.23 * k), r.top + r.height * (0.6 - 0.1 * (k % 2)));
    canvas.drawOval(Rect.fromCenter(center: c, width: r.width * 0.2, height: r.height * 0.22), step);
  }
  final rng = Random(3);
  const colors = [Color(0xFFD9822B), Color(0xFFC0552F), Color(0xFFE3B23C), Color(0xFF9C6B3A)];
  for (var k = 0; k < 18; k++) {
    final c = Offset(r.left + r.width * rng.nextDouble(), r.top + r.height * (0.25 + 0.65 * rng.nextDouble()));
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rng.nextDouble() * pi);
    canvas.drawOval(const Rect.fromLTWH(-6, -3, 12, 6), Paint()..color = colors[k % colors.length]);
    canvas.restore();
  }
  // Escoba de bambú apoyada.
  final broom = Paint()
    ..color = Palette.wood
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  final a = Offset(r.right - r.width * 0.08, r.top + r.height * 0.05);
  final b = Offset(r.right - r.width * 0.2, r.bottom - r.height * 0.15);
  canvas.drawLine(a, b, broom);
  final straw = Paint()
    ..color = const Color(0xFFC9B37A)
    ..strokeWidth = 1.6;
  for (var k = -3; k <= 3; k++) {
    canvas.drawLine(b, b + Offset(k * 3.0 - 4, 16), straw);
  }
}

/// Pabellón de caligrafía: techo curvo, papel abierto y un ensō colgado.
void paintCalligraphyHall(Canvas canvas, Rect r) {
  final wood = Paint()..color = Palette.wood;
  final floor = Rect.fromLTRB(r.left + r.width * 0.06, r.bottom - r.height * 0.12, r.right - r.width * 0.06, r.bottom);
  canvas.drawRect(floor, wood);
  // Postes y pared de papel.
  final wall = Rect.fromLTRB(floor.left + 6, r.top + r.height * 0.36, floor.right - 6, floor.top);
  canvas.drawRect(wall, Paint()..color = Palette.paper);
  for (final x in [wall.left, wall.right - 6]) {
    canvas.drawRect(Rect.fromLTWH(x, wall.top, 6, wall.height), wood);
  }
  // El ensō colgado en el medio.
  final scroll = Rect.fromCenter(center: wall.center, width: wall.width * 0.36, height: wall.height * 0.78);
  canvas.drawRect(scroll, Paint()..color = const Color(0xFFF7F0DE));
  canvas.drawArc(
    Rect.fromCircle(center: scroll.center, radius: scroll.width * 0.32),
    -pi * 0.4,
    pi * 1.8,
    false,
    Paint()
      ..color = Palette.ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = scroll.width * 0.08,
  );
  // Techo de tejas con aleros curvos.
  canvas.drawPath(_roof(r, r.top + r.height * 0.4, r.top + r.height * 0.08), Paint()..color = Palette.stoneDark);
  canvas.drawLine(
    Offset(r.left + 4, r.top + r.height * 0.39),
    Offset(r.right - 4, r.top + r.height * 0.39),
    Paint()
      ..color = Palette.ink.withValues(alpha: 0.4)
      ..strokeWidth = 3,
  );
}

/// Campanario: techo, dos postes, la campana de bronce y el tronco colgado.
void paintBellTower(Canvas canvas, Rect r) {
  final wood = Paint()..color = Palette.wood;
  final postW = r.width * 0.07;
  final top = r.top + r.height * 0.28;
  for (final x in [r.left + r.width * 0.12, r.right - r.width * 0.12 - postW]) {
    canvas.drawRect(Rect.fromLTWH(x, top, postW, r.bottom - top), wood);
  }
  canvas.drawRect(Rect.fromLTWH(r.left + r.width * 0.08, top, r.width * 0.84, postW), wood);
  canvas.drawPath(_roof(r, top + 4, r.top + r.height * 0.04), Paint()..color = Palette.stoneDark);
  // Campana.
  final bell = RRect.fromRectAndCorners(
    Rect.fromCenter(
      center: Offset(r.center.dx + r.width * 0.06, top + r.height * 0.36),
      width: r.width * 0.38,
      height: r.height * 0.42,
    ),
    topLeft: Radius.circular(r.width * 0.17),
    topRight: Radius.circular(r.width * 0.17),
    bottomLeft: const Radius.circular(3),
    bottomRight: const Radius.circular(3),
  );
  canvas.drawLine(
    Offset(bell.center.dx, top + postW),
    Offset(bell.center.dx, bell.top),
    Paint()
      ..strokeWidth = 2
      ..color = Palette.ink,
  );
  canvas.drawRRect(bell, Paint()..color = const Color(0xFF7A6A48));
  canvas.drawRect(
    Rect.fromLTWH(bell.left, bell.top + bell.height * 0.55, bell.width, 2.5),
    Paint()..color = Palette.ink.withValues(alpha: 0.3),
  );
  // Tronco a un costado.
  final log = Rect.fromLTWH(
    r.left + r.width * 0.06,
    bell.center.dy + bell.height * 0.1,
    r.width * 0.28,
    r.height * 0.08,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(log, Radius.circular(log.height / 2)),
    Paint()..color = const Color(0xFFA9774F),
  );
}

/// Techo japonés: cumbrera corta arriba y aleros que se curvan hacia afuera.
Path _roof(Rect r, double eave, double ridge) {
  final h = eave - ridge;
  return Path()
    ..moveTo(r.left - 6, eave)
    ..quadraticBezierTo(r.left + r.width * 0.22, eave - h * 0.15, r.center.dx - r.width * 0.14, ridge)
    ..lineTo(r.center.dx + r.width * 0.14, ridge)
    ..quadraticBezierTo(r.right - r.width * 0.22, eave - h * 0.15, r.right + 6, eave)
    ..close();
}
