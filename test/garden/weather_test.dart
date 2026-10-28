import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/day_cycle.dart';
import 'package:sandora/garden/progress.dart';
import 'package:sandora/garden/weather.dart';
import 'package:sandora/garden/weather_service.dart';

import '../helpers.dart';

void main() {
  final balance = loadBalance();
  final rules = WeatherRules(balance);
  final cycle = DayCycle(balance);
  DateTime at(double h, {int day = 27}) => DateTime(2026, 10, day).add(Duration(minutes: (h * 60).round()));

  test('el clima propio no cambia dentro de un mismo bloque', () {
    expect(rules.simulated(at(9)), rules.simulated(at(9.9)));
    expect(rules.simulated(at(9)), rules.simulated(at(11.9)), reason: 'bloque de 9 a 12');
  });

  test('el clima propio sigue las probabilidades del balance', () {
    final seen = <Weather, int>{};
    for (var d = 0; d < 400; d++) {
      for (var h = 0; h < 24; h += rules.blockHours) {
        final w = rules.simulated(DateTime(2026, 1, 1).add(Duration(days: d, hours: h)));
        seen[w] = (seen[w] ?? 0) + 1;
      }
    }
    final total = seen.values.fold(0, (a, b) => a + b);
    final odds = rules.odds.values.fold(0, (a, b) => a + b);
    for (final e in rules.odds.entries) {
      expect(seen[e.key]! / total, closeTo(e.value / odds, 0.04), reason: e.key.name);
    }
  });

  test('los símbolos de MET Norway se traducen al clima del jardín', () {
    expect(weatherFromSymbol('clearsky_day'), Weather.clear);
    expect(weatherFromSymbol('fair_night'), Weather.clear);
    expect(weatherFromSymbol('partlycloudy_day'), Weather.cloudy);
    expect(weatherFromSymbol('cloudy'), Weather.cloudy);
    expect(weatherFromSymbol('fog'), Weather.fog);
    expect(weatherFromSymbol('lightrainshowers_day'), Weather.rain);
    expect(weatherFromSymbol('heavyrainandthunder'), Weather.storm);
    expect(weatherFromSymbol('sleet'), Weather.snow);
    expect(weatherFromSymbol('snowshowers_polartwilight'), Weather.snow);
  });

  test('el pronóstico usa la próxima hora y si no hay, las 6 horas', () {
    Map<String, dynamic> forecast(Map<String, dynamic> data) => {
      'properties': {
        'timeseries': [
          {'time': '2026-10-28T12:00:00Z', 'data': data},
        ],
      },
    };
    expect(
      symbolFromForecast(
        forecast({
          'next_1_hours': {
            'summary': {'symbol_code': 'rain'},
          },
          'next_6_hours': {
            'summary': {'symbol_code': 'cloudy'},
          },
        }),
      ),
      'rain',
    );
    expect(
      symbolFromForecast(
        forecast({
          'next_6_hours': {
            'summary': {'symbol_code': 'cloudy'},
          },
        }),
      ),
      'cloudy',
    );
    expect(symbolFromForecast({}), isNull);
  });

  group('regalos del clima', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('la lluvia llena las vasijas a cualquier hora; con lluvia no hay luciérnagas', () async {
      final p = Progress.instance;
      await p.load(balance, now: at(12));
      final jar = cycle.gifts.firstWhere((g) => g.id == 'rainjar');
      final fireflies = cycle.gifts.firstWhere((g) => g.id == 'firefly');
      expect(p.giftsLeft(jar, weather: Weather.clear, now: at(12)), 0);
      expect(p.giftsLeft(jar, weather: Weather.rain, now: at(12)), jar.daily);
      expect(p.giftsLeft(jar, weather: Weather.storm, now: at(23)), jar.daily);
      expect(p.giftsLeft(fireflies, weather: Weather.rain, now: at(23)), 0);
      expect(cycle.giftsAt(at(23), Weather.rain).map((g) => g.id), ['rainjar']);
    });
  });
}
