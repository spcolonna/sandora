import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/daily_goals.dart';
import 'package:sandora/garden/day_cycle.dart';
import 'package:sandora/garden/progress.dart';

import '../helpers.dart';

void main() {
  final balance = loadBalance();
  final goals = DailyGoals(balance);
  final cycle = DayCycle(balance);

  /// El primer mediodía, desde el 27/10/2026, cuyas metas cumplen [test].
  DateTime dayWhere(bool Function(List<GoalDef>) test) {
    for (var i = 0; i < 400; i++) {
      final t = DateTime(2026, 10, 27, 12).add(Duration(days: i));
      if (test(goals.forDay(cycle.gardenDay(t)))) return t;
    }
    throw StateError('ningún día cumple');
  }

  test('cada día salen metas de tipos distintos, una se cumple jugando y se repiten ese día', () {
    for (var day = 20000; day < 20300; day++) {
      final today = goals.forDay(day);
      expect(today, hasLength(goals.count));
      expect(today.map((g) => g.kind).toSet(), hasLength(goals.count));
      expect(today.any((g) => g.kind.fromRun), isTrue);
      expect(goals.forDay(day).map((g) => g.id), today.map((g) => g.id));
    }
    // No son siempre las mismas.
    expect({for (var d = 0; d < 30; d++) goals.forDay(d).map((g) => g.id).join()}.length, greaterThan(5));
  });

  group('Progress', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('una meta paga una sola vez, se guarda y al otro día vuelve a cero', () async {
      final p = Progress.instance;
      final day = dayWhere((g) => g.any((g) => g.kind == DailyKind.plays));
      await p.load(balance, now: day);
      final goal = p.goalsToday(now: day).firstWhere((g) => g.kind == DailyKind.plays);
      for (var i = 1; i < goal.target; i++) {
        p.finishRun('stack', 0, now: day);
        expect(p.lastRunGoals.map((g) => g.id), isNot(contains(goal.id)));
      }
      final before = p.pebbles;
      final reward = p.finishRun('stack', 0, now: day);
      expect(p.lastRunGoals.map((g) => g.id), contains(goal.id));
      expect(p.pebbles - before, reward.pebbles + goal.give['pebbles']!);
      expect(p.goalDone(goal, now: day), isTrue);
      p.finishRun('stack', 0, now: day);
      expect(p.lastRunGoals.map((g) => g.id), isNot(contains(goal.id)));

      await p.load(balance, now: day);
      expect(p.goalDone(goal, now: day), isTrue);
      expect(p.goalProgress(goal, now: day), goal.target);
      final tomorrow = day.add(const Duration(days: 1));
      expect(p.goalDone(goal, now: tomorrow), isFalse);
      expect(p.goalsDone(now: tomorrow), 0);
    });

    test('cumplir todas las metas del día da el regalo de todas juntas', () async {
      final p = Progress.instance;
      final day = dayWhere((g) => g.every((g) => g.kind.fromRun));
      await p.load(balance, now: day);
      final done = <String>[];
      for (final game in ['stack', 'sand', 'rain']) {
        p.finishRun(game, 3, record: true, now: day);
        done.addAll(p.lastRunGoals.map((g) => g.id));
      }
      expect(done, containsAll(p.goalsToday(now: day).map((g) => g.id)));
      expect(done.last, 'all');
      expect(done.where((id) => id == 'all'), hasLength(1));
      expect(p.goalsDone(now: day), goals.count);
    });

    test('meditar, un trueque o un regalo cumplen su meta fuera de una partida', () async {
      final p = Progress.instance;
      final day = dayWhere((g) => g.any((g) => g.kind == DailyKind.trade));
      await p.load(balance, now: day);
      final offer = p.shop.offers.firstWhere((o) => o.cost.keys.single == 'pebbles');
      p.pebbles = offer.cost['pebbles']!;
      expect(p.trade(offer, now: day), isTrue);
      expect(p.takePendingGoals().map((g) => g.kind), contains(DailyKind.trade));
      expect(p.takePendingGoals(), isEmpty);
    });
  });
}
