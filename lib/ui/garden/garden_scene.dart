import 'dart:math';

import 'package:flutter/material.dart';

import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../../minigames/enso/enso_ink.dart';
import '../../minigames/sand/sand_painter.dart';
import '../../minigames/sand/sand_shapes.dart';
import '../../minigames/stack/stack_rules.dart';
import '../../minigames/stack/stone_painter.dart';
import '../theme/palette.dart';
import 'garden_east.dart';
import 'garden_forest.dart';
import 'garden_decor.dart';
import 'scene_art.dart';

/// Lugares del jardín que se tocan: cada minijuego, el Mercado, el tablón y
/// el cojín de meditación. Los del patio están en la primera vista; los del
/// estanque, en la segunda, y los del bosque, en la tercera.
enum Place {
  market,
  board,
  meditation,
  sand,
  stack,
  rain,
  pond,
  shishi,
  leaves,
  moss,
  bonsai,
  enso,
  bell,
  matcha,
  flute,
  lanterns;

  /// 0 el patio, 1 el estanque, 2 el bosque.
  int get side => index >= Place.matcha.index
      ? 2
      : index >= Place.pond.index
      ? 1
      : 0;
}

/// Dónde está cada cosa del jardín. La usan el dibujo y las zonas tocables,
/// así siempre coinciden.
class GardenLayout {
  final Size size;

  /// Terreno cuidado (crece con las ampliaciones de patio).
  final Rect ground;
  final Map<Place, Rect> places;

  /// Centro del cartelito con el nombre de cada lugar.
  final Map<Place, Offset> labels;

  /// Dónde cuelgan los faroles que se encienden al anochecer.
  final List<Offset> lanterns;

  GardenLayout._(this.size, this.ground, this.places, this.labels, this.lanterns);

  /// 0 el patio, 1 el estanque, 2 el bosque.
  int get side => places.keys.first.side;

  factory GardenLayout(Size size, int patio, {int side = 0}) {
    if (side == 1) return GardenLayout._east(size);
    if (side == 2) return GardenLayout._forest(size);
    final w = size.width, h = size.height;
    const inset = [0.1, 0.04, 0.0], top = [0.6, 0.56, 0.52];
    final k = patio.clamp(0, 2);
    final ground = Rect.fromLTRB(w * inset[k], h * top[k], w * (1 - inset[k]), h);
    final gh = ground.height;
    final sand = Rect.fromLTRB(
      ground.left + w * 0.05,
      ground.top + gh * 0.08,
      ground.left + ground.width * 0.66,
      ground.top + gh * 0.62,
    );
    final stack = Rect.fromLTRB(sand.right + w * 0.04, ground.top + gh * 0.02, ground.right - w * 0.03, sand.bottom);
    final rain = Rect.fromLTRB(ground.left + w * 0.05, sand.bottom + gh * 0.08, ground.right - w * 0.05, h - gh * 0.03);
    final market = Rect.fromLTRB(w * 0.03, h * 0.29, w * 0.35, ground.top - h * 0.012);
    final board = Rect.fromLTRB(w * 0.39, h * 0.35, w * 0.55, ground.top - h * 0.016);
    final meditation = Rect.fromLTRB(w * 0.58, h * 0.17, w * 0.98, ground.top - h * 0.006);
    return GardenLayout._(
      size,
      ground,
      {
        Place.market: market,
        Place.board: board,
        Place.meditation: meditation,
        Place.sand: sand,
        Place.stack: stack,
        Place.rain: rain,
      },
      {
        Place.market: market.bottomCenter,
        Place.board: board.bottomCenter,
        Place.meditation: Offset(meditation.left + meditation.width * 0.55, meditation.bottom),
        Place.sand: Offset(sand.center.dx, sand.bottom),
        Place.stack: stack.bottomCenter,
        Place.rain: Offset(rain.left + rain.width * 0.82, rain.center.dy),
      },
      [
        Offset(market.right - market.width * 0.1, market.top + market.height * 0.42),
        Offset(meditation.left + meditation.width * 0.1, meditation.bottom - meditation.height * 0.3),
      ],
    );
  }

  /// La vista del estanque: el agua con lotos, el shishi-odoshi, el bonsái,
  /// las piedras con musgo y el camino de hojas.
  factory GardenLayout._east(Size size) {
    final w = size.width, h = size.height;
    final ground = Rect.fromLTRB(0, h * 0.56, w, h);
    final gh = ground.height;
    final pond = Rect.fromLTRB(w * 0.05, ground.top + gh * 0.06, w * 0.64, ground.top + gh * 0.52);
    final shishi = Rect.fromLTRB(w * 0.68, ground.top - h * 0.1, w * 0.97, ground.top + gh * 0.46);
    final bonsai = Rect.fromLTRB(w * 0.34, h * 0.3, w * 0.64, ground.top - h * 0.01);
    final moss = Rect.fromLTRB(w * 0.04, ground.top + gh * 0.6, w * 0.46, h - gh * 0.04);
    final leaves = Rect.fromLTRB(w * 0.5, ground.top + gh * 0.58, w * 0.96, h - gh * 0.04);
    // Sobre la loma del fondo: el pabellón de caligrafía y el campanario.
    final enso = Rect.fromLTRB(w * 0.04, h * 0.3, w * 0.3, ground.top - h * 0.01);
    final bell = Rect.fromLTRB(w * 0.7, h * 0.13, w * 0.96, shishi.top - h * 0.02);
    return GardenLayout._(
      size,
      ground,
      {
        Place.pond: pond,
        Place.shishi: shishi,
        Place.bonsai: bonsai,
        Place.moss: moss,
        Place.leaves: leaves,
        Place.enso: enso,
        Place.bell: bell,
      },
      {
        Place.enso: enso.bottomCenter,
        Place.bell: bell.bottomCenter,
        Place.pond: Offset(pond.center.dx, pond.bottom),
        Place.shishi: shishi.bottomCenter,
        Place.bonsai: bonsai.bottomCenter,
        Place.moss: Offset(moss.center.dx, moss.bottom - gh * 0.02),
        Place.leaves: Offset(leaves.center.dx, leaves.bottom - gh * 0.02),
      },
      [Offset(bonsai.left - w * 0.06, bonsai.bottom - bonsai.height * 0.3)],
    );
  }

