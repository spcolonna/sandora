import 'dart:math';

import '../../balance/balance.dart';
import '../common/grade.dart';

/// Reglas de la Campana del templo, en Dart puro para poder probarlas.
///
/// Se tira el tronco hacia atrás y se suelta: la fuerza del golpe es cuánto se
/// tiró (0 a 1). Cada golpe pide una fuerza distinta y, entre golpe y golpe,
/// hay que dejar que la campana se apague: golpear mientras todavía resuena
/// resta paciencia.
class BellRules {
  final BalanceSection b;
  BellRules(this.b);

  int get strikes => b.i('strikes');
  double get decay => b.d('decaySeconds');
  double get quiet => b.d('quiet');

  /// Fuerzas pedidas para una partida: al azar dentro del rango, sin repetir
  /// casi la misma dos veces seguidas.
  List<double> targets(Random rng) {
    final lo = b.d('targetLow'), hi = b.d('targetHigh');
    final out = <double>[];
    while (out.length < strikes) {
      final t = lo + (hi - lo) * rng.nextDouble();
      if (out.isNotEmpty && (t - out.last).abs() < b.d('zoneWidth')) continue;
      out.add(t);
    }
    return out;
  }

  /// Cuánto resuena la campana [since] segundos después de un golpe de [force].
  double ringAfter(double force, double since) => force * exp(-since / decay);

  /// Precisión del golpe: 1 en el centro de la zona y 0 a [zoneWidth] o más.
  double accuracy(double force, double target) => (1 - (force - target).abs() / b.d('zoneWidth')).clamp(0.0, 1.0);

  /// Paciencia: 1 si la campana ya estaba en silencio; menos cuanto más
  /// resonaba al golpear.
  double patience(double ringing) => ringing <= quiet ? 1 : (1 - (ringing - quiet) / (1 - quiet) * 0.7).clamp(0.3, 1);

  double strikeScore(double force, double target, double ringing) => accuracy(force, target) * patience(ringing);

  Grade? grade(double score) => score >= 0.9
      ? Grade.perfect
      : score >= 0.7
      ? Grade.great
      : score >= 0.45
      ? Grade.good
      : null;
}
