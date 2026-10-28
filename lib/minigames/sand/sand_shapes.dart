import 'dart:math';

import '../../balance/balance.dart';

/// Punto en el cuadro del dibujo, normalizado a 0..1.
typedef P = ({double x, double y});

/// Figuras guía del arenero, en orden de dificultad.
enum SandShape { circle, wave, leaf, mountain, spiral }

/// Variante de una figura: la misma figura sale distinta cada vez (tamaño,
/// giro, espejo y un rasgo propio: forma del óvalo, amplitud y ondas de la
/// onda, ancho de la hoja, altura de los picos, vueltas de la espiral).
typedef ShapeVariant = ({double scale, double turn, bool mirror, double trait});

const plainVariant = (scale: 1.0, turn: 0.0, mirror: false, trait: 0.5);

ShapeVariant randomVariant(Random rng, BalanceSection b) => (
  scale: 1 - rng.nextDouble() * b.d('variantScale'),
  turn: (rng.nextDouble() - 0.5) * 2 * b.d('variantTurn'),
  mirror: rng.nextBool(),
  trait: rng.nextDouble(),
);

/// La figura de la partida: la primera vez el círculo; después al azar, sin
/// repetir la anterior y sin la espiral mientras se aprende.
SandShape pickShape(Random rng, {required int done, SandShape? last, int learning = 0}) {
  if (done == 0) return SandShape.circle;
  final options = [
    for (final s in SandShape.values)
      if (s != last && (done >= learning || s != SandShape.spiral)) s,
  ];
  return options[rng.nextInt(options.length)];
}

/// Polilínea densa de la figura, en el orden en que hay que recorrerla.
List<P> shapePoints(SandShape s, [ShapeVariant v = plainVariant]) => _fit(_place(_raw(s, v.trait), v));

List<P> _raw(SandShape s, double k) {
  const n = 160;
  switch (s) {
    case SandShape.circle:
      final ry = 0.36 * (0.84 + 0.16 * k);
      return [for (var i = 0; i <= n; i++) (x: 0.5 + 0.36 * sin(2 * pi * i / n), y: 0.5 - ry * cos(2 * pi * i / n))];
    case SandShape.wave:
      final amp = 0.13 + 0.07 * k, waves = 1.5 + k;
      return [for (var i = 0; i <= n; i++) (x: 0.08 + 0.84 * i / n, y: 0.5 + amp * sin(2 * pi * waves * i / n))];
    case SandShape.spiral:
      final turns = 1.85 + 0.6 * k;
      return [
        for (var i = 0; i <= n; i++)
          (
            x: 0.5 + (0.05 + 0.33 * i / n) * cos(2 * pi * turns * i / n),
            y: 0.5 + (0.05 + 0.33 * i / n) * sin(2 * pi * turns * i / n),
          ),
      ];
    case SandShape.leaf:
      // Contorno: de la punta de abajo a la de arriba por la izquierda, y de
      // vuelta por la derecha.
      final width = 0.2 + 0.08 * k;
      return [
        for (var i = 0; i <= n; i++)
          () {
            final t = i / n;
            final side = t < 0.5 ? -1.0 : 1.0;
            final u = t < 0.5 ? t * 2 : 2 - t * 2; // 0 abajo, 1 arriba
            return (x: 0.5 + side * width * sin(pi * u) * (1 - 0.25 * u), y: 0.88 - 0.76 * u);
          }(),
      ];
    case SandShape.mountain:
      final corners = [
        (x: 0.06, y: 0.76),
        (x: 0.3, y: 0.28 + 0.12 * k),
        (x: 0.46, y: 0.56),
        (x: 0.66, y: 0.14 + 0.1 * (1 - k)),
        (x: 0.94, y: 0.76),
      ];
      return resample(corners, 0.006);
  }
}