  /// La vista del bosque: el bambú, la casa de té y el río.
  factory GardenLayout._forest(Size size) {
    final w = size.width, h = size.height;
    final ground = Rect.fromLTRB(0, h * 0.56, w, h);
    final gh = ground.height;
    final flute = Rect.fromLTRB(w * 0.03, h * 0.14, w * 0.44, ground.top + gh * 0.24);
    final matcha = Rect.fromLTRB(w * 0.5, h * 0.3, w * 0.97, ground.top + gh * 0.24);
    final lanterns = Rect.fromLTRB(0, ground.top + gh * 0.34, w, h - gh * 0.02);
    return GardenLayout._(
      size,
      ground,
      {Place.matcha: matcha, Place.flute: flute, Place.lanterns: lanterns},
      {
        Place.matcha: matcha.bottomCenter,
        Place.flute: flute.bottomCenter,
        Place.lanterns: Offset(lanterns.center.dx, lanterns.bottom - gh * 0.04),
      },
      [Offset(matcha.left + matcha.width * 0.1, matcha.top + matcha.height * 0.52)],
    );
  }
}

/// Colores del cielo en cada momento: arriba y abajo.
const _skyNight = [Color(0xFF1C2640), Palette.dusk];
const _skyDay = [Palette.skyTop, Palette.skyBottom];
const _skyDawn = [Color(0xFF9DB0CF), Color(0xFFF2C4A0)];
const _skyDusk = [Color(0xFF6A6698), Color(0xFFEFA377)];

/// Cielo de un momento: mezcla noche y día por [daylight] y le suma el tono
/// cálido del amanecer (si es de mañana) o del atardecer.
List<Color> skyColors(double daylight, double warmth, {required bool morning}) {
  final warm = morning ? _skyDawn : _skyDusk;
  return [for (var i = 0; i < 2; i++) Color.lerp(Color.lerp(_skyNight[i], _skyDay[i], daylight), warm[i], warmth)!];
}

/// El jardín dibujado con código hasta tener los fondos y objetos del Lote 1.
/// Lo vivo (nubes, estrellas, luciérnagas) va aparte, en `garden_view.dart`.
const List<TowerStone> _ghostTower = [
  (x: 0, w: 1.7, h: 0.55, kind: 0, tone: 0, seed: 11),
  (x: 0.1, w: 1.1, h: 0.6, kind: 2, tone: 2, seed: 23),
];

final _stoneCache = <int, StoneShape>{};

class GardenPainter extends CustomPainter {
  final GardenLayout layout;
  final List<TowerStone> tower;
  final List<double> drawing;
  final bool meditationOpen;

  /// Cuánto musgo hay en las piedras de la vista del estanque (0 a 1).
  final double moss;

  /// Luz del día (0 noche, 1 día), tono cálido y recorrido del sol o la luna.
  final double daylight, warmth, arc;
  final bool morning;

  /// Cuánto tapan las nubes (0 despejado, 1 tormenta): agrisa el cielo y
  /// esconde el sol o la luna. [snowy] cubre la tierra de blanco.
  final double overcast;
  final bool snowy;

  /// Agua en el suelo (1 lloviendo o recién parado): charcos que se secan.
  final double wet;

  /// Cuánto se ve el arcoíris (0 a 1), detrás de las lomas.
  final double rainbow;

  /// Objetos de la racha de meditación (`bowl`, `cushion`, `lantern`).
  final List<String> streakObjects;

  /// El mejor ensō del jugador, colgado en el pabellón.
  final SavedInk? ensoInk;

  /// Decoraciones puestas en esta vista y dónde va cada una.
  final List<(String, Rect)> decor;

  GardenPainter({
    required this.layout,
    required this.tower,
    required this.drawing,
    required this.meditationOpen,
    this.moss = 0,
    required this.daylight,
    required this.warmth,
    required this.arc,
    required this.morning,
    this.overcast = 0,
    this.snowy = false,
    this.wet = 0,
    this.rainbow = 0,
    this.streakObjects = const [],
    this.ensoInk,
    this.decor = const [],
  });

  Size get size => layout.size;

