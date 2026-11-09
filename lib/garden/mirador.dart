import 'dart:math';
import 'dart:ui';

import '../balance/balance.dart';

/// Un mirador: un punto del patio desde donde se gira 360° a mirar.
class Lookout {
  final String id;
  final Offset at;

  /// Hacia dónde se mira al llegar sin venir caminando (grados; 0 es el fondo
  /// del patio, crece hacia la derecha).
  final double yaw;

  /// Sector del patio (0 entrada y arena, 1 rincón del agua, 2 pabellón y
  /// bambú): el de su decoración y sus cuidados.
  final int sector;

  /// El mirador central de la vista Clásica (no tiene salidas).
  final bool hub;

  const Lookout(this.id, this.at, this.yaw, this.sector, {this.hub = false});
}

/// Qué es cada cosa del patio.
enum PanoKind {
  /// Un lugar de juego (o la meditación, el tablero, la maqueta).
  place,

  /// Paisaje: un árbol, una roca, un farol (no se toca).
  prop,

  /// Un portón (el de la entrada o el de las zonas que vienen).
  gate,
}

/// Algo parado en el plano del patio.
class PanoObject {
  final String id;
  final PanoKind kind;
  final Offset at;

  /// Ancho en metros.
  final double width;

  /// El lugar o la decoración (`obj_decor_<id>`) que se dibuja.
  final String? place, decor;
  final bool flip;

  const PanoObject(this.id, this.kind, this.at, this.width, {this.place, this.decor, this.flip = false});
}

/// El patio ampliado: un solo plano visto desde arriba, en metros (x hacia la
/// derecha, y hacia el fondo), con sus miradores, lugares, paisaje y huecos
/// para decorar. Cada mirador lo mira desde su punto, así cada cosa está en el
/// mismo lugar desde todos lados.
class MiradorWorld {
  final List<Lookout> lookouts;

  /// Pares de miradores unidos por un sendero de piedras (ida y vuelta).
  final List<(String, String)> links;
  final List<PanoObject> objects;

  /// El muro que rodea el patio (izquierda, frente, derecha, fondo) y su alto.
  final Rect wall;
  final double wallHeight;

  /// El estanque: centro y radios.
  final Offset pondAt;
  final Size pondRadii;

  /// Manchas de musgo: centro y radio.
  final List<(Offset, double)> moss;

  /// Por sector, el rectángulo de sus huecos para decorar.
  final List<Rect> decorAreas;
  final int cols, rows;

  /// Cuánto mide una decoración en metros por cada unidad de su tamaño.
  final double decorScale;

  /// La cámara: campo de visión (grados, normal y en la Clásica), altura de
  /// los ojos (m), dónde queda el horizonte (fracción del alto), zoom máximo
  /// y a qué velocidad se camina (m/s).
  final double fov, hubFov, eye, hubEye, horizon, hubHorizon, zoomMax, walk;

  MiradorWorld._({
    required this.lookouts,
    required this.links,
    required this.objects,
    required this.wall,
    required this.wallHeight,
    required this.pondAt,
    required this.pondRadii,
    required this.moss,
    required this.decorAreas,
    required this.cols,
    required this.rows,
    required this.decorScale,
    required this.fov,
    required this.hubFov,
    required this.eye,
    required this.hubEye,
    required this.horizon,
    required this.hubHorizon,
    required this.zoomMax,
    required this.walk,
  });

