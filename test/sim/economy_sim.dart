import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/balance/balance.dart';
import 'package:sandora/garden/daily_goals.dart';
import 'package:sandora/garden/levels.dart';
import 'package:sandora/garden/progress.dart';
import 'package:sandora/garden/weather.dart';
import 'package:sandora/minigames/catalog.dart';

/// Un tipo de jugador: a qué horas entra, cuánto juega y qué tan bien.
class Profile {
  final String name;

  /// Horas del día en que abre el jardín.
  final List<double> sessions;
  final int playsPerSession;

  /// Probabilidad de 0, 1, 2 y 3 estrellas.
  final List<double> stars;

  /// Minutos de meditación por día (0: no medita) y en qué sesión.
  final int meditate;
  final int meditateSession;

  /// Probabilidad de no entrar en todo el día.
  final double skip;

  const Profile(
    this.name, {
    required this.sessions,
    required this.playsPerSession,
    required this.stars,
    this.meditate = 0,
    this.meditateSession = 0,
    this.skip = 0,
  });

  static const casual = Profile(
    'Casual',
    sessions: [20.5],
    playsPerSession: 3,
    stars: [0.1, 0.3, 0.4, 0.2],
    skip: 0.25,
  );
  static const regular = Profile(
    'Regular',
    sessions: [8.5, 21],
    playsPerSession: 3,
    stars: [0.05, 0.2, 0.45, 0.3],
    meditate: 5,
    meditateSession: 1,
    skip: 0.1,
  );
  static const devoted = Profile(
    'Dedicado',
    sessions: [7.5, 13, 22],
    playsPerSession: 5,
    stars: [0.03, 0.12, 0.4, 0.45],
    meditate: 10,
  );
  static const all = [casual, regular, devoted];
}

/// Monedas: piedritas, lotos y esencias.
const wallet = ['pebbles', 'lotus', 'water', 'sand', 'wood', 'light'];

/// Lo que pasó en una corrida.
class SimResult {
  final Profile profile;
  final int days;

  /// Día (1 = el primero) en que se llegó a cada nivel.
  final Map<int, int> levelDay = {};

  /// Día en que se compró cada ampliación.
  final Map<String, int> boughtDay = {};

  /// Días en que el nivel ya alcanzaba para la próxima ampliación pero no la
  /// plata, y qué faltaba cada uno de esos días.
  final Map<String, Map<String, int>> blockedBy = {};

  /// Día en que alcanzaron los lotos y el nivel para un jardín nuevo.
  int? gardenDay;

  /// Lo ganado por fuente y moneda.
  final Map<String, Map<String, int>> income = {};

  /// Partidas por minijuego.
  final Map<String, int> plays = {};

  int lotusSpent = 0;

  /// Decoraciones compradas (día de la primera y total) y Piedritas gastadas en ellas.
  int? firstDecorDay;
  int decorBought = 0, decorPebbles = 0;
  late Map<String, int> end;
  late int level;

  SimResult(this.profile, this.days);

  void add(String source, Map<String, int> delta) {
    final m = income.putIfAbsent(source, () => {});
    for (final e in delta.entries) {
      if (e.value != 0) m[e.key] = (m[e.key] ?? 0) + e.value;
    }
  }
}

Map<String, int> _snap(Progress p) => {for (final k in wallet) k: p.walletOf(k)};

Map<String, int> _diff(Map<String, int> a, Map<String, int> b) => {for (final k in wallet) k: b[k]! - a[k]!};

Map<String, int> _sum(Iterable<GoalDef> goals) {
  final m = <String, int>{};
  for (final g in goals) {
    for (final e in g.give.entries) {
      m[e.key] = (m[e.key] ?? 0) + e.value;
    }
  }
  return m;
}

