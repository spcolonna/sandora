import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/economy.dart';
import 'package:sandora/garden/progress.dart';

import '../helpers.dart';

void main() {
  final balance = loadBalance();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<Progress> afterGuide(DateTime now) async {
    final p = Progress.instance;
    await p.load(balance, now: now);
    p.advanceGuide(Guide.done);
    return p;
  }

  test('el Arenero y las Piedras descansan 30 min después de jugarlos; la Lluvia no', () async {
    final t0 = DateTime(2026, 11, 7, 10);
    final p = await afterGuide(t0);
    p.finishRun('sand', 2, now: t0);
    p.finishRun('rain', 2, now: t0);
    expect(p.restLeft('sand', now: t0), const Duration(minutes: 30));
    expect(p.restLeft('stack', now: t0), Duration.zero);
    expect(p.restLeft('rain', now: t0), Duration.zero);
    expect(p.restLeft('sand', now: t0.add(const Duration(minutes: 29))), const Duration(minutes: 1));
    expect(p.restLeft('sand', now: t0.add(const Duration(minutes: 30))), Duration.zero);
    await p.load(balance, now: t0);
    expect(p.restLeft('sand', now: t0), const Duration(minutes: 30), reason: 'se guarda');
  });

  test('seguir ya cuesta un loto y sin lotos no se puede', () async {
    final t0 = DateTime(2026, 11, 7, 10);
    final p = await afterGuide(t0);
    p.finishRun('stack', 2, now: t0);
    p.lotus = 0;
    expect(p.skipRest('stack', now: t0), isFalse);
    p.lotus = 3;
    expect(p.skipRest('stack', now: t0), isTrue);
    expect(p.lotus, 3 - p.restSkipCost);
    expect(p.restLeft('stack', now: t0), Duration.zero);
    expect(p.skipRest('stack', now: t0), isFalse, reason: 'ya no descansa');
  });

  test('durante la guía del comienzo no hay descanso', () async {
    final t0 = DateTime(2026, 11, 7, 10);
    final p = Progress.instance;
    await p.load(balance, now: t0);
    p.finishRun('sand', 3, now: t0);
    expect(p.restLeft('sand', now: t0), Duration.zero);
  });

  test('los lugares que descansan no se cansan además', () {
    final eco = Economy(balance);
    final late = balance.repeats.i('fullRuns') + 1;
    expect(eco.reward('sand', 3, late).tired, isFalse);
    expect(eco.reward('stack', 3, late).tired, isFalse);
    expect(eco.reward('rain', 3, late).tired, isTrue);
  });
}
