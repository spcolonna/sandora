import 'dart:math';
import 'dart:ui' show Offset;

import '../balance/balance.dart';
import 'decor.dart';

/// Un ramal del Sendero: sale del tronco hacia un costado y termina en un
/// claro con uno o dos lugares (juegos).
class SenderoBranchSpec {
  final int zone;

  /// A cuántos pasos del comienzo de su zona sale del tronco.
  final double at;

  /// -1 a la izquierda, 1 a la derecha.
  final int side;

  /// Los lugares del claro (nombres de `Place`).
  final List<String> places;

  const SenderoBranchSpec({required this.zone, required this.at, required this.side, required this.places});
}

/// Las reglas del Sendero (balance `sendero`). El mundo se arma con
/// [SenderoWorld].
class SenderoRules {
  /// Largo de cada zona en el tronco.
  final double segment;

  /// Dónde cae cada fila de la Maqueta dentro de su zona (la 0 es la del
  /// fondo de la maqueta, así que queda más adelante en el camino).
  final List<double> rowZ;

  /// A qué distancia del centro del camino queda cada columna.
  final List<double> colX;

  /// Cuánto se corre cada columna hacia adelante, para que no queden en fila.
  final double colStagger;

  /// Velocidad al caminar solo (pasos por segundo).
  final double speed;

  /// Ancho de una decoración en el mundo por cada unidad de `DecorItem.size`.
  final double decorScale;

  /// Medio ancho del camino.
  final double halfWidth;

  /// El tablón de récords: pasos desde la entrada y distancia al costado.
  final (double, double) board;

  final List<SenderoBranchSpec> branches;

  const SenderoRules({
    required this.segment,
    required this.rowZ,
    required this.colX,
    required this.colStagger,
    required this.speed,
    required this.decorScale,
    required this.halfWidth,
    this.board = (1.8, -2.3),
    this.branches = const [],
  });

  factory SenderoRules.from(Balance b) {
    final s = b.section('sendero');
    final board = s.list('board');
    return SenderoRules(
      segment: s.d('segment'),
      rowZ: s.list('rowZ'),
      colX: s.list('colX'),
      colStagger: s.d('colStagger'),
      speed: s.d('speed'),
      decorScale: s.d('decorScale'),
      halfWidth: s.d('halfWidth'),
      board: (board[0], board[1]),
      branches: [
        for (final m in (s.raw('branches') as List).cast<Map>())
          SenderoBranchSpec(
            zone: (m['zone'] as num).toInt(),
            at: (m['at'] as num).toDouble(),
            side: (m['side'] as num).toInt(),
            places: (m['places'] as List).cast<String>(),
          ),
      ],
    );
  }

  /// Largo del tronco: las tres zonas y un poco más para ver la última.
  double get length => ModelRules.sides * segment + 3;

  /// Dónde empieza la zona [side] en el tronco.
  double zoneStart(int side) => side * segment;

  /// En qué zona está el paso [s] del tronco.
  int zoneAt(double s) => (s / segment).floor().clamp(0, ModelRules.sides - 1);
}

/// El centro del tronco a [y] pasos hacia adelante: serpentea suave.
double senderoCenter(double y) => 1.5 * sin(y * 0.21) + 0.8 * sin(y * 0.083 + 1.2);

/// Una polilínea del Sendero, medida en pasos desde su comienzo.
class SenderoTrack {
  final List<Offset> points;
  final List<double> _at;

  SenderoTrack(this.points) : _at = _lengths(points);

  static List<double> _lengths(List<Offset> pts) {
    final out = <double>[0];
    for (var i = 1; i < pts.length; i++) {
      out.add(out.last + (pts[i] - pts[i - 1]).distance);
    }
    return out;
  }

  double get length => _at.last;

