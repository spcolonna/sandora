import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../minigames/enso/enso_ink.dart';
import '../theme/palette.dart';
import 'garden_forest.dart' show groundShadow;
import 'scene_art.dart';

/// Lugares de la vista del estanque: el arte pintado si está y, si no, con código.

/// Estanque con lotos y hojas flotando, con piedras de musgo en la orilla.
void paintPond(Canvas canvas, Rect r) {
  final art = SceneArt.instance;
  final img = art['bg_pond_water'];
  if (img == null) return _paintPondDrawn(canvas, r);
  final water = Rect.fromCenter(center: r.center, width: r.width, height: r.height * 0.8);
  // Orilla húmeda alrededor del agua.
  canvas.drawOval(
    water.inflate(6),
    Paint()
      ..color = const Color(0xFF5E5A48).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
  );
  canvas.save();
  canvas.clipPath(Path()..addOval(water));
  drawArtCover(canvas, img, water);
  // El borde del agua, más hondo y en sombra.
  canvas.drawOval(
    water.inflate(water.height * 0.06),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = water.height * 0.16
      ..color = Palette.ink.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
  );
  canvas.restore();
  // Hojas flotando (aplastadas por la perspectiva), algunas con su loto.
  final pad = art['spr_pond_tile_pad'], lotus = art['spr_pond_tile_lotus'];
  for (final (x, y, s, flower) in [
    (0.22, 0.4, 0.11, true),
    (0.34, 0.64, 0.08, false),
    (0.6, 0.32, 0.07, false),
    (0.72, 0.6, 0.11, true),
    (0.5, 0.74, 0.06, false),
    (0.44, 0.48, 0.05, false),
  ]) {
    final c = Offset(water.left + water.width * x, water.top + water.height * y);
    final w = water.width * s;
    if (pad != null) {
      final h = w * pad.height / pad.width * 0.55;
      drawArt(canvas, pad, Rect.fromCenter(center: c, width: w, height: h));
    }
    if (flower && lotus != null) {
      final lw = w * 0.62, lh = lw * lotus.height / lotus.width;
      drawArt(canvas, lotus, Rect.fromLTWH(c.dx - lw / 2, c.dy - lh * 0.8, lw, lh));
    }
  }
  // Piedras de la orilla: las de atrás más chicas.
  final rock = art['obj_moss_rock'];
  if (rock == null) return;
  final rng = Random(7);
  for (final a in [-2.6, -1.9, -0.9, -0.3, 0.5, 1.2, 2.0, 2.7]) {
    final c = water.center + Offset(cos(a) * water.width / 2, sin(a) * water.height / 2);
    final w = water.width * (0.07 + 0.04 * rng.nextDouble()) * (1 + 0.25 * sin(a));
    final h = w * rock.height / rock.width;
    drawArt(canvas, rock, Rect.fromLTWH(c.dx - w / 2, c.dy - h * 0.6, w, h));
  }
}

