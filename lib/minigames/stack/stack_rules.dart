import 'dart:math';

import '../../balance/balance.dart';
import '../common/grade.dart';

/// Forma de una piedra: polígono convexo de 8 vértices (el máximo de Box2D)
/// centrado en el origen, en metros del mundo físico.
class StoneShape {
  final List<(double, double)> vertices;
  final double width, height;
  final int tone; // 0..2: variante de color
  const StoneShape(this.vertices, this.width, this.height, this.tone);
}

/// Piedra chata y redondeada: una superelipse con un poco de azar. Las de
/// arriba de la torre tienden a ser más chicas.
StoneShape randomStone(Random rng, int index) {
  final shrink = min(index * 0.02, 0.35);
  final w = 1.5 + rng.nextDouble() * 0.8 - shrink;
  final h = 0.55 + rng.nextDouble() * 0.3;
  final verts = <(double, double)>[];
  for (var i = 0; i < 8; i++) {
    final a = 2 * pi * i / 8 + pi / 8;
    final c = cos(a), s = sin(a);
    // Exponente < 1 sobre cos/sin: superelipse más cuadrada (base plana).
    final x = w / 2 * c.sign * pow(c.abs(), 0.75) * (0.94 + rng.nextDouble() * 0.06);
    final y = h / 2 * s.sign * pow(s.abs(), 0.75) * (0.94 + rng.nextDouble() * 0.06);
    verts.add((x, y));
  }
  return StoneShape(verts, w, h, rng.nextInt(3));
}

/// Calidad de una piedra según cuánto se corrió del centro de la de abajo,
/// como fracción del ancho de esa piedra.
Grade stoneGrade(double offset, double belowWidth, BalanceSection b) {
  final ratio = offset.abs() / belowWidth;
  if (ratio <= b.d('perfectTolerance')) return Grade.perfect;
  if (ratio <= b.d('greatTolerance')) return Grade.great;
  return Grade.good;
}
