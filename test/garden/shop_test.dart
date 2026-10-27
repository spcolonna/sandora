import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/economy.dart';
import 'package:sandora/garden/progress.dart';
import 'package:sandora/garden/shop.dart';

import '../helpers.dart';

void main() {
  final balance = loadBalance();
  final shop = ShopRules(balance);

  test('toda esencia que cuesta una ampliación se consigue jugando o en el Mercado', () {
    final fromGames = {
      for (final g in ['stack', 'sand', 'rain']) balance.rewards(g).s('essence'),
    };
    final fromShop = {for (final o in shop.offers) ...o.give.keys};
    for (final e in balance.expansions) {
      for (final c in e.nums('cost').keys.where((k) => k != 'pebbles')) {
        expect(fromGames.contains(c) || fromShop.contains(c) || c == 'light', isTrue, reason: '${e.s('id')}: $c');
      }
    }
    expect(fromShop, contains(Essence.wood.name));
  });

  group('Progress', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('la ofrenda del día da un loto una sola vez por día, y subir de nivel da otro', () async {
      final p = Progress.instance;
      final day = DateTime(2026, 10, 27, 10);
      await p.load(balance, now: day);
      expect(p.finishRun('rain', 3, now: day).lotus, shop.lotusDaily);
      final second = p.finishRun('sand', 2, now: day);
      expect(second.newLevel, 2);
      expect(second.lotus, shop.lotusPerLevel, reason: 'sin ofrenda: ya se dio hoy');
      expect(p.finishRun('rain', 0, now: day).lotus, 0);
      expect(p.finishRun('rain', 0, now: day.add(const Duration(days: 1))).lotus, shop.lotusDaily);
      await p.load(balance, now: day);
      expect(p.lotus, shop.lotusDaily * 2 + shop.lotusPerLevel);
    });

    test('un trueque cobra, paga y respeta el límite diario', () async {
      final p = Progress.instance;
      final day = DateTime(2026, 10, 27, 10);
      await p.load(balance, now: day);
      final wood = shop.offers.firstWhere((o) => o.id == 'wood_pebbles');
      p.pebbles = 10000;
      for (var i = 0; i < wood.daily!; i++) {
        expect(p.trade(wood, now: day), isTrue);
      }
      expect(p.shopLeft(wood, now: day), 0);
      expect(p.trade(wood, now: day), isFalse);
      expect(p.essences[Essence.wood], wood.give['wood']! * wood.daily!);
      expect(p.pebbles, 10000 - wood.cost['pebbles']! * wood.daily!);
      expect(p.shopLeft(wood, now: day.add(const Duration(days: 1))), wood.daily);
    });

    test('los trueques con lotos no tienen límite pero piden lotos', () async {
      final p = Progress.instance;
      await p.load(balance);
      final light = shop.offers.firstWhere((o) => o.id == 'light_lotus');
      expect(p.shopLeft(light), isNull);
      expect(p.trade(light), isFalse);
      p.lotus = 2;
      expect(p.trade(light), isTrue);
      expect(p.trade(light), isTrue);
      expect(p.lotus, 0);
      expect(p.essences[Essence.light], light.give['light']! * 2);
    });
  });
}