void _paintPondDrawn(Canvas canvas, Rect r) {
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
  final art = SceneArt.instance;
  final basin = art['obj_shishi_basin'], bamboo = art['obj_shishi_bamboo'];
  if (basin == null || bamboo == null) return _paintShishiDrawn(canvas, r);
  final base = r.bottom - r.height * 0.04;
  // Cuenco de piedra, adelante a la izquierda.
  final bw = r.width * 0.54, bh = bw * basin.height / basin.width;
  final bowl = Rect.fromLTWH(r.left + r.width * 0.3 - bw / 2, base - bh, bw, bh);
  groundShadow(canvas, bowl, 0.95);
  drawArt(canvas, basin, bowl);
  // Poste: el bambú parado, sin la boca cortada.
  final mouthless = Rect.fromLTRB(bamboo.width * 0.3, 0, bamboo.width.toDouble(), bamboo.height.toDouble());
  final px = r.left + r.width * 0.68, top = base - r.height * 0.42;
  final thick = r.width * 0.075;
  final post = Rect.fromLTRB(px - thick / 2, top, px + thick / 2, base - r.height * 0.01);
  groundShadow(canvas, Rect.fromCenter(center: post.bottomCenter, width: thick * 3, height: thick * 2), 1);
  canvas.save();
  canvas.translate(post.center.dx, post.center.dy);
  canvas.rotate(-pi / 2);
  canvas.drawImageRect(
    bamboo,
    mouthless,
    Rect.fromCenter(center: Offset.zero, width: post.height, height: thick),
    Paint()..filterQuality = FilterQuality.medium,
  );
  canvas.restore();
  // Caño que bascula sobre el poste, con la boca arriba sobre el cuenco.
  const tilt = 0.25;
  final len = r.width * 0.62, th = len * bamboo.height / bamboo.width;
  final pivot = Offset(px, top + thick * 0.6);
  canvas.save();
  canvas.translate(pivot.dx, pivot.dy);
  canvas.rotate(tilt);
  drawArt(canvas, bamboo, Rect.fromLTWH(-len * 0.62, -th / 2, len, th));
  canvas.restore();
  canvas.drawCircle(pivot, thick * 0.22, Paint()..color = const Color(0xFF4A3A28));
  // Caño que llega desde la derecha y gotea en la boca.
  final mouth = pivot + Offset(-len * 0.58 * cos(tilt), -len * 0.58 * sin(tilt));
  final feedY = mouth.dy - r.height * 0.16;
  final fl = r.right - mouth.dx + th * 0.2, ft = min(th * 0.8, fl * bamboo.height / bamboo.width);
  canvas.drawLine(
    Offset(mouth.dx, feedY + ft * 0.3),
    mouth,
    Paint()
      ..color = Palette.water.withValues(alpha: 0.7)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round,
  );
  // Su soporte, otro bambú parado cerca del borde.
  final sx = r.right - r.width * 0.06, st = ft * 0.8;
  canvas.save();
  canvas.translate(sx, (feedY + base) / 2);
  canvas.rotate(-pi / 2);
  canvas.drawImageRect(
    bamboo,
    mouthless,
    Rect.fromCenter(center: Offset.zero, width: base - feedY, height: st),
    Paint()..filterQuality = FilterQuality.medium,
  );
  canvas.restore();
  drawArt(canvas, bamboo, Rect.fromLTWH(mouth.dx - th * 0.2, feedY - ft / 2, fl, ft));
}

void _paintShishiDrawn(Canvas canvas, Rect r) {
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
  final art = SceneArt.instance;
  final potArt = art['obj_bonsai_pot'], trunkArt = art['obj_bonsai_trunk'];
  if (potArt == null || trunkArt == null) return _paintBonsaiDrawn(canvas, r);
  final table = _bonsaiTable(canvas, r);
  final pw = r.width * 0.5, ph = pw * potArt.height / potArt.width;
  final pot = Rect.fromLTWH(r.center.dx - pw / 2, table.top - ph + 1, pw, ph);
  // El árbol, con su tierra metida en la maceta (como en el minijuego).
  final tw = min(r.width * 0.9, (pot.top - r.top) / 0.9 * trunkArt.width / trunkArt.height);
  final th = tw * trunkArt.height / trunkArt.width;
  final tree = Rect.fromLTWH(r.center.dx - tw / 2, pot.top + 4 + th * 0.07 - th, tw, th);
  drawArt(canvas, trunkArt, tree);
  drawArt(canvas, potArt, pot);
  // Copas de musgo en las puntas de las ramas de `obj_bonsai_trunk`: nubes de
  // follaje con la textura, apagada para que no brille más que el resto.
  final tex = art['tex_moss'];
  final leaf = Paint()
    ..color = Palette.moss
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
  if (tex != null) {
    leaf
      ..shader = _mossShader(tex, tw / 512 * 0.16, tree.topLeft)
      ..colorFilter = const ColorFilter.mode(Color(0xFFA9B98F), BlendMode.modulate);
  }
  final shade = Paint()
    ..color = Palette.mossDark.withValues(alpha: 0.8)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
  for (final (x, y, w) in [(0.12, 0.38, 0.18), (0.38, 0.3, 0.13), (0.7, 0.12, 0.24), (0.88, 0.5, 0.18)]) {
    final c = Offset(tree.left + tw * x, tree.top + th * y);
    final puffs = [
      for (final (dx, dy, k) in [
        (-0.38, 0.08, 0.3),
        (0.38, 0.08, 0.3),
        (0.0, -0.08, 0.38),
        (-0.16, 0.14, 0.3),
        (0.18, 0.15, 0.3),
      ])
        (c + Offset(dx, dy) * tw * w, k * tw * w),
    ];
    for (final (p, rad) in puffs) {
      canvas.drawCircle(p + Offset(0, tw * 0.018), rad, shade);
    }
    for (final (p, rad) in puffs) {
      canvas.drawCircle(p, rad, leaf);
    }
  }
}

