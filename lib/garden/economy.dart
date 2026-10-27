import 'dart:math';

import '../balance/balance.dart';

/// Esencias por zona (GDD, Economía).
enum Essence { water, sand, wood, light }

/// Lo que da una partida.
class Reward {
  final int pebbles;
  final Essence essence;
  final int essenceAmount;

  /// La partida rindió menos por repetir el mismo minijuego en el día.
  final bool tired;

  /// Calma ganada y, si con ella subió de nivel, el nivel nuevo.
  final int calm;
  final int? newLevel;

  const Reward(this.pebbles, this.essence, this.essenceAmount, {this.tired = false, this.calm = 0, this.newLevel});

  Reward withCalm(int calm, int? newLevel) =>
      Reward(pebbles, essence, essenceAmount, tired: tired, calm: calm, newLevel: newLevel);
}

/// Reglas de la economía, en Dart puro para poder probarlas.
class Economy {
  final Balance balance;
  Economy(this.balance);

  /// Recompensa de [game] con [stars] (0 a 3) siendo la partida número
  /// [runToday] (1 = la primera) de ese minijuego en el día.
  Reward reward(String game, int stars, int runToday) {
    final r = balance.rewards(game);
    final rep = balance.repeats;
    final tired = runToday > rep.i('fullRuns');
    final factor = tired ? rep.d('factorAfter') : 1.0;
    final pebbles = ((r.i('pebblesBase') + r.i('pebblesPerStar') * stars) * factor).round();
    final essence = ((r.i('essencePerStar') * stars) * factor).round();
    return Reward(pebbles, Essence.values.byName(r.s('essence')), essence, tired: tired);
  }

  /// Serenidad después de [days] días sin cuidado: baja un porcentaje por día
  /// sin pasar del piso (nunca se pierde todo).
  int decayedSerenity(int serenity, double days) {
    final s = balance.serenity;
    final floor = (s.i('max') * s.d('floor')).round();
    if (serenity <= floor || days <= 0) return serenity;
    final decayed = (serenity * pow(1 - s.d('decayPerDay'), days)).round();
    return max(decayed, floor);
  }

  int serenityAfterPlay(int serenity) {
    final s = balance.serenity;
    return min(serenity + s.i('perPlay'), s.i('max'));
  }

  /// Piedritas que juntó una torre de [stones] piedras en [hours] horas, con
  /// un tope para que no convenga desaparecer días enteros.
  int towerYield(int stones, double hours) {
    final s = balance.stack;
    final h = hours.clamp(0, s.d('maxHoursStored'));
    return (stones * s.d('pebblesPerHourPerStone') * h).floor();
  }
}
