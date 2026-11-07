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

  test('se pone en una parcela, se mueve, se guarda y todo queda guardado', () async {
    final p = await rich();
    final d = p.decorRules.items[3];
    p.buyDecor(d);
    final i = p.placeDecor(d.id, 1, 5)!;
    expect(p.decorStored(d.id), 0);
    expect(p.decorOn(1), 1);
    expect(p.decorAt(1, 5), i);
    expect(p.placeDecor(d.id, 1, 6), isNull, reason: 'no queda otra en la caja');
    expect(p.moveDecor(i, 10), isTrue);
    await p.load(balance);
    expect(p.decor.single.side, 1);
    expect(p.decor.single.cell, 10);
    final (x, y) = p.modelRules.foot(1, 10);
    expect(p.decor.single.x, closeTo(x, 0.001));
    expect(p.decor.single.y, closeTo(y, 0.001));
    p.storeDecor(0);
    expect(p.decorStored(d.id), 1);
    expect(p.decor.single.cell, isNull);
    expect(p.decorNew, isTrue, reason: 'hay algo en la caja');
  });

  test('las decoraciones son de cada jardín', () async {
    final p = await rich();
    final d = p.decorRules.items.first;
    p.buyDecor(d);
    p.placeDecor(d.id, 0, 5);
    p.lotus = p.gardenCost;
    expect(await p.buyGarden(), isTrue);
    expect(p.decor, isEmpty);
    expect(p.decorCost(d), p.decorRules.cost(d, 0), reason: 'el precio vuelve a empezar en el jardín nuevo');
    await p.switchGarden(0);
    expect(p.decor.single.id, d.id);
    expect(p.decor.single.side, 0);
  });

  test('oferta del día: fija en el día, con descuento, una sola vez y cambia mañana', () async {
    final p = await rich(level: 6);
    final day1 = DateTime.now();
    final d = p.dealToday(now: day1)!;
    expect(d.level, lessThanOrEqualTo(6));
    expect(p.dealCost(d)['pebbles']!, lessThan(p.decorCost(d)['pebbles']!));
    expect(p.dealNew, isTrue);
    p.markDealSeen();
    expect(p.dealNew, isFalse);
    p.calm = p.levels.calmToReach(20);
    expect(p.dealToday(now: day1)!.id, d.id, reason: 'subir de nivel no la cambia');
    final before = p.pebbles;
    final price = p.dealCost(d)['pebbles']!;
    expect(p.buyDeal(now: day1), isTrue);
    expect(p.pebbles, before - price);
    expect(p.decorStored(d.id), 1);
    expect(p.buyDeal(now: day1), isFalse, reason: 'una sola vez');
    await p.load(balance);
    p.calm = p.levels.calmToReach(20); // la Calma del test no se guardó
    expect(p.dealTaken(now: day1), isTrue);
    final ids = {for (var i = 1; i <= 10; i++) p.dealToday(now: day1.add(Duration(days: i)))!.id};
    expect(p.dealTaken(now: day1.add(const Duration(days: 11))), isFalse);
    expect(ids.length, greaterThan(1), reason: 'cambia de un día a otro');
  });

  test('sin el nivel de decorar no hay oferta', () async {
    final p = await rich(level: 1);
    expect(p.dealToday(), isNull);
    expect(p.dealNew, isFalse);
    expect(p.buyDeal(), isFalse);
  });

  test('al llegar al nivel de decorar se regala una decoración, una sola vez', () async {
    final p = Progress.instance;
    await p.load(balance);
    p.calm = p.levels.calmToReach(p.decorRules.minLevel) - 1;
    expect(p.decor, isEmpty);
    while (!p.decorUnlocked) {
      p.finishRun('stack', 3);
    }
    expect(p.decor.single.id, p.decorRules.welcomeGift);
    expect(p.decor.single.placed, isFalse, reason: 'queda en la caja');
    p.finishRun('stack', 3);
    await p.load(balance);
    expect(p.decor.length, 1, reason: 'no se repite');
  });

  test('el Mercado ofrece decoraciones destrabadas, sin la oferta, fijas en el día', () async {
    final p = await rich(level: 8);
    final day = DateTime.now();
    final list = p.marketDecor(now: day);
    expect(list.length, p.decorRules.marketCount);
    expect(list.map((d) => d.id).toSet().length, list.length);
    expect(list.every((d) => d.level <= 8), isTrue);
    expect(list, isNot(contains(p.dealToday(now: day))));
    expect(p.marketDecor(now: day).map((d) => d.id), list.map((d) => d.id));
  });
}
