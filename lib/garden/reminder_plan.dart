import '../balance/balance.dart';

/// Un aviso del jardín: cuándo y qué texto (clave de i18n y sus valores).
class Reminder {
  final DateTime at;
  final String key;
  final Map<String, Object> args;
  const Reminder(this.at, this.key, [this.args = const {}]);
}

/// Qué recordatorios programar, en Dart puro para poder probarlo.
///
/// Se reprograma cada vez que se abre la app: como ese día ya se entró al
/// jardín, el primero sale mañana. Así nunca llega el mismo día que se jugó y,
/// si se deja de entrar, los avisos siguen unos días y después callan.
class ReminderPlan {
  final BalanceSection b;
  ReminderPlan(this.b);

  int get defaultMinutes => b.i('hour') * 60 + b.i('minute');

  List<Reminder> plan({required DateTime now, required int minuteOfDay, int streak = 0, bool tower = false}) {
    final days = b.i('days');
    final pool = b.strings('pool');
    return [
      for (var k = 1; k <= days; k++)
        if (_message(k, pool, streak: streak, tower: tower) case (final key, final args))
          Reminder(DateTime(now.year, now.month, now.day + k, minuteOfDay ~/ 60, minuteOfDay % 60), key, args),
    ];
  }

  /// El primer día, lo más concreto (la racha o la torre); al tercero, que la
  /// serenidad baja; el resto, un texto tranquilo que va rotando.
  (String, Map<String, Object>) _message(int day, List<String> pool, {required int streak, required bool tower}) {
    if (day == 1 && streak > 0) return ('reminder.streak', {'n': streak});
    if (day <= 2 && tower) return ('reminder.tower', const {});
    if (day == 3) return ('reminder.serenity', const {});
    return (pool[day % pool.length], const {});
  }
}
