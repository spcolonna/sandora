import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/achievements.dart';
import 'package:sandora/garden/progress.dart';

import '../helpers.dart';

void main() {
  final balance = loadBalance();
  final day = DateTime(2026, 11, 3, 10);
  final a = Achievements.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    a.games = {'sand', 'rain'};
  });

  Future<List<String>> check() async {
    final fresh = a.check();
    await Future<void>.delayed(Duration.zero);
    return fresh;
  }

  test('cada logro tiene un id distinto', () {
    final ids = Achievements.all.map((d) => d.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('un logro nuevo se guarda y espera su aviso grande', () async {
    final p = Progress.instance;
    await p.load(balance, now: day);
    expect(await check(), isEmpty);
    p.finishRun('sand', 3, now: day);
    expect(await check(), containsAll(['firstRun', 'threeStars']));
    expect(p.achievements, containsAll(['firstRun', 'threeStars']));
    expect(p.milestones, containsAll(['ach:firstRun', 'ach:threeStars']));
    expect(p.achievementsNew, isTrue);
    expect(await check(), isEmpty, reason: 'no se repite');
    expect(p.milestones.where((m) => m == 'ach:firstRun'), hasLength(1));
    p.markAchievementsSeen();
    expect(p.achievementsNew, isFalse);
  });

  test('lo que ya estaba hecho antes de los logros entra sin aviso', () async {
    SharedPreferences.setMockInitialValues({'stats.runs': 3, 'best.rain': 9, 'sandFigures': 1});
    final p = Progress.instance;
    await p.load(balance, now: day);
    expect(p.gamesPlayed, {'rain', 'sand'});
    expect(await check(), containsAll(['firstRun', 'allGames']));
    expect(p.achievements, contains('allGames'));
    expect(p.milestones.where((m) => m.startsWith('ach:')), isEmpty);
    expect(p.achievementsNew, isFalse);
  });

  test('el avance se mide y queda en 1 una vez conseguido', () async {
    SharedPreferences.setMockInitialValues({'stats.three': 10, 'achievements': <String>[]});
    final p = Progress.instance;
    await p.load(balance, now: day);
    final three50 = Achievements.all.firstWhere((d) => d.id == 'three50');
    expect(a.fraction(three50), closeTo(0.2, 1e-9));
    p.addAchievements(['three50']);
    expect(a.fraction(three50), 1);
  });
}
