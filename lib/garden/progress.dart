import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../balance/balance.dart';
import 'economy.dart';
import 'levels.dart';
import 'meditation_rules.dart';

/// Una piedra de la torre guardada en el jardín (unidades del mundo del
/// minijuego: centro x relativo a la base, ancho y alto).
typedef TowerStone = ({double x, double w, double h});

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

  int pebbles = 0;
  final essences = {for (final e in Essence.values) e: 0};
  int serenity = 0;

  List<TowerStone> tower = [];
  int bestTower = 0;
  DateTime? towerCollectedAt;

  /// Último dibujo del arenero: puntos normalizados 0..1, x e y alternados.
  List<double> sandDrawing = [];
  int sandFigures = 0;
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

  String _playsDay = '';
  Map<String, int> _plays = {};

  Future<void> load(Balance balance, {DateTime? now}) async {
    economy = Economy(balance);
    levels = LevelRules(balance);
    meditationRules = MeditationRules(balance);
    _prefs = await SharedPreferences.getInstance();
    now ??= DateTime.now();
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
    tower = [
      for (final s in jsonDecode(_prefs.getString('tower') ?? '[]') as List)
        (x: (s[0] as num).toDouble(), w: (s[1] as num).toDouble(), h: (s[2] as num).toDouble()),
    ];
    bestTower = _prefs.getInt('bestTower') ?? 0;
    final collected = _prefs.getInt('towerCollectedAt');
    towerCollectedAt = collected == null ? null : DateTime.fromMillisecondsSinceEpoch(collected);
    sandDrawing = [for (final v in jsonDecode(_prefs.getString('sandDrawing') ?? '[]') as List) (v as num).toDouble()];
    sandFigures = _prefs.getInt('sandFigures') ?? 0;
    rainBest = _prefs.getInt('rainBest') ?? 0;
    _playsDay = _prefs.getString('playsDay') ?? '';
    _plays = (jsonDecode(_prefs.getString('plays') ?? '{}') as Map).map((k, v) => MapEntry(k as String, v as int));
    gardenName = _prefs.getString('gardenName');
    gardenNameOffered = _prefs.getBool('gardenNameOffered') ?? false;
    calm = _prefs.getInt('calm') ?? 0;
    expansions = (_prefs.getStringList('expansions') ?? []).toSet();
    final medAt = _prefs.getInt('meditation.startedAt');
    meditationStartedAt = medAt == null ? null : DateTime.fromMillisecondsSinceEpoch(medAt);
    meditationChosen = _prefs.getInt('meditation.chosen') ?? 0;
    meditationStreak = _prefs.getInt('meditation.streak') ?? 0;
    _meditationLastDay = _prefs.getInt('meditation.lastDay');
    _meditationGraceDay = _prefs.getInt('meditation.graceDay');
    _meditationDay = _prefs.getInt('meditation.day') ?? 0;
    _meditationMinutesToday = _prefs.getInt('meditation.minutesToday') ?? 0;
    // Una sesión que ya cumplió su tiempo con la app cerrada se cobra al abrir;
    // si todavía no terminó, el jardín la retoma.
    if (meditationStartedAt != null && meditationElapsed(now: now).inMinutes >= meditationChosen) {
      finishMeditation(now: now);
    }
    _saveSerenity(now);
  }

  static const gardenNameMax = 24;

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
  ({MeditationReward reward, int? newLevel}) finishMeditation({DateTime? now}) {
    now ??= DateTime.now();
    if (meditationStartedAt == null) return (reward: MeditationReward.none, newLevel: null);
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
    if (minutes >= economy.balance.meditation.i('streakMinMinutes')) {
      final next = meditationRules.nextStreak(
        today: today,
        lastDay: _meditationLastDay,
        streak: meditationStreak,
        graceDay: _meditationGraceDay,
      );
      meditationStreak = next.streak;
      _meditationGraceDay = next.graceDay;
      _meditationLastDay = today;
      _prefs.setInt('meditation.streak', meditationStreak);
      _prefs.setInt('meditation.lastDay', today);
      if (next.graceDay != null) _prefs.setInt('meditation.graceDay', next.graceDay!);
    }
    final newLevel = _addCalm(reward.calm);
    meditationStartedAt = null;
    _prefs.remove('meditation.startedAt');
    _prefs.setInt('meditation.day', _meditationDay);
    _prefs.setInt('meditation.minutesToday', _meditationMinutesToday);
    _saveWallet();
    _saveSerenity(now);
    notifyListeners();
    return (reward: reward, newLevel: newLevel);
  }

  /// Registra una partida terminada de [game] y paga la recompensa.
  Reward finishRun(String game, int stars, {DateTime? now}) {
    now ??= DateTime.now();
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
    final newLevel = _addCalm(gained);
    _prefs.setString('playsDay', _playsDay);
    _prefs.setString('plays', jsonEncode(_plays));
    _saveWallet();
    _saveSerenity(now);
    notifyListeners();
    return reward.withCalm(gained, newLevel);
  }

  /// La torre nueva reemplaza a la anterior; lo juntado hasta ahora se cobra.
  void setTower(List<TowerStone> stones, {DateTime? now}) {
    collectTower(now: now);
    tower = stones;
    towerCollectedAt = now ?? DateTime.now();
    if (stones.length > bestTower) bestTower = stones.length;
    _prefs.setString(
      'tower',
      jsonEncode([
        for (final s in stones) [s.x, s.w, s.h],
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

  void setSandDrawing(List<double> points) {
    sandDrawing = points;
    sandFigures++;
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

  void _saveWallet() {
    _prefs.setInt('pebbles', pebbles);
    for (final e in Essence.values) {
      _prefs.setInt('essence.${e.name}', essences[e]!);
    }
  }

  void _saveSerenity(DateTime now) {
    _prefs.setInt('serenity', serenity);
    _prefs.setInt('serenityAt', now.millisecondsSinceEpoch);
  }
}
