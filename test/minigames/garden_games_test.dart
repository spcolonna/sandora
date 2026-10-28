import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sandora/minigames/bonsai/bonsai_game.dart';
import 'package:sandora/minigames/common/grade.dart';
import 'package:sandora/minigames/leaves/leaves_game.dart';
import 'package:sandora/minigames/moss/moss_game.dart';
import 'package:sandora/minigames/shishi/shishi_game.dart';

import '../helpers.dart';

void main() {
  final balance = loadBalance();

  test('shishi-odoshi: soltar justo antes de rebalsar es perfecto; rebalsar no vale', () {
    final b = balance.section('shishi');
    expect(shishiGrade(0.95, b), Grade.perfect);
    expect(shishiGrade(0.82, b), Grade.great);
    expect(shishiGrade(0.7, b), Grade.good);
    expect(shishiGrade(0.3, b), isNull);
    expect(shishiGrade(1.05, b), isNull);
  });

  test('hojas: el escobazo empuja las cercanas y más a las livianas', () {
    const from = Offset(0, 0), to = Offset(20, 0);
    final near = sweepPush(const Offset(10, 3), from, to, 30, 1);
    final light = sweepPush(const Offset(10, 3), from, to, 30, 0.5);
    expect(near.dx, greaterThan(0));
    expect(light.dx, greaterThan(near.dx));
    expect(sweepPush(const Offset(10, 80), from, to, 30, 1), Offset.zero);
  });

  group('musgo', () {
    MossField field() {
      final f = MossField(10, 10);
      for (var j = 3; j < 7; j++) {
        for (var i = 3; i < 7; i++) {
          f.rock[j * 10 + i] = 1;
        }
      }
      return f;
    }

    test('pintando sobre la piedra el pincel no mancha la arena', () {
      final f = field();
      f.paint(5, 5, 3, 1);
      expect(f.covered, greaterThan(0.5));
      expect(f.stained, 0);
    });

    test('pintando sobre la arena se mancha', () {
      final f = field();
      f.paint(1, 1, 2, 1);
      expect(f.stained, greaterThan(0));
    });

    test('el musgo crece solo, pero solo sobre la piedra', () {
      final f = field();
      f.paint(4, 4, 1, 1);
      final before = f.covered;
      final rng = Random(1);
      for (var i = 0; i < 200; i++) {
        f.grow(rng, 0.2);
      }
      expect(f.covered, greaterThan(before));
      expect(f.stained, 0);
    });
  });

  test('bonsái: el corte cruza la rama', () {
    expect(segmentsCross(const Offset(0, 0), const Offset(10, 10), const Offset(0, 10), const Offset(10, 0)), isTrue);
    expect(segmentsCross(const Offset(0, 0), const Offset(10, 0), const Offset(0, 5), const Offset(10, 5)), isFalse);
  });
}
