import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../garden/mirador.dart';
import '../garden/garden_decor.dart';
import '../garden/scene_art.dart';
import '../theme/palette.dart';

/// Qué se tocó en el patio.
enum PanoHit { place, model, gate, exit, decor, slot, gift, care, visitor, tea, tower }

class PanoTarget {
  final PanoHit kind;

  /// El lugar, el mirador de una salida, el portón o el id del regalo.
  final String? id;

  /// Sector (hueco, cuidado) e índice (decoración, hueco, cuidado, regalo).
  final int? zone, index;

  const PanoTarget(this.kind, {this.id, this.zone, this.index});

  @override
  bool operator ==(Object other) =>
      other is PanoTarget && other.kind == kind && other.id == id && other.zone == zone && other.index == index;

  @override
  int get hashCode => Object.hash(kind, id, zone, index);

  @override
  String toString() => 'PanoTarget($kind, $id, $zone, $index)';
}

/// Una decoración del jugador puesta en su hueco.
class PanoThing {
  final Offset pos;
  final double width, aspect;
  final String decor;
  final bool flip;
  final int index;
  const PanoThing({
    required this.pos,
    required this.width,
    required this.aspect,
    required this.decor,
    required this.index,
    this.flip = false,
  });
}

/// Algo vivo que se toca: un regalo, un cuidado, un visitante, un hueco. Sin
/// arte, se dibuja como una burbuja con su ícono.
class PanoMarker {
  final Offset pos;
  final double width, aspect;
  final String? art;
  final IconData? icon;
  final Color color;
  final PanoTarget target;

  /// Apoyado en el suelo (un hueco) en vez de parado.
  final bool flat;

  const PanoMarker({
    required this.pos,
    required this.target,
    this.width = 0.5,
    this.aspect = 1,
    this.art,
    this.icon,
    this.color = Palette.lantern,
    this.flat = false,
  });
}

/// Cómo se ve cada lugar.
class PlaceLook {
  final bool open;
  final String name;
  final String? note;

  /// Tiene algo nuevo o para retirar.
  final bool dot;
  const PlaceLook({required this.open, required this.name, this.note, this.dot = false});
}

/// Una salida: la piedra con luz hacia otro mirador.
class PanoExit {
  final Offset pos;
  final String to, label;

  /// Hacia dónde apunta (grados).
  final double bearing;
  const PanoExit({required this.pos, required this.to, required this.label, required this.bearing});
}

/// El arte de cada lugar (el primero que esté pintado) y su alto sobre ancho
/// si no hay arte.
const placeArt = <String, (List<String>, double)>{
  'board': (['obj_court_board'], 1.1),
  'meditation': (['obj_station_meditation', 'obj_court_zafu'], 0.7),
  'sand': (['obj_station_sand'], 0.45),
  'stack': (['obj_stack_pedestal', 'obj_court_tower_base'], 1.2),
  'rain': (['obj_court_jars'], 0.8),
  'pond': (['obj_station_pond'], 0.4),
  'shishi': (['obj_shishi_basin'], 0.9),
  'leaves': (['obj_station_leaves', 'obj_decor_maple'], 0.95),
  'moss': (['obj_moss_rock'], 0.6),
  'bonsai': (['obj_bonsai_table'], 1.0),
  'enso': (['obj_callig_hall'], 0.8),
  'bell': (['obj_temple_belltower'], 1.1),
  'matcha': (['obj_tea_house'], 0.75),
  'flute': (['obj_bamboo_flute'], 1.6),
  'lanterns': (['obj_river_lantern'], 1.6),
  'model': (['obj_model_table'], 0.8),
};

/// Cuántos metros de suelo cubre cada copia de la textura de detalle.
const _detailMeters = 2.2;

/// Lo que va sobre la galería del pabellón (a cuántos metros del suelo).
const _lifted = {'meditation': 0.45, 'model': 0.45};

/// El alto máximo (m) de cada lugar: el arte alto se achica para no pasarse.
const _maxHeight = {
  'flute': 1.7,
  'lanterns': 1.1,
  'stack': 1.5,
  'shishi': 1.3,
  'rain': 1.3,
  'board': 1.7,
  'moss': 1.0,
  'leaves': 2.4,
  'meditation': 0.6,
  'model': 0.9,
  'bonsai': 1.6,
};

/// Recortes de arte ya pintado (una parte de una imagen), hechos una vez.
final _crops = <(int, Rect), ui.Image>{};

/// La parte [frac] (en fracciones del ancho y el alto) del arte [name].
ui.Image? cropArt(String name, Rect frac) {
  final img = SceneArt.instance[name];
  if (img == null) return null;
  return _crops[(identityHashCode(img), frac)] ??= () {
    final src = Rect.fromLTRB(
      frac.left * img.width,
      frac.top * img.height,
      frac.right * img.width,
      frac.bottom * img.height,
    );
    final rec = ui.PictureRecorder();
    Canvas(rec).drawImageRect(img, src, Offset.zero & src.size, Paint()..filterQuality = FilterQuality.medium);
    return rec.endRecording().toImageSync(src.width.round(), src.height.round());
  }();
}

/// El muro pintado del patio (bg_court_wall): el tramo sin portón, de la copa
/// de los árboles al suelo, y el portón solo.
const _wallFrac = Rect.fromLTRB(0, 320 / 1536, 0.62, 770 / 1536);
const _gateFrac = Rect.fromLTRB(615 / 1024, 455 / 1536, 885 / 1024, 772 / 1536);

/// En el muro pintado: dónde está el suelo y el alto del muro con su tejado
/// (en píxeles del recorte, sobre 450 de alto).
const _wallGround = 445.0, _wallRoof = 223.0;

/// La cámara de un mirador: gira 360° alrededor de [pos]. Proyección
/// cilíndrica: el ángulo da la x y la distancia da la altura en pantalla.
class PanoCamera {
  final Size size;
  final Offset pos;

  /// Hacia dónde se mira (radianes) y el campo de visión (radianes).
  final double yaw, fov, zoom, eye, horizonFrac, bob;

  const PanoCamera({
    required this.size,
    required this.pos,
    required this.yaw,
    required this.fov,
    this.zoom = 1,
    this.eye = 1.5,
    this.horizonFrac = 0.47,
    this.bob = 0,
  });

  /// Píxeles por radián.
  double get f => size.width / fov * zoom;
  double get horizon => size.height * horizonFrac + bob;

  static double wrap(double a) {
    a = (a + pi) % (2 * pi);
    if (a < 0) a += 2 * pi;
    return a - pi;
  }

  /// Ángulo (respecto de donde se mira) y distancia a [p].
  (double, double) polar(Offset p) {
    final d = p - pos;
    return (wrap(atan2(d.dx, d.dy) - yaw), d.distance);
  }

  double xAt(double angle) => size.width / 2 + angle * f;

  /// La altura en pantalla de algo a [h] metros del suelo, a [dist] metros.
  double yAt(double dist, [double h = 0]) => horizon + (eye - h) * f / dist;

  /// Un punto del suelo (o a [h] metros) en pantalla; null si queda detrás.
  Offset? project(Offset p, [double h = 0]) {
    final (a, d) = polar(p);
    if (d < 0.3 || a.abs() > pi * 0.7) return null;
    return Offset(xAt(a), yAt(d, h));
  }

  /// Qué ángulo del mundo (radianes) se ve en la columna [x].
  double worldAngleAt(double x) => yaw + (x - size.width / 2) / f;
}

/// Todo lo que hace falta para dibujar un momento del patio.
class PanoView {
  final MiradorWorld world;
  final Offset pos;
  final double yaw, fov, zoom, bob, daylight;
  final Map<String, PlaceLook> places;
  final List<PanoThing> decor;
  final List<PanoMarker> markers;
  final List<PanoExit> exits;

  /// El mirador central de la Clásica: cámara más baja, sin senderos y con
  /// matas en primer plano.
  final bool hub;

  /// Un objeto resaltado (al llegar a un juego o una decoración pedida).
  final PanoTarget? glow;

  const PanoView({
    required this.world,
    required this.pos,
    required this.yaw,
    required this.fov,
    this.zoom = 1,
    this.bob = 0,
    this.daylight = 1,
    this.places = const {},
    this.decor = const [],
    this.markers = const [],
    this.exits = const [],
    this.hub = false,
    this.glow,
  });
}

class _Item {
  final double dist;
  final Rect rect;
  final PanoTarget? target;
  final void Function() draw;
  _Item(this.dist, this.rect, this.target, this.draw);
}

/// El patio visto desde un mirador: qué se dibuja dónde y qué se toca.
class PanoScene {
  final Size size;
  final PanoView v;
  late final PanoCamera cam = PanoCamera(
    size: size,
    pos: v.pos,
    yaw: v.yaw,
    fov: v.fov,
    zoom: v.zoom,
    eye: v.hub ? v.world.hubEye : v.world.eye,
    horizonFrac: v.hub ? v.world.hubHorizon : v.world.horizon,
    bob: v.bob,
  );
  final Canvas _c;
  final _flat = <_Item>[];
  final _items = <_Item>[];
  final _labels = <_Item>[];

  PanoScene(this.size, this.v, [Canvas? canvas]) : _c = canvas ?? Canvas(ui.PictureRecorder()) {
    _build();
  }

  MiradorWorld get w => v.world;

