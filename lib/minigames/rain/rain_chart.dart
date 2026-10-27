import 'dart:math';

import '../../balance/balance.dart';
import '../common/grade.dart';

/// Una gota: llega a la vasija [vessel] en el segundo [time].
class RainNote {
  final double time;
  final int vessel;
  Grade? grade;
  bool missed = false;

  RainNote(this.time, this.vessel);

  bool get judged => grade != null || missed;
}

/// Genera la partitura de una partida: gotas sobre una grilla de pulsos, cada
/// vez más densa, con gotas dobles en la segunda mitad. Las vasijas siguen un
/// paseo de vecinos para que la secuencia suene a melodía.
List<RainNote> buildRainChart(BalanceSection b, {required int vessels, required int seed, double leadIn = 2.0}) {
  final rng = Random(seed);
  final duration = b.d('durationSeconds');
  final beat = b.d('beatSeconds');
  final notes = <RainNote>[];
  var current = vessels ~/ 2;
  for (var k = 0; leadIn + k * beat / 2 <= duration; k++) {
    final t = leadIn + k * beat / 2;
    final progress = (t - leadIn) / (duration - leadIn);
    final onBeat = k.isEven;
    // En la primera mitad solo pulsos enteros; después también medios pulsos.
    if (!onBeat && progress < 0.5) continue;
    final density = b.d('densityStart') + (b.d('densityEnd') - b.d('densityStart')) * progress;
    if (rng.nextDouble() > (onBeat ? density : density * 0.35)) continue;
    current = (current + rng.nextInt(3) - 1).clamp(0, vessels - 1);
    notes.add(RainNote(t, current));
    if (progress >= b.d('doubleFrom') && onBeat && rng.nextDouble() < b.d('doubleChance')) {
      final other = (current + 1 + rng.nextInt(vessels - 1)) % vessels;
      notes.add(RainNote(t, other));
    }
  }
  return notes;
}

/// Juzga los toques contra el reloj del juego (no el del audio). La ventana es
/// generosa: ±120 ms para "bien" y ±40 ms para "perfecto" (GDD).
class RainJudge {
  final List<RainNote> notes;
  final double perfect, great, good, offset;
  int combo = 0;
  int bestCombo = 0;
  int score = 0;

  RainJudge(this.notes, BalanceSection b)
    : perfect = b.d('perfectMs') / 1000,
      great = b.d('greatMs') / 1000,
      good = b.d('goodMs') / 1000,
      offset = b.d('audioOffsetMs') / 1000;

  /// Toque en [vessel] en el segundo [time]: la gota pendiente más cercana de
  /// esa vasija dentro de la ventana, o null si no había ninguna.
  RainNote? tap(int vessel, double time) {
    final t = time - offset;
    RainNote? best;
    for (final n in notes) {
      if (n.judged || n.vessel != vessel) continue;
      final d = (n.time - t).abs();
      if (d <= good && (best == null || d < (best.time - t).abs())) best = n;
    }
    if (best == null) return null;
    final d = (best.time - t).abs();
    best.grade = d <= perfect ? Grade.perfect : (d <= great ? Grade.great : Grade.good);
    combo++;
    bestCombo = max(bestCombo, combo);
    score += (best.grade!.points * 10 * (1 + min(combo, 20) / 20)).round();
    return best;
  }

  /// Marca como perdidas las gotas que ya pasaron su ventana.
  List<RainNote> expire(double time) {
    final t = time - offset;
    final lost = <RainNote>[];
    for (final n in notes) {
      if (!n.judged && t - n.time > good) {
        n.missed = true;
        lost.add(n);
      }
    }
    if (lost.isNotEmpty) combo = 0;
    return lost;
  }

  bool get done => notes.every((n) => n.judged);

  /// 0..1: puntos logrados sobre el máximo posible (todo perfecto).
  double get accuracy =>
      notes.isEmpty ? 0 : notes.fold<int>(0, (a, n) => a + (n.grade?.points ?? 0)) / (notes.length * 3);
}