/// Espejo, giro y tamaño alrededor del centro del cuadro.
List<P> _place(List<P> pts, ShapeVariant v) {
  final c = cos(v.turn), s = sin(v.turn);
  return [
    for (final p in pts)
      () {
        final x = (v.mirror ? 0.5 - p.x : p.x - 0.5) * v.scale, y = (p.y - 0.5) * v.scale;
        return (x: 0.5 + x * c - y * s, y: 0.5 + x * s + y * c);
      }(),
  ];
}

/// Si al girarla se sale del cuadro, se achica hasta que entre (centrada).
List<P> _fit(List<P> pts, {double margin = 0.05}) {
  var lo = (x: double.infinity, y: double.infinity), hi = (x: -double.infinity, y: -double.infinity);
  for (final p in pts) {
    lo = (x: min(lo.x, p.x), y: min(lo.y, p.y));
    hi = (x: max(hi.x, p.x), y: max(hi.y, p.y));
  }
  final room = 1 - 2 * margin;
  final k = min(1.0, min(room / (hi.x - lo.x), room / (hi.y - lo.y)));
  final cx = (lo.x + hi.x) / 2, cy = (lo.y + hi.y) / 2;
  // Recentrar solo si se sale; si entra, queda donde estaba.
  final outside = lo.x < margin || lo.y < margin || hi.x > 1 - margin || hi.y > 1 - margin;
  if (!outside) return pts;
  return [for (final p in pts) (x: 0.5 + (p.x - cx) * k, y: 0.5 + (p.y - cy) * k)];
}

/// Una piedrita en la arena, cerca del camino: el rastrillo la rodea y desvía
/// el trazo si se pasa por encima.
typedef Pebble = ({P at, double r});

Pebble? placePebble(Random rng, List<P> guide, double tolerance, BalanceSection b) {
  if (rng.nextDouble() > b.d('pebbleChance')) return null;
  final i = (guide.length * (0.25 + 0.5 * rng.nextDouble())).floor();
  final a = guide[max(0, i - 1)], c = guide[min(guide.length - 1, i + 1)];
  final len = max(1e-6, _dist(a, c));
  final side = rng.nextBool() ? 1.0 : -1.0;
  final off = tolerance * (0.3 + 0.6 * rng.nextDouble()) * side;
  final g = guide[i];
  return (at: (x: g.x - (c.y - a.y) / len * off, y: g.y + (c.x - a.x) / len * off), r: tolerance * b.d('pebbleSize'));
}

/// El trazo no puede pasar por la piedrita: se corre hasta su borde.
P deflect(P p, Pebble s) {
  final d = _dist(p, s.at);
  if (d >= s.r) return p;
  if (d == 0) return (x: s.at.x + s.r, y: s.at.y);
  return (x: s.at.x + (p.x - s.at.x) / d * s.r, y: s.at.y + (p.y - s.at.y) / d * s.r);
}

double _dist(P a, P b) => sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));

/// Puntos cada [step] a lo largo de la polilínea.
List<P> resample(List<P> pts, double step) {
  if (pts.length < 2) return [...pts];
  final out = <P>[pts.first];
  var carry = 0.0;
  for (var i = 1; i < pts.length; i++) {
    final a = pts[i - 1], b = pts[i];
    final seg = _dist(a, b);
    var d = step - carry;
    while (d <= seg) {
      final t = d / seg;
      out.add((x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t));
      d += step;
    }
    carry = seg - (d - step);
  }
  if (_dist(out.last, pts.last) > step * 0.3) out.add(pts.last);
  return out;
}

/// Suaviza un trazo cortando esquinas (Chaikin). Conserva los extremos.
List<P> chaikin(List<P> pts, {int iterations = 2}) {
  var cur = pts;
  for (var it = 0; it < iterations && cur.length > 2; it++) {
    final next = <P>[cur.first];
    for (var i = 0; i < cur.length - 1; i++) {
      final a = cur[i], b = cur[i + 1];
      next.add((x: a.x * 0.75 + b.x * 0.25, y: a.y * 0.75 + b.y * 0.25));
      next.add((x: a.x * 0.25 + b.x * 0.75, y: a.y * 0.25 + b.y * 0.75));
    }
    next.add(cur.last);
    cur = next;
  }
  return cur;
}