/// La textura de musgo repetida, a escala [k] y empezando en [origin].
ImageShader _mossShader(ui.Image tex, double k, Offset origin) => ImageShader(
  tex,
  TileMode.repeated,
  TileMode.repeated,
  Float64List.fromList([k, 0, 0, 0, 0, k, 0, 0, 0, 0, 1, 0, origin.dx, origin.dy, 0, 1]),
);

/// Mesita de madera del bonsái; devuelve su tabla.
Rect _bonsaiTable(Canvas canvas, Rect r) {
  final table = Rect.fromLTWH(r.left + r.width * 0.12, r.bottom - r.height * 0.18, r.width * 0.76, r.height * 0.06);
  final wood = Paint()..color = Palette.wood;
  canvas.drawRect(table, wood);
  for (final x in [table.left + 6, table.right - 12]) {
    canvas.drawRect(Rect.fromLTWH(x, table.bottom, 6, r.height * 0.12), wood);
  }
  return table;
}

void _paintBonsaiDrawn(Canvas canvas, Rect r) {
  final table = _bonsaiTable(canvas, r);
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
  final art = SceneArt.instance;
  final rock = art['obj_moss_rock'], tex = art['tex_moss'];
  if (rock == null || tex == null) return _paintMossRocksDrawn(canvas, r, cover);
  final boxes = [
    Rect.fromLTWH(r.left + r.width * 0.02, r.top + r.height * 0.2, r.width * 0.58, r.height * 0.72),
    Rect.fromLTWH(r.left + r.width * 0.5, r.top + r.height * 0.42, r.width * 0.44, r.height * 0.54),
  ];
  for (final box in boxes) {
    final dst = artRectIn(rock, box);
    groundShadow(canvas, dst, 0.95);
    // El musgo se pinta solo sobre la piedra: va en una capa con ella.
    canvas.saveLayer(dst, Paint());
    drawArt(canvas, rock, dst);
    // Cubre desde arriba según lo que se pintó (mínimo un poco), en manchas.
    final reach = dst.height * (0.2 + 0.75 * cover.clamp(0, 1));
    final k = dst.width / 512 * 0.22;
    final moss = Paint()
      ..blendMode = BlendMode.srcATop
      ..shader = _mossShader(tex, k, dst.topLeft)
      ..colorFilter = const ColorFilter.mode(Color(0xFFA9B98F), BlendMode.modulate)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, dst.width * 0.012);
    final rng = Random(box.left.round());
    for (var n = 0; n < 22; n++) {
      final c = Offset(dst.left + dst.width * rng.nextDouble(), dst.top + reach * rng.nextDouble());
      canvas.drawCircle(c, dst.width * (0.07 + 0.08 * rng.nextDouble()), moss);
    }
    canvas.restore();
  }
}

