import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/progress.dart';
import 'package:sandora/garden/visitors.dart';

import '../helpers.dart';

void main() {
  final balance = loadBalance();
  final rules = VisitorRules(balance);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  GardenFacts facts({int level = 20, int serenity = 500, Set<String> placed = const {}, int care = 0}) => GardenFacts(
    level: level,
    serenity: serenity,
    decorPlaced: placed.length,
    pendingCare: care,
    decorPlacedIds: placed,
    decorUnlocked: (_) => level >= 3,
    gameOpen: (g) => g == 'sand' || g == 'stack' || g == 'rain',
    canEverUpgrade: level >= 4,
  );

  test('el catálogo es válido y cada pedido deja algo', () {
    expect(rules.requests.map((r) => r.id).toSet().length, rules.requests.length);
    for (final r in rules.requests) {
      expect(r.give, isNotEmpty, reason: r.id);
      if (r.kind == RequestKind.decor || r.kind == RequestKind.stars) expect(r.target, isNotNull, reason: r.id);
    }
  });

  test('solo pide lo que tiene sentido y es el mismo en el día, sin repetir el último', () {
    final f = facts(level: 2, serenity: 900);
    for (var day = 0; day < 40; day++) {
      final (_, r) = rules.pick(day, f)!;
      expect(rules.fits(r, f), isTrue, reason: r.id);
      expect(r.kind, isNot(RequestKind.serenity), reason: 'ya tiene 900');
      expect(r.kind, isNot(RequestKind.upgrade), reason: 'todavía no puede mejorar');
      expect(r.kind, isNot(RequestKind.noCare), reason: 'no hay cuidados');
    }
    final a = rules.pick(5, f)!, b = rules.pick(5, f)!;
    expect((a.$1, a.$2.id), (b.$1, b.$2.id));
    expect(rules.pick(5, f, lastId: a.$2.id)!.$2.id, isNot(a.$2.id));
  });

  test('lo que se ve en el jardín cumple el pedido', () {
    final step = rules.byId('step')!;
    expect(rules.satisfied(step, facts()), isFalse);
    expect(rules.satisfied(step, facts(placed: {'step'})), isTrue);
    expect(rules.satisfied(rules.byId('tidy')!, facts(care: 2)), isFalse);
    expect(rules.satisfied(rules.byId('tidy')!, facts()), isTrue);
  });

  group('Progress', () {
    Future<Progress> ready() async {
      final p = Progress.instance;
      await p.load(balance);
      p.calm = p.levels.calmToReach(6);
      p.daysPlayed = rules.fromDay;
      return p;
    }

    test('llega uno por día, se acepta, se cumple jugando y deja su regalo', () async {
      final p = await ready();
      final day = DateTime(2026, 11, 2, 10);
      p.refreshVisitor(day);
      expect(p.visitorState, VisitorState.offering);
      // Para probar el camino de las estrellas, se fuerza ese pedido.
      final stars = rules.requests.firstWhere((r) => r.kind == RequestKind.stars && r.target == 'stack');
      p.debugVisitor('monk', stars.id, day);
      final when = day;
      p.acceptVisitor(now: when);
      expect(p.visitorState, VisitorState.waiting);
      p.finishRun('stack', stars.n - 1, now: when);
      expect(p.visitorState, VisitorState.waiting, reason: 'pocas estrellas');
      p.finishRun('stack', stars.n, now: when);
      expect(p.visitorState, VisitorState.done);
      final before = Map.of(stars.give.map((k, _) => MapEntry(k, p.walletOf(k))));
      expect(p.claimVisitor(), stars.give);
      for (final e in stars.give.entries) {
        expect(p.walletOf(e.key), before[e.key]! + e.value);
      }
      expect(p.visitorState, VisitorState.none);
      p.refreshVisitor(when);
      expect(p.visitorState, VisitorState.none, reason: 'uno por día');
    });

    test('el pedido aceptado vence y el no aceptado se va al otro día', () async {
      final p = await ready();
      final day = DateTime(2026, 11, 2, 10);
      p.refreshVisitor(day);
      p.refreshVisitor(day.add(const Duration(days: 1)));
      expect(p.visitorState, VisitorState.offering, reason: 'llegó otro');
      p.acceptVisitor(now: day.add(const Duration(days: 1)));
      if (p.visitorState == VisitorState.waiting) {
        p.refreshVisitor(day.add(Duration(days: 2 + rules.expireDays)));
        expect(p.visitorState, isNot(VisitorState.waiting));
      }
    });
  });
}