  factory MiradorWorld.from(Balance b, {required int cols, required int rows}) {
    final s = b.section('miradores');
    Object? m(String k) => s.raw(k);
    Offset pt(dynamic v) => Offset((v[0] as num).toDouble(), (v[1] as num).toDouble());
    final cam = s.sub('camera');
    double c(String k) => cam.d(k);
    final objects = <PanoObject>[
      for (final MapEntry(key: id, value: v) in (m('places') as Map<String, dynamic>).entries)
        PanoObject(id, PanoKind.place, pt(v), (v[2] as num).toDouble(), place: id, flip: v.length > 3 && v[3] == true),
      for (final MapEntry(key: id, value: v) in (m('gates') as Map<String, dynamic>).entries)
        PanoObject(id, PanoKind.gate, pt(v), (v[2] as num).toDouble()),
      for (final (i, v) in (m('props') as List).indexed)
        PanoObject(
          'prop$i',
          PanoKind.prop,
          Offset((v[1] as num).toDouble(), (v[2] as num).toDouble()),
          (v[3] as num).toDouble(),
          decor: v[0] as String,
          flip: v.length > 4 && v[4] == true,
        ),
    ];
    final wall = m('wall') as List;
    final pond = m('pond') as List;
    return MiradorWorld._(
      lookouts: [
        for (final v in m('lookouts') as List)
          Lookout(
            v['id'] as String,
            pt(v['at']),
            (v['yaw'] as num).toDouble(),
            v['sector'] as int,
            hub: v['hub'] == true,
          ),
      ],
      links: [for (final l in m('links') as List) (l[0] as String, l[1] as String)],
      objects: objects,
      wall: Rect.fromLTRB(
        (wall[0] as num).toDouble(),
        (wall[1] as num).toDouble(),
        (wall[2] as num).toDouble(),
        (wall[3] as num).toDouble(),
      ),
      wallHeight: s.d('wallHeight'),
      pondAt: pt(pond),
      pondRadii: Size((pond[2] as num).toDouble(), (pond[3] as num).toDouble()),
      moss: [for (final v in m('moss') as List) (pt(v), (v[2] as num).toDouble())],
      decorAreas: [
        for (final v in m('decor') as List)
          Rect.fromLTRB(
            (v[0] as num).toDouble(),
            (v[1] as num).toDouble(),
            (v[2] as num).toDouble(),
            (v[3] as num).toDouble(),
          ),
      ],
      cols: cols,
      rows: rows,
      decorScale: s.d('decorScale'),
      fov: c('fov'),
      hubFov: c('hubFov'),
      eye: c('eye'),
      hubEye: c('hubEye'),
      horizon: c('horizon'),
      hubHorizon: c('hubHorizon'),
      zoomMax: c('zoomMax'),
      walk: c('walk'),
    );
  }

  Lookout lookout(String id) => lookouts.firstWhere((l) => l.id == id);

  /// El mirador central (el de la vista Clásica).
  Lookout get hub => lookouts.firstWhere((l) => l.hub);

  /// El de la entrada: donde se aparece al abrir el jardín.
  Lookout get entrance => lookouts.firstWhere((l) => !l.hub);

  /// Los miradores que se recorren (sin el central).
  Iterable<Lookout> get walkable => lookouts.where((l) => !l.hub);

  /// A qué miradores se puede ir desde [id].
  List<String> exits(String id) => [
    for (final (a, b) in links)
      if (a == id) b else if (b == id) a,
  ];

  PanoObject? place(String place) => objects.where((o) => o.place == place).firstOrNull;

  /// El mirador desde donde mejor se ve [place]: el más cercano.
  Lookout lookoutOf(String place) {
    final o = this.place(place);
    if (o == null) return entrance;
    return walkable.reduce((a, b) => (a.at - o.at).distance <= (b.at - o.at).distance ? a : b);
  }

  /// El mirador más cercano a un punto.
  Lookout nearest(Offset p) => walkable.reduce((a, b) => (a.at - p).distance <= (b.at - p).distance ? a : b);

  /// El camino más corto (en miradores) de [from] a [to], sin contar [from].
  List<String> route(String from, String to) {
    if (from == to) return const [];
    final prev = <String, String>{from: from};
    final queue = [from];
    while (queue.isNotEmpty) {
      final at = queue.removeAt(0);
      for (final next in exits(at)) {
        if (prev.containsKey(next)) continue;
        prev[next] = at;
        if (next == to) {
          final out = [to];
          var k = to;
          while (prev[k] != from) {
            k = prev[k]!;
            out.insert(0, k);
          }
          return out;
        }
        queue.add(next);
      }
    }
    return const [];
  }

  /// Hacia dónde queda [to] mirando desde [from] (grados).
  static double bearing(Offset from, Offset to) {
    final d = to - from;
    return atan2(d.dx, d.dy) * 180 / pi;
  }

  /// El hueco [cell] (fila * cols + col; la fila 0 es la del fondo) del sector [sector].
  Offset slot(int sector, int cell) {
    final a = decorAreas[sector];
    final col = cell % cols, row = cell ~/ cols;
    final x = a.left + a.width * (col + 0.5) / cols;
    final y = a.bottom - a.height * (row + 0.5) / rows;
    // Un poco corridos fila por medio, para que no se vean en fila india.
    return Offset(x + (row.isOdd ? a.width / cols * 0.25 : 0), y);
  }

