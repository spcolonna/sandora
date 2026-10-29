import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../balance/balance.dart';
import '../minigames/sand/sand_shapes.dart';
import 'daily_goals.dart';
import 'day_cycle.dart';
import 'economy.dart';
import 'levels.dart';
import 'meditation_rules.dart';
import 'shop.dart';
import 'weather.dart';

/// Una piedra de la torre guardada en el jardín (unidades del mundo del
/// minijuego: centro x relativo a la base, ancho y alto).
/// Una piedra de la torre: centro, tamaño y cómo se ve (tipo, tono y semilla
/// de `StoneShape`).
typedef TowerStone = ({double x, double w, double h, int kind, int tone, int seed});

/// Progreso del jugador: monedas, serenidad y lo que quedó en el jardín.
/// Singleton sobre SharedPreferences; todo se guarda al momento, así cerrar
/// la app nunca hace perder lo ganado.
class Progress extends ChangeNotifier {
  Progress._();
  static final instance = Progress._();

  late SharedPreferences _prefs;
  late Economy economy;
  late LevelRules levels;
  late MeditationRules meditationRules;
  late ShopRules shop;
  late DayCycle dayCycle;
  late DailyGoals dailyGoals;

  int pebbles = 0;
  final essences = {for (final e in Essence.values) e: 0};
  int serenity = 0;

  /// Lotos: moneda escasa que se gana por constancia y se usa en el Mercado.
  int lotus = 0;
  int _lotusDay = -1;

  /// Trueques del Mercado hechos hoy, por oferta (para el límite diario).
  int _shopDay = 0;
  Map<String, int> _shopBought = {};

  /// Regalos del momento del día juntados hoy (día del jardín), por id.
  int _giftDay = 0;
  Map<String, int> _giftsTaken = {};

  /// Metas del día (día del jardín): cuánto se juntó de cada [DailyKind], qué
  /// juegos se jugaron (para la variedad) y qué metas ya se pagaron.
  int _goalsDay = -1;
  Map<String, int> _goalCounts = {};
  Set<String> _goalGames = {};
  Set<String> _goalsPaid = {};

  /// Metas cumplidas en la última partida, para festejarlas en el resultado.
  List<GoalDef> lastRunGoals = [];

  /// Metas cumplidas fuera de una partida (meditar, el Mercado, un regalo):
  /// el jardín las anuncia con [takePendingGoals].
  final _pendingGoals = <GoalDef>[];

  List<TowerStone> tower = [];
  int bestTower = 0;
  DateTime? towerCollectedAt;

  /// Último dibujo del arenero: puntos normalizados 0..1, x e y alternados.
  List<double> sandDrawing = [];
  int sandFigures = 0;
  SandShape? sandLastShape;
  int rainBest = 0;

  /// Nombre que el jugador le puso a su jardín; null hasta que lo elige.
  String? gardenName;

  /// Si ya se le ofreció ponerle nombre (se ofrece una sola vez al empezar).
  bool gardenNameOffered = false;

  /// Calma acumulada (experiencia): define el nivel del jardín.
  int calm = 0;
  Set<String> expansions = {};

  /// Sesión de meditación en curso (reloj real), o null.
  DateTime? meditationStartedAt;
  int meditationChosen = 0;
  int meditationStreak = 0;
  int? _meditationLastDay, _meditationGraceDay;
  int _meditationDay = 0, _meditationMinutesToday = 0;

  /// Objetos ganados con la racha de meditación, en el orden en que llegan
  /// (cuenco, cojín, farol). Son de la cuenta: se ven en todos los jardines.
  List<String> streakObjects = [];

  String _playsDay = '';
  Map<String, int> _plays = {};

  /// Días distintos en que se abrió el jardín: destraban minijuegos (GDD).
  int daysPlayed = 0;
  int _lastDay = -1;
  late Map<String, num> _unlockDays;

  /// Minijuegos que abre una zona con otro id (Ensō abre la caligrafía).
  Map<String, String> _zoneOf = {};

  /// Minijuegos destrabados que ya se anunciaron en el jardín.
  Set<String> unlocksSeen = {};

  /// Primera partida guiada: 0 = señalar un lugar para jugar, 1 = después de
  /// la primera partida, señalar el nivel y el Mercado, 2 = terminada.
  int guideStep = 0;

