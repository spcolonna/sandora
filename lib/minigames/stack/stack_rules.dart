import 'dart:math';
import 'dart:ui';

import '../../balance/balance.dart';
import '../common/grade.dart';

/// Tipos de piedra. Cada uno tiene su rango de tamaño (en metros), qué tan
/// cuadrada es su silueta, cuánto relieve tiene y qué tan estable es: sobre
/// una laja se apoya fácil; sobre un canto redondo, no.
enum StoneKind {
  river(w: (1.4, 2.1), h: (0.45, 0.65), square: 0.72, lumps: 0.03, stability: 1.0, odds: 5),
  slab(w: (1.8, 2.5), h: (0.30, 0.42), square: 0.45, lumps: 0.025, stability: 1.3, odds: 3),
  pebble(w: (0.9, 1.25), h: (0.55, 0.75), square: 0.95, lumps: 0.02, stability: 0.7, odds: 3),
  egg(w: (1.1, 1.5), h: (0.6, 0.85), square: 0.9, lumps: 0.02, stability: 0.8, odds: 2),
  boulder(w: (1.6, 2.2), h: (0.75, 1.0), square: 0.6, lumps: 0.07, stability: 1.1, odds: 2),
  wedge(w: (1.3, 1.8), h: (0.45, 0.7), square: 0.62, lumps: 0.04, stability: 0.85, odds: 2);

  final (double, double) w, h;
  final double square, lumps, stability;
  final int odds;
  const StoneKind({
    required this.w,
    required this.h,
    required this.square,
    required this.lumps,
    required this.stability,
    required this.odds,
  });
}

/// Una piedra concreta. [seed] fija su silueta y sus vetas, así se ve igual
/// en el minijuego y en el jardín.
class StoneShape {
  final StoneKind kind;
  final double width, height;
  final int tone, seed;
  StoneShape(this.kind, this.width, this.height, this.tone, this.seed);

  /// Silueta cerrada centrada en el origen, con la base un poco aplanada.
  late final List<Offset> outline = _outline();

  late final Path path = Path()..addPolygon(outline, true);

  List<Offset> _outline() {
    final rng = Random(seed);
    final p1 = rng.nextDouble() * 2 * pi, p2 = rng.nextDouble() * 2 * pi;
    final tilt = (rng.nextDouble() - 0.5) * 0.5;
    const n = 30;
    return [
      for (var i = 0; i < n; i++)
        () {
          final a = 2 * pi * i / n;
          final c = cos(a), s = sin(a);
          var x = width / 2 * c.sign * pow(c.abs(), kind.square);
          var y = height / 2 * s.sign * pow(s.abs(), kind.square);
          // Relieve: dos ondas suaves con fase propia de cada piedra.
          final r = 1 + kind.lumps * (sin(a * 3 + p1) + 0.6 * sin(a * 5 + p2));
          x *= r;
          y *= r;
          switch (kind) {
            // Un extremo más gordo que el otro.
            case StoneKind.egg:
              y *= 1 + 0.18 * c * (tilt > 0 ? 1 : -1);
            // Arriba se angosta hacia un costado.
            case StoneKind.wedge:
              if (y < 0) x = x * (1 + 0.35 * y / height * 2) + tilt * y;
            default:
          }
          // Base aplanada para que apoye.
          if (y > height * 0.38) y = height * 0.38 + (y - height * 0.38) * 0.4;
          return Offset(x, y);
        }(),
    ];
  }
}

const stoneTones = 5;

StoneKind _pickKind(Random rng) {
  final total = StoneKind.values.fold(0, (a, k) => a + k.odds);
  var roll = rng.nextInt(total);
  for (final k in StoneKind.values) {
    if (roll < k.odds) return k;
    roll -= k.odds;
  }
  return StoneKind.river;
}

double _between((double, double) r, Random rng) => r.$1 + (r.$2 - r.$1) * rng.nextDouble();