  /// En qué sector queda un punto: el de su mirador más cercano.
  int sectorOf(Offset p) => nearest(p).sector;

  /// Si [p] cae en el agua del estanque.
  bool inPond(Offset p) {
    final d = p - pondAt;
    return pow(d.dx / pondRadii.width, 2) + pow(d.dy / pondRadii.height, 2) <= 1;
  }

  /// Cuánto musgo hay en [p] (0 grava, 1 musgo).
  double mossAt(Offset p) {
    var w = 0.0;
    for (final (c, r) in moss) {
      final k = 1 - (p - c).distance / r;
      if (k > w) w = k;
    }
    return (w * 2.2).clamp(0.0, 1.0);
  }

  /// El punto libre más cercano a [p] para pararse: dentro del muro, fuera del
  /// agua y sin meterse en los lugares, el paisaje ni el pabellón.
  Offset resolve(Offset p) {
    final box = wall.deflate(0.9);
    p = Offset(p.dx.clamp(box.left, box.right), p.dy.clamp(box.top, box.bottom));
    for (final o in objects) {
      if (o.kind == PanoKind.gate) continue;
      if (o.decor == 'pavilion' || o.place == 'sand') {
        // El pabellón (la galería de 1.8 m de fondo) y el arenero: rectángulos, con margen.
        final r = o.place == 'sand'
            ? Rect.fromCenter(center: o.at, width: o.width + 0.7, height: o.width * 0.64 + 0.7)
            : Rect.fromCenter(center: o.at, width: o.width + 1.0, height: 2.8);
        if (!r.contains(p)) continue;
        final opts = [Offset(r.left, p.dy), Offset(r.right, p.dy), Offset(p.dx, r.top), Offset(p.dx, r.bottom)]
          ..sort((a, b) => (a - p).distance.compareTo((b - p).distance));
        p = opts.first;
        continue;
      }
      if (o.place == 'pond') continue;
      final r = o.width / 2 + 0.45;
      final v = p - o.at;
      if (v.distance >= r) continue;
      p = o.at + (v.distance < 1e-6 ? Offset(0, -r) : v / v.distance * r);
    }
    for (final (c, _, wd) in islands) {
      final r = wd * 0.35 + 0.3;
      final v = p - c;
      if (v.distance < r) p = c + (v.distance < 1e-6 ? Offset(0, -r) : v / v.distance * r);
    }
    final d = p - pondAt;
    final e = sqrt(pow(d.dx / (pondRadii.width + 0.5), 2) + pow(d.dy / (pondRadii.height + 0.5), 2));
    if (e < 1) p = pondAt + (e < 1e-6 ? Offset(-(pondRadii.width + 0.5), 0) : d / e);
    // Lo que empujó un objeto tampoco saca del muro.
    return Offset(p.dx.clamp(box.left, box.right), p.dy.clamp(box.top, box.bottom));
  }

  /// La distancia desde [from] hasta el muro mirando hacia [angle] (radianes).
  double wallDistance(Offset from, double angle) {
    final dx = sin(angle), dy = cos(angle);
    var best = double.infinity;
    if (dx > 1e-9) best = min(best, (wall.right - from.dx) / dx);
    if (dx < -1e-9) best = min(best, (wall.left - from.dx) / dx);
    if (dy > 1e-9) best = min(best, (wall.bottom - from.dy) / dy);
    if (dy < -1e-9) best = min(best, (wall.top - from.dy) / dy);
    return best;
  }

  /// Las piedras de paso de cada sendero entre miradores.
  late final List<(Offset, double)> stones = () {
    final out = <(Offset, double)>[];
    for (final (a, b) in links) {
      final p = lookout(a).at, q = lookout(b).at;
      final d = q - p;
      final len = d.distance;
      final n = Offset(-d.dy, d.dx) / len;
      final count = (len / 0.85).floor();
      final rng = Random(a.hashCode ^ b.hashCode);
      for (var i = 0; i <= count; i++) {
        final t = i / count;
        final side = (i.isEven ? 1 : -1) * (0.12 + rng.nextDouble() * 0.1);
        out.add((p + d * t + n * side, 0.26 + rng.nextDouble() * 0.08));
      }
    }
    return out;
  }();