  /// Minijuegos cuya tarjeta de cómo se juega ya se vio.
  Set<String> introSeen = {};

  late Balance _balance;

  // --- Varios jardines -------------------------------------------------
  //
  // El jardín actual vive en las claves de siempre; los demás, guardados
  // aparte como una foto de esas claves. Cambiar de jardín guarda la foto del
  // actual y pone la del elegido. Monedas, nivel, meditación y récords son de
  // la cuenta y no cambian.

  static const _gardenKeys = [
    'tower',
    'towerCollectedAt',
    'sandDrawing',
    'sandLastShape',
    'gardenName',
    'gardenNameOffered',
    'expansions',
    'serenity',
    'serenityAt',
  ];

  /// Fotos de cada jardín (la del actual puede estar vieja: manda lo vivo).
  List<Map<String, dynamic>> _gardens = [{}];
  int currentGarden = 0;

  int get gardenCount => _gardens.length;

  /// Nombre de cada jardín, para elegir entre ellos.
  String? gardenNameAt(int i) => i == currentGarden ? gardenName : _gardens[i]['gardenName'] as String?;

  int get gardenCost => _balance.section('gardens').i('lotus');
  int get gardenMinLevel => _balance.section('gardens').i('minLevel');
  int get gardenMax => _balance.section('gardens').i('max');
  bool get canBuyGarden => level >= gardenMinLevel && lotus >= gardenCost && gardenCount < gardenMax;

  Map<String, dynamic> _snapshot() => {for (final k in _gardenKeys) k: ?_prefs.get(k)};

  Future<void> _restore(Map<String, dynamic> snap) async {
    for (final k in _gardenKeys) {
      final v = snap[k];
      switch (v) {
        case null:
          await _prefs.remove(k);
        case int():
          await _prefs.setInt(k, v);
        case double():
          await _prefs.setDouble(k, v);
        case bool():
          await _prefs.setBool(k, v);
        case String():
          await _prefs.setString(k, v);
        case List():
          await _prefs.setStringList(k, [for (final e in v) e as String]);
      }
    }
  }

  Future<void> _saveGardens() async {
    await _prefs.setString('gardens', jsonEncode(_gardens));
    await _prefs.setInt('garden.current', currentGarden);
  }

  /// Pasa al jardín [i]: guarda el actual y carga el elegido.
  Future<void> switchGarden(int i, {DateTime? now}) async {
    if (i == currentGarden || i < 0 || i >= _gardens.length) return;
    _gardens[currentGarden] = _snapshot();
    await _restore(_gardens[i]);
    currentGarden = i;
    await _saveGardens();
    await load(_balance, now: now);
    notifyListeners();
  }

  /// Compra un jardín nuevo con lotos y pasa a él (empieza vacío).
  Future<bool> buyGarden({DateTime? now}) async {
    if (!canBuyGarden) return false;
    lotus -= gardenCost;
    _saveWallet();
    _gardens[currentGarden] = _snapshot();
    _gardens.add({});
    await _saveGardens();
    await switchGarden(_gardens.length - 1, now: now);
    return true;
  }

