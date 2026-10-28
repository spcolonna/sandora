import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sandora/minigames/bell/bell_rules.dart';
import 'package:sandora/minigames/common/grade.dart';
import 'package:sandora/minigames/enso/enso_scorer.dart';

import '../helpers.dart';

void main() {
  final balance = loadBalance();

  group('Ensō', () {
    final b = balance.section('enso');
    const width = 400.0;

    /// Un trazo circular de [turns] vueltas, con [wobble] de desvío del radio
    /// y velocidad pareja (o a tirones con [jerky]).
    List<InkPoint> circle({double turns = 0.95, double wobble = 0, bool jerky = false, double r = 120}) {
      const n = 120;
      var t = 0.0;
      return [
        for (var i = 0; i < n; i++)
          (() {
            final a = -pi / 2 + 2 * pi * turns * i / (n - 1);
            final rr = r * (1 + wobble * sin(a * 3));
            t += jerky && i % 10 < 5 ? 0.005 : 0.03;
            return (at: Offset(200 + rr * cos(a), 300 + rr * sin(a)), t: t);
          })(),
      ];
    }

    test('un círculo limpio con una pequeña abertura es casi perfecto', () {
      final r = scoreEnso(circle(), width, b);
      expect(r.sweep, closeTo(0.95, 0.02));
      expect(r.roundness, greaterThan(0.95));
      expect(r.closure, 1);
      expect(r.total, greaterThan(b.list('stars').last));
    });

    test('quedarse corto, deformarlo o hacerlo a tirones resta', () {
      final good = scoreEnso(circle(), width, b).total;
      expect(scoreEnso(circle(turns: 0.6), width, b).total, lessThan(good));
      expect(scoreEnso(circle(wobble: 0.15), width, b).roundness, lessThan(0.5));
      expect(scoreEnso(circle(jerky: true), width, b).fluency, lessThan(0.8));
      expect(scoreEnso(circle(turns: 1.6), width, b).closure, lessThan(0.5), reason: 'vuelta y media');
    });

    test('muy chico o muy corto no cuenta', () {
      expect(scoreEnso(circle(r: 20), width, b).tooSmall, isTrue);
      expect(scoreEnso(circle().take(5).toList(), width, b).tooSmall, isTrue);
    });
  });

  group('Campana', () {
    final rules = BellRules(balance.section('bell'));

    test('las fuerzas pedidas están en rango y no se repiten seguidas', () {
      final t = rules.targets(Random(3));
      expect(t, hasLength(rules.strikes));
      for (var i = 0; i < t.length; i++) {
        expect(t[i], inInclusiveRange(rules.b.d('targetLow'), rules.b.d('targetHigh')));
        if (i > 0) expect((t[i] - t[i - 1]).abs(), greaterThanOrEqualTo(rules.b.d('zoneWidth')));
      }
    });

    test('golpe justo y en silencio es perfecto; apurarse resta', () {
      expect(rules.grade(rules.strikeScore(0.6, 0.6, 0)), Grade.perfect);
      final ringing = rules.ringAfter(0.9, 0.3);
      expect(ringing, greaterThan(rules.quiet));
      expect(rules.strikeScore(0.6, 0.6, ringing), lessThan(1));
      expect(rules.grade(rules.strikeScore(0.95, 0.4, 0)), isNull, reason: 'muy lejos de la fuerza pedida');
    });

    test('la campana se apaga sola con el tiempo', () {
      expect(rules.ringAfter(1, 0), 1);
      expect(rules.ringAfter(1, rules.decay * 3), lessThan(rules.quiet));
    });
  });
}
