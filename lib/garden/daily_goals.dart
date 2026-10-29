import 'dart:math';

import '../balance/balance.dart';
import 'shop.dart';

/// Lo que cuenta para una meta del día.
enum DailyKind {
  /// Partidas terminadas.
  plays,

  /// Estrellas juntadas entre todas las partidas.
  stars,

  /// Partidas con 3 estrellas.
  three,

  /// Minijuegos distintos jugados.
  variety,

  /// Récords superados.
  record,

  /// Meditaciones que pagaron.
  meditate,

  /// Regalos juntados en el jardín.
  gift,

  /// Trueques en el Mercado.
  trade;

  /// Las que se cumplen jugando: siempre hay al menos una entre las del día.
  bool get fromRun => index <= DailyKind.record.index;
}

/// Una meta del día: llegar a [target] de [kind] y recibir [give].
class GoalDef {
  final String id;
  final DailyKind kind;
  final int target;
  final Map<String, int> give;

  const GoalDef(this.id, this.kind, this.target, this.give);

  factory GoalDef.from(BalanceSection s) {
    final give = s.nums('give').map((k, v) => MapEntry(k, v.round()));
    final bad = give.keys.where((k) => !walletKeys.contains(k));
    if (bad.isNotEmpty) throw FormatException('Moneda desconocida en ${s.s('id')}: $bad');
    return GoalDef(s.s('id'), DailyKind.values.byName(s.s('kind')), s.i('target'), give);
  }
}

/// Metas del día (sección `dailyGoals` del balance): cada día del jardín
/// salen [count] metas suaves del pool, siempre las mismas para ese día. Cada
/// una paga al cumplirse y las tres juntas dan [bonus]. No hay castigo por no
/// hacerlas: al día siguiente salen otras.
class DailyGoals {
  final int count;
  final List<GoalDef> pool;

  /// El regalo por cumplir todas las del día, con id `all`.
  final GoalDef bonus;

  DailyGoals._(this.count, this.pool, this.bonus);

  factory DailyGoals(Balance balance) {
    final s = balance.section('dailyGoals');
    final bonus = s.nums('bonus').map((k, v) => MapEntry(k, v.round()));
    final pool = [for (final g in s.sections('pool')) GoalDef.from(g)];
    final count = s.i('count');
    return DailyGoals._(count, pool, GoalDef('all', DailyKind.plays, count, bonus));
  }

  /// Las metas del día [day]: una que se cumple jugando y el resto de tipos
  /// distintos, elegidas con el día como semilla. Sin [canMeditate] no sale
  /// la de meditar (todavía no se puede cumplir).
  List<GoalDef> forDay(int day, {bool canMeditate = true}) {
    final rng = Random(day * 7919 + 17);
    final runs = pool.where((g) => g.kind.fromRun).toList()..shuffle(rng);
    final picked = [runs.first];
    final rest = pool.where((g) => g != runs.first && (canMeditate || g.kind != DailyKind.meditate)).toList()
      ..shuffle(rng);
    for (final g in rest) {
      if (picked.length >= count) break;
      if (picked.every((p) => p.kind != g.kind)) picked.add(g);
    }
    return picked;
  }
}