  Future<void> load(Balance balance, {DateTime? now}) async {
    _balance = balance;
    economy = Economy(balance);
    levels = LevelRules(balance);
    meditationRules = MeditationRules(balance);
    shop = ShopRules(balance);
    dayCycle = DayCycle(balance);
    dailyGoals = DailyGoals(balance);
    _unlockDays = balance.section('unlocks').nums('days');
    final unlocks = balance.section('unlocks');
    _zoneOf = unlocks.has('zones') ? unlocks.sub('zones').stringMap() : {};
    _prefs = await SharedPreferences.getInstance();
    now ??= DateTime.now();
    // Si nunca hubo varios jardines, el de siempre es el primero.
    _gardens = [
      for (final g in jsonDecode(_prefs.getString('gardens') ?? '[{}]') as List) (g as Map).cast<String, dynamic>(),
    ];
    currentGarden = (_prefs.getInt('garden.current') ?? 0).clamp(0, _gardens.length - 1);
    pebbles = _prefs.getInt('pebbles') ?? 0;
    for (final e in Essence.values) {
      essences[e] = _prefs.getInt('essence.${e.name}') ?? 0;
    }
    final start = balance.serenity.i('start');
    final savedAt = _prefs.getInt('serenityAt');
    serenity = _prefs.getInt('serenity') ?? start;
    if (savedAt != null) {
      final days = now.difference(DateTime.fromMillisecondsSinceEpoch(savedAt)).inMinutes / (60 * 24);
      serenity = economy.decayedSerenity(serenity, days);
    }
    final saved = jsonDecode(_prefs.getString('tower') ?? '[]') as List;
    tower = [
      for (var i = 0; i < saved.length; i++)
        (
          x: (saved[i][0] as num).toDouble(),
          w: (saved[i][1] as num).toDouble(),
          h: (saved[i][2] as num).toDouble(),
          // Las torres guardadas antes de los tipos de piedra solo tenían x, w y h.
          kind: saved[i].length > 3 ? saved[i][3] as int : 0,
          tone: saved[i].length > 3 ? saved[i][4] as int : i % 3,
          seed: saved[i].length > 3 ? saved[i][5] as int : i * 7919,
        ),
    ];
    bestTower = _prefs.getInt('bestTower') ?? 0;
    final collected = _prefs.getInt('towerCollectedAt');
    towerCollectedAt = collected == null ? null : DateTime.fromMillisecondsSinceEpoch(collected);
    sandDrawing = [for (final v in jsonDecode(_prefs.getString('sandDrawing') ?? '[]') as List) (v as num).toDouble()];
    sandFigures = _prefs.getInt('sandFigures') ?? 0;
    final lastShape = _prefs.getInt('sandLastShape');
    sandLastShape = lastShape == null ? null : SandShape.values[lastShape];
    rainBest = _prefs.getInt('rainBest') ?? 0;
    _playsDay = _prefs.getString('playsDay') ?? '';
    _plays = (jsonDecode(_prefs.getString('plays') ?? '{}') as Map).map((k, v) => MapEntry(k as String, v as int));
    gardenName = _prefs.getString('gardenName');
    gardenNameOffered = _prefs.getBool('gardenNameOffered') ?? false;
    introSeen = (_prefs.getStringList('intro.seen') ?? []).toSet();
    calm = _prefs.getInt('calm') ?? 0;
    // Quien ya jugaba antes de la guía no la ve.
    guideStep = _prefs.getInt('guide.step') ?? (calm > 0 ? 2 : 0);
    expansions = (_prefs.getStringList('expansions') ?? []).toSet();
    lotus = _prefs.getInt('lotus') ?? 0;
    _lotusDay = _prefs.getInt('lotus.day') ?? -1;
    _shopDay = _prefs.getInt('shop.day') ?? 0;
    _shopBought = (jsonDecode(_prefs.getString('shop.bought') ?? '{}') as Map).map(
      (k, v) => MapEntry(k as String, v as int),
    );
    _giftDay = _prefs.getInt('gift.day') ?? 0;
    _giftsTaken = (jsonDecode(_prefs.getString('gift.taken') ?? '{}') as Map).map(
      (k, v) => MapEntry(k as String, v as int),
    );
    _goalsDay = _prefs.getInt('goals.day') ?? -1;
    _goalCounts = (jsonDecode(_prefs.getString('goals.counts') ?? '{}') as Map).map(
      (k, v) => MapEntry(k as String, v as int),
    );
    _goalGames = (_prefs.getStringList('goals.games') ?? []).toSet();
    _goalsPaid = (_prefs.getStringList('goals.paid') ?? []).toSet();
    final medAt = _prefs.getInt('meditation.startedAt');
    meditationStartedAt = medAt == null ? null : DateTime.fromMillisecondsSinceEpoch(medAt);
    meditationChosen = _prefs.getInt('meditation.chosen') ?? 0;
    meditationStreak = _prefs.getInt('meditation.streak') ?? 0;
    _meditationLastDay = _prefs.getInt('meditation.lastDay');
    _meditationGraceDay = _prefs.getInt('meditation.graceDay');
    _meditationDay = _prefs.getInt('meditation.day') ?? 0;
    _meditationMinutesToday = _prefs.getInt('meditation.minutesToday') ?? 0;
    streakObjects = _prefs.getStringList('meditation.objects') ?? [];
    final ink = _prefs.getString('enso.ink');
    ensoInk = ink == null ? null : [for (final v in jsonDecode(ink) as List) (v as num).toDouble()];
    daysPlayed = _prefs.getInt('days.played') ?? 0;
    _lastDay = _prefs.getInt('days.last') ?? -1;
    unlocksSeen = (_prefs.getStringList('unlocks.seen') ?? []).toSet();
    countDay(now);
    // Una sesión que ya cumplió su tiempo con la app cerrada se cobra al abrir;
    // si todavía no terminó, el jardín la retoma.
    if (meditationStartedAt != null && meditationElapsed(now: now).inMinutes >= meditationChosen) {
      finishMeditation(now: now);
    }
    _saveSerenity(now);
  }