  /// Los arbustos al pie del muro (centro y ancho): dejan libres los portones,
  /// los lugares y los huecos para decorar.
  late final List<(Offset, double)> hedges = () {
    final out = <(Offset, double)>[];
    final inner = wall.deflate(0.75);
    final pts = <Offset>[];
    for (var x = inner.left; x <= inner.right; x += 1.6) {
      pts.add(Offset(x, inner.top));
      pts.add(Offset(x, inner.bottom));
    }
    for (var y = inner.top + 1.6; y < inner.bottom; y += 1.6) {
      pts.add(Offset(inner.left, y));
      pts.add(Offset(inner.right, y));
    }
    final rng = Random(7);
    for (final p in pts) {
      final size = 0.9 + rng.nextDouble() * 0.7;
      if (objects.any((o) => o.kind != PanoKind.prop && (o.at - p).distance < o.width / 2 + size / 2 + 0.3)) continue;
      if (objects.any((o) => o.decor == 'pavilion' && (o.at - p).distance < o.width / 2 + 1.2)) continue;
      if (inPond(p)) continue;
      if (decorAreas.any((a) => a.inflate(0.6).contains(p))) continue;
      out.add((p + Offset(rng.nextDouble() * 0.4 - 0.2, rng.nextDouble() * 0.4 - 0.2), size));
    }
    return out;
  }();

  /// Islas de musgo y piedras sobre la arena (centro, decoración y ancho), en
  /// lo que queda libre: le dan vida al patio cuando se camina.
  late final List<(Offset, String, double)> islands = () {
    final out = <(Offset, String, double)>[];
    final rng = Random(23);
    final box = wall.deflate(2.2);
    for (var x = box.left; x <= box.right; x += 2.7) {
      for (var y = box.top; y <= box.bottom; y += 2.7) {
        final p = Offset(x + rng.nextDouble() * 1.6 - 0.8, y + rng.nextDouble() * 1.6 - 0.8);
        final keep = rng.nextDouble();
        if (keep > 0.55) continue;
        if ((p - hub.at).distance < 3.2) continue;
        if (objects.any((o) => (o.at - p).distance < o.width / 2 + (o.decor == 'pavilion' ? 1.8 : 1.3))) continue;
        if (decorAreas.any((a) => a.inflate(0.9).contains(p))) continue;
        if (stones.any((s) => (s.$1 - p).distance < 1.1)) continue;
        final e = p - pondAt;
        if (pow(e.dx / (pondRadii.width + 1.2), 2) + pow(e.dy / (pondRadii.height + 1.2), 2) <= 1) continue;
        if (hubPlants.any((h) => (h.$1 - p).distance < 1.2)) continue;
        // Una mata de musgo con una piedra al lado, o piedras solas.
        final big = keep < 0.3;
        out.add((p, big ? 'moss' : 'rocks', big ? 1.1 + rng.nextDouble() * 0.4 : 0.7 + rng.nextDouble() * 0.3));
        if (big) {
          final t = rng.nextDouble() * 2 * pi;
          out.add((p + Offset(sin(t), cos(t)) * 0.75, rng.nextBool() ? 'step' : 'rocks', 0.5 + rng.nextDouble() * 0.2));
        }
      }
    }
    return out;
  }();

  /// Matas bajas alrededor del mirador central (centro y ancho): dan un
  /// primer plano en la Clásica sin tapar los juegos, que quedan más lejos.
  late final List<(Offset, double)> hubPlants = () {
    final out = <(Offset, double)>[];
    final rng = Random(11);
    for (var k = 0; k < 14; k++) {
      final t = (k + rng.nextDouble() * 0.5) * 2 * pi / 14;
      final d = 2.1 + rng.nextDouble() * 0.6;
      final p = hub.at + Offset(sin(t), cos(t)) * d;
      if (objects.any((o) => (o.at - p).distance < o.width / 2 + 0.5)) continue;
      if (decorAreas.any((a) => a.inflate(0.5).contains(p))) continue;
      out.add((p, 0.55 + rng.nextDouble() * 0.35));
    }
    return out;
  }();
}
