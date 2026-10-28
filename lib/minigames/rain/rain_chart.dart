import 'dart:math';

import '../../balance/balance.dart';
import '../common/grade.dart';

/// Una gota: llega a la vasija [vessel] en el segundo [time].
class RainNote {
  final double time;
  final int vessel;

  /// Viento que la empuja al caer (-1 a 1; 0 sin viento): cae en diagonal.
  final double wind;
  Grade? grade;
  bool missed = false;

  RainNote(this.time, this.vessel, {this.wind = 0});

  bool get judged => grade != null || missed;
}

/// Una ráfaga de viento: empieza en [start], dura [length] y sopla hacia
/// [dir] (-1 izquierda, 1 derecha). Se avisa antes de que llegue.
typedef RainGust = ({double start, double length, double dir});

/// Las ráfagas de una partida (salen de la misma semilla que la partitura).
List<RainGust> rainGusts(BalanceSection b, {required int seed, double leadIn = 2.0}) {
  final rng = Random(seed ^ 0x5bd1e995);
  final gusts = <RainGust>[];
  final duration = b.d('durationSeconds');
  for (
    var t = leadIn + b.d('windFirst');
    t + b.d('windDuration') < duration - 1;
    t += b.d('windEvery') * (0.7 + 0.6 * rng.nextDouble())
  ) {
    if (rng.nextDouble() > b.d('windChance')) continue;
    gusts.add((start: t, length: b.d('windDuration'), dir: rng.nextBool() ? 1.0 : -1.0));
  }
  return gusts;
}

/// Genera la partitura de una partida: gotas sobre una grilla de pulsos, cada
/// vez más densa, con gotas dobles en la segunda mitad. Las vasijas siguen un
/// paseo de vecinos para que la secuencia suene a melodía. Como la lluvia de
/// verdad, viene en chubascos (la densidad sube y baja) y con las ráfagas las
/// gotas caen en diagonal y algunas se adelantan o se atrasan un poco.
List<RainNote> buildRainChart(BalanceSection b, {required int vessels, required int seed, double leadIn = 2.0}) {
  final rng = Random(seed);
  final duration = b.d('durationSeconds');
  final beat = b.d('beatSeconds');
  final gusts = rainGusts(b, seed: seed, leadIn: leadIn);
  // Chubascos: dos ondas lentas con fase al azar.
  final period = b.d('burstPeriod');
  final ph1 = rng.nextDouble() * 2 * pi, ph2 = rng.nextDouble() * 2 * pi;
  double burst(double t) => 0.65 * sin(2 * pi * t / period + ph1) + 0.35 * sin(2 * pi * t / (period * 0.43) + ph2);
  final notes = <RainNote>[];
  var current = vessels ~/ 2;
  for (var k = 0; leadIn + k * beat / 2 <= duration; k++) {
    final t = leadIn + k * beat / 2;
    final progress = (t - leadIn) / (duration - leadIn);
    final onBeat = k.isEven;
    // En la primera mitad solo pulsos enteros; después también medios pulsos.
    if (!onBeat && progress < 0.5) continue;
    final ramp = b.d('densityStart') + (b.d('densityEnd') - b.d('densityStart')) * progress;
    final density = (ramp * (1 + b.d('burstAmp') * burst(t))).clamp(0.15, 1.0);
    if (rng.nextDouble() > (onBeat ? density : density * 0.35)) continue;
    current = (current + rng.nextInt(3) - 1).clamp(0, vessels - 1);
    final gust = gusts.where((g) => t >= g.start && t <= g.start + g.length).firstOrNull;
    final wind = gust == null ? 0.0 : gust.dir * (0.6 + 0.4 * rng.nextDouble());
    // Con viento la gota llega un poco antes o después del pulso.
    final shift = gust == null ? 0.0 : (rng.nextDouble() * 2 - 1) * b.d('windShift');
    notes.add(RainNote(t + shift, current, wind: wind));
    if (progress >= b.d('doubleFrom') && onBeat && rng.nextDouble() < b.d('doubleChance')) {
      final other = (current + 1 + rng.nextInt(vessels - 1)) % vessels;
      notes.add(RainNote(t + shift, other, wind: wind));
    }
  }
  return notes..sort((a, c) => a.time.compareTo(c.time));
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