  static const gardenNameMax = 24;

  /// Avanza la guía hasta [step] (nunca vuelve atrás).
  void advanceGuide(int step) {
    if (step <= guideStep) return;
    guideStep = step;
    _prefs.setInt('guide.step', step);
    notifyListeners();
  }

  void markIntroSeen(String game) {
    if (!introSeen.add(game)) return;
    _prefs.setStringList('intro.seen', introSeen.toList());
  }

  void markGardenNameOffered() {
    gardenNameOffered = true;
    _prefs.setBool('gardenNameOffered', true);
  }

  /// Guarda el nombre del jardín (recortado); vacío vuelve a no tener nombre.
  void renameGarden(String name) {
    final clean = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    gardenName = clean.isEmpty ? null : String.fromCharCodes(clean.runes.take(gardenNameMax));
    if (gardenName == null) {
      _prefs.remove('gardenName');
    } else {
      _prefs.setString('gardenName', gardenName!);
    }
    notifyListeners();
  }

  /// Suma el día de hoy a los días de juego, una sola vez por día.
  void countDay(DateTime now) {
    final today = _dayIndex(now);
    if (today == _lastDay) return;
    _lastDay = today;
    daysPlayed++;
    _prefs.setInt('days.last', today);
    _prefs.setInt('days.played', daysPlayed);
  }

  /// Para probar: `--dart-define=SANDORA_DAY=5` juega como si fuera el día 5
  /// (y abre las zonas cuyo nivel no supere ese número).
  static const _dayOverride = int.fromEnvironment('SANDORA_DAY');
  int get playDay => _dayOverride > 0 ? _dayOverride : daysPlayed;

  /// Día de juego en que se abre [game] (1: desde el principio).
  int unlockDay(String game) => (_unlockDays[game] ?? 1).toInt();

  /// La zona que destraba [game], si tiene una con su mismo id (el Estanque
  /// de lotos se abre al comprar el Estanque).
  Expansion? unlockZone(String game) {
    final id = _zoneOf[game] ?? game;
    return levels.expansions.where((e) => e.zone && e.id == id).firstOrNull;
  }

  bool gameUnlocked(String game) {
    final zone = unlockZone(game);
    if (zone != null) return expansions.contains(zone.id) || _dayOverride >= zone.level;
    return playDay >= unlockDay(game);
  }

  /// Minijuegos que se abrieron y todavía no se anunciaron (los del primer
  /// día no se anuncian).
  List<String> newUnlocks(Iterable<String> games) => [
    for (final g in games)
      if (gameUnlocked(g) && !unlocksSeen.contains(g) && (unlockDay(g) > 1 || unlockZone(g) != null)) g,
  ];

  void markUnlocksSeen(Iterable<String> games) {
    unlocksSeen.addAll(games);
    _prefs.setStringList('unlocks.seen', unlocksSeen.toList());
  }

  int get level => levels.levelFor(calm);
  bool get meditationUnlocked => level >= levels.meditationLevel;

  /// Cuántas ampliaciones de patio tiene (0, 1 o 2): el jardín se dibuja más grande.
  int get patioSize => levels.expansions.where((e) => !e.zone && expansions.contains(e.id)).length;

  /// Suma Calma y devuelve el nivel nuevo si subió.
  int? _addCalm(int amount) {
    final before = level;
    calm += amount;
    _prefs.setInt('calm', calm);
    return level > before ? level : null;
  }

  bool canAfford(Expansion e) => pebbles >= e.pebbles && e.essences.entries.every((c) => essences[c.key]! >= c.value);

