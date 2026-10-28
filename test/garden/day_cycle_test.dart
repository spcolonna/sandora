import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/day_cycle.dart';
import 'package:sandora/garden/economy.dart';
import 'package:sandora/garden/progress.dart';

import '../helpers.dart';

void main() {
  final balance = loadBalance();
  final cycle = DayCycle(balance);
  DateTime at(double h, {int day = 27}) => DateTime(2026, 10, day).add(Duration(minutes: (h * 60).round()));

  test('momentos del día según la hora', () {
    expect(cycle.phaseAt(at(3)), DayPhase.night);
    expect(cycle.phaseAt(at(cycle.dawn)), DayPhase.dawn);
    expect(cycle.phaseAt(at(12)), DayPhase.day);
    expect(cycle.phaseAt(at(cycle.dusk + 0.5)), DayPhase.dusk);
    expect(cycle.phaseAt(at(23)), DayPhase.night);
  });

  test('la luz cambia sin saltos entre momentos', () {
    expect(cycle.daylight(at(12)), 1);
    expect(cycle.daylight(at(2)), 0);
    for (var h = 0.0; h < 24; h += 0.05) {
      expect((cycle.daylight(at(h + 0.05)) - cycle.daylight(at(h))).abs(), lessThan(0.06), reason: 'hora $h');
    }
    expect(cycle.warmth(at(12)), 0);
    expect(cycle.warmth(at((cycle.dusk + cycle.night) / 2)), closeTo(1, 0.01));
  });

  test('una noche que cruza la medianoche es un solo día del jardín', () {
    expect(cycle.gardenDay(at(23)), cycle.gardenDay(at(2, day: 28)));
    expect(cycle.gardenDay(at(2, day: 28)), isNot(cycle.gardenDay(at(12, day: 28))));
  });

  group('Progress', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('las luciérnagas se juntan solo de noche y hasta el límite', () async {
      final p = Progress.instance;
      await p.load(balance, now: at(12));
      final fireflies = cycle.gifts.firstWhere((g) => g.id == 'firefly');
      expect(p.giftsLeft(fireflies, now: at(12)), 0, reason: 'de día no hay');
      expect(p.takeGift(fireflies, now: at(12)), isFalse);
      for (var i = 0; i < fireflies.daily; i++) {
        expect(p.takeGift(fireflies, now: at(23)), isTrue);
      }
      expect(p.takeGift(fireflies, now: at(1, day: 28)), isFalse, reason: 'la misma noche');
      expect(p.essences[Essence.light], fireflies.give['light']! * fireflies.daily);
      expect(p.giftsLeft(fireflies, now: at(23, day: 28)), fireflies.daily);
    });
  });
}