  int _seg(double s) {
    var lo = 0, hi = _at.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (_at[mid] <= s) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// El punto a [s] pasos del comienzo (afuera, sigue derecho).
  Offset pointAt(double s) {
    if (s <= 0) return points.first + tangentAt(0) * s;
    if (s >= length) return points.last + tangentAt(length) * (s - length);
    final i = _seg(s);
    final t = (s - _at[i]) / (_at[i + 1] - _at[i]);
    return Offset.lerp(points[i], points[i + 1], t)!;
  }

  /// Hacia dónde va el camino en [s] (unitario).
  Offset tangentAt(double s) {
    final i = _seg(s.clamp(0, length)).clamp(0, points.length - 2);
    final d = points[i + 1] - points[i];
    return d / d.distance;
  }

  /// Hacia la derecha de quien camina hacia adelante en [s].
  Offset normalAt(double s) {
    final t = tangentAt(s);
    return Offset(t.dy, -t.dx);
  }

  /// El paso más cercano a [p] y a qué distancia queda.
  (double, double) nearest(Offset p) {
    var best = double.infinity, bestS = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i], b = points[i + 1];
      final ab = b - a;
      final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
      final t = len2 == 0 ? 0.0 : (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2).clamp(0.0, 1.0);
      final d = (p - (a + ab * t)).distance;
      if (d < best) {
        best = d;
        bestS = _at[i] + t * (_at[i + 1] - _at[i]);
      }
    }
    return (bestS, best);
  }
}

/// Un lugar (juego) al final de un ramal.
class SenderoStation {
  final String place;
  final int zone;
  final int branch;
  final Offset pos;

  const SenderoStation({required this.place, required this.zone, required this.branch, required this.pos});
}

/// Un ramal ya armado.
class SenderoBranch {
  final SenderoBranchSpec spec;

  /// Su índice en [SenderoWorld.tracks] (el tronco es el 0).
  final int track;

  /// Dónde sale del tronco.
  final double at;

  /// Dónde está el cartel de la bifurcación.
  final Offset sign;

  const SenderoBranch({required this.spec, required this.track, required this.at, required this.sign});
}

/// Hacia dónde se puede seguir en una bifurcación.
class SenderoWay {
  final int track;
  final int dir;

  /// Lugares del ramal, o la zona hacia la que va el tronco (-1: la entrada;
  /// 3: seguir hasta el final).
  final List<String> places;
  final int zone;

  const SenderoWay({required this.track, required this.dir, this.places = const [], this.zone = -1});
}

/// Qué frenó a quien camina.
enum SenderoStop { none, fork, end, gate }

/// Quien camina por el Sendero: en qué tramo, en qué paso y hacia dónde.
class SenderoWalker {
  final int track;
  final double s;
  final int dir;
  const SenderoWalker(this.track, this.s, this.dir);

  @override
  bool operator ==(Object other) =>
      other is SenderoWalker && other.track == track && other.s == s && other.dir == dir;

  @override
  int get hashCode => Object.hash(track, s, dir);
}

/// El Sendero armado: el tronco, los ramales, los lugares, los portones y los
/// huecos de la decoración. Es lo mismo que se ve caminando y desde arriba.
class SenderoWorld {
  final SenderoRules rules;
  final List<SenderoTrack> tracks;
  final List<SenderoBranch> branches;
  final List<SenderoStation> stations;

  /// La grilla de la Maqueta: columnas y filas de parcelas por zona.
  final int cols, rows;

  SenderoWorld._(this.rules, this.tracks, this.branches, this.stations, this.cols, this.rows);

  factory SenderoWorld(SenderoRules r, {int cols = 4, int rows = 3}) {
    final pts = <Offset>[];
    for (var y = 0.0; y <= r.length + 0.01; y += 0.4) {
      pts.add(Offset(senderoCenter(y), y));
    }
    final trunk = SenderoTrack(pts);
    final tracks = [trunk];
    final branches = <SenderoBranch>[];
    final stations = <SenderoStation>[];
    for (final spec in r.branches) {
      final at = trunk.nearest(Offset(senderoCenter(r.zoneStart(spec.zone) + spec.at), r.zoneStart(spec.zone) + spec.at)).$1;
      final p0 = trunk.pointAt(at), t = trunk.tangentAt(at), n = trunk.normalAt(at) * spec.side.toDouble();
      // Sale en diagonal y se va abriendo hacia el costado.
      final c1 = p0 + t * 1.6 + n * 1.2;
      final c2 = p0 + t * 3.2 + n * 4.2;
      final p3 = p0 + t * 3.6 + n * 7.4;
      final bpts = <Offset>[];
      for (var i = 0; i <= 28; i++) {
        final u = i / 28, v = 1 - u;
        bpts.add(p0 * (v * v * v) + c1 * (3 * v * v * u) + c2 * (3 * v * u * u) + p3 * (u * u * u));
      }
      final track = SenderoTrack(bpts);
      tracks.add(track);
      final index = branches.length;
      branches.add(
        SenderoBranch(spec: spec, track: tracks.length - 1, at: at, sign: p0 - t * 0.9 + n * 1.25),
      );
      // El claro: los lugares un poco más allá del final, de frente.
      final e = track.tangentAt(track.length), en = track.normalAt(track.length);
      final end = track.points.last + e * 2.4;
      final k = spec.places.length;
      for (final (i, place) in spec.places.indexed) {
        final off = k == 1 ? 0.0 : (i - (k - 1) / 2) * 2.6;
        stations.add(SenderoStation(place: place, zone: spec.zone, branch: index, pos: end + en * off));
      }
    }
    return SenderoWorld._(r, tracks, branches, stations, cols, rows);
  }

