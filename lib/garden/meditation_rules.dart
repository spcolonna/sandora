import 'dart:math';

import '../balance/balance.dart';

/// Lo que paga una sesión de meditación.
class MeditationReward {
  final int minutes;
  final int pebbles, light, calm, serenity;

  /// Sesión completa de una duración de la tabla: cobra con bonus.
  final bool complete;

  /// Parte de la sesión quedó fuera del techo diario.
  final bool capped;

  const MeditationReward(
    this.minutes,
    this.pebbles,
    this.light,
    this.calm,
    this.serenity, {
    this.complete = false,
    this.capped = false,
  });

  static const none = MeditationReward(0, 0, 0, 0, 0);
}

/// Reglas del Modo meditación (GDD): más tiempo, más puntos, con techo diario.
class MeditationRules {
  final Balance balance;
  MeditationRules(this.balance);

  BalanceSection get _m => balance.meditation;

  List<int> get durations => [for (final d in _m.list('durations')) d.round()];

  /// Recompensa de [minutes] meditados de una sesión de [chosen] minutos,
  /// cuando en el día ya se cobraron [usedToday] minutos.
  MeditationReward reward(int minutes, int chosen, int usedToday) {
    final left = max(0, _m.i('dailyCapMinutes') - usedToday);
    final paid = min(minutes, left);
    if (paid <= 0) return MeditationReward(0, 0, 0, 0, 0, capped: minutes > 0);
    final capped = paid < minutes;
    final table = _m.sub('rewards');
    if (!capped && minutes >= chosen && table.has('$chosen')) {
      final r = table.nums('$chosen');
      return MeditationReward(
        paid,
        r['pebbles']!.round(),
        r['light']!.round(),
        r['calm']!.round(),
        r['serenity']!.round(),
        complete: true,
      );
    }
    final r = _m.nums('perMinute');
    int per(String k) => (r[k]! * paid).floor();
    return MeditationReward(paid, per('pebbles'), per('light'), per('calm'), per('serenity'), capped: capped);
  }

  /// Racha de días con al menos una sesión de `streakMinMinutes`. Perdona un
  /// día perdido por semana (como la racha diaria).
  ({int streak, int? graceDay}) nextStreak({
    required int today,
    required int? lastDay,
    required int streak,
    required int? graceDay,
  }) {
    if (lastDay == null) return (streak: 1, graceDay: graceDay);
    final gap = today - lastDay;
    if (gap <= 0) return (streak: streak, graceDay: graceDay);
    if (gap == 1) return (streak: streak + 1, graceDay: graceDay);
    if (gap == 2 && (graceDay == null || today - graceDay >= 7)) return (streak: streak + 1, graceDay: today);
    return (streak: 1, graceDay: graceDay);
  }
}
