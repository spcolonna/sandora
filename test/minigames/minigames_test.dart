import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zen_garden/minigames/common/grade.dart';
import 'package:zen_garden/minigames/rain/rain_chart.dart';
import 'package:zen_garden/minigames/sand/sand_shapes.dart';
import 'package:zen_garden/minigames/stack/stack_rules.dart';

import '../helpers.dart';

void main() {
  final balance = loadBalance();

  group('Lluvia', () {
    final b = balance.rain;

    test('la partitura respeta las vasijas, se densifica y es reproducible', () {
      final a = buildRainChart(b, vessels: 4, seed: 1);
      final again = buildRainChart(b, vessels: 4, seed: 1);
      expect(a.map((n) => (n.time, n.vessel)), again.map((n) => (n.time, n.vessel)));
      expect(a.every((n) => n.vessel >= 0 && n.vessel < 4), isTrue);
      expect(a.last.time, lessThanOrEqualTo(b.d('durationSeconds')));
      final half = b.d('durationSeconds') / 2;
      expect(a.where((n) => n.time > half).length, greaterThan(a.where((n) => n.time <= half).length));
    });

    test('las gotas dobles caen en vasijas distintas', () {
      for (var seed = 0; seed < 20; seed++) {
        final chart = buildRainChart(b, vessels: 3, seed: seed);
        for (var i = 1; i < chart.length; i++) {
          if (chart[i].time == chart[i - 1].time) expect(chart[i].vessel, isNot(chart[i - 1].vessel));
        }
      }
    });

    test('ventanas: ±40 ms perfecto, ±120 ms bien, fuera no cuenta', () {
      RainJudge judge() => RainJudge([RainNote(5, 0), RainNote(6, 1)], b);
      expect(judge().tap(0, 5.03)!.grade, Grade.perfect);
      expect(judge().tap(0, 4.93)!.grade, Grade.great);
      expect(judge().tap(0, 5.11)!.grade, Grade.good);
      expect(judge().tap(0, 5.2), isNull);
      expect(judge().tap(1, 5.0), isNull, reason: 'otra vasija');
    });

    test('perder una gota corta el combo; todo perfecto es 100%', () {
      final j = RainJudge([RainNote(1, 0), RainNote(2, 0), RainNote(3, 0)], b);
      j.tap(0, 1);
      j.tap(0, 2);
      expect(j.combo, 2);
      expect(j.expire(3.5), hasLength(1));
      expect(j.combo, 0);
      expect(j.bestCombo, 2);
      expect(j.done, isTrue);
      final all = RainJudge([RainNote(1, 0), RainNote(2, 1)], b)
        ..tap(0, 1)
        ..tap(1, 2);
      expect(all.accuracy, 1);
    });
  });

  group('Arenero', () {
    final b = balance.sand;

    for (final shape in SandShape.values) {
      test('${shape.name}: recorrerla bien da 3 estrellas; un garabato, 0', () {
        final guide = shapePoints(shape);
        final scorer = SandScorer(b, guide, b.d('toleranceEasy'));
        // Trazo humano: la guía con un temblor chico.
        final rng = Random(4);
        final good = [
          for (final p in guide) (x: p.x + (rng.nextDouble() - 0.5) * 0.01, y: p.y + (rng.nextDouble() - 0.5) * 0.01),
        ];
        final s = scorer.score([good]);
        expect(s.stars, 3, reason: 'total ${s.total}');
        final scribble = [for (var i = 0; i < 40; i++) (x: 0.1 + 0.02 * (i % 2), y: 0.1 + i * 0.002)];
        expect(scorer.score([scribble]).stars, 0);
      });
    }

    test('un pedacito exacto no alcanza: hace falta cobertura', () {
      final guide = shapePoints(SandShape.circle);
      final scorer = SandScorer(b, guide, b.d('toleranceEasy'));
      final s = scorer.score([guide.take(30).toList()]);
      expect(s.precision, greaterThan(0.9));
      expect(s.stars, 0);
    });

    test('levantar el dedo resta continuidad', () {
      final guide = shapePoints(SandShape.wave);
      final scorer = SandScorer(b, guide, b.d('toleranceEasy'));
      final one = scorer.score([guide]);
      final cut = scorer.score([guide.sublist(0, 80), guide.sublist(80)]);
      expect(cut.continuity, lessThan(one.continuity));
      expect(cut.total, lessThan(one.total));
    });
  });

  group('Apilado', () {
    final b = balance.stack;

    test('centrada dentro del 10% es perfecta', () {
      expect(stoneGrade(0.15, 2, b), Grade.perfect);
      expect(stoneGrade(-0.4, 2, b), Grade.great);
      expect(stoneGrade(0.8, 2, b), Grade.good);
    });

    test('las piedras son polígonos válidos para Box2D', () {
      final rng = Random(1);
      for (var i = 0; i < 50; i++) {
        final s = randomStone(rng, i);
        expect(s.vertices, hasLength(lessThanOrEqualTo(8)));
        expect(s.width, greaterThan(s.height));
        expect(s.width, greaterThan(1));
      }
    });

    test('estrellas por altura', () {
      final h = b.list('starHeights');
      expect(starsFor(0, h), 0);
      expect(starsFor(h[1], h), 2);
      expect(starsFor(99, h), 3);
    });
  });
}