void _paintMossRocksDrawn(Canvas canvas, Rect r, double cover) {
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
  final art = SceneArt.instance;
  final stone = art['obj_decor_step'];
  final step = Paint()..color = Palette.stoneLight;
  for (var k = 0; k < 4; k++) {
    final c = Offset(r.left + r.width * (0.15 + 0.23 * k), r.top + r.height * (0.6 - 0.1 * (k % 2)));
    if (stone == null) {
      canvas.drawOval(Rect.fromCenter(center: c, width: r.width * 0.2, height: r.height * 0.22), step);
    } else {
      // Pisadas aplastadas, como vistas desde arriba.
      final w = r.width * 0.21, h = min(w * stone.height / stone.width * 0.7, r.height * 0.34);
      final dst = Rect.fromCenter(center: c, width: w, height: h);
      groundShadow(canvas, dst, 0.9);
      drawArt(canvas, stone, dst);
    }
  }
  final rng = Random(3);
  const colors = [Color(0xFFD9822B), Color(0xFFC0552F), Color(0xFFE3B23C), Color(0xFF9C6B3A)];
  for (var k = 0; k < 18; k++) {
    final c = Offset(r.left + r.width * rng.nextDouble(), r.top + r.height * (0.25 + 0.65 * rng.nextDouble()));
    final leaf = art['spr_leaf_0${k % 4 + 1}'];
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rng.nextDouble() * pi);
    if (leaf == null) {
      canvas.drawOval(const Rect.fromLTWH(-6, -3, 12, 6), Paint()..color = colors[k % colors.length]);
    } else {
      // Hoja caída, aplastada contra el suelo.
      final s = r.width * (0.045 + 0.02 * rng.nextDouble());
      drawArt(canvas, leaf, Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.65));
    }
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

/// Pabellón de caligrafía, con el ensō colgado: el mejor del jugador ([ink])
/// o, hasta que haga uno, el que trae el dibujo.
void paintCalligraphyHall(Canvas canvas, Rect r, {SavedInk? ink}) {
  final dst = drawArtIn(canvas, SceneArt.instance['obj_callig_hall'], r);
  if (dst == null || ink == null) return;
  // Papel del rollo y centro del ensō en `obj_callig_hall` (fracciones).
  final paper = Rect.fromLTRB(
    dst.left + dst.width * 0.441,
    dst.top + dst.height * 0.531,
    dst.left + dst.width * 0.558,
    dst.top + dst.height * 0.685,
  );
  canvas.drawRect(paper, Paint()..color = const Color(0xFFE2C4A0));
  ink.paint(canvas, Offset(dst.left + dst.width * 0.5, dst.top + dst.height * 0.608), dst.width * 0.046);
}

/// Campanario con la campana de bronce y el tronco colgados de la viga.
void paintBellTower(Canvas canvas, Rect r) {
  final art = SceneArt.instance;
  final t = drawArtIn(canvas, art['obj_temple_belltower'], r);
  if (t == null) return;
  // El gancho de `obj_temple_belltower` está al medio de la viga.
  final hook = Offset(t.left + t.width * 0.505, t.top + t.height * 0.58);
  final bell = art['obj_temple_bell'];
  if (bell != null) {
    final h = t.height * 0.3;
    final w = h * bell.width / bell.height;
    drawArt(canvas, bell, Rect.fromLTWH(hook.dx - w / 2, hook.dy, w, h));
  }
  final log = art['obj_temple_log'];
  if (log != null) {
    final w = t.width * 0.22;
    final dst = Rect.fromLTWH(hook.dx - t.width * 0.14 - w, hook.dy + t.height * 0.12, w, w * log.height / log.width);
    final rope = Paint()
      ..color = const Color(0xFFB59A6A)
      ..strokeWidth = 1.5;
    for (final f in [0.25, 0.75]) {
      final x = dst.left + dst.width * f;
      canvas.drawLine(Offset(x, t.top + t.height * 0.52), Offset(x, dst.center.dy), rope);
    }
    drawArt(canvas, log, dst);
  }
}
