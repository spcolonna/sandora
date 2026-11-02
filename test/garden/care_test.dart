import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/care.dart';
import 'package:sandora/garden/progress.dart';
import 'package:sandora/garden/weather.dart';

import '../helpers.dart';

void main() {
  final balance = loadBalance();
  final rules = CareRules(balance);
  final t0 = DateTime(2026, 11, 2, 9);

  (List<CareTask>, CareNews) spawn(
    Weather w, {
    int hours = 3,
    int weeds = 0,
    List<CareTask> have = const [],
    List<int> decor = const [],
    bool windy = false,
    bool drawing = true,
  }) => rules.spawn(
    from: t0,
    to: t0.add(Duration(hours: hours)),
    have: have,
    weeds: weeds,
    weatherAt: (_) => w,
    windy: (_, _) => windy,
    blockHours: 3,
    decorPlaced: decor,
    hasDrawing: drawing,
  );

  Iterable<CareTask> of(List<CareTask> l, CareKind k) => l.where((t) => t.kind == k);

  test('la maleza crece con el tiempo y respeta el tope', () {
    expect(rules.weedsSince(t0, t0.add(const Duration(hours: 7))), 0);
    expect(rules.weedsSince(t0, t0.add(const Duration(hours: 17))), 2);
    final (few, news) = spawn(Weather.clear, weeds: 2);
    expect(of(few, CareKind.weed).length, 2);
    expect(news, CareNews.grew);
    final (many, _) = spawn(Weather.clear, weeds: 50);
    expect(of(many, CareKind.weed).length, rules.maxWeeds);
    final (none, _) = spawn(Weather.clear, weeds: 3, have: many);
    expect(none, isEmpty, reason: 'ya está en el tope');
  });

  test('la lluvia borra la arena (una vez y solo si hay dibujo) y el viento trae hojas', () {
    final (rain, _) = spawn(Weather.rain, hours: 12);
    expect(of(rain, CareKind.sand).length, 1);
    final (dry, _) = spawn(Weather.rain, drawing: false);
    expect(of(dry, CareKind.sand), isEmpty);
    final (wind, _) = spawn(Weather.clear, hours: 30, windy: true);
    expect(of(wind, CareKind.leaves).length, rules.maxLeaves);
    final (calm, _) = spawn(Weather.clear, hours: 30);
    expect(calm, isEmpty);
  });

  test('la tormenta tira piedras, quizás una vasija y una decoración, y se avisa', () {
    final (storm, news) = spawn(Weather.storm, hours: 24, decor: [0, 1, 2]);
    expect(news, CareNews.storm);
    final stones = of(storm, CareKind.stone).toList();
    expect(stones.length, inInclusiveRange(1, rules.maxStones));
    expect(stones.map((t) => t.x).toSet().length, stones.length, reason: 'cada piedra en su lugar');
    expect(of(storm, CareKind.jar).length, lessThanOrEqualTo(1));
    final knocked = of(storm, CareKind.decor).map((t) => t.decor).toList();
    expect(knocked.length, lessThanOrEqualTo(rules.maxDecor));
    expect(knocked.toSet().length, knocked.length);
    expect(storm.length, lessThanOrEqualTo(rules.maxTasks));
    expect(storm.map((t) => t.id).toSet().length, storm.length);
  });

  test('es reproducible y se guarda', () {
    final (a, _) = spawn(Weather.storm, hours: 24, weeds: 3, decor: [0]);
    final (b, _) = spawn(Weather.storm, hours: 24, weeds: 3, decor: [0]);
    expect(a.map((t) => t.toJson()), b.map((t) => t.toJson()));
    for (final t in a) {
      expect(CareTask.fromJson(t.toJson()).toJson(), t.toJson());
    }
  });

  group('Progress', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    CareNews refresh(Progress p, DateTime now, Weather w) =>
        p.refreshCare(now, weatherAt: (_) => w, windy: (_, _) => false, blockHours: 3);

    test('la primera vez solo empieza a contar; después aparecen y arreglar paga', () async {
      final p = Progress.instance;
      await p.load(balance, now: t0);
      expect(refresh(p, t0, Weather.storm), CareNews.none);
      expect(p.care, isEmpty);
      expect(refresh(p, t0.add(const Duration(minutes: 30)), Weather.storm), CareNews.none);
      final later = t0.add(const Duration(hours: 20));
      expect(refresh(p, later, Weather.storm), CareNews.storm);
      expect(p.care.where((t) => t.kind == CareKind.weed).length, 2);
      expect(refresh(p, later, Weather.storm), CareNews.none, reason: 'no se repite');

      final serenity = p.serenity, pebbles = p.pebbles;
      final id = p.care.first.id;
      expect(p.fixCare(id, now: later), rules.pebblesPerFix);
      expect(p.serenity, greaterThan(serenity));
      expect(p.pebbles, pebbles + rules.pebblesPerFix);
      expect(p.fixCare(id, now: later), 0, reason: 'ya está arreglado');

      await p.load(balance, now: later);
      expect(p.care.any((t) => t.id == id), isFalse, reason: 'quedó guardado');
    });

    test('jugar en el lugar lo arregla', () async {
      final p = Progress.instance;
      await p.load(balance, now: t0);
      p.sandDrawing = [1, 2, 3, 4];
      refresh(p, t0, Weather.rain);
      refresh(p, t0.add(const Duration(hours: 6)), Weather.storm);
      expect(p.care.any((t) => t.kind == CareKind.sand), isTrue);
      expect(p.care.any((t) => t.kind == CareKind.stone), isTrue);
      p.finishRun('sand', 2, now: t0.add(const Duration(hours: 6)));
      expect(p.care.any((t) => t.kind == CareKind.sand), isFalse);
      p.finishRun('stack', 2, now: t0.add(const Duration(hours: 6)));
      expect(p.care.any((t) => t.kind == CareKind.stone), isFalse);
    });

    test('con cuidados pendientes la serenidad baja más rápido', () {
      final e = Progress.instance.economy;
      expect(e.decayedSerenity(900, 2, extra: 0.05), lessThan(e.decayedSerenity(900, 2)));
    });
  });
}
