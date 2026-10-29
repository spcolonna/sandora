import 'dart:math';

import '../../balance/balance.dart';
import '../common/grade.dart';

/// Una ráfaga de viento: llega en [start], dura [length] segundos y pide
/// tapar el hueco [hole] (0 a 3) mientras pasa.
typedef Gust = ({int hole, double start, double length});

/// Reglas de la Flauta de bambú, en Dart puro para poder probarlas.
///
/// Las ráfagas forman una melodía pentatónica que sube y baja de a poco. Cada
/// ráfaga vale la parte de su duración en que el hueco pedido estuvo tapado,
/// con un margen al empezar para reaccionar. Tapar otro hueco no resta: la
/// escala pentatónica suena bien igual.
class FluteRules {
  final BalanceSection b;
  FluteRules(this.b);

  static const holes = 4;

  /// Margen al empezar cada ráfaga (segundos) que no cuenta.
  double get grace => b.d('graceSeconds');

  List<Gust> song(Random rng) {
    final lengths = b.list('lengths');
    final out = <Gust>[];
    var t = b.d('leadIn');
    var hole = rng.nextInt(holes);
    for (var i = 0; i < b.i('gusts'); i++) {
      final length = lengths[rng.nextInt(lengths.length)];
      out.add((hole: hole, start: t, length: length));
      t += length + b.d('gapMin') + rng.nextDouble() * (b.d('gapMax') - b.d('gapMin'));
      // La melodía camina: casi siempre un paso al lado, a veces un salto.
      final step = rng.nextDouble() < 0.7 ? 1 : 2;
      final up = hole + step < holes && (hole - step < 0 || rng.nextBool());
      hole = up ? hole + step : hole - step;
    }
    return out;
  }

  /// Cuánto se tapó bien una ráfaga: la parte de su duración (descontando el
  /// margen) cubierta por los intervalos [held] (inicio, fin) de su hueco.
  double coverage(Gust g, List<(double, double)> held) {
    final from = g.start + min(grace, g.length * 0.5), to = g.start + g.length;
    var covered = 0.0;
    for (final (a, z) in held) {
      covered += max(0, min(z, to) - max(a, from));
    }
    return (covered / (to - from)).clamp(0.0, 1.0);
  }

  Grade? grade(double v) => v >= 0.9
      ? Grade.perfect
      : v >= 0.65
      ? Grade.great
      : v >= 0.35
      ? Grade.good
      : null;
}