double _distToSegment(P p, P a, P b) {
  final dx = b.x - a.x, dy = b.y - a.y;
  final len2 = dx * dx + dy * dy;
  if (len2 == 0) return _dist(p, a);
  final t = (((p.x - a.x) * dx + (p.y - a.y) * dy) / len2).clamp(0.0, 1.0);
  return _dist(p, (x: a.x + dx * t, y: a.y + dy * t));
}

double distToPolyline(P p, List<P> line) {
  var best = double.infinity;
  for (var i = 1; i < line.length; i++) {
    best = min(best, _distToSegment(p, line[i - 1], line[i]));
  }
  return best;
}

/// Giro medio (radianes) entre segmentos consecutivos.
double meanTurn(List<P> pts) {
  if (pts.length < 3) return 0;
  var sum = 0.0;
  for (var i = 2; i < pts.length; i++) {
    final a1 = atan2(pts[i - 1].y - pts[i - 2].y, pts[i - 1].x - pts[i - 2].x);
    final a2 = atan2(pts[i].y - pts[i - 1].y, pts[i].x - pts[i - 1].x);
    var d = (a2 - a1).abs();
    if (d > pi) d = 2 * pi - d;
    sum += d;
  }
  return sum / (pts.length - 2);
}

class SandScore {
  final double precision, coverage, continuity, smoothness, total;
  final int stars;
  const SandScore(this.precision, this.coverage, this.continuity, this.smoothness, this.total, this.stars);
}

/// Califica un dibujo. [strokes] son los trazos (cada vez que se levanta el
/// dedo empieza uno nuevo); [tolerance] es la distancia que todavía cuenta
/// como "sobre la guía", en unidades del cuadro.
class SandScorer {
  final BalanceSection b;
  final List<P> guide;
  final double tolerance;
  late final List<P> _guideSamples = resample(guide, 0.01);
  late final double _guideTurn = meanTurn(resample(guide, 0.03));

  SandScorer(this.b, this.guide, this.tolerance);

  /// Fracción de la guía que ya tiene trazo cerca.
  double coverage(List<List<P>> strokes) {
    final pts = [for (final s in strokes) ...resample(s, 0.01)];
    if (pts.isEmpty) return 0;
    var hit = 0;
    for (final g in _guideSamples) {
      if (pts.any((p) => _dist(p, g) <= tolerance)) hit++;
    }
    return hit / _guideSamples.length;
  }

  /// [bonus] se suma al total (por ejemplo, rodear la piedrita con limpieza).
  SandScore score(List<List<P>> strokes, {double bonus = 0}) {
    final drawn = strokes.where((s) => s.length > 1).toList();
    final pts = [for (final s in drawn) ...resample(s, 0.01)];
    if (pts.length < 2) return const SandScore(0, 0, 0, 0, 0, 0);
    final mean = pts.fold<double>(0, (a, p) => a + distToPolyline(p, guide)) / pts.length;
    final precision = (1 - mean / (tolerance * 1.6)).clamp(0.0, 1.0);
    final cov = coverage(drawn);
    final continuity = (1 - b.d('liftPenalty') * (drawn.length - 1)).clamp(0.0, 1.0);
    final turns = drawn.map((s) => meanTurn(resample(s, 0.03))).reduce((a, c) => a + c) / drawn.length;
    final smoothness = (1 - max(0, turns - _guideTurn) / 0.25).clamp(0.0, 1.0);
    final w = b.sub('weights');
    // Sin cobertura no hay dibujo: la precisión de un trazo corto no alcanza.
    final base =
        (w.d('precision') * precision +
            w.d('coverage') * cov +
            w.d('continuity') * continuity +
            w.d('smoothness') * smoothness) *
        min(1.0, cov / 0.6);
    final total = min(1.0, base + (cov >= 0.6 ? bonus : 0));
    final stars = b.list('stars').where((t) => total >= t).length;
    return SandScore(precision, cov, continuity, smoothness, total, stars);
  }
}
