import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/progress.dart';

import '../helpers.dart';

void main() {
  final balance = loadBalance();
  final now = DateTime(2026, 10, 28, 12);

  test('el jardín de siempre pasa a ser el primero, sin perder nada', () async {
    SharedPreferences.setMockInitialValues({
      'gardenName': 'Kiri',
      'expansions': ['patio1'],
      'pebbles': 50,
    });
    final p = Progress.instance;
    await p.load(balance, now: now);
    expect(p.gardenCount, 1);
    expect(p.currentGarden, 0);
    expect(p.gardenName, 'Kiri');
    expect(p.expansions, {'patio1'});
  });

  test('un jardín nuevo cuesta lotos, empieza vacío y comparte las monedas', () async {
    SharedPreferences.setMockInitialValues({
      'gardenName': 'Kiri',
      'gardenNameOffered': true,
      'expansions': ['patio1'],
      'calm': 100000,
      'pebbles': 50,
      'lotus': 30,
    });
    final p = Progress.instance;
    await p.load(balance, now: now);
    expect(p.canBuyGarden, isTrue);
    expect(await p.buyGarden(now: now), isTrue);
    expect(p.gardenCount, 2);
    expect(p.currentGarden, 1);
    expect(p.gardenName, isNull);
    expect(p.gardenNameOffered, isFalse, reason: 'el jardín nuevo ofrece ponerle nombre');
    expect(p.expansions, isEmpty);
    expect(p.lotus, 30 - p.gardenCost);
    expect(p.pebbles, 50, reason: 'las monedas son de la cuenta');
    p.renameGarden('Musgo');
    expect(p.gardenNameAt(0), 'Kiri');

    await p.switchGarden(0, now: now);
    expect(p.gardenName, 'Kiri');
    expect(p.expansions, {'patio1'});
    expect(p.gardenNameAt(1), 'Musgo');
    await p.switchGarden(1, now: now);
    expect(p.gardenName, 'Musgo');
  });

  test('sin nivel o sin lotos no se compra', () async {
    SharedPreferences.setMockInitialValues({'lotus': 30});
    final p = Progress.instance;
    await p.load(balance, now: now);
    expect(p.canBuyGarden, isFalse);
    expect(await p.buyGarden(now: now), isFalse);
    expect(p.gardenCount, 1);
  });
}
