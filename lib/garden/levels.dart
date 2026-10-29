import 'dart:math';

import '../balance/balance.dart';
import 'economy.dart';

/// Una ampliación del jardín: agranda el patio o abre una zona nueva. El nivel
/// la habilita; se compra con tokens (GDD, Nivel del jardín).
class Expansion {
  final String id;
  final bool zone;
  final int level;
  final int pebbles;
  final Map<Essence, int> essences;

  /// false: todavía no está en el juego (se muestra como "próximamente").
  final bool ready;

  const Expansion(
    this.id, {
    required this.zone,
    required this.level,
    required this.pebbles,
    required this.essences,
    this.ready = true,
  });

  factory Expansion.from(BalanceSection s) {
    final cost = s.nums('cost');
    return Expansion(
      s.s('id'),
      zone: s.s('kind') == 'zone',
      level: s.i('level'),
      pebbles: (cost['pebbles'] ?? 0).round(),
      essences: {
        for (final e in Essence.values)
          if (cost.containsKey(e.name)) e: cost[e.name]!.round(),
      },
      ready: s.flag('ready', orElse: true),
    );
  }
}

enum GoalKind {
  /// Se puede comprar ya.
  buy,

  /// El nivel alcanza, faltan Piedritas o esencias.
  gather,

  /// Hay que subir de nivel.
  reach,
}

/// Lo próximo que se puede conseguir en el jardín: una ampliación o la
/// meditación ('meditation'), y el nivel que pide.
typedef Goal = ({GoalKind kind, String id, int level});

/// Nivel del jardín a partir de la Calma acumulada. Dart puro.
class LevelRules {
  final Balance balance;
  late final List<Expansion> expansions = [for (final e in balance.expansions) Expansion.from(e)];
  LevelRules(this.balance);

  BalanceSection get _l => balance.level;

  int calmFor(int stars) => _l.i('xpPerRun') + _l.i('xpPerStar') * stars;

  /// Calma total necesaria para llegar a [level] (el nivel 1 pide 0).
  int calmToReach(int level) {
    var total = 0.0;
    var step = _l.d('first');
    for (var n = 2; n <= level; n++) {
      total += min(step, _l.d('maxStep'));
      step *= _l.d('growth');
    }
    return total.round();
  }

  int levelFor(int calm) {
    var level = 1;
    while (calmToReach(level + 1) <= calm) {
      level++;
    }
    return level;
  }

  /// Avance dentro del nivel actual, de 0 a 1.
  double progress(int calm) {
    final l = levelFor(calm);
    final from = calmToReach(l), to = calmToReach(l + 1);
    return (calm - from) / (to - from);
  }

  int get meditationLevel => balance.meditation.i('unlockLevel');

  /// Lo que se destraba justo al llegar a [level]: ids de ampliaciones y
  /// 'meditation'.
  List<String> unlocksAt(int level) => [
    if (level == meditationLevel) 'meditation',
    for (final e in expansions)
      if (e.level == level) e.id,
  ];

  /// La meta que conviene mostrar: primero lo que ya se puede comprar, después
  /// lo que el nivel alcanza pero falta juntar, y si no, lo que abre el
  /// próximo nivel con algo nuevo.
  Goal? nextGoal(int calm, Set<String> owned, bool Function(Expansion) affordable) {
    final level = levelFor(calm);
    final open = [
      for (final e in expansions)
        if (e.ready && !owned.contains(e.id) && e.level <= level) e,
    ];
    final ready = open.where(affordable).firstOrNull;
    if (ready != null) return (kind: GoalKind.buy, id: ready.id, level: ready.level);
    if (open.isNotEmpty) return (kind: GoalKind.gather, id: open.first.id, level: open.first.level);
    final ahead = <(String, int)>[
      if (meditationLevel > level) ('meditation', meditationLevel),
      for (final e in expansions)
        if (e.ready && !owned.contains(e.id) && e.level > level) (e.id, e.level),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    if (ahead.isEmpty) return null;
    return (kind: GoalKind.reach, id: ahead.first.$1, level: ahead.first.$2);
  }
}