/// Juega [days] días como [profile], con el `Progress` y el balance reales.
Future<SimResult> simulate(Balance balance, Profile profile, {int days = 60, int seed = 1}) async {
  SharedPreferences.setMockInitialValues({});
  final rng = Random(seed);
  final start = DateTime(2026, 11, 2);
  final p = Progress.instance;
  await p.load(balance, now: start);
  final weather = WeatherRules(balance);
  final games = [for (final m in minigames) m.id];
  final r = SimResult(profile, days);
  final tower = <TowerStone>[];
  var lastLevel = p.level;

  // Saca de una acción lo que pagaron las metas, que se anota aparte.
  void book(String source, Map<String, int> before, List<GoalDef> goals) {
    final goal = _sum(goals);
    final delta = _diff(before, _snap(p));
    for (final e in goal.entries) {
      delta[e.key] = delta[e.key]! - e.value;
    }
    r.add(source, delta);
    r.add('metas', goal);
  }

  int stars() {
    var x = rng.nextDouble();
    for (var s = 0; s < 3; s++) {
      x -= profile.stars[s];
      if (x < 0) return s;
    }
    return 3;
  }

  /// La próxima ampliación que todavía no se tiene.
  Expansion? target() => p.levels.expansions.where((e) => e.ready && !p.expansions.contains(e.id)).firstOrNull;

  /// Trueques para lo que falta de la próxima ampliación, sin tocar lo que ya
  /// junta para ella. Los lotos solo se gastan si es lo único que falta.
  void shop(DateTime now, int day) {
    final e = target();
    if (e == null) return;
    final need = {'pebbles': e.pebbles, for (final c in e.essences.entries) c.key.name: c.value};
    for (final o in p.shop.offers) {
      final missing = p.missingFor(e);
      if (!o.give.keys.any(missing.containsKey)) continue;
      final usesLotus = o.cost.containsKey('lotus');
      if (usesLotus && (p.level < e.level || missing.keys.any((k) => !o.give.containsKey(k)))) continue;
      while (p.canTrade(o, now: now) &&
          p.missingFor(e).keys.any(o.give.containsKey) &&
          o.cost.entries.every((c) => p.walletOf(c.key) - c.value >= (usesLotus ? 0 : need[c.key] ?? 0))) {
        final before = _snap(p);
        p.trade(o, now: now);
        book('trueques', before, p.takePendingGoals());
        if (usesLotus) r.lotusSpent += o.cost['lotus']!;
      }
    }
  }

  /// Con lo que sobra después de guardar para la próxima ampliación, compra
  /// la decoración más barata que alcance, de a una por sesión.
  void decorate(int day) {
    final e = target();
    final keep = <String, int>{
      if (e != null) ...{'pebbles': e.pebbles, for (final c in e.essences.entries) c.key.name: c.value},
    };
    final options = [
      for (final d in p.decorRules.items)
        if (p.canBuyDecor(d) && p.decorCost(d).entries.every((c) => p.walletOf(c.key) - c.value >= (keep[c.key] ?? 0)))
          d,
    ]..sort((a, b) => p.decorCost(a)['pebbles']!.compareTo(p.decorCost(b)['pebbles']!));
    if (options.isEmpty) return;
    final d = options.first;
    final cost = p.decorCost(d)['pebbles']!;
    if (!p.buyDecor(d)) return;
    r.firstDecorDay ??= day + 1;
    r.decorBought++;
    r.decorPebbles += cost;
  }

  for (var day = 0; day < days; day++) {
    if (day > 0 && rng.nextDouble() < profile.skip) continue;
    for (final (si, hour) in profile.sessions.indexed) {
      final now = start.add(Duration(days: day, minutes: (hour * 60).round() + rng.nextInt(40)));
      p.countDay(now);

      var before = _snap(p);
      p.collectTower(now: now);
      r.add('torre', _diff(before, _snap(p)));

      before = _snap(p);
      p.takeVisit(now: now);
      book('té', before, p.takePendingGoals());

      final w = weather.simulated(now);
      final stop = weather.simulatedRainStop(now);
      final afterRain = stop != null && now.difference(stop) < weather.rainbowFor;
      for (final g in p.dayCycle.gifts) {
        while (p.giftsLeft(g, weather: w, afterRain: afterRain, now: now) > 0) {
          before = _snap(p);
          p.takeGift(g, weather: w, afterRain: afterRain, now: now);
          book('regalos', before, p.takePendingGoals());
        }
      }

      for (var i = 0; i < profile.playsPerSession; i++) {
        final open = games.where(p.gameUnlocked).toList()..shuffle(rng);
        open.sort((a, b) => (r.plays[a] ?? 0).compareTo(r.plays[b] ?? 0));
        // Prefiere lo menos jugado, con algo de azar entre los tres primeros.
        final game = open[rng.nextInt(min(3, open.length))];
        final s = stars();
        r.plays[game] = (r.plays[game] ?? 0) + 1;
        before = _snap(p);
        p.finishRun(game, s, record: s == 3 && rng.nextDouble() < 0.2, now: now);
        book('partidas', before, p.lastRunGoals);
        if (game == 'stack') {
          // Las estrellas son piedras netas de la bolsa; aparte, la torre
          // guardada a veces cede un tramo (≈ lossScale · altura^lossExponent).
          if (tower.isNotEmpty && rng.nextDouble() < 0.5) {
            final st = balance.stack;
            final loss = (st.d('lossScale') * pow(tower.length, st.d('lossExponent')) * (0.2 + 0.7 * rng.nextDouble()))
                .round();
            tower.removeRange(max(0, tower.length - loss), tower.length);
          }
          final add = [2, 4, 7, 10][s];
          for (var k = 0; k < add; k++) {
            tower.add((x: 0, w: 1, h: 0.5, kind: 0, tone: 0, seed: tower.length));
          }
          p.setTower([...tower], now: now);
        }
      }

      if (profile.meditate > 0 && si == profile.meditateSession && p.meditationUnlocked) {
        before = _snap(p);
        p.startMeditation(profile.meditate, now: now);
        p.finishMeditation(now: now.add(Duration(minutes: profile.meditate)));
        book('meditación', before, p.takePendingGoals());
      }

      shop(now, day);
      for (final e in p.levels.expansions) {
        if (p.buyExpansion(e)) r.boughtDay[e.id] = day + 1;
      }
      decorate(day);
      for (var l = lastLevel + 1; l <= p.level; l++) {
        r.levelDay[l] = day + 1;
      }
      lastLevel = p.level;
      if (r.gardenDay == null && p.level >= balance.section('gardens').i('minLevel')) {
        if (p.lotus >= balance.section('gardens').i('lotus')) r.gardenDay = day + 1;
      }
    }
    final e = target();
    if (e != null && p.level >= e.level) {
      final m = r.blockedBy.putIfAbsent(e.id, () => {});
      for (final k in p.missingFor(e).keys) {
        m[k] = (m[k] ?? 0) + 1;
      }
    }
  }
  r.end = _snap(p);
  r.level = p.level;
  return r;
}

