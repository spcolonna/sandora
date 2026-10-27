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
}
