import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zen_garden/garden/economy.dart';
import 'package:zen_garden/garden/levels.dart';
import 'package:zen_garden/garden/meditation_rules.dart';
import 'package:zen_garden/garden/progress.dart';

import '../helpers.dart';

void main() {
  final balance = loadBalance();
  final levels = LevelRules(balance);
  final med = MeditationRules(balance);

  test('curva de nivel: 60 para el 2, +40 % por nivel, con tope', () {
    expect(levels.calmToReach(1), 0);
    expect(levels.calmToReach(2), 60);
    expect(levels.calmToReach(3), 144);
    expect(levels.levelFor(0), 1);
    expect(levels.levelFor(143), 2);
    expect(levels.levelFor(144), 3);
    final step = balance.level.i('maxStep');
    expect(levels.calmToReach(31) - levels.calmToReach(30), step);
    expect(levels.progress(102), closeTo(0.5, 0.01));
  });

  test('ritmo: el nivel 5 llega entre el día 3 y el 4 (GDD)', () {
    // 2 o 3 sesiones por día de ~3 partidas con 1 o 2 estrellas.
    final perDay = 8 * levels.calmFor(1.5.round());
    final day = (levels.calmToReach(levels.meditationLevel) / perDay).ceil();
    expect(day, inInclusiveRange(2, 4));
  });

  test('cada ampliación pide nivel y tiene costo; los niveles suben', () {
    expect(levels.expansions, isNotEmpty);
    var last = 0;
    for (final e in levels.expansions.where((e) => e.zone)) {
      expect(e.level, greaterThan(last));
      last = e.level;
    }
    expect(levels.expansions.every((e) => e.pebbles > 0), isTrue);
    expect(levels.unlocksAt(levels.meditationLevel), contains('meditation'));
  });

  test('meditar: más tiempo, más puntos; cortar cobra por minuto; techo diario', () {
    final five = med.reward(5, 5, 0), twenty = med.reward(20, 20, 0);
    expect(five.complete, isTrue);
    expect(twenty.pebbles, greaterThan(five.pebbles * 4), reason: 'premia sesiones largas');
    final cut = med.reward(4, 10, 0);
    expect(cut.complete, isFalse);
    expect(cut.pebbles, lessThan(med.reward(5, 5, 0).pebbles));
    final capped = med.reward(10, 10, 15);
    expect(capped.capped, isTrue);
    expect(capped.minutes, 5);
    expect(med.reward(10, 10, 20).pebbles, 0);
  });

  test('racha de meditación: perdona un día por semana', () {
    var s = med.nextStreak(today: 100, lastDay: 99, streak: 3, graceDay: null);
    expect(s.streak, 4);
    s = med.nextStreak(today: 102, lastDay: 100, streak: 4, graceDay: null);
    expect((s.streak, s.graceDay), (5, 102));
    s = med.nextStreak(today: 105, lastDay: 103, streak: 6, graceDay: 102);
    expect(s.streak, 1, reason: 'el perdón ya se usó esta semana');
    expect(med.nextStreak(today: 110, lastDay: 100, streak: 9, graceDay: null).streak, 1);
  });

  group('Progress', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('las partidas dan Calma y suben de nivel', () async {
      final p = Progress.instance;
      final day = DateTime(2026, 10, 27, 10);
      await p.load(balance, now: day);
      expect(p.level, 1);
      final r1 = p.finishRun('rain', 3, now: day);
      expect(r1.calm, 40);
      expect(r1.newLevel, isNull);
      final r2 = p.finishRun('sand', 2, now: day);
      expect(r2.newLevel, 2);
    });

    test('el nombre del jardín se limpia, se recorta y se guarda', () async {
      final p = Progress.instance;
      await p.load(balance);
      expect(p.gardenName, isNull);
      p.renameGarden('  Jardín   de la   Bruma ');
      expect(p.gardenName, 'Jardín de la Bruma');
      p.renameGarden('x' * 40);
      expect(p.gardenName!.length, Progress.gardenNameMax);
      p.markGardenNameOffered();
      await p.load(balance);
      expect(p.gardenName, 'x' * Progress.gardenNameMax);
      expect(p.gardenNameOffered, isTrue);
      p.renameGarden('   ');
      expect(p.gardenName, isNull);
    });

    test('una ampliación necesita el nivel y los tokens', () async {
      final p = Progress.instance;
      final day = DateTime(2026, 10, 27, 10);
      await p.load(balance, now: day);
      final patio = p.levels.expansions.firstWhere((e) => e.id == 'patio1');
      p.pebbles = 1000;
      p.essences[Essence.sand] = 100;
      expect(p.canBuy(patio), isFalse, reason: 'nivel 1');
      p.calm = p.levels.calmToReach(patio.level);
      expect(p.buyExpansion(patio), isTrue);
      expect(p.patioSize, 1);
      expect(p.pebbles, 1000 - patio.pebbles);
      expect(p.buyExpansion(patio), isFalse, reason: 'ya está');
    });

    test('meditación con reloj real: se cobra al reabrir si terminó con la app cerrada', () async {
      final p = Progress.instance;
      final start = DateTime(2026, 10, 27, 8);
      await p.load(balance, now: start);
      p.startMeditation(10, now: start);
      await p.load(balance, now: start.add(const Duration(minutes: 30)));
      expect(p.meditationStartedAt, isNull);
      expect(p.essences[Essence.light], med.reward(10, 10, 0).light);
      expect(p.meditationMinutesLeft(now: start.add(const Duration(minutes: 31))), 10);
      expect(p.meditationStreak, 1);
    });
  });
}
