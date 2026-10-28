import 'dart:math';
import 'dart:ui';

import '../../ui/theme/palette.dart';

/// Pinta un trazo de tinta: discos superpuestos con el ancho de cada punto,
/// sobre una curva de Catmull-Rom; hacia el final el pincel se seca (más claro
/// y con huecos). Lo usan el juego y el ensō colgado en el jardín.
void paintEnsoInk(Canvas canvas, List<Offset> pts, List<double> widths, {double step = 2}) {
  final n = pts.length;
  if (n < 2) return;
  for (var i = 1; i < n; i++) {
    final a = pts[i - 1], c = pts[i];
    final p0 = pts[max(0, i - 2)], p3 = pts[min(n - 1, i + 1)];
    final dry = (i / n - 0.75).clamp(0.0, 0.25) * 4; // 0 → 1 en el último cuarto
    final steps = max(1, ((c - a).distance / step).ceil());
    for (var k = 0; k < steps; k++) {
      final p = _catmull(p0, a, c, p3, k / steps);
      final w = (widths[i - 1] + (widths[i] - widths[i - 1]) * k / steps) * (1 - 0.35 * dry);
      // El pincel seco deja huecos.
      if (dry > 0 && ((i * 7 + k * 13) % 10) / 10 < dry * 0.45) continue;
      canvas.drawCircle(p, w / 2, Paint()..color = Palette.ink.withValues(alpha: 0.85 - 0.35 * dry));
    }
  }
}

Offset _catmull(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
  final t2 = t * t, t3 = t2 * t;
  return (p1 * 2 + (p2 - p0) * t + (p0 * 2 - p1 * 5 + p2 * 4 - p3) * t2 + (p1 * 3 - p0 - p2 * 3 + p3) * t3) * 0.5;
}

/// Un trazo guardado sin escala: centrado en el centro del círculo y medido
/// en radios, para dibujarlo de cualquier tamaño.
class SavedInk {
  final List<Offset> points;
  final List<double> widths;
  const SavedInk(this.points, this.widths);

  /// Hasta [maxPoints] puntos del trazo, normalizados.
  static SavedInk fromStroke(List<Offset> pts, List<double> widths, {int maxPoints = 96}) {
    final c = pts.reduce((a, p) => a + p) / pts.length.toDouble();
    final r = pts.map((p) => (p - c).distance).reduce((a, d) => a + d) / pts.length;
    final every = max(1, (pts.length / maxPoints).ceil());
    final out = <Offset>[], ws = <double>[];
    for (var i = 0; i < pts.length; i += every) {
      out.add((pts[i] - c) / r);
      ws.add(widths[i] / r);
    }
    // El final del trazo siempre entra: ahí se seca el pincel.
    if ((pts.length - 1) % every != 0) {
      out.add((pts.last - c) / r);
      ws.add(widths.last / r);
    }
    return SavedInk(out, ws);
  }

  /// Plano: x, y, ancho, x, y, ancho… con 3 decimales.
  List<double> toFlat() => [
    for (var i = 0; i < points.length; i++) ...[points[i].dx, points[i].dy, widths[i]],
  ].map((v) => double.parse(v.toStringAsFixed(3))).toList();

  static SavedInk? fromFlat(List<double>? v) {
    if (v == null || v.length < 6 || v.length % 3 != 0) return null;
    return SavedInk(
      [for (var i = 0; i < v.length; i += 3) Offset(v[i], v[i + 1])],
      [for (var i = 2; i < v.length; i += 3) v[i]],
    );
  }

  /// Dibuja el trazo con centro [center] y radio [radius].
  void paint(Canvas canvas, Offset center, double radius) {
    paintEnsoInk(
      canvas,
      [for (final p in points) center + p * radius],
      [for (final w in widths) w * radius],
      step: max(0.5, radius / 12),
    );
  }
}
