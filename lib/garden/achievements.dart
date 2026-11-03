import 'dart:async';

import '../minigames/sand/sand_shapes.dart';
import 'game_center.dart';
import 'progress.dart';

/// Un logro: cuánto lleva hecho la partida y cuánto pide.
class AchievementDef {
  final String id;
  final ({int value, int target}) Function(Progress p, Set<String> games) _measure;
  const AchievementDef(this.id, this._measure);

  ({int value, int target}) measure(Progress p, Set<String> games) => _measure(p, games);

  bool done(Progress p, Set<String> games) {
    final m = measure(p, games);
    return m.value >= m.target;
  }
}

int _placed(Progress p) => p.decor.where((d) => d.placed).length;
int _found(Progress p, String prefix) => p.found.where((f) => f.startsWith(prefix)).length;

/// Los logros salen de lo que la partida ya guarda (nada se anota aparte), así
/// que valen hacia atrás y viajan con la nube. Una vez conseguidos, quedan.
class Achievements {
  Achievements._();
  static final instance = Achievements._();

  /// En el orden en que suelen llegar.
  static final all = <AchievementDef>[
    AchievementDef('firstRun', (p, _) => (value: p.runsTotal, target: 1)),
    AchievementDef('threeStars', (p, _) => (value: p.threeTotal, target: 1)),
    AchievementDef('firstDecor', (p, _) => (value: _placed(p), target: 1)),
    AchievementDef('level5', (p, _) => (value: p.level, target: 5)),
    AchievementDef('patio', (p, _) => (value: p.patioSize, target: 1)),
    AchievementDef('days7', (p, _) => (value: p.daysPlayed, target: 7)),
    AchievementDef('tower', (p, _) => (value: p.bestTower, target: 15)),
    AchievementDef('meditate', (p, _) => (value: p.meditationStreak, target: 7)),
    AchievementDef('three50', (p, _) => (value: p.threeTotal, target: 50)),
    AchievementDef('level10', (p, _) => (value: p.level, target: 10)),
    AchievementDef('decor20', (p, _) => (value: _placed(p), target: 20)),
    AchievementDef(
      'upgradeMax',
      (p, _) => (value: p.upgrades.values.fold(0, (a, b) => a > b ? a : b), target: p.upgradeRules.maxTier),
    ),
    AchievementDef('shapes', (p, _) => (value: _found(p, 'shape.'), target: SandShape.values.length)),
    AchievementDef('gifts', (p, _) => (value: _found(p, 'gift.'), target: p.dayCycle.gifts.length)),
    AchievementDef('visitors', (p, _) => (value: _found(p, 'visitor.'), target: p.teaVisits.visitors.length)),
    AchievementDef('allGames', (p, g) => (value: p.gamesPlayed.intersection(g).length, target: g.length)),
    AchievementDef('days30', (p, _) => (value: p.daysPlayed, target: 30)),
    AchievementDef('level20', (p, _) => (value: p.level, target: 20)),
    AchievementDef('runs500', (p, _) => (value: p.runsTotal, target: 500)),
  ];

  /// Los ids de todos los minijuegos (para "probaste todos").
  Set<String> games = {};
  bool _started = false;

  ({int value, int target}) measure(AchievementDef a) => a.measure(Progress.instance, games);

  /// Lo que va de 0 a 1 hacia [a] (1 si ya se consiguió).
  double fraction(AchievementDef a) {
    if (Progress.instance.achievements.contains(a.id)) return 1;
    final m = measure(a);
    return m.target <= 0 ? 0 : (m.value / m.target).clamp(0.0, 1.0);
  }

  /// Empieza a mirar la partida: cada logro nuevo espera su aviso grande y se
  /// manda a Game Center.
  void start(Iterable<String> games) {
    this.games = games.toSet();
    if (_started) return;
    _started = true;
    Progress.instance.addListener(check);
    check();
    GameCenter.instance.signedIn.addListener(_reportAll);
  }

  /// Los logros conseguidos ahora. Los que ya estaban hechos la primera vez
  /// (partidas de antes de que hubiera logros) se guardan sin aviso.
  List<String> check() {
    final p = Progress.instance;
    final fresh = [
      for (final a in all)
        if (!p.achievements.contains(a.id) && a.done(p, games)) a.id,
    ];
    if (fresh.isEmpty && p.achievementsStarted) return fresh;
    final announce = p.achievementsStarted;
    // Se guarda después de esta vuelta de avisos (para no avisar adentro de otro aviso).
    scheduleMicrotask(() => p.addAchievements(fresh, announce: announce));
    if (fresh.isNotEmpty) GameCenter.instance.report({for (final id in fresh) id: 100});
    return fresh;
  }

  /// Al entrar a Game Center se manda todo lo que va (no baja lo que ya hay).
  void _reportAll() {
    if (!GameCenter.instance.signedIn.value) return;
    GameCenter.instance.report({
      for (final a in all)
        if (fraction(a) > 0) a.id: fraction(a) * 100,
    });
  }
}