  /// Lo que se tocó en [p] (lo más cercano primero).
  PanoTarget? hit(Offset p) {
    // Lo de adelante primero; el cartel de algo, apenas antes que su dibujo.
    final all = [
      for (final it in _labels) (it.dist - 0.01, it),
      for (final it in _items) (it.dist, it),
      for (final it in _flat) (it.dist + 0.5, it),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    for (final (_, it) in all) {
      if (it.target != null && it.rect.contains(p)) return it.target;
    }
    return null;
  }

  /// Dónde quedó [t] en pantalla.
  Rect? rectOf(PanoTarget t) {
    for (final it in [..._items, ..._flat]) {
      if (it.target == t) return it.rect;
    }
    return null;
  }

  void paint() {
    _sky();
    _far();
    _ground();
    _wall();
    _texture();
    _flat.sort((a, b) => b.dist.compareTo(a.dist));
    for (final it in _flat) {
      it.draw();
    }
    _items.sort((a, b) => b.dist.compareTo(a.dist));
    for (final it in _items) {
      it.draw();
    }
    _labels.sort((a, b) => b.dist.compareTo(a.dist));
    for (final it in _labels) {
      it.draw();
    }
    _veil();
  }

  // ---- Colores del momento ----

  late final _mist = Color.lerp(const Color(0xFF3A4660), const Color(0xFFEFE6D2), v.daylight)!;
  late final _tint = Color.lerp(const Color(0xFF7A86A8), Colors.white, v.daylight)!;

  double _fog(double d) => ((d - 10) / 28).clamp(0.0, 0.4);

  /// El filtro de algo a [d] metros: bruma, luz del día y, si está cerrado,
  /// casi sin color.
  ColorFilter? _filter(double d, {bool locked = false}) {
    final fog = _fog(d);
    final sat = locked ? 0.35 : 1.0;
    if (fog < 0.01 && !locked && v.daylight > 0.99) return null;
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final tint = [_tint.r, _tint.g, _tint.b];
    final mist = [_mist.r, _mist.g, _mist.b];
    final m = <double>[];
    for (var c = 0; c < 3; c++) {
      final k = tint[c] * (1 - fog) * (locked ? 0.92 : 1);
      m.addAll([
        k * (sat * (c == 0 ? 1 : 0) + (1 - sat) * lr),
        k * (sat * (c == 1 ? 1 : 0) + (1 - sat) * lg),
        k * (sat * (c == 2 ? 1 : 0) + (1 - sat) * lb),
        0,
        fog * mist[c] * 255,
      ]);
    }
    m.addAll([0, 0, 0, 1, 0]);
    return ColorFilter.matrix(m);
  }

  /// Dibuja [draw] (con código) con el filtro de [d] metros.
  void _filtered(Rect bounds, double d, void Function() draw, {bool locked = false, double alpha = 1}) {
    final f = _filter(d, locked: locked);
    if (f == null && alpha > 0.99) return draw();
    _c.saveLayer(
      bounds.inflate(30),
      Paint()
        ..colorFilter = f
        ..color = Colors.white.withValues(alpha: alpha),
    );
    draw();
    _c.restore();
  }

  void _art(ui.Image img, Rect r, double d, {bool flip = false, bool locked = false, double alpha = 1}) {
    final paint = Paint()
      ..colorFilter = _filter(d, locked: locked)
      ..color = Colors.white.withValues(alpha: alpha);
    if (!flip) return drawArt(_c, img, r, paint: paint);
    _c.save();
    _c.translate(r.center.dx * 2, 0);
    _c.scale(-1, 1);
    drawArt(_c, img, r, paint: paint);
    _c.restore();
  }

  ui.Image? _img(List<String> names) {
    for (final n in names) {
      if (SceneArt.instance[n] case final img?) return img;
    }
    return null;
  }

  // ---- Cielo, montes y suelo ----

  void _sky() {
    final dl = v.daylight;
    final top = Color.lerp(const Color(0xFF1D2740), const Color(0xFFA9C6D2), dl)!;
    final low = Color.lerp(const Color(0xFF3B4766), const Color(0xFFF2E7D0), dl)!;
    final r = Rect.fromLTRB(0, 0, size.width, cam.horizon + 2);
    _c.drawRect(r, Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, [top, low]));
    final art = SceneArt.instance['pano_sky'];
    if (art != null) _band(art, 0, cam.horizon, 0.4, opacity: 0.9);
    // El cielo pintado del patio, de día (de noche queda el degradado).
    final painted = SceneArt.instance['bg_court_sky'];
    if (art == null && painted != null) {
      _band(
        painted,
        cam.horizon - cam.f * 1.5,
        cam.horizon + 2,
        0.25,
        opacity: 0.15 + 0.85 * dl,
        mirror: true,
        filter: _farFilter(0),
      );
      return;
    }
    // Nubes que giran con la mirada.
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.35 * dl + 0.05);
    for (var i = 0; i < 9; i++) {
      final a = i * 2 * pi / 9 + (i.isEven ? 0.2 : 0);
      final x = cam.xAt(PanoCamera.wrap(a - cam.yaw));
      final y = cam.horizon * (0.25 + 0.4 * ((i * 37) % 10) / 10);
      final wpx = cam.f * (0.35 + (i % 3) * 0.12);
      if (x + wpx < 0 || x - wpx > size.width) continue;
      _c.drawOval(Rect.fromCenter(center: Offset(x, y), width: wpx, height: wpx * 0.22), cloud);
      _c.drawOval(
        Rect.fromCenter(center: Offset(x + wpx * 0.2, y - wpx * 0.06), width: wpx * 0.55, height: wpx * 0.2),
        cloud,
      );
    }
  }

  /// Una franja pintada que se repite alrededor (360°): [turn] es qué parte de
  /// la vuelta ocupa una copia.
  /// Con [mirror], una copia sí y otra no va espejada (así el arte que no se
  /// repite empalma sin costura; [turn] tiene que dar una cantidad par de copias).
  void _band(
    ui.Image img,
    double top,
    double bottom,
    double turn, {
    double opacity = 1,
    bool mirror = false,
    ColorFilter? filter,
  }) {
    final period = 2 * pi * turn;
    final wpx = cam.f * period;
    if (wpx < 4) return;
    final paint = Paint()
      ..colorFilter = filter ?? _filter(40)
      ..color = Colors.white.withValues(alpha: opacity)
      ..filterQuality = FilterQuality.medium;
    final src = Offset.zero & Size(img.width.toDouble(), img.height.toDouble());
    var n = ((cam.yaw - size.width / 2 / cam.f) / period).floor();
    while (true) {
      final x = size.width / 2 + (n * period - cam.yaw) * cam.f;
      if (x >= size.width) break;
      final dst = Rect.fromLTRB(x, top, x + wpx + 1, bottom);
      if (mirror && n % 2 != 0) {
        _c.save();
        _c.translate(dst.center.dx * 2, 0);
        _c.scale(-1, 1);
        _c.drawImageRect(img, src, dst, paint);
        _c.restore();
      } else {
        _c.drawImageRect(img, src, dst, paint);
      }
      n++;
    }
  }

  /// Una silueta que da la vuelta entera sin costura (suma de senos con
  /// frecuencias enteras).
  double _ridge(double a, List<(double, double, double)> waves) {
    var h = 0.0;
    for (final (k, amp, ph) in waves) {
      h += amp * sin(k * a + ph);
    }
    return h;
  }

  void _far() {
    final hz = cam.horizon;
    final mountains = SceneArt.instance['pano_far_mountains'];
    final far = cropArt('bg_base_far', const Rect.fromLTRB(0, 0, 1, 0.78));
    final hills = cropArt('bg_court_far', const Rect.fromLTRB(0, 330 / 1536, 1, 866 / 1536));
    if (mountains == null && far != null) {
      // Las montañas pintadas y, más cerca, las lomas con bosque (ya no se mueven al caminar).
      _band(far, hz - cam.f * 0.62, hz + cam.f * 0.12, 0.125, mirror: true, filter: _farFilter(0.35));
      if (hills != null) {
        _band(hills, hz - cam.f * 0.4, hz + cam.f * 0.03, 0.125, mirror: true, filter: _farFilter(0.15));
      }
      return;
    }
    if (mountains != null) {
      _band(mountains, hz - cam.f * 0.32, hz + 2, 0.5);
    } else {
      _silhouette(hz, 0.13, 0.05, const [
        (2, 0.5, 0.3),
        (3, 0.3, 1.7),
        (7, 0.15, 0.4),
        (11, 0.08, 2.2),
      ], Color.lerp(const Color(0xFF2E3852), const Color(0xFFB9C3C4), v.daylight)!);
    }
    // Las copas de los árboles detrás del muro.
    _silhouette(hz, 0.11, 0.05, const [
      (5, 0.4, 0.9),
      (13, 0.25, 0.2),
      (29, 0.18, 1.1),
      (47, 0.1, 2.5),
    ], Color.lerp(const Color(0xFF223024), const Color(0xFF8C9C78), v.daylight)!);
  }

  /// Lo lejano: el tinte de la hora y [haze] de bruma.
  ColorFilter _farFilter(double haze) {
    final k = 1 - haze;
    return ColorFilter.matrix([
      _tint.r * k,
      0,
      0,
      0,
      haze * _mist.r * 255,
      0,
      _tint.g * k,
      0,
      0,
      haze * _mist.g * 255,
      0,
      0,
      _tint.b * k,
      0,
      haze * _mist.b * 255,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  void _silhouette(double base, double height, double minH, List<(double, double, double)> waves, Color color) {
    final path = Path()..moveTo(0, base + 2);
    for (var x = 0.0; x <= size.width + 6; x += 6) {
      final a = cam.worldAngleAt(x);
      final h = minH + height * (0.55 + 0.45 * _ridge(a, waves));
      path.lineTo(x, base - h * cam.f);
    }
    path
      ..lineTo(size.width, base + 2)
      ..close();
    _c.drawPath(path, Paint()..color = color);
  }

  /// El color del suelo en [p]; con la arena pintada encima ([painted]), la
  /// grava va casi blanca (la arena pone el color).
  Color _groundAt(Offset p, double d, {bool painted = false}) {
    Color base;
    if (w.inPond(p)) {
      base = const Color(0xFF6F98A2);
    } else {
      final n = sin(p.dx * 1.9) * sin(p.dy * 1.4) * 0.5 + sin(p.dx * 0.6 + p.dy * 0.8) * 0.5;
      final gravel = painted
          ? Color.lerp(const Color(0xFFFFFFFF), const Color(0xFFEDE6D8), 0.5 + n * 0.5)!
          : Color.lerp(const Color(0xFFE9E0CB), const Color(0xFFD9CDB2), 0.5 + n * 0.5)!;
      final moss = Color.lerp(const Color(0xFF8E9F68), const Color(0xFF6E8350), 0.5 + n * 0.5)!;
      base = Color.lerp(gravel, moss, w.mossAt(p))!;
    }
    base = Color.from(alpha: 1, red: base.r * _tint.r, green: base.g * _tint.g, blue: base.b * _tint.b);
    return Color.lerp(base, _mist, _fog(d))!;
  }

  /// El suelo: una malla que va de lejos a cerca con el color de cada punto.
  void _ground() {
    final hz = cam.horizon;
    if (hz >= size.height) return;
    final ownDetail = SceneArt.instance['tex_pano_ground_detail'];
    // Sin textura propia del suelo, la arena y el musgo pintados de los juegos.
    final sand = ownDetail == null ? SceneArt.instance['tex_sand_base'] : null;
    final mossTex = sand == null ? null : SceneArt.instance['tex_moss'];
    final detail = ownDetail ?? sand;
    final cols = detail == null ? 22 : 30;
    final ys = <double>[];
    // Más filas cerca del horizonte (donde cambia más rápido).
    final rows = detail == null ? 34 : 46;
    for (var i = 0; i <= rows; i++) {
      final t = i / rows;
      ys.add(hz + 1.5 + (size.height - hz) * t * t);
    }
    final pos = Float32List((cols + 1) * ys.length * 2);
    final tex = Float32List((cols + 1) * ys.length * 2);
    final colors = Int32List((cols + 1) * ys.length);
    // La textura de detalle cubre [_detailMeters] metros por copia, pegada al suelo.
    final pxPerM = detail == null ? 0.0 : detail.width / (sand != null ? 1.6 : _detailMeters);
    final mossCols = mossTex == null ? null : Int32List((cols + 1) * ys.length);
    var k = 0;
    for (var r = 0; r < ys.length; r++) {
      final y = ys[r];
      final d = min(60.0, cam.eye * cam.f / (y - hz));
      for (var col = 0; col <= cols; col++) {
        final x = size.width * col / cols;
        final a = cam.worldAngleAt(x);
        final p = cam.pos + Offset(sin(a), cos(a)) * d;
        pos[k * 2] = x;
        pos[k * 2 + 1] = y;
        tex[k * 2] = p.dx * pxPerM;
        tex[k * 2 + 1] = p.dy * pxPerM;
        colors[k] = _groundAt(p, d, painted: sand != null).toARGB32();
        if (mossCols != null) {
          final m = w.inPond(p) ? 0.0 : ((w.mossAt(p) - 0.2) / 0.6).clamp(0.0, 1.0);
          mossCols[k] = Color.lerp(_tint, _mist, _fog(d))!.withValues(alpha: m).toARGB32();
        }
        k++;
      }
    }
    final idx = <int>[];
    for (var r = 0; r < ys.length - 1; r++) {
      for (var col = 0; col < cols; col++) {
        final a = r * (cols + 1) + col, b = a + 1, c = a + cols + 1, dd = c + 1;
        idx.addAll([a, b, c, b, dd, c]);
      }
    }
    _c.drawRect(Rect.fromLTRB(0, hz, size.width, size.height), Paint()..color = _mist);
    final indices = Uint16List.fromList(idx);
    if (detail == null) {
      _c.drawVertices(
        ui.Vertices.raw(ui.VertexMode.triangles, pos, colors: colors, indices: indices),
        BlendMode.dst,
        Paint(),
      );
      return;
    }
    // El color de cada punto multiplicado por la textura (casi blanca, con piedritas y surcos).
    _c.drawVertices(
      ui.Vertices.raw(ui.VertexMode.triangles, pos, colors: colors, textureCoordinates: tex, indices: indices),
      BlendMode.modulate,
      Paint()
        ..shader = ImageShader(detail, TileMode.repeated, TileMode.repeated, Matrix4.identity().storage)
        ..filterQuality = FilterQuality.medium,
    );
    if (mossTex == null || mossCols == null) return;
    // El musgo pintado encima, donde hay musgo (el alfa de cada punto).
    final mk = mossTex.width / 2.0 / pxPerM;
    for (var i = 0; i < tex.length; i++) {
      tex[i] *= mk;
    }
    _c.drawVertices(
      ui.Vertices.raw(ui.VertexMode.triangles, pos, colors: mossCols, textureCoordinates: tex, indices: indices),
      BlendMode.modulate,
      Paint()
        ..shader = ImageShader(mossTex, TileMode.mirror, TileMode.mirror, Matrix4.identity().storage)
        ..filterQuality = FilterQuality.medium,
    );
  }

  /// El muro de yeso con tejado que rodea el patio y, detrás, el bosque.
  void _wall() {
    const step = 4.0;
    final pts = <(double, double, double, int)>[];
    for (var x = -step; x <= size.width + step; x += step) {
      final a = cam.worldAngleAt(x);
      final d = w.wallDistance(cam.pos, a);
      final hit = cam.pos + Offset(sin(a), cos(a)) * d;
      final face = (hit.dy - w.wall.bottom).abs() < 0.01
          ? 0
          : (hit.dx - w.wall.left).abs() < 0.01
          ? 1
          : (hit.dx - w.wall.right).abs() < 0.01
          ? 2
          : 3;
      // Por dónde pasa el borde del bosque (en metros a lo largo del muro).
      final along = face == 1 || face == 2 ? hit.dy : hit.dx;
      pts.add((x, d, along + face * 37.0, face));
    }
    void strip(double Function(int i) yTop, double Function(int i) yBot, Color Function(int i) color) {
      final n = pts.length;
      final pos = Float32List(n * 4);
      final cols = Int32List(n * 2);
      for (var i = 0; i < n; i++) {
        pos[i * 4] = pts[i].$1;
        pos[i * 4 + 1] = yTop(i);
        pos[i * 4 + 2] = pts[i].$1;
        pos[i * 4 + 3] = yBot(i);
        final c = color(i).toARGB32();
        cols[i * 2] = c;
        cols[i * 2 + 1] = c;
      }
      _c.drawVertices(ui.Vertices.raw(ui.VertexMode.triangleStrip, pos, colors: cols), BlendMode.dst, Paint());
    }

    Color lit(Color c, double d) => Color.lerp(
      Color.from(alpha: 1, red: c.r * _tint.r, green: c.g * _tint.g, blue: c.b * _tint.b),
      _mist,
      _fog(d) * 0.8,
    )!;
    final painted = cropArt('bg_court_wall', _wallFrac);
    if (painted != null) return _paintedWall(painted, pts);
    final hgt = w.wallHeight;
    double d(int i) => pts[i].$2;
    double s(int i) => pts[i].$3;
    final forest = SceneArt.instance['pano_forest'];
    if (forest != null) {
      // Pintado: una franja que da la vuelta, apoyada detrás del muro.
      final far = pts.map((p) => p.$2).reduce(min);
      _band(forest, cam.yAt(far + 6, hgt + 5.5), cam.yAt(far + 6, hgt - 0.5), 0.5);
    }
    // El bosque de atrás: copas de distintos altos (pinos, cedros, arces), en dos tandas.
    double crown(int i, double k) {
      final a = s(i);
      return hgt +
          1.3 +
          k * (1.2 * (0.5 + 0.5 * sin(a * 0.9)) + 0.8 * (0.5 + 0.5 * sin(a * 2.3 + 1)) + 0.25 * sin(a * 4.3));
    }

    if (forest == null) {
      strip(
        (i) => cam.yAt(d(i) + 6, crown(i, 1.3)),
        (i) => cam.yAt(d(i)),
        (i) => lit(const Color(0xFF8A9C86), d(i) + 14),
      );
      strip(
        (i) => cam.yAt(d(i) + 1.5, crown(i, 0.8) - 0.6),
        (i) => cam.yAt(d(i)),
        (i) =>
            lit(Color.lerp(const Color(0xFF6A8460), const Color(0xFF8C8A5E), 0.3 + 0.3 * sin(s(i) * 0.37))!, d(i) + 8),
      );
    }
    const plaster = [Color(0xFFEDE3CC), Color(0xFFE2D6BB), Color(0xFFE6DAC0), Color(0xFFF0E8D4)];
    // Base de piedra, yeso y un tejadito.
    strip((i) => cam.yAt(d(i), hgt), (i) => cam.yAt(d(i)), (i) => lit(plaster[pts[i].$4], d(i)));
    strip((i) => cam.yAt(d(i), 0.3), (i) => cam.yAt(d(i)), (i) => lit(const Color(0xFFA39C90), d(i)));
    strip(
      (i) => cam.yAt(d(i), hgt + 0.22),
      (i) => cam.yAt(d(i), hgt - 0.04),
      (i) => lit(const Color(0xFF666D78), d(i)),
    );
  }

  /// El muro pintado (yeso, tejado, matas al pie y árboles detrás) estirado
  /// sobre el muro del patio, a su distancia.
  void _paintedWall(ui.Image img, List<(double, double, double, int)> pts) {
    final k = img.height / 450;
    final pxPerM = _wallRoof * k / (w.wallHeight + 0.22);
    final top = _wallGround * k / pxPerM;
    final n = pts.length;
    final pos = Float32List(n * 4);
    final tex = Float32List(n * 4);
    final cols = Int32List(n * 2);
    for (var i = 0; i < n; i++) {
      final (x, d, along, _) = pts[i];
      pos[i * 4] = x;
      pos[i * 4 + 1] = cam.yAt(d, top);
      pos[i * 4 + 2] = x;
      pos[i * 4 + 3] = cam.yAt(d) + 1;
      tex[i * 4] = along * pxPerM;
      tex[i * 4 + 1] = 0;
      tex[i * 4 + 2] = along * pxPerM;
      tex[i * 4 + 3] = _wallGround * k;
      final c = Color.lerp(_tint, _mist, _fog(d) * 0.8)!.toARGB32();
      cols[i * 2] = c;
      cols[i * 2 + 1] = c;
    }
    _c.drawVertices(
      ui.Vertices.raw(ui.VertexMode.triangleStrip, pos, colors: cols, textureCoordinates: tex),
      BlendMode.modulate,
      Paint()
        ..shader = ImageShader(img, TileMode.mirror, TileMode.clamp, Matrix4.identity().storage)
        ..filterQuality = FilterQuality.medium,
    );
  }

  /// Los surcos del rastrillo en la grava y las matitas del musgo, cerca.
  void _texture() {
    const reach = 11.0;
    final half = cam.fov / cam.zoom / 2 + 0.15;
    final lines = [Path(), Path(), Path()];
    final c0 = cam.pos;
    bool gravel(Offset p) => w.wall.deflate(0.4).contains(p) && !w.inPond(p) && w.mossAt(p) < 0.3;
    // Ondas concéntricas alrededor del centro del patio, como el rastrillo.
    final center = w.decorAreas.length > 2 ? w.decorAreas[2].center : Offset.zero;
    final dc = (c0 - center).distance;
    final r0 = max(0.3, dc - reach), r1 = dc + reach;
    for (var ring = (r0 / 0.34).floor(); ring <= (r1 / 0.34).ceil(); ring++) {
      final rad = ring * 0.34;
      if (rad < 0.3) continue;
      var drawing = false;
      var band = 0;
      final n = max(24, (rad * 2 * pi / 0.4).ceil());
      for (var k = 0; k <= n; k++) {
        final t = k * 2 * pi / n;
        final p = center + Offset(sin(t), cos(t)) * (rad + 0.05 * sin(t * 7 + ring));
        final (a, dist) = cam.polar(p);
        if (dist < 0.6 || dist > reach || a.abs() > half || !gravel(p)) {
          drawing = false;
          continue;
        }
        final sp = Offset(cam.xAt(a), cam.yAt(dist));
        final b = dist < 3.5 ? 0 : (dist < 7 ? 1 : 2);
        if (!drawing || b != band) {
          lines[b].moveTo(sp.dx, sp.dy);
          drawing = true;
          band = b;
        } else {
          lines[b].lineTo(sp.dx, sp.dy);
        }
      }
    }
    final groove = Color.lerp(const Color(0xFFC2B698), _mist, 0.2)!;
    for (final (i, wpx) in [(0, 1.6), (1, 1.0), (2, 0.6)]) {
      _c.drawPath(
        lines[i],
        Paint()
          ..color = groove.withValues(alpha: 0.55 - i * 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = wpx,
      );
    }
    // Matitas y manchitas en el musgo.
    const cell = 0.55;
    final tuft = Paint()..color = Color.lerp(const Color(0xFF5D7442), _mist, 0.1)!;
    final light = Paint()..color = Color.lerp(const Color(0xFFA7B47A), _mist, 0.1)!.withValues(alpha: 0.6);
    for (var gx = ((c0.dx - 8) / cell).floor(); gx <= ((c0.dx + 8) / cell).ceil(); gx++) {
      for (var gy = ((c0.dy - 8) / cell).floor(); gy <= ((c0.dy + 8) / cell).ceil(); gy++) {
        final h = (gx * 73856093) ^ (gy * 19349663);
        final p = Offset((gx + (h & 255) / 255) * cell, (gy + ((h >> 8) & 255) / 255) * cell);
        if (w.mossAt(p) < 0.6 || w.inPond(p)) continue;
        final (a, dist) = cam.polar(p);
        if (dist < 1.4 || dist > 8 || a.abs() > half) continue;
        final s = Offset(cam.xAt(a), cam.yAt(dist));
        final k = cam.f / dist;
        if (h.isEven) {
          // Una matita de pasto: tres hojitas.
          for (final dx in [-0.05, 0.0, 0.05]) {
            _c.drawLine(s, s + Offset(dx * 1.2 * k, -0.08 * k), tuft..strokeWidth = max(0.6, 0.006 * k));
          }
        } else {
          _c.drawOval(Rect.fromCenter(center: s, width: 0.09 * k, height: 0.09 * k * cam.eye / dist), light);
        }
      }
    }
  }

  // ---- Cosas del patio ----

  void _build() {
    // Las piedras de paso entre miradores (en la Clásica se camina libre: no van).
    if (!v.hub) {
      for (final (p, r) in w.stones) {
        _stone(p, r);
      }
    }
    // Con el muro pintado, sus matas ya están al pie; sin él, arbustos de código.
    if (cropArt('bg_court_wall', _wallFrac) == null) {
      for (final (i, (p, size)) in w.hedges.indexed) {
        _hedge(p, size, i);
      }
    }
    for (final (i, (p, id, wd)) in w.islands.indexed) {
      if (SceneArt.instance['obj_decor_$id'] == null) continue;
      final (_, d) = cam.polar(p);
      if (id == 'moss') _patch(p, wd * 1.3, d);
      _prop(PanoObject('island$i', PanoKind.prop, p, wd, decor: id, flip: i.isOdd));
    }
    if (v.hub) {
      // Matas, musgo y piedras pintadas alrededor del centro.
      const kinds = ['azalea', 'moss', 'rocks', 'azalea', 'boulder', 'moss'];
      for (final (i, (p, size)) in w.hubPlants.indexed) {
        final id = kinds[i % kinds.length];
        if (SceneArt.instance['obj_decor_$id'] == null) {
          _hedge(p, size, i + 100);
        } else {
          _prop(PanoObject('hub$i', PanoKind.prop, p, size * (id == 'boulder' ? 0.9 : 1.2), decor: id, flip: i.isOdd));
        }
      }
    }
    for (final o in w.objects) {
      switch (o.kind) {
        case PanoKind.place:
          o.place == 'pond' ? _pond(o) : _place(o);
        case PanoKind.prop:
          o.decor == 'pavilion' ? _pavilion(o) : _prop(o);
        case PanoKind.gate:
          _gate(o);
      }
    }
    for (final t in v.decor) {
      _decor(t);
    }
    for (final m in v.markers) {
      _marker(m);
    }
    for (final e in v.exits) {
      _exit(e);
    }
    // Los carteles no se pisan: si dos chocan, queda el del más cercano.
    _labels.sort((a, b) => a.dist.compareTo(b.dist));
    final kept = <_Item>[];
    for (final l in _labels) {
      if (!kept.any((k) => k.rect.inflate(3).overlaps(l.rect))) kept.add(l);
    }
    _labels
      ..clear()
      ..addAll(kept);
  }

  bool _offscreen(Rect r) => r.right < -20 || r.left > size.width + 20 || r.bottom < 0;

  /// Un rectángulo parado en [p], de [width] metros de ancho y [aspect] de
  /// alto sobre ancho, apoyado a [lift] metros del suelo.
  (Rect, double)? _stand(Offset p, double width, double aspect, {double lift = 0}) {
    final (a, d) = cam.polar(p);
    if (d < 0.75 || a.abs() > cam.fov / cam.zoom * 0.5 + 1.2) return null;
    final wpx = width * cam.f / d;
    final base = cam.yAt(d, lift);
    final r = Rect.fromLTWH(cam.xAt(a) - wpx / 2, base - wpx * aspect, wpx, wpx * aspect);
    if (_offscreen(r)) return null;
    return (r, d);
  }

  /// Lo que está casi encima se desvanece (para no tapar todo).
  double _near(double d) => ((d - 0.75) / 0.9).clamp(0.0, 1.0);

  /// Un óvalo en el suelo de [rx] x [ry] metros (proyectado).
  Path? _groundOval(Offset c, double rx, double ry, {double h = 0, int n = 24}) {
    final path = Path();
    for (var i = 0; i < n; i++) {
      final t = i * 2 * pi / n;
      final s = cam.project(c + Offset(cos(t) * rx, sin(t) * ry), h);
      if (s == null) return null;
      i == 0 ? path.moveTo(s.dx, s.dy) : path.lineTo(s.dx, s.dy);
    }
    return path..close();
  }

  void _stone(Offset p, double r, {double near = 0.45}) {
    final (a, d) = cam.polar(p);
    if (d < near || a.abs() > cam.fov / cam.zoom * 0.5 + 0.3) return;
    final ctr = Offset(cam.xAt(a), cam.yAt(d));
    final wpx = 2 * r * cam.f / d;
    final hpx = min(wpx * 0.7, wpx * cam.eye / d);
    final rect = Rect.fromCenter(center: ctr, width: wpx, height: hpx);
    if (_offscreen(rect)) return;
    final art = SceneArt.instance['obj_decor_step'];
    if (art != null) {
      // La piedra de paso pintada, aplastada según cuánto se la ve de costado.
      final h = min(wpx * 0.75, wpx * cam.eye / d * 1.6);
      final r = Rect.fromCenter(center: ctr, width: wpx * 1.1, height: h);
      _flat.add(_Item(d, r, null, () => _art(art, r, d)));
      return;
    }
    _flat.add(
      _Item(d, rect, null, () {
        final shade = Color.lerp(const Color(0xFF8F8A80), _mist, _fog(d))!;
        final top = Color.lerp(const Color(0xFFC4BFB3), _mist, _fog(d))!;
        _c.drawOval(rect.shift(Offset(0, hpx * 0.12)), Paint()..color = shade);
        _c.drawOval(rect, Paint()..color = top);
        _c.drawOval(
          Rect.fromCenter(center: ctr - Offset(wpx * 0.12, hpx * 0.12), width: wpx * 0.45, height: hpx * 0.4),
          Paint()..color = Colors.white.withValues(alpha: 0.18),
        );
      }),
    );
  }

  /// Un parche de grava rastrillada o de musgo bajo un lugar: lo apoya en el patio.
  void _patch(Offset p, double width, double d, {bool moss = false}) {
    final path = _groundOval(p, width * 0.62, width * 0.42);
    if (path == null) return;
    final b = path.getBounds();
    _flat.add(
      _Item(d + 0.4, b, null, () {
        final base = moss ? const Color(0xFF7D9158) : const Color(0xFFF1EADA);
        _c.drawPath(path, Paint()..color = Color.lerp(base, _mist, _fog(d))!.withValues(alpha: 0.85));
        _c.drawPath(
          path,
          Paint()
            ..color = (moss ? const Color(0xFF5E7244) : const Color(0xFFB5AA92)).withValues(alpha: 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(1, b.width * 0.012),
        );
        if (!moss) {
          // Surcos del rastrillo alrededor.
          for (final k in [0.78, 0.56]) {
            final ring = _groundOval(p, width * 0.62 * k, width * 0.42 * k);
            if (ring == null) continue;
            _c.drawPath(
              ring,
              Paint()
                ..color = const Color(0xFFC9BEA6).withValues(alpha: 0.55)
                ..style = PaintingStyle.stroke
                ..strokeWidth = max(1, b.width * 0.008),
            );
          }
        }
      }),
    );
  }

  void _place(PanoObject o) {
    final id = o.place!;
    final look = v.places[id];
    if (id == 'model' && look == null) return;
    final (arts, fallback) = placeArt[id] ?? (const <String>[], 1.0);
    final img = _img(arts);
    // El bonsái se arma: mesa, maceta y el árbol encima.
    final bonsai = id == 'bonsai' && img != null && SceneArt.instance['obj_decor_pine'] != null;
    final aspect = bonsai ? 1.25 : (img == null ? fallback : img.height / img.width);
    final lift = _lifted[id] ?? 0;
    final width = min(o.width, (_maxHeight[id] ?? 99) / aspect);
    final s = _stand(o.at, width, aspect, lift: lift);
    if (s == null) return;
    final (r, d) = s;
    final locked = look != null && !look.open;
    if (lift == 0 && (id != 'sand' || img != null)) _patch(o.at, o.width, d, moss: w.mossAt(o.at) > 0.5);
    final target = id == 'model' ? const PanoTarget(PanoHit.model) : PanoTarget(PanoHit.place, id: id);
    final alpha = _near(d);
    if (id == 'sand' && img == null) _sandBed(o, d, locked);
    _items.add(
      _Item(d, r.inflate(r.width * 0.06), target, () {
        if (lift == 0) _shadow(r);
        if (v.glow == target) _glowRing(r);
        if (bonsai) {
          _bonsai(img, r, d, locked, alpha);
        } else if (img != null) {
          _art(img, r, d, flip: o.flip, locked: locked, alpha: alpha);
          final bowl = SceneArt.instance['obj_court_singing_bowl'];
          if (id == 'meditation' && bowl != null) {
            // El cuenco al lado del cojín.
            final bw = r.width * 0.42;
            final bh = bw * bowl.height / bowl.width;
            _art(bowl, Rect.fromLTWH(r.right - bw * 0.2, r.bottom - bh, bw, bh), d, locked: locked, alpha: alpha);
          }
        } else {
          _filtered(r, d, () => _sketch(id, r), locked: locked, alpha: alpha);
        }
      }),
    );
    if (look != null && d < _labelFar) {
      _labels.add(_Item(d, _labelRect(look, r.topCenter, d), target, () => _label(look, r.topCenter, d)));
    }
  }

  void _bonsai(ui.Image table, Rect r, double d, bool locked, double alpha) {
    final w = r.width;
    final th = w * table.height / table.width;
    final tableR = Rect.fromLTWH(r.left, r.bottom - th, w, th);
    final top = tableR.top + th * 0.14;
    final pot = SceneArt.instance['obj_bonsai_pot'];
    final pine = SceneArt.instance['obj_decor_pine']!;
    var base = top;
    final pw = w * 0.64;
    Rect? potR;
    if (pot != null) {
      final ph = pw * pot.height / pot.width;
      potR = Rect.fromLTWH(r.center.dx - pw / 2, top - ph, pw, ph);
      base = potR.top + ph * 0.25;
    }
    final tw = w * 0.74;
    final treeR = Rect.fromLTWH(
      r.center.dx - tw / 2,
      base - tw * pine.height / pine.width,
      tw,
      tw * pine.height / pine.width,
    );
    _art(table, tableR, d, locked: locked, alpha: alpha);
    _art(pine, treeR, d, locked: locked, alpha: alpha);
    if (potR != null) _art(pot!, potR, d, locked: locked, alpha: alpha);
  }

  void _shadow(Rect r) => _c.drawOval(
    Rect.fromCenter(center: r.bottomCenter, width: r.width * 1.05, height: r.width * 0.16),
    Paint()..color = Palette.ink.withValues(alpha: 0.16 * v.daylight + 0.04),
  );

  void _glowRing(Rect r) => _c.drawOval(
    Rect.fromCenter(center: r.bottomCenter, width: r.width * 1.3, height: r.width * 0.3),
    Paint()
      ..color = Palette.lantern.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
  );

  /// El arenero: un lecho de arena rastrillada con borde de madera, en el suelo.
  void _sandBed(PanoObject o, double d, bool locked) {
    final hw = o.width / 2, hd = o.width * 0.32;
    final corners = [
      for (final c in [Offset(-hw, -hd), Offset(hw, -hd), Offset(hw, hd), Offset(-hw, hd)]) cam.project(o.at + c, 0.12),
    ];
    if (corners.any((c) => c == null)) return;
    final path = Path()..addPolygon(corners.cast<Offset>(), true);
    final b = path.getBounds();
    _flat.add(
      _Item(d + 0.2, b, PanoTarget(PanoHit.place, id: o.place), () {
        _filtered(b, d, () {
          final frame = Path()
            ..addPolygon([
              for (final c in [
                Offset(-hw - 0.12, -hd - 0.12),
                Offset(hw + 0.12, -hd - 0.12),
                Offset(hw + 0.12, hd + 0.12),
                Offset(-hw - 0.12, hd + 0.12),
              ])
                cam.project(o.at + c, 0.12) ?? b.center,
            ], true);
          _c.drawPath(frame, Paint()..color = Palette.wood);
          _c.drawPath(path, Paint()..color = const Color(0xFFF1E8D2));
          final line = Paint()
            ..color = const Color(0xFFCDBF9F)
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(1, b.width * 0.006);
          for (var i = 1; i < 6; i++) {
            final t = -hd + 2 * hd * i / 6;
            final l = cam.project(o.at + Offset(-hw + 0.08, t), 0.12),
                rr = cam.project(o.at + Offset(hw - 0.08, t), 0.12);
            if (l != null && rr != null) {
              final mid = Offset((l.dx + rr.dx) / 2, (l.dy + rr.dy) / 2 + b.height * 0.015);
              _c.drawPath(
                Path()
                  ..moveTo(l.dx, l.dy)
                  ..quadraticBezierTo(mid.dx, mid.dy, rr.dx, rr.dy),
                line,
              );
            }
          }
          // Tres piedras en la arena.
          for (final (dx, dy, rad) in [(-0.45, 0.1, 0.16), (0.3, -0.12, 0.2), (0.6, 0.18, 0.11)]) {
            final rock = _groundOval(o.at + Offset(dx * hw, dy * hd * 2), rad, rad * 0.8, h: 0.14, n: 12);
            if (rock != null) _c.drawPath(rock, Paint()..color = Palette.stoneDark);
          }
        }, locked: locked);
      }),
    );
  }

  /// El estanque: agua con su borde de piedras, nenúfares y koi.
  void _pond(PanoObject o) {
    final path = _groundOval(w.pondAt, w.pondRadii.width, w.pondRadii.height, n: 36);
    if (path == null) return;
    final rim = _groundOval(w.pondAt, w.pondRadii.width + 0.28, w.pondRadii.height + 0.28, n: 36);
    final b = path.getBounds();
    final (_, d) = cam.polar(w.pondAt);
    final look = v.places['pond'];
    const target = PanoTarget(PanoHit.place, id: 'pond');
    _flat.add(
      _Item(d + 3, b, target, () {
        _filtered(b, d, () {
          if (rim != null) _c.drawPath(rim, Paint()..color = const Color(0xFF8D877C));
          _c.drawPath(path, Paint()..color = const Color(0xFF5F8C97));
          final water = SceneArt.instance['bg_pond_water'];
          if (water != null) {
            _c.save();
            _c.clipPath(path);
            drawArtCover(_c, water, b, paint: Paint()..color = Colors.white.withValues(alpha: 0.85));
            _c.restore();
          }
          for (final (dx, dy, r, c) in [
            (-0.4, 0.2, 0.32, const Color(0xFF6E9150)),
            (0.35, -0.3, 0.26, const Color(0xFF7C9C58)),
            (0.1, 0.45, 0.12, const Color(0xFFE59A5A)),
            (-0.15, -0.4, 0.1, const Color(0xFFF2EEE6)),
          ]) {
            final pad = _groundOval(
              w.pondAt + Offset(dx * w.pondRadii.width, dy * w.pondRadii.height),
              r,
              r * (c.g > 0.5 && c.r < 0.6 ? 0.85 : 0.45),
              n: 12,
            );
            if (pad != null) _c.drawPath(pad, Paint()..color = c);
          }
        }, locked: look != null && !look.open);
        if (v.glow == target) {
          _c.drawPath(
            path,
            Paint()
              ..color = Palette.lantern
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        }
      }),
    );
    if (look != null && d < _labelFar) {
      final top = Offset(b.center.dx, b.top);
      _labels.add(_Item(d, _labelRect(look, top, d), target, () => _label(look, top, d)));
    }
  }

  void _prop(PanoObject o) {
    final id = o.decor!;
    final art = id.startsWith('obj_') ? SceneArt.instance[id] : SceneArt.instance['obj_decor_$id'];
    final aspect = art != null ? art.height / art.width : (_decorAspect[id] ?? 1.0);
    final s = _stand(o.at, o.width, aspect);
    if (s == null) return;
    final (r, d) = s;
    final alpha = _near(d);
    _items.add(
      _Item(d, r, null, () {
        _shadow(r);
        if (art != null) return _art(art, r, d, flip: o.flip, alpha: alpha);
        _filtered(r, d, () {
          if (id.startsWith('obj_')) return _bush(r);
          paintDecor(_c, id, r, flip: o.flip);
        }, alpha: alpha);
      }),
    );
  }

  static const _decorAspect = {
    'pine': 1.0,
    'maple': 0.95,
    'sakura': 0.99,
    'azalea': 0.76,
    'bamboo': 1.33,
    'lantern': 1.9,
    'boulder': 0.76,
    'rocks': 0.9,
    'peak': 1.36,
    'moss': 0.9,
    'jizo': 1.95,
    'pagoda': 2.31,
  };

  /// Un arbusto podado en mata (karikomi), dibujado con código.
  void _hedge(Offset p, double size, int seed) {
    final art = SceneArt.instance['obj_path_bush'];
    final s = _stand(p, size, art == null ? 0.62 : art.height / art.width);
    if (s == null) return;
    final (r, d) = s;
    final alpha = _near(d);
    _items.add(
      _Item(d, r, null, () {
        _shadow(r);
        if (art != null) return _art(art, r, d, flip: seed.isOdd, alpha: alpha);
        _filtered(r, d, () => _bush(r, seed: seed), alpha: alpha);
      }),
    );
  }

  void _bush(Rect r, {int seed = 0}) {
    final greens = [const Color(0xFF52683F), const Color(0xFF657D4A), const Color(0xFF7A9157), const Color(0xFF8FA566)];
    final rng = Random(seed);
    // Matas redondeadas que se pisan, de atrás (oscuras) a adelante (claras).
    for (var k = 0; k < 4; k++) {
      final cx = r.left + r.width * (0.2 + rng.nextDouble() * 0.6);
      final wpx = r.width * (0.55 + rng.nextDouble() * 0.3);
      final hpx = r.height * (0.6 + rng.nextDouble() * 0.25);
      final top = r.bottom - hpx - (3 - k) * r.height * 0.06;
      _c.drawOval(Rect.fromLTWH(cx - wpx / 2, top, wpx, r.bottom - top), Paint()..color = greens[k]);
    }
    if (seed % 3 == 0) {
      // Algunas con flores.
      for (var k = 0; k < 7; k++) {
        _c.drawCircle(
          Offset(r.left + r.width * (0.2 + rng.nextDouble() * 0.6), r.top + r.height * (0.25 + rng.nextDouble() * 0.5)),
          max(1, r.width * 0.025),
          Paint()..color = const Color(0xFFE9A0B0),
        );
      }
    }
  }

  void _decor(PanoThing t) {
    final art = SceneArt.instance['obj_decor_${t.decor}'];
    final aspect = art != null ? art.height / art.width : t.aspect;
    final s = _stand(t.pos, t.width, aspect);
    if (s == null) return;
    final (r, d) = s;
    final target = PanoTarget(PanoHit.decor, index: t.index);
    final alpha = _near(d);
    _items.add(
      _Item(d, r, target, () {
        _shadow(r);
        if (v.glow == target) _glowRing(r);
        if (art != null) return _art(art, r, d, flip: t.flip, alpha: alpha);
        _filtered(r, d, () => paintDecor(_c, t.decor, r, flip: t.flip), alpha: alpha);
      }),
    );
  }

  void _marker(PanoMarker m) {
    final img = m.art == null ? null : SceneArt.instance[m.art!];
    if (m.flat) {
      final path = _groundOval(m.pos, m.width / 2, m.width / 2, n: 18);
      if (path == null) return;
      final b = path.getBounds();
      final (_, d) = cam.polar(m.pos);
      // En la Clásica los huecos para decorar son discretos y no se pisan.
      final soft = v.hub && m.target.kind == PanoHit.slot;
      if (soft && d < 2.6) return;
      final k = soft ? 0.5 * ((d - 2.6) / 1.5).clamp(0.0, 1.0) : 1.0;
      _flat.add(
        _Item(d - 0.1, b.inflate(8), m.target, () {
          if (img != null) return _art(img, b, d, alpha: soft ? k * 1.6 : 1);
          _c.drawPath(path, Paint()..color = m.color.withValues(alpha: 0.16 * k));
          _c.drawPath(
            path,
            Paint()
              ..color = m.color.withValues(alpha: 0.8 * k)
              ..style = PaintingStyle.stroke
              ..strokeWidth = max(1.2, b.height * (soft ? 0.035 : 0.06)),
          );
          if (m.icon != null) {
            _glyph(m.icon!, b.center, min(b.height, b.width) * (soft ? 0.4 : 0.6), m.color.withValues(alpha: k));
          }
        }),
      );
      return;
    }
    final aspect = img != null ? img.height / img.width : m.aspect;
    final s = _stand(m.pos, m.width, aspect);
    if (s == null) return;
    final (r, d) = s;
    // Lo chiquito lejos igual se tiene que poder tocar.
    final hit = r.inflate(max(0, 22 - r.width / 2));
    _items.add(
      _Item(d - 0.05, hit, m.target, () {
        if (img != null) return _art(img, r, d);
        final dd = max(18.0, min(r.width, r.height));
        final ctr = Offset(r.center.dx, r.bottom - dd / 2);
        _c.drawCircle(ctr, dd * 0.55, Paint()..color = m.color.withValues(alpha: 0.25));
        _c.drawCircle(ctr, dd * 0.42, Paint()..color = Palette.paper.withValues(alpha: 0.92));
        if (m.icon != null) _glyph(m.icon!, ctr, dd * 0.5, m.color);
      }),
    );
  }

  /// Una salida: una piedra grande con luz y una flecha hacia el otro mirador.
  void _exit(PanoExit e) {
    final path = _groundOval(e.pos, 0.42, 0.42, n: 20);
    if (path == null) return;
    final b = path.getBounds();
    final (_, d) = cam.polar(e.pos);
    final target = PanoTarget(PanoHit.exit, id: e.to);
    final hit = b.inflate(max(10, 40 - b.width / 3));
    _flat.add(
      _Item(d - 0.2, hit, target, () {
        final glow = _groundOval(e.pos, 0.7, 0.7, n: 20);
        if (glow != null) {
          _c.drawPath(glow, Paint()..color = Palette.lantern.withValues(alpha: 0.18 + 0.12 * (1 - v.daylight)));
        }
        final art = SceneArt.instance['spr_path_glow_stone'];
        if (art != null) {
          drawArt(_c, art, b);
        } else {
          _c.drawPath(path.shift(Offset(0, b.height * 0.1)), Paint()..color = const Color(0xFF8F8A80));
          _c.drawPath(path, Paint()..color = const Color(0xFFD3CDBF));
        }
        // La flecha pintada en la piedra, hacia el otro mirador.
        final dir = e.bearing * pi / 180;
        final tip = cam.project(e.pos + Offset(sin(dir), cos(dir)) * 0.3);
        final tail = cam.project(e.pos - Offset(sin(dir), cos(dir)) * 0.2);
        if (tip != null && tail != null) {
          final side = Offset(cos(dir), -sin(dir)) * 0.16;
          final l = cam.project(e.pos + side), rr = cam.project(e.pos - side);
          if (l != null && rr != null) {
            _c.drawPath(
              Path()..addPolygon([tip, l, tail, rr], true),
              Paint()..color = Palette.lantern.withValues(alpha: 0.9),
            );
          }
        }
      }),
    );
    if (d < 9) {
      final top = Offset(b.center.dx, b.top - 6);
      final rect = _pillRect(e.label, top, 13);
      _labels.add(_Item(d, rect, target, () => _pill(e.label, top, 13, icon: Icons.directions_walk_rounded)));
    }
  }

  void _gate(PanoObject o) {
    final open = o.id == 'entrance';
    // Sin arte propio, el portón del muro pintado (cerrado, con su tejadito).
    final own = SceneArt.instance[open ? 'obj_path_gate' : 'obj_gate_future'];
    final art = own ?? cropArt('bg_court_wall', _gateFrac);
    final s = _stand(o.at, o.width, art == null ? 1.0 : art.height / art.width);
    if (s == null) return;
    final (r, d) = s;
    _items.add(
      _Item(d, r, open ? null : PanoTarget(PanoHit.gate, id: o.id), () {
        if (art == null) return _filtered(r, d, () => _gateSketch(r, open));
        _art(art, r, d);
        if (!open && own == null) {
          // El sello con candado de las zonas que vienen.
          final seal = Offset(r.center.dx - r.width * 0.02, r.top + r.height * 0.62);
          _c.drawCircle(seal, r.width * 0.06, Paint()..color = Palette.clay);
          _glyph(Icons.lock_rounded, seal, r.width * 0.07, Palette.paper);
        }
      }),
    );
  }

  void _gateSketch(Rect r, bool open) {
    final wood = Paint()..color = const Color(0xFF7A5536);
    final dark = Paint()..color = const Color(0xFF3B3430);
    final post = r.width * 0.07;
    final top = r.top + r.height * 0.18;
    // Hueco (afuera se ve el camino) o puertas cerradas.
    final door = Rect.fromLTRB(r.left + post, top + r.height * 0.1, r.right - post, r.bottom);
    if (open) {
      // Por la puerta abierta se ve afuera: cielo, árboles y el camino que llega.
      _c.drawRect(door, Paint()..color = Color.lerp(const Color(0xFFDCE6E2), _mist, 0.3)!);
      final trees = Path()..moveTo(door.left, door.top + door.height * 0.55);
      for (var i = 0; i <= 8; i++) {
        final x = door.left + door.width * i / 8;
        trees.lineTo(x, door.top + door.height * (0.3 + 0.12 * sin(i * 1.7)));
      }
      trees
        ..lineTo(door.right, door.bottom)
        ..lineTo(door.left, door.bottom)
        ..close();
      _c.drawPath(trees, Paint()..color = const Color(0xFF8DA07A));
      _c.drawPath(
        Path()
          ..moveTo(door.center.dx - door.width * 0.08, door.top + door.height * 0.62)
          ..lineTo(door.center.dx + door.width * 0.08, door.top + door.height * 0.62)
          ..lineTo(door.right - door.width * 0.1, door.bottom)
          ..lineTo(door.left + door.width * 0.1, door.bottom)
          ..close(),
        Paint()..color = const Color(0xFFD9CFB6),
      );
    } else {
      _c.drawRect(door, Paint()..color = const Color(0xFF8C6844));
      final seam = Paint()
        ..color = const Color(0xFF5A4028)
        ..strokeWidth = max(1, r.width * 0.01);
      _c.drawLine(door.topCenter, door.bottomCenter, seam);
      for (var i = 1; i < 4; i++) {
        final y = door.top + door.height * i / 4;
        _c.drawLine(Offset(door.left, y), Offset(door.right, y), seam);
      }
      // Cuerda de paja y un sello con candado.
      final ropeY = door.top + door.height * 0.22;
      _c.drawPath(
        Path()
          ..moveTo(door.left, ropeY)
          ..quadraticBezierTo(door.center.dx, ropeY + door.height * 0.12, door.right, ropeY),
        Paint()
          ..color = const Color(0xFFC9A964)
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(2, r.width * 0.035),
      );
      final seal = Offset(door.center.dx, ropeY + door.height * 0.12);
      _c.drawCircle(seal, r.width * 0.07, Paint()..color = Palette.clay);
      _glyph(Icons.lock_rounded, seal, r.width * 0.08, Palette.paper);
    }
    _c.drawRect(Rect.fromLTRB(r.left, top, r.left + post, r.bottom), wood);
    _c.drawRect(Rect.fromLTRB(r.right - post, top, r.right, r.bottom), wood);
    final roof = Path()
      ..moveTo(r.left - r.width * 0.12, top + r.height * 0.06)
      ..quadraticBezierTo(r.center.dx, top - r.height * 0.02, r.right + r.width * 0.12, top + r.height * 0.06)
      ..lineTo(r.right - r.width * 0.05, r.top)
      ..lineTo(r.left + r.width * 0.05, r.top)
      ..close();
    _c.drawPath(roof, dark);
    _c.drawRect(Rect.fromLTRB(r.left, top + r.height * 0.06, r.right, top + r.height * 0.11), wood);
  }

  /// El pabellón: pared del fondo con puertas abiertas, galería (engawa) y
  /// adelante los postes y el tejado. Lo de la galería (meditación, maqueta)
  /// queda entre las capas.
  void _pavilion(PanoObject o) {
    final c = o.at;
    final hw = o.width / 2;
    const depth = 1.8, floor = 0.45, wallTop = 2.5;
    final back = c + const Offset(0, depth / 2), front = c - const Offset(0, depth / 2);
    // La galería: el piso de madera elevado.
    final corners = [
      for (final p in [front + Offset(-hw, 0), front + Offset(hw, 0), back + Offset(hw, 0), back + Offset(-hw, 0)])
        cam.project(p, floor),
    ];
    final lows = [cam.project(front + Offset(-hw, 0)), cam.project(front + Offset(hw, 0))];
    final (_, dBack) = cam.polar(back);
    final (_, dFront) = cam.polar(front);
    final backArt = SceneArt.instance['obj_pavilion_back'];
    final sb = _stand(back, o.width, (wallTop - floor + 1.4) / o.width, lift: floor);
    if (sb != null) {
      final (r, d) = sb;
      _items.add(
        _Item(d, r, null, () {
          if (backArt != null) return _art(backArt, r, d);
          _filtered(r, d, () {
            final wallRect = Rect.fromLTRB(
              r.left,
              r.bottom - r.height * (wallTop - floor) / (wallTop - floor + 1.4),
              r.right,
              r.bottom,
            );
            _c.drawRect(wallRect, Paint()..color = const Color(0xFF6B4A33));
            // Shoji abiertos: el interior en penumbra y los paneles corridos.
            final opening = Rect.fromLTRB(
              wallRect.left + wallRect.width * 0.18,
              wallRect.top + wallRect.height * 0.08,
              wallRect.right - wallRect.width * 0.18,
              wallRect.bottom,
            );
            _c.drawRect(opening, Paint()..color = const Color(0xFF3E3027));
            final shoji = Paint()..color = const Color(0xFFF2EBDA);
            final lattice = Paint()
              ..color = const Color(0xFF8A6A4C)
              ..strokeWidth = max(1, r.width * 0.004);
            for (final side in [
              Rect.fromLTRB(
                wallRect.left + wallRect.width * 0.03,
                opening.top,
                opening.left - wallRect.width * 0.01,
                wallRect.bottom,
              ),
              Rect.fromLTRB(
                opening.right + wallRect.width * 0.01,
                opening.top,
                wallRect.right - wallRect.width * 0.03,
                wallRect.bottom,
              ),
            ]) {
              _c.drawRect(side, shoji);
              for (var i = 1; i < 3; i++) {
                final x = side.left + side.width * i / 3;
                _c.drawLine(Offset(x, side.top), Offset(x, side.bottom), lattice);
              }
              for (var i = 1; i < 5; i++) {
                final y = side.top + side.height * i / 5;
                _c.drawLine(Offset(side.left, y), Offset(side.right, y), lattice);
              }
            }
            // Un rollo colgado al fondo (tokonoma).
            final scroll = Rect.fromCenter(
              center: Offset(opening.center.dx, opening.top + opening.height * 0.35),
              width: opening.width * 0.12,
              height: opening.height * 0.45,
            );
            _c.drawRect(scroll, Paint()..color = const Color(0xFFE9DFC6));
            _c.drawLine(
              scroll.topCenter + Offset(0, scroll.height * 0.3),
              scroll.bottomCenter - Offset(0, scroll.height * 0.2),
              Paint()
                ..color = Palette.ink.withValues(alpha: 0.6)
                ..strokeWidth = max(1, scroll.width * 0.12),
            );
          });
        }),
      );
    }
    if (!corners.contains(null) && !lows.contains(null)) {
      final top = corners.cast<Offset>();
      final b = Path()..addPolygon(top, true);
      final bounds = b.getBounds();
      _items.add(
        _Item(dBack - 0.05, bounds, null, () {
          _filtered(bounds, dFront, () {
            _c.drawPath(b, Paint()..color = const Color(0xFFB98B5E));
            final plank = Paint()
              ..color = const Color(0xFF946B45)
              ..strokeWidth = max(1, bounds.width * 0.003);
            for (var i = 1; i < 8; i++) {
              final t = i / 8;
              final l = Offset.lerp(top[0], top[3], t)!, rr = Offset.lerp(top[1], top[2], t)!;
              _c.drawLine(l, rr, plank);
            }
            // El frente de la galería, de la madera al suelo.
            _c.drawPath(
              Path()..addPolygon([top[0], top[1], lows[1]!, lows[0]!], true),
              Paint()..color = const Color(0xFF6E4D33),
            );
          });
        }),
      );
    }
    final frontArt = SceneArt.instance['obj_pavilion_front'];
    final sf = _stand(front, o.width * 1.16, 4.0 / (o.width * 1.16));
    if (sf != null) {
      final (r, d) = sf;
      _items.add(
        _Item(d - 0.6, r, null, () {
          if (frontArt != null) return _art(frontArt, r, d);
          _filtered(r, d, () {
            final hgt = r.height;
            final px = r.width * 0.035;
            final wood = Paint()..color = const Color(0xFF5E4130);
            final roofTop = r.top, roofLow = r.top + hgt * 0.36;
            for (final fx in [0.1, 0.9]) {
              final x = r.left + r.width * fx;
              _c.drawRect(Rect.fromLTRB(x - px / 2, roofLow, x + px / 2, r.bottom), wood);
            }
            // Viga y tejado a cuatro aguas con las puntas levantadas.
            _c.drawRect(
              Rect.fromLTRB(r.left + r.width * 0.07, roofLow, r.right - r.width * 0.07, roofLow + hgt * 0.04),
              wood,
            );
            final roof = Path()
              ..moveTo(r.left, roofLow - hgt * 0.02)
              ..quadraticBezierTo(r.center.dx, roofLow + hgt * 0.04, r.right, roofLow - hgt * 0.02)
              ..lineTo(r.right - r.width * 0.2, roofTop + hgt * 0.06)
              ..lineTo(r.left + r.width * 0.2, roofTop + hgt * 0.06)
              ..close();
            _c.drawPath(roof, Paint()..color = const Color(0xFF4C535E));
            final ridge = Rect.fromLTRB(
              r.left + r.width * 0.18,
              roofTop,
              r.right - r.width * 0.18,
              roofTop + hgt * 0.07,
            );
            _c.drawRRect(
              RRect.fromRectAndRadius(ridge, Radius.circular(hgt * 0.02)),
              Paint()..color = const Color(0xFF3A4049),
            );
            final tile = Paint()
              ..color = const Color(0xFF656D79)
              ..strokeWidth = max(1, r.width * 0.003);
            for (var i = 1; i < 12; i++) {
              final t = i / 12;
              _c.drawLine(
                Offset(r.left + r.width * (0.2 + 0.6 * t), roofTop + hgt * 0.07),
                Offset(r.left + r.width * t, roofLow - hgt * 0.01),
                tile,
              );
            }
          });
        }),
      );
    }
  }

  /// Un lugar sin arte propio: un esbozo que se entiende.
  void _sketch(String id, Rect r) {
    final rr = r;
    switch (id) {
      case 'meditation':
        // Un zafu redondo y un cuenco.
        _c.drawOval(
          Rect.fromLTRB(rr.left, rr.top + rr.height * 0.35, rr.right - rr.width * 0.25, rr.bottom),
          Paint()..color = const Color(0xFF3F4A6B),
        );
        _c.drawOval(
          Rect.fromLTRB(rr.right - rr.width * 0.28, rr.bottom - rr.height * 0.35, rr.right, rr.bottom),
          Paint()..color = const Color(0xFFB08D57),
        );
      case 'model':
        final top = Rect.fromLTRB(rr.left, rr.top + rr.height * 0.25, rr.right, rr.top + rr.height * 0.5);
        _c.drawRect(top, Paint()..color = Palette.wood);
        _c.drawRect(top.deflate(top.height * 0.18), Paint()..color = const Color(0xFFEDE3CB));
        for (final (fx, col) in [(0.3, Palette.stoneDark), (0.55, Palette.moss), (0.72, Palette.stone)]) {
          _c.drawCircle(Offset(rr.left + rr.width * fx, top.center.dy), top.height * 0.22, Paint()..color = col);
        }
        final leg = Paint()..color = Color.lerp(Palette.wood, Palette.ink, 0.35)!;
        for (final fx in [0.1, 0.86]) {
          _c.drawRect(Rect.fromLTWH(rr.left + rr.width * fx, top.bottom, rr.width * 0.05, rr.bottom - top.bottom), leg);
        }
      case 'sand':
        // El rastrillo apoyado al costado del lecho.
        final rake = SceneArt.instance['obj_court_rake'];
        if (rake != null) {
          drawArtIn(_c, rake, Rect.fromLTRB(rr.right - rr.width * 0.22, rr.top - rr.height * 0.6, rr.right, rr.bottom));
        }
      default:
        _c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(rr.left, rr.top + rr.height * 0.3, rr.right, rr.bottom),
            Radius.circular(rr.width * 0.08),
          ),
          Paint()..color = Palette.wood,
        );
    }
  }

  void _veil() {
    final night = (1 - v.daylight).clamp(0.0, 1.0);
    if (night < 0.05) return;
    _c.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF141B30).withValues(alpha: night * 0.25));
  }

  // ---- Carteles ----

  /// Hasta dónde se ve el cartel de un lugar (m) y desde dónde se empieza a
  /// desvanecer.
  static const _labelFar = 19.0, _labelFade = 14.0;

  double _labelAlpha(double d) => (1 - (d - _labelFade) / (_labelFar - _labelFade)).clamp(0.0, 1.0);

  /// El cartel de madera de un lugar: más chico cuanto más lejos.
  (Rect, TextPainter, TextPainter?) _labelLayout(PlaceLook look, Offset top, double d) {
    final k = (1 - (d - 5) / 12).clamp(0.0, 1.0);
    final size = 12.5 + 2.5 * k;
    final name = TextPainter(
      text: TextSpan(
        text: look.name,
        style: TextStyle(color: Palette.ink, fontSize: size, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 200);
    final note = look.note == null
        ? null
        : (TextPainter(
            text: TextSpan(
              text: look.note,
              style: TextStyle(color: Palette.ink.withValues(alpha: 0.75), fontSize: size - 2.5),
            ),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: 200));
    final lock = look.open ? 0.0 : size + 3;
    final wpx = max(name.width + lock, note?.width ?? 0) + 20;
    final hpx = name.height + (note?.height ?? 0) + 9;
    return (Rect.fromLTWH(top.dx - wpx / 2, top.dy - hpx - 10, wpx, hpx), name, note);
  }

  Rect _labelRect(PlaceLook look, Offset top, double d) => _labelLayout(look, top, d).$1;

  void _label(PlaceLook look, Offset top, double d) {
    final alpha = _labelAlpha(d);
    if (alpha <= 0) return;
    final (box, name, note) = _labelLayout(look, top, d);
    final rr = RRect.fromRectAndRadius(box, const Radius.circular(9));
    if (alpha < 0.99) _c.saveLayer(box.inflate(12), Paint()..color = Colors.white.withValues(alpha: alpha));
    // Un palito que lo baja hasta el lugar, sombra, papel y borde de madera.
    _c.drawLine(
      box.bottomCenter,
      top,
      Paint()
        ..color = Palette.wood.withValues(alpha: 0.8)
        ..strokeWidth = 2,
    );
    _c.drawRRect(rr.shift(const Offset(0, 2)), Paint()..color = Palette.ink.withValues(alpha: 0.22));
    _c.drawRRect(rr, Paint()..color = look.open ? Palette.paper : Color.lerp(Palette.paper, Palette.stoneDark, 0.18)!);
    _c.drawRRect(
      rr,
      Paint()
        ..color = Palette.wood
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    if (look.dot) {
      _c.drawCircle(box.topRight + const Offset(-3, 3), 5.5, Paint()..color = Palette.lantern);
    }
    final lock = look.open ? 0.0 : name.height * 0.8 + 3;
    final x = box.center.dx - (name.width + lock) / 2;
    if (!look.open) {
      _glyph(
        Icons.lock_rounded,
        Offset(x + lock / 2 - 1, box.top + 4.5 + name.height / 2),
        name.height * 0.8,
        Palette.ink.withValues(alpha: 0.75),
      );
    }
    name.paint(_c, Offset(x + lock, box.top + 4.5));
    note?.paint(_c, Offset(box.center.dx - note.width / 2, box.top + 4.5 + name.height));
    if (alpha < 0.99) _c.restore();
  }

  Rect _pillRect(String text, Offset top, double size) {
    final wpx = text.length * size * 0.6 + 40;
    return Rect.fromLTWH(top.dx - wpx / 2, top.dy - size * 2.2, wpx, size * 2.2);
  }

  void _pill(String text, Offset top, double size, {IconData? icon}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: Palette.paper, fontSize: size, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 200);
    final iw = icon == null ? 0.0 : size + 4;
    final box = Rect.fromCenter(
      center: Offset(top.dx, top.dy - size * 1.1),
      width: tp.width + iw + 20,
      height: tp.height + 10,
    );
    _c.drawRRect(
      RRect.fromRectAndRadius(box, Radius.circular(box.height / 2)),
      Paint()..color = Palette.ink.withValues(alpha: 0.6),
    );
    if (icon != null) _glyph(icon, Offset(box.left + 10 + size / 2, box.center.dy), size, Palette.lantern);
    tp.paint(_c, Offset(box.left + 10 + iw, box.center.dy - tp.height / 2));
  }

  void _glyph(IconData icon, Offset center, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: size, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(_c, center - Offset(tp.width / 2, tp.height / 2));
  }
}

/// Dibuja el patio desde un mirador.
class PanoPainter extends CustomPainter {
  final PanoView view;
  PanoPainter(this.view);

  @override
  void paint(Canvas canvas, Size size) => PanoScene(size, view, canvas).paint();

  @override
  bool shouldRepaint(PanoPainter old) => old.view != view;
}