  SenderoTrack get trunk => tracks[0];

  /// Dónde está el portón de la zona [zone] (1 y 2) en el tronco; el de la
  /// entrada (0) siempre está abierto.
  double gateAt(int zone) => zone == 0 ? 0.8 : rules.zoneStart(zone);

  /// El hueco (x, y) de la parcela [cell] de la zona [side].
  Offset slot(int side, int cell) {
    final row = cell ~/ cols, col = cell % cols;
    final s = rules.zoneStart(side) + rules.rowZ[row] + col * rules.colStagger;
    return trunk.pointAt(s) + trunk.normalAt(s) * rules.colX[col];
  }

  /// Dónde está el tablón de récords.
  Offset get board => trunk.pointAt(rules.board.$1) + trunk.normalAt(rules.board.$1) * rules.board.$2;

  /// La zona de un punto cualquiera del mundo (por cuánto avanzó).
  int zoneOf(Offset p) => rules.zoneAt(p.dy);

  /// El lugar [place], si está en el Sendero.
  SenderoStation? station(String place) => stations.where((s) => s.place == place).firstOrNull;

  /// Dónde pararse para mirar el lugar [place]: al final de su ramal.
  SenderoWalker? walkerAt(String place) {
    final st = station(place);
    if (st == null) return null;
    final b = branches[st.branch];
    return SenderoWalker(b.track, tracks[b.track].length, 1);
  }

  /// Dónde pararse para mirar algo en [p]: unos pasos antes, sobre el tramo
  /// más cercano, mirando hacia adelante.
  SenderoWalker viewOf(Offset p, {double back = 3.2}) {
    var best = (0, 0.0, double.infinity);
    for (final (i, t) in tracks.indexed) {
      final (s, d) = t.nearest(p);
      if (d < best.$3 - 0.5) best = (i, s, d);
    }
    return SenderoWalker(best.$1, max(0.0, best.$2 - back), 1);
  }

  /// Dónde y hacia dónde mira quien camina.
  Offset position(SenderoWalker w) => tracks[w.track].pointAt(w.s);

  /// El rumbo hacia el que mira (ángulo: 0 es hacia adelante, +y; positivo
  /// hacia la derecha), mirando un poco más allá para que gire suave.
  double heading(SenderoWalker w) {
    final t = tracks[w.track];
    final here = t.pointAt(w.s);
    final ahead = w.s + w.dir * 1.6;
    Offset d;
    if (ahead > t.length && w.track > 0) {
      // Al final del ramal se mira al claro, donde están los lugares.
      d = t.tangentAt(t.length);
    } else {
      final a = t.pointAt(ahead.clamp(0.0, t.length));
      d = a - here;
      if (d.distance < 1e-3) d = t.tangentAt(w.s) * w.dir.toDouble();
    }
    return atan2(d.dx, d.dy);
  }

  /// Las bifurcaciones del tramo [track] (pasos), sin contar los extremos.
  List<double> forksOn(int track) =>
      track == 0 ? [for (final b in branches) b.at] : const [];

  /// Hasta dónde se puede caminar en el tronco con los portones como están.
  /// [open] dice si la zona está abierta.
  double trunkLimit(bool Function(int zone) open) {
    for (var z = 1; z < ModelRules.sides; z++) {
      if (!open(z)) return gateAt(z) - 1.0;
    }
    return trunk.length;
  }

