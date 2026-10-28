import '../balance/balance.dart';

/// Clima del jardín.
enum Weather { clear, cloudy, rain, storm, fog, snow }

/// Clima fijo para probar (`--dart-define=SANDORA_WEATHER=rain`); vacío en el juego.
const _weatherOverride = String.fromEnvironment('SANDORA_WEATHER');

Weather? get weatherOverride => Weather.values.asNameMap()[_weatherOverride];

/// Para probar el arcoíris y los charcos: `--dart-define=SANDORA_AFTER_RAIN=20`
/// hace como si la lluvia hubiera parado hace 20 minutos.
const afterRainOverride = int.fromEnvironment('SANDORA_AFTER_RAIN');

extension WeatherWet on Weather {
  bool get wet => this == Weather.rain || this == Weather.storm;
}

/// Clima propio del jardín cuando no se usa el real: cambia cada [blockHours]
/// horas según [odds] y es el mismo para todos a la misma hora, así no se
/// "tira de nuevo" cerrando y abriendo la app.
class WeatherRules {
  final int blockHours;
  final Map<Weather, int> odds;
  final Duration refreshEvery, realMaxAge;

  /// Después de la lluvia: cuánto dura el arcoíris y cuánto tardan en secarse
  /// los charcos.
  final Duration rainbowFor, puddlesFor;
  final double windChance;

  WeatherRules(Balance balance)
    : blockHours = balance.section('weather').i('blockHours'),
      odds = balance.section('weather').nums('odds').map((k, v) => MapEntry(Weather.values.byName(k), v.round())),
      refreshEvery = Duration(minutes: balance.section('weather').i('refreshMinutes')),
      realMaxAge = Duration(minutes: balance.section('weather').i('realMaxAgeMinutes')),
      rainbowFor = Duration(minutes: balance.section('weather').i('rainbowMinutes')),
      puddlesFor = Duration(minutes: balance.section('weather').i('puddleMinutes')),
      windChance = balance.section('weather').d('windChance');

  /// Cuánta agua queda en el suelo (1 lloviendo o recién parado, 0 seco).
  double wetness(Weather w, DateTime now, DateTime? stoppedAt) {
    if (w.wet) return 1;
    if (stoppedAt == null) return 0;
    final k = now.difference(stoppedAt).inSeconds / puddlesFor.inSeconds;
    return (1 - k).clamp(0.0, 1.0);
  }

  /// Si en este bloque sopla viento con hojas (solo despejado o nublado).
  bool windy(Weather w, DateTime t) {
    if (w != Weather.clear && w != Weather.cloudy) return false;
    final block = blockStart(t).millisecondsSinceEpoch ~/ 3600000;
    return (_hash(block * 31 + 7) % 1000) / 1000 < windChance;
  }

  /// Comienzo del bloque de clima de [t] (hora local).
  DateTime blockStart(DateTime t) {
    final local = DateTime.utc(t.year, t.month, t.day, t.hour);
    final span = 3600000 * blockHours;
    final u = DateTime.fromMillisecondsSinceEpoch(local.millisecondsSinceEpoch ~/ span * span, isUtc: true);
    return DateTime(u.year, u.month, u.day, u.hour);
  }

  /// Si en el clima propio la lluvia paró al empezar el bloque de [t]: el
  /// comienzo de ese bloque; si no, null.
  DateTime? simulatedRainStop(DateTime t) {
    final start = blockStart(t);
    if (simulated(t).wet) return null;
    return simulated(start.subtract(const Duration(minutes: 30))).wet ? start : null;
  }

  Weather simulated(DateTime t) {
    final local = DateTime.utc(t.year, t.month, t.day, t.hour);
    final block = local.millisecondsSinceEpoch ~/ (3600000 * blockHours);
    final total = odds.values.fold(0, (a, b) => a + b);
    var roll = _hash(block) % total;
    for (final e in odds.entries) {
      if (roll < e.value) return e.key;
      roll -= e.value;
    }
    return Weather.clear;
  }

  /// Mezcla entera estable (no depende de la plataforma, como Random(seed)).
  static int _hash(int x) {
    var h = (x * 0x9E3779B1) & 0xFFFFFFFF;
    h = ((h ^ (h >> 15)) * 0x85EBCA77) & 0xFFFFFFFF;
    h = ((h ^ (h >> 13)) * 0xC2B2AE3D) & 0xFFFFFFFF;
    return h ^ (h >> 16);
  }
}

/// Traduce el símbolo del pronóstico de MET Norway (`partlycloudy_day`,
/// `heavyrainandthunder`, ...) al clima del jardín.
Weather weatherFromSymbol(String code) {
  final c = code.split('_').first;
  if (c.contains('thunder')) return Weather.storm;
  if (c.contains('snow') || c.contains('sleet')) return Weather.snow;
  if (c.contains('rain')) return Weather.rain;
  if (c == 'fog') return Weather.fog;
  if (c == 'cloudy' || c == 'partlycloudy') return Weather.cloudy;
  return Weather.clear;
}