  bool canBuy(Expansion e) => e.ready && level >= e.level && !expansions.contains(e.id) && canAfford(e);

  /// Ampliaciones que ya se pueden comprar (para avisar en el jardín).
  bool get expansionAvailable => levels.expansions.any(canBuy);

  /// Lo próximo para conseguir, para mostrarlo siempre arriba del jardín.
  Goal? get nextGoal => levels.nextGoal(calm, expansions, canAfford);

  /// Cuánto falta de cada moneda ('pebbles' o una esencia) para pagar [e].
  Map<String, int> missingFor(Expansion e) => {
    if (pebbles < e.pebbles) 'pebbles': e.pebbles - pebbles,
    for (final c in e.essences.entries)
      if (essences[c.key]! < c.value) c.key.name: c.value - essences[c.key]!,
  };

  bool buyExpansion(Expansion e) {
    if (!canBuy(e)) return false;
    pebbles -= e.pebbles;
    for (final c in e.essences.entries) {
      essences[c.key] = essences[c.key]! - c.value;
    }
    expansions.add(e.id);
    _prefs.setStringList('expansions', expansions.toList());
    _saveWallet();
    notifyListeners();
    return true;
  }

  /// Lotos ganados ahora: la ofrenda del día (la primera partida o meditación
  /// del día), uno por cada nivel subido y [bonus]. Se guardan con la billetera.
  int _earnLotus(DateTime now, {int levelsUp = 0, int bonus = 0}) {
    var gain = levelsUp * shop.lotusPerLevel + bonus;
    final today = _dayIndex(now);
    if (today != _lotusDay) {
      _lotusDay = today;
      _prefs.setInt('lotus.day', today);
      gain += shop.lotusDaily;
    }
    lotus += gain;
    return gain;
  }

  /// Cuánto tiene de una moneda del Mercado ('pebbles', 'lotus' o una esencia).
  int walletOf(String key) => switch (key) {
    'pebbles' => pebbles,
    'lotus' => lotus,
    _ => essences[Essence.values.byName(key)]!,
  };

  /// Lotos comprados en la tienda de la app.
  void grantLotus(int n) {
    if (n <= 0) return;
    lotus += n;
    _saveWallet();
    notifyListeners();
  }

  void _addTo(String key, int amount) {
    switch (key) {
      case 'pebbles':
        pebbles += amount;
      case 'lotus':
        lotus += amount;
      default:
        final e = Essence.values.byName(key);
        essences[e] = essences[e]! + amount;
    }
  }

  /// Veces que todavía se puede hacer [o] hoy; null si no tiene límite.
  int? shopLeft(ShopOffer o, {DateTime? now}) {
    if (o.daily == null) return null;
    final used = _dayIndex(now ?? DateTime.now()) == _shopDay ? (_shopBought[o.id] ?? 0) : 0;
    return (o.daily! - used).clamp(0, o.daily!);
  }

  bool canPayOffer(ShopOffer o) => o.cost.entries.every((c) => walletOf(c.key) >= c.value);

  bool canTrade(ShopOffer o, {DateTime? now}) => shopLeft(o, now: now) != 0 && canPayOffer(o);

  bool trade(ShopOffer o, {DateTime? now}) {
    now ??= DateTime.now();
    if (!canTrade(o, now: now)) return false;
    final today = _dayIndex(now);
    if (today != _shopDay) {
      _shopDay = today;
      _shopBought = {};
    }
    for (final c in o.cost.entries) {
      _addTo(c.key, -c.value);
    }
    for (final g in o.give.entries) {
      _addTo(g.key, g.value);
    }
    _shopBought[o.id] = (_shopBought[o.id] ?? 0) + 1;
    _prefs.setInt('shop.day', _shopDay);
    _prefs.setString('shop.bought', jsonEncode(_shopBought));
    _pendingGoals.addAll(_goalEvent(now, {DailyKind.trade: 1}));
    _saveWallet();
    notifyListeners();
    return true;
  }

