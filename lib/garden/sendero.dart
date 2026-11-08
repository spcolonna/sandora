import 'dart:math';

import '../balance/balance.dart';
import 'decor.dart';

/// El Sendero: un camino que se recorre en primera persona y atraviesa las
/// tres zonas del jardín (patio, estanque, bosque). Cada parcela de la Maqueta
/// es un lugar al costado del camino: la Maqueta es su plano visto desde arriba.
///
/// Coordenadas del mundo: `z` avanza por el camino (en unidades de un paso
/// largo) y `x` es la distancia al costado, medida desde el centro del camino.
class SenderoRules {
  /// Largo de cada zona.
  final double segment;

  /// Dónde cae cada fila de la Maqueta dentro de su zona (la 0 es la del
  /// fondo de la maqueta, así que queda más adelante en el camino).
  final List<double> rowZ;

  /// A qué distancia del centro del camino queda cada columna.
  final List<double> colX;

  /// Cuánto se corre cada columna en `z`, para que las filas no queden en fila.
  final double colStagger;

  /// Velocidad al caminar solo (unidades por segundo).
  final double speed;

  /// Ancho de una decoración en el mundo por cada unidad de `DecorItem.size`.
  final double decorScale;

  /// Medio ancho del camino.
  final double halfWidth;

  const SenderoRules({
    required this.segment,
    required this.rowZ,
    required this.colX,
    required this.colStagger,
    required this.speed,
    required this.decorScale,
    required this.halfWidth,
  });

  factory SenderoRules.from(Balance b) {
    final s = b.section('sendero');
    return SenderoRules(
      segment: s.d('segment'),
      rowZ: s.list('rowZ'),
      colX: s.list('colX'),
      colStagger: s.d('colStagger'),
      speed: s.d('speed'),
      decorScale: s.d('decorScale'),
      halfWidth: s.d('halfWidth'),
    );
  }

  /// Hasta dónde se camina: las tres zonas y un poco más para ver la última.
  double get length => ModelRules.sides * segment + 2;

  /// Dónde empieza la zona [side].
  double zoneStart(int side) => side * segment;

  /// En qué zona está [z].
  int zoneAt(double z) => (z / segment).floor().clamp(0, ModelRules.sides - 1);

  /// El lugar (x, z) de la parcela [cell] de la zona [side].
  ({double x, double z}) slot(ModelRules m, int side, int cell) {
    final row = m.row(cell), col = m.col(cell);
    return (x: colX[col], z: zoneStart(side) + rowZ[row] + col * colStagger);
  }

  /// Desde dónde mirar algo que está en [z]: unos pasos antes.
  double viewFrom(double z) => max(0, z - 3.2);
}

/// El centro del camino en [z]: serpentea suave, sin repetirse a la vista.
double senderoCenter(double z) => 1.5 * sin(z * 0.21) + 0.8 * sin(z * 0.083 + 1.2);

/// La pendiente del camino en [z] (hacia dónde se mira al caminar).
double senderoSlope(double z) => 1.5 * 0.21 * cos(z * 0.21) + 0.8 * 0.083 * cos(z * 0.083 + 1.2);
