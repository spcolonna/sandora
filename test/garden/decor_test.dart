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
    p.lotus = 1000;
    return p;
  }

  test('el catálogo es válido: niveles en orden y monedas conocidas', () async {
    final p = await rich();
    final items = p.decorRules.items;
    expect(items.map((d) => d.id).toSet().length, items.length);
    for (var i = 1; i < items.length; i++) {
      expect(items[i].level, greaterThanOrEqualTo(items[i - 1].level), reason: items[i].id);
    }
    for (final d in items) {
      expect(d.level, greaterThanOrEqualTo(p.decorRules.minLevel));
      for (final k in d.cost.keys) {
        expect(() => p.walletOf(k), returnsNormally, reason: '${d.id}: $k');
      }
    }
  });

  test('comprar cobra, deja en la caja y la copia siguiente sale más cara', () async {
    final p = await rich();
    final d = p.decorRules.items.first;
    final first = p.decorCost(d);
    final before = p.pebbles;
    expect(p.buyDecor(d), isTrue);
    expect(p.pebbles, before - first['pebbles']!);
    expect(p.decorStored(d.id), 1);
    expect(p.decorOn(0), 0);
    expect(p.found, contains('decor.${d.id}'));
    expect(p.decorCost(d)['pebbles']!, greaterThan(first['pebbles']!));
    expect(p.decorCost(d)['pebbles']! % 5, 0);
  });

  test('sin el nivel o sin la plata no se compra', () async {
    final p = await rich(level: 3);
    final top = p.decorRules.items.last;
    expect(p.canBuyDecor(top), isFalse);
    expect(p.buyDecor(top), isFalse);
    final cheap = p.decorRules.items.first;
    p.pebbles = 0;
    expect(p.buyDecor(cheap), isFalse);
    expect(p.decor, isEmpty);
  });

  test('se pone, se mueve, se guarda y todo queda guardado', () async {
    final p = await rich();
    final d = p.decorRules.items[3];
    p.buyDecor(d);
    final i = p.placeDecor(d.id, 1, 0.3, 0.8)!;
    expect(p.decorStored(d.id), 0);
    expect(p.decorOn(1), 1);
    expect(p.placeDecor(d.id, 1, 0.5, 0.8), isNull, reason: 'no queda otra en la caja');
    p.moveDecor(i, 0.62, 0.9);
    await p.load(balance);
    expect(p.decor.single.side, 1);
    expect(p.decor.single.x, closeTo(0.62, 0.001));
    expect(p.decor.single.y, closeTo(0.9, 0.001));
    p.storeDecor(0);
    expect(p.decorStored(d.id), 1);
    expect(p.decorNew, isTrue, reason: 'hay algo en la caja');
  });

  test('cada vista tiene un límite', () async {
    final p = await rich();
    final d = p.decorRules.items.first;
    for (var i = 0; i <= p.decorRules.perSide; i++) {
      p.pebbles = 1 << 40;
      for (final e in p.essences.keys) {
        p.essences[e] = 1 << 30;
      }
      expect(p.buyDecor(d), isTrue);
    }
    for (var i = 0; i < p.decorRules.perSide; i++) {
      expect(p.placeDecor(d.id, 2, 0.5, 0.8), isNotNull);
    }
    expect(p.placeDecor(d.id, 2, 0.5, 0.8), isNull);
    expect(p.placeDecor(d.id, 0, 0.5, 0.8), isNotNull, reason: 'en otra vista sí entra');
  });

  test('las decoraciones son de cada jardín', () async {
    final p = await rich();
    final d = p.decorRules.items.first;
    p.buyDecor(d);
    p.placeDecor(d.id, 0, 0.4, 0.8);
    p.lotus = p.gardenCost;
    expect(await p.buyGarden(), isTrue);
    expect(p.decor, isEmpty);
    expect(p.decorCost(d), p.decorRules.cost(d, 0), reason: 'el precio vuelve a empezar en el jardín nuevo');
    await p.switchGarden(0);
    expect(p.decor.single.id, d.id);
    expect(p.decor.single.side, 0);
  });
}