  @override
  void paint(Canvas canvas, Size size) {
    final all = Offset.zero & size;
    final grey = Color.lerp(const Color(0xFF2B3038), const Color(0xFFB8C0C6), daylight)!;
    final sky = [for (final c in skyColors(daylight, warmth, morning: morning)) Color.lerp(c, grey, overcast * 0.8)!];
    canvas.drawRect(
      all,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.45)),
    );
    // El cielo pintado es de día: se funde con el degradado según la luz, el
    // atardecer y las nubes, y de noche queda solo el degradado.
    final skyArt = SceneArt.instance['bg_base_sky'];
    final skyAlpha = daylight * (1 - 0.6 * warmth) * (1 - 0.85 * overcast);
    if (skyArt != null && skyAlpha > 0.01) {
      drawArt(
        canvas,
        skyArt,
        Rect.fromLTWH(0, 0, size.width, size.height * 0.48),
        paint: Paint()..color = Colors.white.withValues(alpha: skyAlpha.clamp(0.0, 1.0)),
      );
    }
    _paintSunOrMoon(canvas);
    if (rainbow > 0) _paintRainbow(canvas, size);
    // La tierra se dibuja en una capa aparte para oscurecerla de noche sin
    // tocar el cielo.
    canvas.saveLayer(all, Paint());
    _paintHills(canvas);
    _paintGround(canvas);
    if (wet > 0) _paintPuddles(canvas);
    if (snowy) {
      canvas.drawRect(
        all,
        Paint()
          ..color = const Color(0xFFF4F7FA).withValues(alpha: 0.5)
          ..blendMode = BlendMode.srcATop,
      );
    }
    final at = layout.places;
    if (layout.side == 0) {
      _paintSandBed(canvas, at[Place.sand]!);
      _paintFence(canvas);
      _paintTower(canvas, at[Place.stack]!);
      _paintJars(canvas, at[Place.rain]!);
      _paintMarket(canvas, at[Place.market]!);
      _paintBoard(canvas, at[Place.board]!);
      _paintMeditation(canvas, at[Place.meditation]!);
    } else if (layout.side == 1) {
      paintBonsai(canvas, at[Place.bonsai]!);
      paintPond(canvas, at[Place.pond]!);
      paintShishi(canvas, at[Place.shishi]!);
      paintMossRocks(canvas, at[Place.moss]!, moss);
      paintLeafPath(canvas, at[Place.leaves]!);
      paintCalligraphyHall(canvas, at[Place.enso]!, ink: ensoInk);
      paintBellTower(canvas, at[Place.bell]!);
    } else {
      paintBambooGrove(canvas, at[Place.flute]!);
      paintRiver(canvas, at[Place.lanterns]!);
      paintTeahouse(canvas, at[Place.matcha]!, layout.lanterns[0]);
    }
    paintDecorations(canvas, decor);
    _paintFoliage(canvas, size);
    final dark = 1 - daylight;
    canvas.drawRect(
      all,
      Paint()
        ..color = const Color(0xFF141C34).withValues(alpha: dark * 0.55)
        ..blendMode = BlendMode.srcATop,
    );
    canvas.drawRect(
      all,
      Paint()
        ..color = const Color(0xFFE8955A).withValues(alpha: warmth * 0.16 * (1 - overcast))
        ..blendMode = BlendMode.srcATop,
    );
    if (overcast > 0) {
      canvas.drawRect(
        all,
        Paint()
          ..color = const Color(0xFF5C6670).withValues(alpha: overcast * 0.18)
          ..blendMode = BlendMode.srcATop,
      );
    }
    canvas.restore();
    _paintLanternLight(canvas);
  }

  void _paintSunOrMoon(Canvas canvas) {
    final x = size.width * (0.08 + 0.84 * arc);
    final y = size.height * (0.3 - 0.22 * sin(pi * arc));
    final r = size.width * 0.055;
    final c = Offset(x, y);
    final hidden = 1 - overcast;
    canvas.saveLayer(Offset.zero & size, Paint()..color = Colors.white.withValues(alpha: hidden));
    if (daylight > 0 || warmth > 0) {
      final sun = Color.lerp(const Color(0xFFFFF0C4), const Color(0xFFF4A261), warmth)!;
      final a = (daylight * 1.6 + warmth).clamp(0.0, 1.0);
      canvas.drawCircle(c, r * 2.4, Paint()..color = sun.withValues(alpha: 0.18 * a));
      canvas.drawCircle(c, r, Paint()..color = sun.withValues(alpha: a));
    } else {
      final moon = const Color(0xFFF1EEDF);
      canvas.drawCircle(c, r * 2.6, Paint()..color = moon.withValues(alpha: 0.08));
      canvas.drawCircle(c, r * 0.85, Paint()..color = moon);
      final crater = Paint()..color = const Color(0xFFDAD5C2);
      canvas.drawCircle(c + Offset(-r * 0.25, -r * 0.2), r * 0.18, crater);
      canvas.drawCircle(c + Offset(r * 0.3, r * 0.25), r * 0.12, crater);
    }
    canvas.restore();
  }

  /// Lomas lejanas con niebla (`bg_base_far`): las cimas quedan a un tercio
  /// de la pantalla y el suelo tapa el resto.
  void _paintHills(Canvas canvas) {
    final w = size.width, h = size.height;
    final art = SceneArt.instance['bg_base_far'];
    if (art != null) {
      drawArt(canvas, art, Rect.fromLTWH(0, h * 0.31, w, w * art.height / art.width));
      return;
    }
    final far = Path()..moveTo(0, h * 0.4);
    for (var x = 0.0; x <= w; x += 8) {
      far.lineTo(x, h * (0.36 + 0.035 * sin(x / 41 + 1) + 0.015 * sin(x / 11)));
    }
    far
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(far, Paint()..color = const Color(0xFF8DA58C));
    final near = Path()..moveTo(0, h * 0.42);
    for (var x = 0.0; x <= w; x += 8) {
      near.lineTo(x, h * (0.41 + 0.025 * sin(x / 33) + 0.012 * sin(x / 9 + 2)));
    }
    near
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(near, Paint()..color = Palette.mossDark.withValues(alpha: 0.85));
  }

  void _paintGround(Canvas canvas) {
    final w = size.width, h = size.height;
    canvas.drawRect(Rect.fromLTRB(0, h * 0.45, w, h), Paint()..color = Palette.moss);
    // Matas de pasto.
    final tuft = Paint()
      ..color = Palette.mossDark.withValues(alpha: 0.5)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final rng = Random(5);
    for (var i = 0; i < 40; i++) {
      final o = Offset(rng.nextDouble() * w, h * (0.47 + rng.nextDouble() * 0.5));
      if (layout.side == 0 && layout.ground.contains(o)) continue;
      for (final d in [-3.0, 0.0, 3.0]) {
        canvas.drawLine(o, o + Offset(d, -6 - rng.nextDouble() * 3), tuft);
      }
    }
    if (layout.side != 0) return;
    final g = layout.ground;
    // El patio pintado (arena con borde de piedras) se estira al terreno
    // cuidado, que crece con las ampliaciones.
    final art = SceneArt.instance['bg_base_ground'];
    if (art != null) {
      drawArt(canvas, art, g);
      return;
    }
    canvas.save();
    canvas.clipRect(g);
    canvas.translate(g.left, g.top);
    canvas.drawPicture(sandTexture(g.size, seed: 11));
    canvas.restore();
  }

  /// Hojas de arce arriba a la izquierda y bambú abajo a la derecha, que
  /// enmarcan la vista. Cada mitad del arte se apoya en su borde.
  void _paintFoliage(Canvas canvas, Size size) {
    final art = SceneArt.instance['bg_base_foliage'];
    if (art == null) return;
    // A 70 % del ancho, para que no tape los lugares de las esquinas.
    final w = size.width * 0.7, half = art.height / 2;
    final h = w * half / art.width;
    final paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(art, Rect.fromLTWH(0, 0, art.width.toDouble(), half), Rect.fromLTWH(0, 0, w, h), paint);
    canvas.drawImageRect(
      art,
      Rect.fromLTWH(0, half, art.width.toDouble(), half),
      Rect.fromLTWH(size.width - w, size.height - h, w, h),
      paint,
    );
  }

  /// Arco suave detrás de las nubes, con los colores apenas marcados.
  void _paintRainbow(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final c = Offset(w * 0.6, h * 0.62);
    final r = w * 0.62;
    const bands = [
      Color(0xFFE57373),
      Color(0xFFFFB74D),
      Color(0xFFFFF176),
      Color(0xFF81C784),
      Color(0xFF64B5F6),
      Color(0xFF9575CD),
    ];
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, w, h * 0.62));
    for (final (i, color) in bands.indexed) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - i * 5),
        pi,
        pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
          ..color = color.withValues(alpha: 0.32 * rainbow),
      );
    }
    canvas.restore();
  }

  /// Charcos en el pasto y en el borde del patio, que se achican al secarse.
  void _paintPuddles(Canvas canvas) {
    final w = size.width, h = size.height;
    final rng = Random(17);
    final sky = Color.lerp(const Color(0xFF5E6B78), const Color(0xFFBFD8DC), daylight)!;
    for (var i = 0; i < 6; i++) {
      final c = Offset(w * (0.06 + 0.88 * rng.nextDouble()), h * (0.5 + 0.47 * rng.nextDouble()));
      final rw = (18 + 22 * rng.nextDouble()) * (0.35 + 0.65 * wet);
      final rect = Rect.fromCenter(center: c, width: rw * 2, height: rw * 0.7);
      canvas.drawOval(rect, Paint()..color = sky.withValues(alpha: 0.55 * wet));
      canvas.drawOval(
        rect.deflate(rw * 0.25).translate(-rw * 0.2, -rw * 0.06),
        Paint()..color = Colors.white.withValues(alpha: 0.18 * wet),
      );
    }
  }

  /// Arenero con marco de madera y el último dibujo.
  void _paintSandBed(Canvas canvas, Rect r) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(r.inflate(5), const Radius.circular(6)),
      Paint()..color = Palette.wood.withValues(alpha: 0.85),
    );
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)));
    canvas.translate(r.left, r.top);
    canvas.drawPicture(sandTexture(r.size, seed: 4));
    canvas.restore();
    if (drawing.length >= 4) {
      final side = min(r.width, r.height) * 0.92;
      final box = Rect.fromCenter(center: r.center, width: side, height: side);
      final pts = <P>[for (var i = 0; i + 1 < drawing.length; i += 2) (x: drawing[i], y: drawing[i + 1])];
      drawGrooves(canvas, [pts], box, 1, tines: 4);
    } else {
      // Surcos rectos de jardín recién rastrillado y una piedra.
      final groove = Paint()
        ..color = Palette.sandShadow.withValues(alpha: 0.6)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      for (var y = r.top + 10; y < r.bottom - 6; y += 9) {
        canvas.drawLine(Offset(r.left + 6, y), Offset(r.right - 6, y), groove);
      }
      final rock = Offset(r.left + r.width * 0.72, r.top + r.height * 0.45);
      for (var i = 1; i <= 3; i++) {
        canvas.drawOval(
          Rect.fromCenter(center: rock, width: 26.0 + i * 16, height: 14.0 + i * 9),
          Paint()..color = Palette.sand,
        );
        canvas.drawOval(Rect.fromCenter(center: rock, width: 26.0 + i * 16, height: 14.0 + i * 9), groove);
      }
      canvas.drawOval(Rect.fromCenter(center: rock, width: 26, height: 15), Paint()..color = Palette.stone);
      final tp = TextPainter(
        text: TextSpan(
          text: tr('garden.sand.empty'),
          style: TextStyle(color: Palette.ink.withValues(alpha: 0.5), fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: r.width * 0.5);
      tp.paint(canvas, Offset(r.left + 10, r.top + 10));
    }
  }

  /// Cerco de bambú en el borde del terreno cuidado (si no ocupa todo).
  void _paintFence(Canvas canvas) {
    final g = layout.ground;
    if (g.left <= 0) return;
    final post = Paint()..color = const Color(0xFFB59A5B);
    final rail = Paint()
      ..color = const Color(0xFF8E7746)
      ..strokeWidth = 3;
    for (final x in [g.left, g.right]) {
      for (var y = g.top; y < size.height; y += 16) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 3, y - 10, 6, 14), const Radius.circular(2)), post);
      }
      canvas.drawLine(Offset(x, g.top - 6), Offset(x, size.height), rail);
    }
    canvas.drawLine(Offset(g.left, g.top - 4), Offset(g.right, g.top - 4), rail);
  }

  /// La torre guardada del Apilado, sobre su pedestal. Una torre muy alta
  /// sigue hacia arriba hasta salir de la escena.
  void _paintTower(Canvas canvas, Rect r) {
    final scale = r.width / 3.8;
    final base = Offset(r.center.dx, r.bottom - scale * 1.1);
    final ped = Rect.fromCenter(center: base + Offset(0, scale * 0.5), width: scale * 3.4, height: scale);
    canvas.drawOval(
      ped.shift(Offset(0, scale * 0.35)).inflate(4),
      Paint()..color = Palette.ink.withValues(alpha: 0.12),
    );
    canvas.drawRRect(RRect.fromRectAndRadius(ped, Radius.circular(scale * 0.15)), Paint()..color = Palette.stoneDark);
    final ghost = tower.isEmpty;
    final stones = ghost ? _ghostTower : tower;
    // Una torre alta se achica para no tapar el jardín; si ni así entra,
    // sigue hacia arriba fuera de la escena.
    final meters = stones.fold(0.0, (a, s) => a + s.h * 0.88);
    final stoneScale = max(scale * 0.3, min(scale, (r.height - scale * 1.1) * 1.2 / max(meters, 0.1)));
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(stoneScale);
    var bottom = 0.0;
    double? prevH;
    for (final s in stones) {
      // La silueta se arma una vez por piedra.
      final shape = _stoneCache[s.seed] ??= StoneShape(
        StoneKind.values[s.kind.clamp(0, StoneKind.values.length - 1)],
        s.w,
        s.h,
        s.tone,
        s.seed,
      );
      bottom += prevH == null ? 0 : 0.12 * min(prevH, s.h);
      final y = bottom - s.h / 2;
      if (base.dy + (y - s.h) * stoneScale < r.top - r.height * 0.2) break;
      canvas.save();
      canvas.translate(s.x, y);
      paintStone(canvas, shape, opacity: ghost ? 0.45 : 1);
      canvas.restore();
      bottom -= s.h;
      prevH = s.h;
    }
    canvas.restore();
  }

  /// Vasijas de la Lluvia, con agua quieta adentro.
  void _paintJars(Canvas canvas, Rect r) {
    const n = 4;
    final span = r.width * 0.6;
    final slot = span / n;
    final jw = min(slot * 0.74, r.height * 1.1);
    final jh = jw * 0.82;
    const glaze = [Color(0xFF6F8F9A), Color(0xFF8A6F5C), Color(0xFF5E7B86), Color(0xFF9A7E66)];
    for (var i = 0; i < n; i++) {
      final cx = r.left + slot * (i + 0.5);
      final bottom = r.center.dy + jh / 2;
      final body = Rect.fromLTRB(cx - jw / 2, bottom - jh, cx + jw / 2, bottom);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, bottom), width: jw * 1.1, height: jh * 0.22),
        Paint()..color = Palette.ink.withValues(alpha: 0.12),
      );
      // Las mismas vasijas pintadas del minijuego, si están.
      final art = SceneArt.instance['obj_rain_vessel_0${i + 1}'];
      if (drawArtIn(canvas, art, Rect.fromLTRB(cx - jw * 0.6, bottom - jh * 1.25, cx + jw * 0.6, bottom)) != null) {
        continue;
      }
      final path = Path()
        ..moveTo(body.left + jw * 0.16, body.top + jh * 0.08)
        ..quadraticBezierTo(body.left - jw * 0.06, body.top + jh * 0.55, body.left + jw * 0.24, body.bottom)
        ..lineTo(body.right - jw * 0.24, body.bottom)
        ..quadraticBezierTo(body.right + jw * 0.06, body.top + jh * 0.55, body.right - jw * 0.16, body.top + jh * 0.08)
        ..close();
      canvas.drawPath(path, Paint()..color = glaze[i]);
      // Brillo del esmalte.
      canvas.drawLine(
        Offset(body.left + jw * 0.22, body.top + jh * 0.3),
        Offset(body.left + jw * 0.2, body.top + jh * 0.62),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
      final mouth = Rect.fromCenter(center: Offset(cx, body.top + jh * 0.08), width: jw * 0.7, height: jh * 0.2);
      canvas.drawOval(mouth, Paint()..color = Color.lerp(glaze[i], Palette.ink, 0.3)!);
      canvas.drawOval(mouth.deflate(jw * 0.05), Paint()..color = Palette.water.withValues(alpha: 0.9));
    }
  }

  /// Puesto del Mercado: mostrador con mercadería, toldo a rayas y un farol.
  void _paintMarket(Canvas canvas, Rect m) {
    final w = m.width, h = m.height;
    final wood = Paint()..color = Palette.wood;
    final dark = Paint()..color = const Color(0xFF5E3D28);
    canvas.drawOval(
      Rect.fromLTRB(m.left, m.bottom - h * 0.08, m.right, m.bottom + h * 0.04),
      Paint()..color = Palette.ink.withValues(alpha: 0.12),
    );
    for (final x in [m.left + w * 0.1, m.right - w * 0.1]) {
      canvas.drawRect(Rect.fromLTRB(x - w * 0.025, m.top + h * 0.18, x + w * 0.025, m.bottom), dark);
    }
    final counter = Rect.fromLTRB(m.left + w * 0.04, m.top + h * 0.6, m.right - w * 0.04, m.bottom - h * 0.02);
    canvas.drawRRect(RRect.fromRectAndRadius(counter, const Radius.circular(3)), wood);
    canvas.drawRect(Rect.fromLTRB(counter.left, counter.top, counter.right, counter.top + h * 0.05), dark);
    for (var x = counter.left + w * 0.12; x < counter.right - 4; x += w * 0.15) {
      canvas.drawLine(
        Offset(x, counter.top + h * 0.06),
        Offset(x, counter.bottom),
        Paint()
          ..color = const Color(0xFF6F4A31)
          ..strokeWidth = 1,
      );
    }
    // Mercadería: frascos de esencias y un loto.
    final goods = [Palette.water, Palette.sandShadow, Palette.wood, Palette.lantern, Palette.lotus];
    for (var i = 0; i < goods.length; i++) {
      final c = Offset(counter.left + counter.width * (0.14 + 0.18 * i), counter.top - h * 0.045);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: w * 0.09, height: h * 0.09),
          const Radius.circular(4),
        ),
        Paint()..color = goods[i],
      );
    }
    // Toldo a rayas con borde ondulado.
    final top = m.top + h * 0.08, bottom = m.top + h * 0.3;
    final awning = Path()
      ..moveTo(m.left + w * 0.06, top)
      ..lineTo(m.right - w * 0.06, top)
      ..lineTo(m.right, bottom)
      ..lineTo(m.left, bottom)
      ..close();
    canvas.save();
    canvas.clipPath(awning);
    const stripes = 7;
    for (var i = 0; i < stripes; i++) {
      canvas.drawRect(
        Rect.fromLTWH(m.left + w * i / stripes, top, w / stripes + 1, bottom - top),
        Paint()..color = i.isEven ? Palette.lotus : Palette.paper,
      );
    }
    canvas.restore();
    for (var i = 0; i < stripes; i++) {
      canvas.drawCircle(
        Offset(m.left + w * (i + 0.5) / stripes, bottom),
        w / stripes / 2,
        Paint()..color = i.isEven ? Palette.lotus : Palette.paper,
      );
    }
    canvas.drawRect(Rect.fromLTRB(m.left + w * 0.04, top - h * 0.05, m.right - w * 0.04, top), dark);
    // Farol de papel colgado (se enciende de noche en _paintLanternLight).
    final lamp = layout.lanterns[0];
    canvas.drawLine(Offset(lamp.dx, bottom), lamp - Offset(0, h * 0.06), dark..strokeWidth = 1.2);
    canvas.drawOval(
      Rect.fromCenter(center: lamp, width: w * 0.1, height: h * 0.13),
      Paint()..color = const Color(0xFFD8643F),
    );
  }

  /// Tablón de piedras (los récords) con techito y papeles clavados.
  void _paintBoard(Canvas canvas, Rect b) {
    final w = b.width, h = b.height;
    final dark = Paint()..color = const Color(0xFF5E3D28);
    for (final x in [b.left + w * 0.14, b.right - w * 0.14]) {
      canvas.drawRect(Rect.fromLTRB(x - w * 0.04, b.top + h * 0.12, x + w * 0.04, b.bottom), dark);
    }
    final roof = Path()
      ..moveTo(b.left - w * 0.04, b.top + h * 0.2)
      ..quadraticBezierTo(b.center.dx, b.top - h * 0.02, b.right + w * 0.04, b.top + h * 0.2)
      ..lineTo(b.right - w * 0.04, b.top + h * 0.24)
      ..quadraticBezierTo(b.center.dx, b.top + h * 0.08, b.left + w * 0.04, b.top + h * 0.24)
      ..close();
    canvas.drawPath(roof, Paint()..color = Palette.stoneDark);
    final plank = Rect.fromLTRB(b.left + w * 0.04, b.top + h * 0.28, b.right - w * 0.04, b.top + h * 0.72);
    canvas.drawRRect(
      RRect.fromRectAndRadius(plank, const Radius.circular(3)),
      Paint()..color = const Color(0xFFB08560),
    );
    final ink = Paint()
      ..color = Palette.ink.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final note = Rect.fromLTWH(
        plank.left + plank.width * (0.08 + 0.3 * i),
        plank.top + plank.height * (i.isEven ? 0.12 : 0.2),
        plank.width * 0.26,
        plank.height * 0.66,
      );
      canvas.save();
      canvas.translate(note.center.dx, note.center.dy);
      canvas.rotate((i - 1) * 0.07);
      canvas.translate(-note.center.dx, -note.center.dy);
      canvas.drawRect(note, Paint()..color = Palette.paper);
      for (var k = 1; k <= 3; k++) {
        final y = note.top + note.height * k / 4.5;
        canvas.drawLine(Offset(note.left + 3, y), Offset(note.right - 3, y), ink);
      }
      canvas.restore();
    }
  }

  /// Cerezo con el cojín de meditación y un farol de piedra.
  void _paintMeditation(Canvas canvas, Rect d) {
    final w = d.width, h = d.height;
    canvas.drawOval(
      Rect.fromLTRB(d.left + w * 0.12, d.bottom - h * 0.1, d.right - w * 0.02, d.bottom + h * 0.03),
      Paint()..color = Palette.ink.withValues(alpha: 0.12),
    );
    // Tronco y ramas.
    final bark = Paint()
      ..color = const Color(0xFF5A4034)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final trunk = Path()
      ..moveTo(d.left + w * 0.7, d.bottom - h * 0.04)
      ..quadraticBezierTo(d.left + w * 0.76, d.top + h * 0.6, d.left + w * 0.6, d.top + h * 0.36);
    canvas.drawPath(trunk, bark..strokeWidth = w * 0.07);
    canvas.drawLine(
      Offset(d.left + w * 0.68, d.top + h * 0.5),
      Offset(d.left + w * 0.86, d.top + h * 0.34),
      bark..strokeWidth = w * 0.03,
    );
    // Copa de flores.
    final rng = Random(8);
    const blossoms = [Color(0xFFE6AEBC), Color(0xFFF1C9D2), Color(0xFFD993A6)];
    final crown = Offset(d.left + w * 0.62, d.top + h * 0.27);
    for (var i = 0; i < 16; i++) {
      final a = rng.nextDouble() * pi * 2;
      final dist = rng.nextDouble();
      final c = crown + Offset(cos(a) * w * 0.28 * dist, sin(a) * h * 0.16 * dist);
      canvas.drawCircle(c, w * (0.1 + rng.nextDouble() * 0.07), Paint()..color = blossoms[i % 3]);
    }
    // Pétalos caídos.
    for (var i = 0; i < 9; i++) {
      final c = Offset(d.left + w * (0.25 + rng.nextDouble() * 0.7), d.bottom - h * rng.nextDouble() * 0.12);
      canvas.drawOval(Rect.fromCenter(center: c, width: 4, height: 2.6), Paint()..color = blossoms[i % 3]);
    }
    // Tarima de piedra y cojín.
    final seat = Offset(d.left + w * 0.42, d.bottom - h * 0.13);
    canvas.drawOval(
      Rect.fromCenter(center: seat, width: w * 0.42, height: h * 0.11),
      Paint()..color = Palette.stoneLight,
    );
    if (meditationOpen) {
      // El cojín de la racha es un zafu de brocado rojo con ribete dorado.
      final zafu = streakObjects.contains('cushion');
      final cushion = seat - Offset(0, h * 0.035);
      canvas.drawOval(
        Rect.fromCenter(center: cushion, width: w * 0.24, height: h * 0.08),
        Paint()..color = zafu ? const Color(0xFF9E3F38) : const Color(0xFF4F5A86),
      );
      if (zafu) {
        canvas.drawOval(
          Rect.fromCenter(center: cushion, width: w * 0.24, height: h * 0.08),
          Paint()
            ..color = Palette.lantern
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
      canvas.drawOval(
        Rect.fromCenter(center: cushion - Offset(0, h * 0.012), width: w * 0.16, height: h * 0.04),
        Paint()..color = zafu ? const Color(0xFFBF5A4C) : const Color(0xFF6A76A3),
      );
    }
    if (streakObjects.contains('bowl')) _paintSingingBowl(canvas, Offset(seat.dx + w * 0.17, d.bottom - h * 0.035), w);
    final lantern = _paperLantern;
    if (lantern != null) {
      final hook = Offset(lantern.dx, d.top + h * 0.34);
      canvas.drawLine(
        hook,
        lantern - Offset(0, w * 0.05),
        Paint()
          ..color = Palette.ink
          ..strokeWidth = 1,
      );
      _paintPaperLantern(canvas, lantern, w * 0.05, 0);
    }
    // Farol de piedra (tōrō).
    final lamp = layout.lanterns[1];
    final s = w * 0.07;
    final stone = Paint()..color = Palette.stone;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(lamp.dx, d.bottom - h * 0.02), width: s * 1.6, height: s * 0.4),
      stone,
    );
    canvas.drawRect(Rect.fromLTRB(lamp.dx - s * 0.3, lamp.dy + s * 0.6, lamp.dx + s * 0.3, d.bottom - h * 0.02), stone);
    canvas.drawRect(Rect.fromCenter(center: lamp, width: s * 1.2, height: s * 1.1), stone);
    canvas.drawRect(
      Rect.fromCenter(center: lamp, width: s * 0.55, height: s * 0.6),
      Paint()..color = Palette.stoneDark,
    );
    final cap = Path()
      ..moveTo(lamp.dx - s * 1.1, lamp.dy - s * 0.5)
      ..lineTo(lamp.dx, lamp.dy - s * 1.2)
      ..lineTo(lamp.dx + s * 1.1, lamp.dy - s * 0.5)
      ..close();
    canvas.drawPath(cap, Paint()..color = Palette.stoneDark);
  }

  /// Cuenco tibetano de bronce sobre un almohadón, apoyado en [base].
  void _paintSingingBowl(Canvas canvas, Offset base, double w) {
    final s = w * 0.07;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: base, width: s * 2.2, height: s * 0.7), Radius.circular(s * 0.3)),
      Paint()..color = const Color(0xFF9E3F38),
    );
    final bowl = Path()
      ..moveTo(base.dx - s, base.dy - s * 1.1)
      ..quadraticBezierTo(base.dx - s, base.dy - s * 0.1, base.dx, base.dy - s * 0.1)
      ..quadraticBezierTo(base.dx + s, base.dy - s * 0.1, base.dx + s, base.dy - s * 1.1)
      ..close();
    canvas.drawPath(bowl, Paint()..color = const Color(0xFFA9803F));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(base.dx, base.dy - s * 1.1), width: s * 2, height: s * 0.45),
      Paint()..color = const Color(0xFF6E5228),
    );
    canvas.drawLine(
      Offset(base.dx - s * 0.55, base.dy - s * 0.75),
      Offset(base.dx - s * 0.15, base.dy - s * 0.4),
      Paint()
        ..color = const Color(0xFFE0BE78)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Centro del farol de papel de la racha, colgado de la rama del cerezo.
  Offset? get _paperLantern {
    final d = layout.places[Place.meditation];
    if (d == null || !streakObjects.contains('lantern')) return null;
    return Offset(d.left + d.width * 0.86, d.top + d.height * 0.34 + d.width * 0.12);
  }

  /// Farol de papel de tamaño [s]; [lit] (0 a 1) lo enciende.
  void _paintPaperLantern(Canvas canvas, Offset c, double s, double lit) {
    final body = Rect.fromCenter(center: c, width: s * 1.6, height: s * 2);
    canvas.drawOval(body, Paint()..color = Color.lerp(const Color(0xFFE9D7B0), const Color(0xFFFFD98A), lit)!);
    final rib = Paint()
      ..color = Palette.ink.withValues(alpha: 0.25)
      ..strokeWidth = 0.8;
    for (final k in [-0.5, 0.0, 0.5]) {
      canvas.drawLine(
        Offset(body.left + s * 0.2, c.dy + k * s * 0.8),
        Offset(body.right - s * 0.2, c.dy + k * s * 0.8),
        rib,
      );
    }
    final cap = Paint()..color = Palette.ink.withValues(alpha: 0.85);
    canvas.drawRect(Rect.fromCenter(center: Offset(c.dx, body.top), width: s * 0.9, height: s * 0.3), cap);
    canvas.drawRect(Rect.fromCenter(center: Offset(c.dx, body.bottom), width: s * 0.9, height: s * 0.3), cap);
  }

  /// Faroles encendidos: aparecen al atardecer y brillan toda la noche.
  void _paintLanternLight(Canvas canvas) {
    final glow = ((1 - daylight) * 1.2).clamp(0.0, 1.0);
    if (glow <= 0) return;
    for (final c in layout.lanterns) {
      final r = size.width * 0.11;
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
    // El farol de la racha se enciende encima de la penumbra.
    final paper = _paperLantern;
    if (paper != null) {
      final r = size.width * 0.08;
      canvas.drawCircle(
        paper,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Palette.lantern.withValues(alpha: 0.45 * glow),
              Palette.lantern.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: paper, radius: r)),
      );
      final s = layout.places[Place.meditation]!.width * 0.05;
      canvas.saveLayer(null, Paint()..color = Colors.white.withValues(alpha: glow));
      _paintPaperLantern(canvas, paper, s, 1);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(GardenPainter old) =>
      old.layout.size != layout.size ||
      old.layout.ground != layout.ground ||
      old.tower != tower ||
      old.drawing != drawing ||
      old.meditationOpen != meditationOpen ||
      old.moss != moss ||
      old.layout.side != layout.side ||
      (old.daylight - daylight).abs() > 0.004 ||
      (old.warmth - warmth).abs() > 0.004 ||
      (old.arc - arc).abs() > 0.002 ||
      old.morning != morning ||
      old.overcast != overcast ||
      old.snowy != snowy ||
      (old.wet - wet).abs() > 0.01 ||
      (old.rainbow - rainbow).abs() > 0.01 ||
      old.streakObjects.length != streakObjects.length ||
      old.ensoInk != ensoInk ||
      !_sameDecor(old.decor, decor);
}

bool _sameDecor(List<(String, Rect)> a, List<(String, Rect)> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