  /// Cuántos [g] quedan por juntar ahora: 0 si no es su momento del día o su
  /// clima.
  int giftsLeft(DayGift g, {required Weather weather, bool afterRain = false, DateTime? now}) {
    now ??= gardenNow();
    if (!g.activeAt(dayCycle.phaseAt(now), weather, afterRain: afterRain)) return 0;
    final used = dayCycle.gardenDay(now) == _giftDay ? (_giftsTaken[g.id] ?? 0) : 0;
    return (g.daily - used).clamp(0, g.daily);
  }

  bool takeGift(DayGift g, {required Weather weather, bool afterRain = false, DateTime? now}) {
    now ??= gardenNow();
    if (giftsLeft(g, weather: weather, afterRain: afterRain, now: now) == 0) return false;
    final today = dayCycle.gardenDay(now);
    if (today != _giftDay) {
      _giftDay = today;
      _giftsTaken = {};
    }
    for (final e in g.give.entries) {
      _addTo(e.key, e.value);
    }
    _giftsTaken[g.id] = (_giftsTaken[g.id] ?? 0) + 1;
    _prefs.setInt('gift.day', _giftDay);
    _prefs.setString('gift.taken', jsonEncode(_giftsTaken));
    _pendingGoals.addAll(_goalEvent(now, {DailyKind.gift: 1}));
    _saveWallet();
    notifyListeners();
    return true;
  }

  static int _dayIndex(DateTime t) => DateTime.utc(t.year, t.month, t.day).millisecondsSinceEpoch ~/ 86400000;

  Duration meditationElapsed({DateTime? now}) {
    final start = meditationStartedAt;
    if (start == null) return Duration.zero;
    final d = (now ?? DateTime.now()).difference(start);
    final max = Duration(minutes: meditationChosen);
    return d.isNegative ? Duration.zero : (d > max ? max : d);
  }

  /// Minutos con recompensa que quedan hoy.
  int meditationMinutesLeft({DateTime? now}) {
    final today = _dayIndex(now ?? DateTime.now());
    final used = today == _meditationDay ? _meditationMinutesToday : 0;
    return (_meditationCap - used).clamp(0, _meditationCap);
  }

  int get _meditationCap => economy.balance.meditation.i('dailyCapMinutes');

  void startMeditation(int minutes, {DateTime? now}) {
    meditationStartedAt = now ?? DateTime.now();
    meditationChosen = minutes;
    _prefs.setInt('meditation.startedAt', meditationStartedAt!.millisecondsSinceEpoch);
    _prefs.setInt('meditation.chosen', minutes);
  }

  /// Termina la sesión (completa o cortada) y paga con el reloj real.
  ({MeditationReward reward, int? newLevel, int lotus, String? object}) finishMeditation({DateTime? now}) {
    now ??= DateTime.now();
    if (meditationStartedAt == null) return (reward: MeditationReward.none, newLevel: null, lotus: 0, object: null);
    final minutes = meditationElapsed(now: now).inMinutes;
    final today = _dayIndex(now);
    if (today != _meditationDay) {
      _meditationDay = today;
      _meditationMinutesToday = 0;
    }
    final reward = meditationRules.reward(minutes, meditationChosen, _meditationMinutesToday);
    _meditationMinutesToday += reward.minutes;
    pebbles += reward.pebbles;
    essences[Essence.light] = essences[Essence.light]! + reward.light;
    serenity = (serenity + reward.serenity).clamp(0, economy.balance.serenity.i('max'));
    var streakBonus = 0;
    String? object;
    if (minutes >= economy.balance.meditation.i('streakMinMinutes')) {
      final next = meditationRules.nextStreak(
        today: today,
        lastDay: _meditationLastDay,
        streak: meditationStreak,
        graceDay: _meditationGraceDay,
      );
      if (next.streak != meditationStreak && next.streak % shop.lotusStreakEvery == 0) {
        streakBonus = shop.lotusStreakBonus;
      }
      if (next.streak != meditationStreak) object = _streakObject(next.streak);
      meditationStreak = next.streak;
      _meditationGraceDay = next.graceDay;
      _meditationLastDay = today;
      _prefs.setInt('meditation.streak', meditationStreak);
      _prefs.setInt('meditation.lastDay', today);
      if (next.graceDay != null) _prefs.setInt('meditation.graceDay', next.graceDay!);
    }
    final before = level;
    final newLevel = _addCalm(reward.calm);
    final lotusGain = reward.minutes > 0
        ? _earnLotus(now, levelsUp: newLevel == null ? 0 : newLevel - before, bonus: streakBonus)
        : 0;
    meditationStartedAt = null;
    _prefs.remove('meditation.startedAt');
    _prefs.setInt('meditation.day', _meditationDay);
    _prefs.setInt('meditation.minutesToday', _meditationMinutesToday);
    if (reward.minutes > 0) _pendingGoals.addAll(_goalEvent(now, {DailyKind.meditate: 1}));
    _saveWallet();
    _saveSerenity(now);
    notifyListeners();
    return (reward: reward, newLevel: newLevel, lotus: lotusGain, object: object);
  }

