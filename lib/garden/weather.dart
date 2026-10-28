import '../balance/balance.dart';

/// Clima del jardín.
enum Weather { clear, cloudy, rain, storm, fog, snow }

/// Clima fijo para probar (`--dart-define=SANDORA_WEATHER=rain`); vacío en el juego.
const _weatherOverride = String.fromEnvironment('SANDORA_WEATHER');

Weather? get weatherOverride => Weather.values.asNameMap()[_weatherOverride];

/// Clima propio del jardín cuando no se usa el real: cambia cada [blockHours]
/// horas según [odds] y es el mismo para todos a la misma hora, así no se
/// "tira de nuevo" cerrando y abriendo la app.
class WeatherRules {
  final int blockHours;
  final Map<Weather, int> odds;
  final Duration refreshEvery, realMaxAge;

  WeatherRules(Balance balance)
    : blockHours = balance.section('weather').i('blockHours'),
      odds = balance.section('weather').nums('odds').map((k, v) => MapEntry(Weather.values.byName(k), v.round())),
      refreshEvery = Duration(minutes: balance.section('weather').i('refreshMinutes')),
      realMaxAge = Duration(minutes: balance.section('weather').i('realMaxAgeMinutes'));

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
