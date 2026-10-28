import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sandora/minigames/common/grade.dart';
import 'package:sandora/minigames/rain/rain_chart.dart';
import 'package:sandora/minigames/sand/sand_shapes.dart';
import 'package:sandora/minigames/stack/stack_rules.dart';

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

    test('con ráfagas las gotas caen en diagonal, cerca del pulso y siguen en orden', () {
      var windy = 0;
      for (var seed = 0; seed < 30; seed++) {
        final chart = buildRainChart(b, vessels: 4, seed: seed);
        final gusts = rainGusts(b, seed: seed);
        for (var i = 1; i < chart.length; i++) {
          expect(chart[i].time, greaterThanOrEqualTo(chart[i - 1].time));
        }
        for (final n in chart.where((n) => n.wind != 0)) {
          windy++;
          expect(n.wind.abs(), lessThanOrEqualTo(1));
          final grid = b.d('beatSeconds') / 2;
          final off = ((n.time - 2.0) / grid - ((n.time - 2.0) / grid).round()).abs() * grid;
          expect(off, lessThanOrEqualTo(b.d('windShift') + 1e-9));
          expect(gusts.any((g) => n.time >= g.start - 0.2 && n.time <= g.start + g.length + 0.2), isTrue);
        }
      }
      expect(windy, greaterThan(0));
    });

    test('con viento se puede llegar igual al 100 %', () {
      final chart = buildRainChart(b, vessels: 4, seed: 7);
      final j = RainJudge(chart, b);
      for (final n in chart) {
        j.tap(n.vessel, n.time);
      }
      expect(j.accuracy, 1);
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

    test('cualquier variante bien recorrida sigue dando 3 estrellas', () {
      final rng = Random(11);
      for (var i = 0; i < 40; i++) {
        final shape = SandShape.values[i % SandShape.values.length];
        final guide = shapePoints(shape, randomVariant(rng, b));
        for (final p in guide) {
          expect(p.x, inInclusiveRange(0.0, 1.0));
          expect(p.y, inInclusiveRange(0.0, 1.0));
        }
        final s = SandScorer(b, guide, b.d('toleranceHard')).score([guide]);
        expect(s.stars, 3, reason: '${shape.name} #$i: ${s.total}');
      }
    });

    test('la figura sale al azar, sin repetir la anterior ni la espiral al aprender', () {
      final rng = Random(2);
      expect(pickShape(rng, done: 0), SandShape.circle);
      var last = SandShape.circle;
      final seen = <SandShape>{};
      for (var i = 1; i < 200; i++) {
        final s = pickShape(rng, done: i, last: last, learning: 5);
        expect(s, isNot(last));
        if (i < 5) expect(s, isNot(SandShape.spiral));
        seen.add(s);
        last = s;
      }
      expect(seen, SandShape.values.toSet());
    });

    test('la piedrita desvía el trazo y rodearla limpio suma', () {
      final guide = shapePoints(SandShape.wave);
      final tol = b.d('toleranceEasy');
      Pebble? stone;
      for (var seed = 0; stone == null; seed++) {
        stone = placePebble(Random(seed), guide, tol, b);
      }
      expect(distToPolyline(stone.at, guide), lessThan(tol));
      final pushed = deflect(stone.at, stone);
      expect(sqrt(pow(pushed.x - stone.at.x, 2) + pow(pushed.y - stone.at.y, 2)), closeTo(stone.r, 1e-9));
      final far = (x: stone.at.x + stone.r * 3, y: stone.at.y);
      expect(deflect(far, stone), far);
      final scorer = SandScorer(b, guide, tol);
      final shaky = [for (final p in guide) (x: p.x, y: p.y + 0.02)];
      expect(scorer.score([shaky], bonus: 0.04).total, greaterThan(scorer.score([shaky]).total));
    });

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

    test('hay piedras de todos los tipos y cada una se ve siempre igual', () {
      final rng = Random(1);
      final stones = [for (var i = 0; i < 300; i++) randomStone(rng)];
      expect(stones.map((s) => s.kind).toSet(), StoneKind.values.toSet());
      for (final s in stones) {
        expect(s.width, inInclusiveRange(s.kind.w.$1, s.kind.w.$2));
        expect(s.outline, hasLength(greaterThan(8)));
      }
      final s = stones.first;
      expect(StoneShape(s.kind, s.width, s.height, s.tone, s.seed).outline, s.outline);
    });

    final rules = StackRules(b);

    test('centrada es firme; con el centro sobre el borde casi siempre cae', () {
      final safe = rules.safeRatio(StoneKind.river, 1, 10);
      expect(rules.fallChance(rules.severity(0.1, safe)), 0);
      expect(rules.fallChance(rules.severity(safe * 0.9, safe)), 0);
      expect(rules.fallChance(rules.severity(1.0, safe)), greaterThan(0.8));
      expect(rules.fallChance(rules.severity(1.3, safe)), 1);
    });

    test('las piedras redondas y las torres altas perdonan menos', () {
      expect(rules.safeRatio(StoneKind.pebble, 1, 10), lessThan(rules.safeRatio(StoneKind.slab, 1, 10)));
      expect(rules.safeRatio(StoneKind.river, 1, 500), lessThan(rules.safeRatio(StoneKind.river, 1, 5)));
      expect(rules.severity(0.5, 0.4, wobble: 0.8), greaterThan(rules.severity(0.5, 0.4)));
    });

    test('lo que se cae depende de qué tan mal quedó y de la altura', () {
      double avg(int h, double sev) {
        final rng = Random(3);
        var sum = 0;
        for (var i = 0; i < 400; i++) {
          sum += rules.collapseLoss(h, sev, rng);
        }
        return sum / 400;
      }

      expect(avg(10, 0.05), inInclusiveRange(1, 3.5), reason: 'por poco en 10: caen ~2');
      expect(avg(10, 1.15), inInclusiveRange(6, 9), reason: 'por mucho en 10: caen ~8');
      expect(avg(500, 0.05), inInclusiveRange(15, 30), reason: 'por poco en 500: caen ~20');
      expect(avg(500, 1.15), inInclusiveRange(65, 110), reason: 'por mucho en 500: caen ~80');
      final rng = Random(4);
      for (var i = 0; i < 200; i++) {
        expect(rules.collapseLoss(3, 1.15, rng), inInclusiveRange(1, 3));
      }
    });

    test('el balanceo crece con lo corrida que quedó y se apaga solo', () {
      expect(rules.wobbleAdd(0.8, 0, 10), greaterThan(rules.wobbleAdd(0.1, 0, 10)));
      expect(rules.wobbleAdd(0.3, 0, 300), greaterThan(rules.wobbleAdd(0.3, 0, 3)));
      expect(rules.wobbleDecay(1, 5, 10), lessThan(0.1));
    });

    test('estrellas por piedras sumadas', () {
      final h = b.list('starNet');
      expect(starsFor(0, h), 0);
      expect(starsFor(h[1], h), 2);
      expect(starsFor(99, h), 3);
    });
  });
}