  /// Cada `streakObjectEvery` días de racha se gana el siguiente objeto de
  /// `streakObjects` que todavía no se tiene. Devuelve cuál, o null.
  String? _streakObject(int streak) {
    final m = economy.balance.meditation;
    final all = m.strings('streakObjects');
    if (streak % m.i('streakObjectEvery') != 0 || streakObjects.length >= all.length) return null;
    final object = all[streakObjects.length];
    streakObjects = [...streakObjects, object];
    _prefs.setStringList('meditation.objects', streakObjects);
    return object;
  }

  /// Registra una partida terminada de [game] y paga la recompensa. Las metas
  /// del día que se cumplieron quedan en [lastRunGoals].
  Reward finishRun(String game, int stars, {bool record = false, DateTime? now}) {
    now ??= DateTime.now();
    advanceGuide(1);
    final day = '${now.year}-${now.month}-${now.day}';
    if (day != _playsDay) {
      _playsDay = day;
      _plays = {};
    }
    final run = (_plays[game] ?? 0) + 1;
    _plays[game] = run;
    final reward = economy.reward(game, stars, run);
    pebbles += reward.pebbles;
    essences[reward.essence] = essences[reward.essence]! + reward.essenceAmount;
    serenity = economy.serenityAfterPlay(serenity);
    final gained = levels.calmFor(stars);
    final before = level;
    final newLevel = _addCalm(gained);
    final lotusGain = _earnLotus(now, levelsUp: newLevel == null ? 0 : newLevel - before);
    lastRunGoals = _goalEvent(now, {
      DailyKind.plays: 1,
      DailyKind.stars: stars,
      if (stars >= 3) DailyKind.three: 1,
      if (record) DailyKind.record: 1,
    }, game: game);
    _prefs.setString('playsDay', _playsDay);
    _prefs.setString('plays', jsonEncode(_plays));
    _saveWallet();
    _saveSerenity(now);
    notifyListeners();
    return reward.withCalm(gained, newLevel, lotus: lotusGain);
  }

  /// La torre como quedó después de una partida; lo juntado hasta ahora se cobra.
  void setTower(List<TowerStone> stones, {DateTime? now}) {
    collectTower(now: now);
    tower = stones;
    towerCollectedAt = now ?? DateTime.now();
    if (stones.length > bestTower) bestTower = stones.length;
    _prefs.setString(
      'tower',
      jsonEncode([
        for (final s in stones) [s.x, s.w, s.h, s.kind, s.tone, s.seed],
      ]),
    );
    _prefs.setInt('bestTower', bestTower);
    _prefs.setInt('towerCollectedAt', towerCollectedAt!.millisecondsSinceEpoch);
    notifyListeners();
  }

  /// Piedritas que la torre juntó desde la última vez que se cobró.
  int towerPending({DateTime? now}) {
    final since = towerCollectedAt;
    if (since == null || tower.isEmpty) return 0;
    final hours = (now ?? DateTime.now()).difference(since).inSeconds / 3600;
    return economy.towerYield(tower.length, hours);
  }

  int collectTower({DateTime? now}) {
    final gain = towerPending(now: now);
    if (gain == 0) return 0;
    pebbles += gain;
    towerCollectedAt = now ?? DateTime.now();
    _prefs.setInt('towerCollectedAt', towerCollectedAt!.millisecondsSinceEpoch);
    _saveWallet();
    notifyListeners();
    return gain;
  }