/// El informe en texto, con la mediana de varias corridas por perfil.
String report(Balance balance, List<List<SimResult>> runs) {
  final b = StringBuffer();
  int? median(Iterable<int?> xs) {
    final v = xs.whereType<int>().toList()..sort();
    if (v.length * 2 <= xs.length) return null;
    return v[v.length ~/ 2];
  }

  String cell(int? d) => d == null ? '  —' : d.toString().padLeft(3);
  final ex = [for (final e in balance.expansions) (e.s('id'), e.i('level'))];
  final n = runs.first.length;
  final days = runs.first.first.days;
  b.writeln('Simulación de $days días, mediana de $n corridas por perfil (— = no llega).\n');
  b.writeln('Día en que se compra cada ampliación (nivel pedido):');
  b.writeln('${''.padRight(16)}${[for (final rs in runs) rs.first.profile.name.padLeft(10)].join()}');
  for (final (id, level) in ex) {
    b.writeln(
      '${'$id ($level)'.padRight(16)}${[for (final rs in runs) cell(median(rs.map((r) => r.boughtDay[id]))).padLeft(10)].join()}',
    );
  }
  b.writeln('\nDía en que se llega al nivel:');
  for (final l in [3, 5, 7, 8, 10, 12, 14, 16, 18, 20]) {
    b.writeln(
      '${'nivel $l'.padRight(16)}${[for (final rs in runs) cell(median(rs.map((r) => r.levelDay[l]))).padLeft(10)].join()}',
    );
  }
  b.writeln(
    '${'jardín nuevo'.padRight(16)}${[for (final rs in runs) cell(median(rs.map((r) => r.gardenDay))).padLeft(10)].join()}',
  );
  b.writeln(
    '${'1ª decoración'.padRight(16)}${[for (final rs in runs) cell(median(rs.map((r) => r.firstDecorDay))).padLeft(10)].join()}',
  );
  b.writeln(
    '${'decoraciones'.padRight(16)}${[for (final rs in runs) cell(median(rs.map((r) => r.decorBought))).padLeft(10)].join()}',
  );
  b.writeln(
    '${'nivel final'.padRight(16)}${[for (final rs in runs) cell(median(rs.map((r) => r.level))).padLeft(10)].join()}',
  );

  for (final rs in runs) {
    final r = rs.first;
    b.writeln('\n${r.profile.name} (corrida 1)');
    b.writeln('  Ganado por fuente:');
    for (final e in r.income.entries) {
      final parts = [
        for (final k in wallet)
          if ((e.value[k] ?? 0) != 0) '$k ${e.value[k]}',
      ];
      if (parts.isNotEmpty) b.writeln('    ${e.key.padRight(11)} ${parts.join(', ')}');
    }
    b.writeln(
      '  Al final: ${[for (final k in wallet) '$k ${r.end[k]}'].join(', ')}; lotos gastados ${r.lotusSpent}; '
      'en decoraciones ${r.decorPebbles} piedritas',
    );
    if (r.blockedBy.isNotEmpty) {
      b.writeln('  Días con el nivel pero sin la plata:');
      for (final e in r.blockedBy.entries) {
        b.writeln('    ${e.key.padRight(11)} ${[for (final m in e.value.entries) '${m.key} ${m.value}d'].join(', ')}');
      }
    }
    final total = r.plays.values.fold(0, (a, b) => a + b);
    b.writeln('  Partidas: $total (${[for (final e in r.plays.entries) '${e.key} ${e.value}'].join(', ')})');
  }
  return b.toString();
}