  /// Avanza [ds] pasos (con signo: negativo es caminar de espaldas) desde [w].
  /// Se frena en la próxima bifurcación (yendo hacia adelante), en un portón
  /// cerrado o al final del tramo.
  (SenderoWalker, SenderoStop) advance(SenderoWalker w, double ds, bool Function(int zone) open) {
    final t = tracks[w.track];
    final hi = w.track == 0 ? trunkLimit(open) : t.length;
    final move = ds * w.dir;
    var target = w.s + move;
    var stop = SenderoStop.none;
    // Bifurcaciones: solo frenan yendo hacia donde se mira.
    if (ds > 0) {
      for (final f in forksOn(w.track)) {
        final ahead = w.dir > 0 ? f > w.s + 1e-4 && f <= target : f < w.s - 1e-4 && f >= target;
        if (ahead && (stop == SenderoStop.none || (f - w.s).abs() < (target - w.s).abs())) {
          target = f;
          stop = SenderoStop.fork;
        }
      }
    }
    // El comienzo del ramal, de vuelta: es una bifurcación en el tronco.
    if (w.track > 0 && target <= 0) {
      return (SenderoWalker(w.track, 0, w.dir), ds > 0 ? SenderoStop.fork : SenderoStop.none);
    }
    if (target >= hi) {
      final gate = w.track == 0 && hi < t.length;
      return (SenderoWalker(w.track, max(w.s, hi).clamp(0.0, hi), w.dir), gate ? SenderoStop.gate : SenderoStop.end);
    }
    if (target <= 0) return (SenderoWalker(w.track, 0, w.dir), ds > 0 ? SenderoStop.end : SenderoStop.none);
    return (SenderoWalker(w.track, target, w.dir), stop);
  }

  /// Hacia dónde se puede seguir parado en [w] (en una bifurcación).
  List<SenderoWay> ways(SenderoWalker w) {
    if (w.track > 0 && w.s <= 1e-3) {
      final b = branches[w.track - 1];
      return [
        SenderoWay(track: 0, dir: 1, zone: towards(b.at, 1)),
        SenderoWay(track: 0, dir: -1, zone: towards(b.at, -1)),
      ];
    }
    if (w.track != 0) return const [];
    final out = <SenderoWay>[];
    for (final b in branches) {
      if ((b.at - w.s).abs() < 1e-3) {
        out.add(SenderoWay(track: b.track, dir: 1, places: b.spec.places, zone: b.spec.zone));
      }
    }
    if (out.isEmpty) return const [];
    final ahead = w.dir > 0 ? (w.s < trunk.length - 0.5) : w.s > 0.5;
    if (ahead) out.insert(0, SenderoWay(track: 0, dir: w.dir, zone: towards(w.s, w.dir)));
    return out;
  }

  /// Hacia qué zona se va por el tronco desde [s] en [dir]: la siguiente
  /// (o [ModelRules.sides], seguir hasta el final) o la anterior (-1, la entrada).
  int towards(double s, int dir) {
    final z = rules.zoneAt(s);
    return dir > 0 ? z + 1 : z - 1;
  }

  /// Toma el camino [way] parado en [w].
  SenderoWalker take(SenderoWalker w, SenderoWay way) {
    if (way.track == 0 && w.track > 0) return SenderoWalker(0, branches[w.track - 1].at, way.dir);
    if (way.track > 0) return SenderoWalker(way.track, 0, 1);
    return SenderoWalker(0, w.s, way.dir);
  }

  /// De qué lado (-1 izquierda, 1 derecha, 0 derecho) queda [way] para quien
  /// mira con rumbo [heading].
  int sideOf(SenderoWalker w, SenderoWay way, double heading) {
    final next = take(w, way);
    final t = tracks[next.track];
    final d = t.pointAt(next.s + next.dir * 2.5) - t.pointAt(next.s);
    var diff = atan2(d.dx, d.dy) - heading;
    while (diff > pi) {
      diff -= 2 * pi;
    }
    while (diff < -pi) {
      diff += 2 * pi;
    }
    if (diff.abs() < 0.35) return 0;
    return diff > 0 ? 1 : -1;
  }
}