  void setSandDrawing(List<double> points, {SandShape? shape}) {
    sandDrawing = points;
    sandFigures++;
    sandLastShape = shape;
    if (shape != null) _prefs.setInt('sandLastShape', shape.index);
    _prefs.setString('sandDrawing', jsonEncode(points.map((v) => double.parse(v.toStringAsFixed(4))).toList()));
    _prefs.setInt('sandFigures', sandFigures);
    notifyListeners();
  }

  /// Devuelve true si es récord.
  bool setRainScore(int score) {
    if (score <= rainBest) return false;
    rainBest = score;
    _prefs.setInt('rainBest', score);
    return true;
  }

  /// Mejor puntaje de los minijuegos que no guardan otra cosa.
  int best(String game) => _prefs.getInt('best.$game') ?? 0;

  /// Devuelve true si es récord.
  bool setBest(String game, int score) {
    if (score <= best(game)) return false;
    _prefs.setInt('best.$game', score);
    return true;
  }

  /// El mejor ensō (`SavedInk.toFlat`), para colgarlo en el pabellón.
  List<double>? ensoInk;

  void setEnsoInk(List<double> flat) {
    ensoInk = flat;
    _prefs.setString('enso.ink', jsonEncode(flat));
    notifyListeners();
  }

  /// Las metas de hoy, en orden.
  List<GoalDef> goalsToday({DateTime? now}) => dailyGoals.forDay(dayCycle.gardenDay(now ?? DateTime.now()));

  bool _goalsFresh(DateTime now) => dayCycle.gardenDay(now) == _goalsDay;

  /// Cuánto se avanzó en [g] hoy, hasta su objetivo.
  int goalProgress(GoalDef g, {DateTime? now}) {
    if (!_goalsFresh(now ?? DateTime.now())) return 0;
    final n = g.kind == DailyKind.variety ? _goalGames.length : (_goalCounts[g.kind.name] ?? 0);
    return n.clamp(0, g.target);
  }

  bool goalDone(GoalDef g, {DateTime? now}) => _goalsFresh(now ?? DateTime.now()) && _goalsPaid.contains(g.id);

  /// Metas de hoy ya cumplidas.
  int goalsDone({DateTime? now}) => goalsToday(now: now).where((g) => goalDone(g, now: now)).length;

  /// Las metas cumplidas fuera de una partida que todavía no se anunciaron.
  List<GoalDef> takePendingGoals() {
    final done = [..._pendingGoals];
    _pendingGoals.clear();
    return done;
  }

  /// Suma [add] a las metas del día, paga las que se cumplieron (y el regalo
  /// de todas juntas) y las devuelve. No avisa: lo hace quien la llama.
  List<GoalDef> _goalEvent(DateTime now, Map<DailyKind, int> add, {String? game}) {
    final today = dayCycle.gardenDay(now);
    if (today != _goalsDay) {
      _goalsDay = today;
      _goalCounts = {};
      _goalGames = {};
      _goalsPaid = {};
    }
    for (final e in add.entries) {
      _goalCounts[e.key.name] = (_goalCounts[e.key.name] ?? 0) + e.value;
    }
    if (game != null) _goalGames.add(game);
    final goals = dailyGoals.forDay(today);
    final done = <GoalDef>[];
    for (final g in [...goals, dailyGoals.bonus]) {
      if (_goalsPaid.contains(g.id)) continue;
      final reached = g == dailyGoals.bonus
          ? goals.every((g) => _goalsPaid.contains(g.id))
          : goalProgress(g, now: now) >= g.target;
      if (!reached) continue;
      _goalsPaid.add(g.id);
      for (final c in g.give.entries) {
        _addTo(c.key, c.value);
      }
      done.add(g);
    }
    _prefs.setInt('goals.day', _goalsDay);
    _prefs.setString('goals.counts', jsonEncode(_goalCounts));
    _prefs.setStringList('goals.games', _goalGames.toList());
    _prefs.setStringList('goals.paid', _goalsPaid.toList());
    return done;
  }

  void _saveWallet() {
    _prefs.setInt('pebbles', pebbles);
    _prefs.setInt('lotus', lotus);
    for (final e in Essence.values) {
      _prefs.setInt('essence.${e.name}', essences[e]!);
    }
  }

  void _saveSerenity(DateTime now) {
    _prefs.setInt('serenity', serenity);
    _prefs.setInt('serenityAt', now.millisecondsSinceEpoch);
  }
}