/// Piedra al azar, de cualquier tipo.
StoneShape randomStone(Random rng) {
  final kind = _pickKind(rng);
  return StoneShape(kind, _between(kind.w, rng), _between(kind.h, rng), rng.nextInt(stoneTones), rng.nextInt(1 << 30));
}

/// Calidad de una piedra según cuánto se corrió del centro de la de abajo,
/// como fracción del ancho de esa piedra.
Grade stoneGrade(double offset, double belowWidth, BalanceSection b) {
  final ratio = offset.abs() / belowWidth;
  if (ratio <= b.d('perfectTolerance')) return Grade.perfect;
  if (ratio <= b.d('greatTolerance')) return Grade.great;
  return Grade.good;
}

/// Equilibrio de la torre, en Dart puro para poder probarlo. No es física
/// exacta: es una física "creíble" con azar, que castiga según lo lejos del
/// centro que cayó la piedra y la altura de la torre.
class StackRules {
  final BalanceSection b;
  StackRules(this.b);

  /// Qué tanto se corrió: 0 en el centro, 1 con el centro sobre el borde.
  static double offRatio(double dx, double belowWidth) => dx.abs() / (belowWidth / 2);

  /// 0 en el piso, 1 en una torre de `heightRiskAt` piedras (escala log).
  double heightFactor(int height) => min(1, log(1 + height) / log(1 + b.d('heightRiskAt')));

  /// Hasta qué [offRatio] la piedra apoya firme. Depende de las dos piedras
  /// que se tocan y baja un poco con la altura.
  double safeRatio(StoneKind top, double belowStability, int height) =>
      b.d('safeRatio') * sqrt(top.stability * belowStability) * (1 - b.d('heightRisk') * heightFactor(height));

  /// Qué tan mal quedó: 0 es firme; 1, con el centro sobre el borde. Suman el
  /// balanceo que traía la torre ([wobble], 0 a 1) y si la piedra carga hacia
  /// el mismo lado que las de abajo ([lean], 0 a 1).
  double severity(double ratio, double safe, {double wobble = 0, double lean = 0}) {
    final off = max(0.0, (ratio - safe) / (1 - safe));
    return off + b.d('wobbleRisk') * wobble.clamp(0, 1) + b.d('leanRisk') * lean.clamp(0, 1);
  }

  /// Probabilidad de que la torre ceda con esa [severity].
  double fallChance(double severity) {
    if (severity <= 0) return 0;
    if (severity >= b.d('sureFall')) return 1;
    return min(1, b.d('fallScale') * pow(severity, b.d('fallExponent')));
  }

  /// Cuántas piedras se caen (contando la que se soltó) en una torre de
  /// [height]. Crece más lento que la altura: en 10 piedras se caen de 2 a 8;
  /// en 500, de 20 a 100. Siempre al menos 1.
  int collapseLoss(int height, double severity, Random rng) {
    final s = 0.2 + 0.7 * min(severity, b.d('sureFall')) / b.d('sureFall');
    var noise = 0.75 + 0.5 * rng.nextDouble();
    if (rng.nextDouble() < b.d('badLuckChance')) noise *= 1.5;
    final lost = b.d('lossScale') * pow(height, b.d('lossExponent')) * s * noise;
    return lost.round().clamp(1, height);
  }

  /// Cuánto balanceo suma una piedra al apoyarse. [impact] es la velocidad
  /// de costado con la que llegó.
  double wobbleAdd(double ratio, double impact, int height) =>
      (b.d('wobbleBase') + b.d('wobblePerRatio') * ratio + b.d('wobblePerImpact') * impact) *
      (1 + heightFactor(height));

  /// Balanceo que queda después de [dt] segundos: las torres altas tardan
  /// más en quedarse quietas.
  double wobbleDecay(double wobble, double dt, int height) =>
      wobble * exp(-dt * b.d('wobbleDamping') / (1 + heightFactor(height)));
}
