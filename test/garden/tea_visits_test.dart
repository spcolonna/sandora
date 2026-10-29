import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/progress.dart';

import '../helpers.dart';

void main() {
  final balance = loadBalance();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('el té servido recibe una visita que deja su ofrenda una vez por día', () async {
    final p = Progress.instance;
    final noon = DateTime(2026, 10, 27, 12);
    await p.load(balance, now: noon);
    expect(p.teaState(now: noon), TeaState.empty);

    p.finishRun('matcha', 0, now: noon);
    expect(p.lastRunTea, isFalse, reason: 'sin estrellas no queda servido');
    p.finishRun('matcha', 2, now: noon);
    expect(p.lastRunTea, isTrue);
    expect(p.teaState(now: noon), TeaState.served);
    expect(p.takeVisit(now: noon), isNull);

    // Un té mejor el mismo día no adelanta ni atrasa la visita.
    final later = noon.add(const Duration(minutes: 5));
    p.finishRun('matcha', 3, now: later);
    final arrives = noon.add(p.teaVisits.arrive);
    expect(p.teaArrivesAt, arrives);

    final visit = arrives.add(const Duration(minutes: 1));
    expect(p.teaState(now: visit), TeaState.visit);
    final gift = p.teaVisitor(now: visit).gift(3);
    final before = {'pebbles': p.pebbles, ...p.essences.map((k, v) => MapEntry(k.name, v))};
    expect(p.takeVisit(now: visit), gift);
    for (final e in gift.entries) {
      final now = e.key == 'pebbles' ? p.pebbles : p.essences.entries.firstWhere((x) => x.key.name == e.key).value;
      expect(now - before[e.key]!, e.value);
    }
    expect(p.takeVisit(now: visit), isNull);
    expect(p.teaState(now: visit), TeaState.visited);
    expect(p.takePendingGoals(), isA<List>());

    // Ese día ya no se sirve otro; al día siguiente, sí.
    p.finishRun('matcha', 3, now: visit);
    expect(p.lastRunTea, isFalse);
    final tomorrow = noon.add(const Duration(days: 1));
    expect(p.teaState(now: tomorrow), TeaState.empty);
    p.finishRun('matcha', 1, now: tomorrow);
    expect(p.teaState(now: tomorrow), TeaState.served);

    // Se guarda.
    await p.load(balance, now: tomorrow);
    expect(p.teaState(now: tomorrow), TeaState.served);
  });

  test('otros juegos no sirven té y cada día viene alguien conocido', () async {
    final p = Progress.instance;
    final noon = DateTime(2026, 10, 27, 12);
    await p.load(balance, now: noon);
    p.finishRun('stack', 3, now: noon);
    expect(p.lastRunTea, isFalse);
    final ids = p.teaVisits.visitors.map((v) => v.id).toSet();
    final seen = {for (var d = 0; d < 60; d++) p.teaVisits.visitorFor(d).id};
    expect(ids.containsAll(seen), isTrue);
    expect(seen.length, greaterThan(2));
    expect(p.teaVisits.visitorFor(5).id, p.teaVisits.visitorFor(5).id);
  });

  test('un té servido justo antes del amanecer recibe su visita en el día nuevo', () async {
    final p = Progress.instance;
    final dawn = p.dayCycle;
    final night = DateTime(2026, 10, 28, 5, 20);
    await p.load(balance, now: night);
    p.finishRun('matcha', 2, now: night);
    expect(p.lastRunTea, isTrue);
    expect(p.teaState(now: night), TeaState.served);
    final visit = p.teaArrivesAt.add(const Duration(minutes: 1));
    expect(dawn.gardenDay(visit), isNot(dawn.gardenDay(night)));
    expect(p.teaState(now: visit), TeaState.visit);
    expect(p.takeVisit(now: visit), isNotNull);
  });

  test('con la ofrenda esperando, otro matcha no se anuncia como té servido', () async {
    final p = Progress.instance;
    final noon = DateTime(2026, 10, 27, 12);
    await p.load(balance, now: noon);
    p.finishRun('matcha', 1, now: noon);
    final later = noon.add(p.teaVisits.arrive).add(const Duration(minutes: 1));
    p.finishRun('matcha', 3, now: later);
    expect(p.lastRunTea, isFalse);
    expect(p.teaState(now: later), TeaState.visit);
    expect(p.teaGift(now: later), p.teaVisitor(now: later).gift(3));
  });
}
