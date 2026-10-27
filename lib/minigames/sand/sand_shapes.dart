import 'dart:math';

import '../../balance/balance.dart';

/// Punto en el cuadro del dibujo, normalizado a 0..1.
typedef P = ({double x, double y});

/// Figuras guía del arenero, en orden de dificultad.
enum SandShape { circle, wave, leaf, mountain, spiral }

/// Polilínea densa de la figura, en el orden en que hay que recorrerla.
List<P> shapePoints(SandShape s) {
  const n = 160;
  switch (s) {
    case SandShape.circle:
      return [for (var i = 0; i <= n; i++) (x: 0.5 + 0.36 * sin(2 * pi * i / n), y: 0.5 - 0.36 * cos(2 * pi * i / n))];
    case SandShape.wave:
      return [for (var i = 0; i <= n; i++) (x: 0.08 + 0.84 * i / n, y: 0.5 + 0.17 * sin(2 * pi * 2 * i / n))];
    case SandShape.spiral:
      return [
        for (var i = 0; i <= n; i++)
          (
            x: 0.5 + (0.05 + 0.33 * i / n) * cos(2 * pi * 2.25 * i / n),
            y: 0.5 + (0.05 + 0.33 * i / n) * sin(2 * pi * 2.25 * i / n),
          ),
      ];
    case SandShape.leaf:
      // Contorno: de la punta de abajo a la de arriba por la izquierda, y de
      // vuelta por la derecha.
      return [
        for (var i = 0; i <= n; i++)
          () {
            final t = i / n;
            final side = t < 0.5 ? -1.0 : 1.0;
            final u = t < 0.5 ? t * 2 : 2 - t * 2; // 0 abajo, 1 arriba
            return (x: 0.5 + side * 0.24 * sin(pi * u) * (1 - 0.25 * u), y: 0.88 - 0.76 * u);
          }(),
      ];
    case SandShape.mountain:
      const corners = [
        (x: 0.06, y: 0.76),
        (x: 0.3, y: 0.34),
        (x: 0.46, y: 0.56),
        (x: 0.66, y: 0.18),
        (x: 0.94, y: 0.76),
      ];
      return resample([...corners], 0.006);
  }
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

  SandScore score(List<List<P>> strokes) {
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
    final total =
        (w.d('precision') * precision +
            w.d('coverage') * cov +
            w.d('continuity') * continuity +
            w.d('smoothness') * smoothness) *
        min(1.0, cov / 0.6);
    final stars = b.list('stars').where((t) => total >= t).length;
    return SandScore(precision, cov, continuity, smoothness, total, stars);
  }
}
