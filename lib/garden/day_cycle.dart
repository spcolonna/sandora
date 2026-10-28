import 'dart:math';

import '../balance/balance.dart';
import 'shop.dart';
import 'weather.dart';

/// Momentos del día del jardín, según la hora del dispositivo.
enum DayPhase { dawn, day, dusk, night }

/// Hora fija para probar (`--dart-define=SANDORA_HOUR=21.5`); vacía en el juego.
const _hourOverride = String.fromEnvironment('SANDORA_HOUR');

/// La hora que ve el jardín: la del dispositivo, salvo que se fije para probar.
DateTime gardenNow() {
  final now = DateTime.now();
  final h = double.tryParse(_hourOverride);
  if (h == null) return now;
  return DateTime(now.year, now.month, now.day).add(Duration(minutes: (h * 60).round()));
}

/// Un regalo del jardín según el momento del día y el clima (el rocío del
/// amanecer, las luciérnagas de la noche, las vasijas que llenó la lluvia): se
/// toca en el jardín y da [give], hasta [daily] veces por día. Sin [phase]
/// aparece a cualquier hora; sin [weather], con cualquier clima.
class DayGift {
  final String id;
  final DayPhase? phase;
  final Set<Weather>? weather;
  final Map<String, int> give;
  final int daily;

  /// Solo aparece un rato después de que para la lluvia (el arcoíris).
  final bool afterRain;

  const DayGift(this.id, {this.phase, this.weather, required this.give, required this.daily, this.afterRain = false});

  bool activeAt(DayPhase p, Weather w, {bool afterRain = false}) =>
      (phase == null || phase == p) && (weather?.contains(w) ?? true) && (!this.afterRain || afterRain);

  factory DayGift.from(BalanceSection s) {
    final give = s.nums('give').map((k, v) => MapEntry(k, v.round()));
    final bad = give.keys.where((k) => !walletKeys.contains(k));
    if (bad.isNotEmpty) throw FormatException('Moneda desconocida en ${s.s('id')}: $bad');
    return DayGift(
      s.s('id'),
      phase: s.has('phase') ? DayPhase.values.byName(s.s('phase')) : null,
      weather: s.has('weather') ? {for (final w in s.strings('weather')) Weather.values.byName(w)} : null,
      give: give,
      daily: s.i('daily'),
      afterRain: s.flag('afterRain'),
    );
  }
}

/// Ciclo del día (GDD: el jardín vive con la hora real). Las horas son
/// decimales: amanecer de [dawn] a [day], día hasta [dusk], atardecer hasta
/// [night] y noche hasta el próximo amanecer.
class DayCycle {
  final double dawn, day, dusk, night;
  final List<DayGift> gifts;

  DayCycle(Balance balance)
    : dawn = balance.section('dayCycle').d('dawn'),
      day = balance.section('dayCycle').d('day'),
      dusk = balance.section('dayCycle').d('dusk'),
      night = balance.section('dayCycle').d('night'),
      gifts = [for (final g in balance.section('dayCycle').sections('gifts')) DayGift.from(g)];

  static double _hours(DateTime t) => t.hour + t.minute / 60 + t.second / 3600;

  DayPhase phaseAt(DateTime t) {
    final h = _hours(t);
    if (h < dawn || h >= night) return DayPhase.night;
    if (h < day) return DayPhase.dawn;
    if (h < dusk) return DayPhase.day;
    return DayPhase.dusk;
  }

  /// Cuánta luz de día hay: 0 de noche, 1 de día, y sube o baja suave en el
  /// amanecer y el atardecer.
  double daylight(DateTime t) {
    final h = _hours(t);
    final v = switch (phaseAt(t)) {
      DayPhase.night => 0.0,
      DayPhase.dawn => (h - dawn) / (day - dawn),
      DayPhase.day => 1.0,
      DayPhase.dusk => (night - h) / (night - dusk),
    };
    return v * v * (3 - 2 * v);
  }

  /// Tono cálido del cielo: máximo a mitad del amanecer y del atardecer.
  double warmth(DateTime t) {
    final h = _hours(t);
    return switch (phaseAt(t)) {
      DayPhase.dawn => sin(pi * (h - dawn) / (day - dawn)),
      DayPhase.dusk => sin(pi * (h - dusk) / (night - dusk)),
      _ => 0.0,
    };
  }

  /// Recorrido del sol (de día) o de la luna (de noche) por el cielo, de 0 a 1.
  double arc(DateTime t) {
    final h = _hours(t);
    if (phaseAt(t) != DayPhase.night) return (h - dawn) / (night - dawn);
    final length = 24 - night + dawn;
    return ((h - night) % 24) / length;
  }

  /// Día del jardín: empieza al amanecer, así una noche que cruza la
  /// medianoche cuenta como una sola.
  int gardenDay(DateTime t) {
    final shifted = t.subtract(Duration(minutes: (dawn * 60).round()));
    return DateTime.utc(shifted.year, shifted.month, shifted.day).millisecondsSinceEpoch ~/ 86400000;
  }

  List<DayGift> giftsAt(DateTime t, Weather w, {bool afterRain = false}) => [
    for (final g in gifts)
      if (g.activeAt(phaseAt(t), w, afterRain: afterRain)) g,
  ];
}
