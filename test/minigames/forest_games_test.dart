import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sandora/minigames/flute/flute_rules.dart';
import 'package:sandora/minigames/lanterns/lantern_rules.dart';
import 'package:sandora/minigames/matcha/matcha_rules.dart';

import '../helpers.dart';

void main() {
  final balance = loadBalance();

  group('Matcha', () {
    final rules = MatchaRules(balance.section('matcha'));

    test('batir a tiempo y amplio llena la espuma; a destiempo, no', () {
      // Una partida perfecta: cada batida justo al ritmo del tramo.
      var sum = 0.0;
      for (var t = 0.0; t < rules.duration;) {
        final tempo = rules.tempoAt(t);
        sum += rules.strokeValue(1 / tempo, 0.5, tempo);
        t += 1 / tempo;
      }
      expect(rules.foam(sum), 1);
      expect(rules.strokeValue(1 / 3, 0.5, 3), 1);
      expect(rules.strokeValue(1 / 6, 0.5, 3), 0, reason: 'el doble de rápido');
      expect(rules.strokeValue(1 / 3, 0.1, 3), rules.b.d('weakStroke'), reason: 'batida corta');
      expect(rules.strokeValue(1 / 3.6, 0.5, 3), inExclusiveRange(0.3, 1));
    });

    test('el batidor cuenta cada cambio de dirección con su tiempo y recorrido', () {
      final w = WhiskTracker();
      w.start(100, 0);
      final strokes = <({double interval, double reach})>[];
      // Zigzag de 100 a 300 en pasos de 40 px cada 0,04 s.
      var t = 0.0;
      for (var i = 0; i < 4; i++) {
        final xs = i.isEven ? [140, 180, 220, 260, 300] : [260, 220, 180, 140, 100];
        for (final x in xs) {
          t += 0.04;
          final s = w.move(x.toDouble(), t);
          if (s != null) strokes.add(s);
        }
      }
      expect(strokes, hasLength(3), reason: 'tres vueltas en cuatro pasadas');
      expect(strokes.first.reach, 200);
      expect(strokes[1].interval, closeTo(0.2, 0.001));
      // Un temblor de pocos píxeles no es una vuelta.
      expect(w.move(103, t + 0.04), isNull);
    });

    test('el ritmo cambia por tramos', () {
      expect(rules.tempoAt(0), rules.tempos.first);
      expect(rules.tempoAt(rules.phaseSeconds + 0.1), rules.tempos[1]);
      expect(rules.tempoAt(rules.duration + 5), rules.tempos.last);
    });
  });

  group('Flauta', () {
    final rules = FluteRules(balance.section('flute'));

    test('la melodía camina por los cuatro huecos sin repetir el mismo', () {
      final song = rules.song(Random(5));
      expect(song, hasLength(rules.b.i('gusts')));
      for (var i = 1; i < song.length; i++) {
        expect(song[i].hole, inInclusiveRange(0, FluteRules.holes - 1));
        expect(song[i].hole, isNot(song[i - 1].hole));
        expect(song[i].start, greaterThan(song[i - 1].start + song[i - 1].length));
      }
    });

    test('tapar toda la ráfaga vale 1, la mitad vale la mitad, el margen no cuenta', () {
      const g = (hole: 0, start: 2.0, length: 1.0);
      expect(rules.coverage(g, [(1.0, 4.0)]), 1);
      expect(rules.coverage(g, [(2.0 + rules.grace, 3.0)]), 1, reason: 'llegó tarde pero dentro del margen');
      expect(rules.coverage(g, []), 0);
      final from = 2.0 + rules.grace, half = from + (3.0 - from) / 2;
      expect(rules.coverage(g, [(from, half)]), closeTo(0.5, 0.001));
      expect(rules.coverage(g, [(from, half), (half, 3.0)]), closeTo(1, 0.001));
    });
  });

  group('Linternas', () {
    final rules = LanternRules(balance.section('lanterns'));

    test('sin piedras, la linterna no llega a su muelle', () {
      for (var seed = 0; seed < 20; seed++) {
        final l = rules.setup(Random(seed));
        expect(rules.simulate(l, const []).end, LanternEnd.missed);
      }
    });

    test('tocar una piedra la apaga; rozarla la desvía', () {
      final l = rules.setup(Random(1));
      expect(rules.simulate(l, [Offset(l.startX, 0.03)]).end, LanternEnd.out);
      final mid = rules.simulate(l, const []).path.firstWhere((p) => p.dy > 0.5);
      final side = rules.simulate(l, [mid + const Offset(0.08, 0)]);
      expect(side.end, isNot(LanternEnd.out));
      expect(
        side.path.last.dx,
        lessThan(rules.simulate(l, const []).path.last.dx - 0.05),
        reason: 'la piedra a la derecha la manda a la izquierda',
      );
    });

    test('se puede llevar al muelle con las piedras permitidas', () {
      // Búsqueda golosa: cada piedra nueva es la que más la acerca al muelle.
      for (var seed = 0; seed < 12; seed++) {
        final l = rules.setup(Random(seed));
        final stones = <Offset>[];
        LanternRun run = rules.simulate(l, stones);
        while (run.end != LanternEnd.docked && stones.length < rules.maxStones) {
          Offset? best;
          var bestGap = double.infinity;
          for (var x = 0.06; x < 0.95; x += 0.03) {
            for (var y = 0.18; y < 0.9; y += 0.04) {
              final s = Offset(x, y);
              final r = rules.simulate(l, [...stones, s]);
              if (r.end == LanternEnd.out) continue;
              final gap = (r.path.last.dx - l.dockX).abs();
              if (gap < bestGap) (best, bestGap) = (s, gap);
            }
          }
          stones.add(best!);
          run = rules.simulate(l, stones);
        }
        expect(run.end, LanternEnd.docked, reason: 'semilla $seed');
      }
    });

    test('las piedras de más restan', () {
      expect(rules.value(1), 1);
      expect(rules.value(4), lessThan(rules.value(2)));
    });
  });
}
