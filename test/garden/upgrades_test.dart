import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/progress.dart';

import '../helpers.dart';

void main() {
  final balance = loadBalance();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<Progress> rich({int level = 20}) async {
    final p = Progress.instance;
    await p.load(balance);
    p.calm = p.levels.calmToReach(level);
    p.pebbles = 100000;
    for (final e in p.essences.keys) {
      p.essences[e] = 10000;
    }
    return p;
  }

  test('los niveles van en orden, más caros y con más bonus', () async {
    final p = await rich();
    final tiers = p.upgradeRules.tiers;
    for (var i = 1; i < tiers.length; i++) {
      expect(tiers[i].level, greaterThan(tiers[i - 1].level));
      expect(tiers[i].pebbles, greaterThan(tiers[i - 1].pebbles));
      expect(tiers[i].bonus, greaterThan(tiers[i - 1].bonus));
    }
    for (final g in p.upgradeRules.places) {
      expect(() => p.economy.essenceOf(g), returnsNormally, reason: g);
    }
  });

  test('mejorar cobra la esencia del lugar, sube de a uno y llega al máximo', () async {
    final p = await rich();
    final cost = p.upgradeCost('sand');
    final pebbles = p.pebbles, sand = p.walletOf('sand');
    expect(p.buyUpgrade('sand'), isTrue);
    expect(p.upgradeTier('sand'), 1);
    expect(p.pebbles, pebbles - cost['pebbles']!);
    expect(p.walletOf('sand'), sand - cost['sand']!);
    while (p.buyUpgrade('sand')) {}
    expect(p.upgradeTier('sand'), p.upgradeRules.maxTier);
    expect(p.upgradeCost('sand'), isEmpty);
    await p.load(balance);
    expect(p.upgradeTier('sand'), p.upgradeRules.maxTier, reason: 'queda guardado');
  });

  test('pide el nivel y el minijuego destrabado', () async {
    final p = await rich(level: 2);
    expect(p.canUpgrade('sand'), isFalse, reason: 'falta nivel');
    p.calm = p.levels.calmToReach(20);
    expect(p.canUpgrade('pond'), isFalse, reason: 'el estanque se abre con su ampliación');
  });

  test('un lugar mejorado da más Piedritas', () async {
    final p = await rich();
    final plain = p.finishRun('stack', 3).pebbles;
    final p2 = await rich();
    p2.buyUpgrade('stack');
    p2.buyUpgrade('stack');
    final better = p2.finishRun('stack', 3).pebbles;
    expect(better, (plain * (1 + p2.upgradeRules.bonus(2))).round());
  });
}
