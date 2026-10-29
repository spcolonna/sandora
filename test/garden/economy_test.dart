import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/economy.dart';
import 'package:sandora/garden/progress.dart';

import '../helpers.dart';

void main() {
  final balance = loadBalance();
  final eco = Economy(balance);

  test('más estrellas, más recompensa; repetir en el día rinde menos', () {
    final zero = eco.reward('rain', 0, 1);
    final three = eco.reward('rain', 3, 1);
    expect(three.pebbles, greaterThan(zero.pebbles));
    expect(three.essence, Essence.water);
    expect(zero.essenceAmount, 0);
    final tired = eco.reward('rain', 3, balance.repeats.i('fullRuns') + 1);
    expect(tired.tired, isTrue);
    expect(tired.pebbles, lessThan(three.pebbles));
    expect(tired.pebbles, greaterThan(0), reason: 'sin energía: siempre se gana algo');
  });

  test('regla de esencias: cada minijuego da la de su material', () {
    const rule = {
      'stack': Essence.sand,
      'sand': Essence.sand,
      'rain': Essence.water,
      'pond': Essence.water,
      'shishi': Essence.water,
      'leaves': Essence.wood,
      'moss': Essence.wood,
      'bonsai': Essence.wood,
      'enso': Essence.sand,
      'bell': Essence.light,
      'matcha': Essence.wood,
      'flute': Essence.wood,
      'lanterns': Essence.water,
    };
    for (final e in rule.entries) {
      expect(eco.essenceOf(e.key), e.value, reason: e.key);
    }
    // La Luz no sale de los minijuegos iniciales: la dan la meditación, los regalos y la Campana.
    final gifts = balance.section('dayCycle').sections('gifts');
    expect(gifts.any((g) => g.sub('give').has('light')), isTrue);
    expect(balance.meditation.sub('rewards').sub('3').i('light'), greaterThan(0));
  });

  test('la serenidad baja con los días pero nunca del piso', () {
    final max = balance.serenity.i('max');
    final floor = (max * balance.serenity.d('floor')).round();
    expect(eco.decayedSerenity(max, 1), lessThan(max));
    expect(eco.decayedSerenity(max, 365), floor);
    expect(eco.decayedSerenity(floor - 10, 5), floor - 10, reason: 'debajo del piso no baja más');
    expect(eco.serenityAfterPlay(max), max);
  });

  test('la torre junta por hora según su altura, con tope', () {
    expect(eco.towerYield(16, 1), (4 * balance.stack.d('pebblesPerHour')).floor());
    expect(eco.towerYield(10, 1000), eco.towerYield(10, balance.stack.d('maxHoursStored')));
    expect(eco.towerRate(500), lessThan(eco.towerRate(10) * 10), reason: 'rinde por la raíz de la altura');
  });

  test('una sesión de 3 minutos alcanza para algo visible (GDD)', () {
    // ~3 partidas de 1 estrella en minijuegos distintos.
    final total = ['stack', 'sand', 'rain'].map((g) => eco.reward(g, 1, 1).pebbles).reduce((a, b) => a + b);
    expect(total, greaterThanOrEqualTo(25));
  });

  group('Progress', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('paga, cuenta las partidas del día y guarda la torre', () async {
      final p = Progress.instance;
      final day = DateTime(2026, 10, 27, 10);
      await p.load(balance, now: day);
      final before = p.pebbles;
      final r = p.finishRun('sand', 2, now: day);
      expect(p.pebbles, before + r.pebbles);
      expect(p.essences[Essence.sand], greaterThan(0));
      p.setTower([
        (x: 0, w: 2, h: 0.6, kind: 0, tone: 0, seed: 1),
        (x: 0.1, w: 1.8, h: 0.5, kind: 1, tone: 2, seed: 2),
      ], now: day);
      expect(p.bestTower, 2);
      expect(p.towerPending(now: day.add(const Duration(hours: 3))), eco.towerYield(2, 3));
      final got = p.collectTower(now: day.add(const Duration(hours: 3)));
      expect(got, greaterThan(0));
      expect(p.towerPending(now: day.add(const Duration(hours: 3))), 0);
    });
  });
}
