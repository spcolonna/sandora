import 'package:flutter_test/flutter_test.dart';
import 'package:sandora/garden/reminder_plan.dart';

import '../helpers.dart';

void main() {
  final rules = ReminderPlan(loadBalance().section('reminders'));

  test('recordatorios: desde mañana a la hora elegida, uno por día', () {
    final now = DateTime(2026, 10, 28, 8, 30);
    final plan = rules.plan(now: now, minuteOfDay: rules.defaultMinutes);
    expect(plan, hasLength(rules.b.i('days')));
    expect(plan.first.at, DateTime(2026, 10, 29, 19));
    for (final (i, r) in plan.indexed) {
      expect(r.at.day, DateTime(2026, 10, 29 + i).day, reason: 'nunca el mismo día que se abrió la app');
      expect(r.at.hour, 19);
    }
  });

  test('recordatorios: la hora elegida se respeta y cruza fin de mes', () {
    final plan = rules.plan(now: DateTime(2026, 10, 31, 23), minuteOfDay: 9 * 60 + 15);
    expect(plan.first.at, DateTime(2026, 11, 1, 9, 15));
  });

  test('recordatorios: primero la racha, después la torre, al tercer día la serenidad', () {
    final now = DateTime(2026, 10, 28);
    final plan = rules.plan(now: now, minuteOfDay: 600, streak: 4, tower: true);
    expect(plan[0].key, 'reminder.streak');
    expect(plan[0].args['n'], 4);
    expect(plan[1].key, 'reminder.tower');
    expect(plan[2].key, 'reminder.serenity');
    final calm = rules.plan(now: now, minuteOfDay: 600);
    expect(calm[0].key, startsWith('reminder.calm'));
    expect({for (final r in calm) r.key}.length, greaterThan(2), reason: 'el texto va rotando');
  });
}
