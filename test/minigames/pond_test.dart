import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sandora/minigames/pond/pond_rules.dart';

import '../helpers.dart';

void main() {
  const L = Tile.lotus, P = Tile.pad, S = Tile.stone, K = Tile.koi, D = Tile.drop;

  test('el tablero nuevo no trae líneas hechas y siempre tiene jugada', () {
    for (var seed = 0; seed < 30; seed++) {
      final b = PondBoard(6, 7, Random(seed));
      expect(b.groups(), isEmpty);
      expect(b.hasMove(), isTrue);
      expect(b.cells.every((c) => c != null), isTrue);
    }
  });

  test('un cambio que no arma línea se deshace', () {
    // 3x3:  L P S / P L K / S K D
    final b = PondBoard.fromTiles(3, 3, Random(1), [L, P, S, P, L, K, S, K, D]);
    final before = [for (final c in b.cells) c!.id];
    expect(b.trySwap(0, 1), isFalse);
    expect([for (final c in b.cells) c!.id], before);
  });

  test('tres en línea se van, cae lo de arriba y entra nuevo', () {
    // 3x3:  P S K / L L D / S K L   -> cambiar (2,2) con (1,2) arma L L L en la fila 1.
    final b = PondBoard.fromTiles(3, 3, Random(1), [P, S, K, L, L, D, S, K, L]);
    final topLeft = b.cells[0]!.id;
    expect(b.trySwap(8, 5), isTrue);
    final step = b.step(moved: {8, 5})!;
    expect(step.cleared, {3, 4, 5});
    expect(step.lotus, 3);
    expect(step.points, 30);
    expect(b.cells[3]!.id, topLeft, reason: 'la de arriba cayó una fila');
    expect(step.spawned.keys, containsAll([0, 1, 2]));
  });

  test('cuatro en línea deja una onda; cinco, una luna', () {
    final four = PondBoard.fromTiles(4, 2, Random(1), [L, L, P, L, S, K, L, D]);
    expect(four.trySwap(2, 6), isTrue);
    final s4 = four.step(moved: {2, 6})!;
    expect(s4.created.values.single.power, Power.rowWave);

    final five = PondBoard.fromTiles(5, 2, Random(1), [L, L, P, L, L, S, K, L, D, S]);
    expect(five.trySwap(2, 7), isTrue);
    final s5 = five.step(moved: {2, 7})!;
    expect(s5.created.values.single.power, Power.moon);
    expect(s5.created.values.single.tile, isNull);
  });

  test('la luna se lleva todas las de un tipo', () {
    // La luna en 0 se cambia con un koi: se van todos los koi.
    final b = PondBoard.fromTiles(3, 3, Random(1), [null, K, S, P, K, D, K, L, P]);
    expect(b.trySwap(0, 1), isTrue);
    final step = b.step(moved: {0, 1})!;
    expect(step.cleared, containsAll([0, 1, 4, 6]));
  });

  test('la corriente corre una fila y la última entra por el otro lado', () {
    final b = PondBoard.fromTiles(3, 1, Random(1), [L, P, S]);
    b.drift(0, 1);
    expect([for (final c in b.cells) c!.tile], [S, L, P]);
  });

  test('20 jugadas al azar dan un puntaje dentro de lo esperado', () {
    final scores = <int>[];
    for (var seed = 0; seed < 60; seed++) {
      final rng = Random(seed);
      final b = PondBoard(6, 7, rng);
      var score = 0;
      for (var move = 0; move < 20; move++) {
        final options = <(int, int)>[];
        for (var i = 0; i < b.cells.length; i++) {
          for (final j in [if (b.col(i) + 1 < b.cols) i + 1, if (b.row(i) + 1 < b.rows) i + b.cols]) {
            if (b.trySwap(i, j)) {
              b.trySwap(i, j);
              options.add((i, j));
            }
          }
        }
        if (options.isEmpty) {
          b.shuffle();
          continue;
        }
        final (a, c) = options[rng.nextInt(options.length)];
        b.trySwap(a, c);
        var cascade = 1;
        var moved = {a, c};
        while (true) {
          final s = b.step(moved: moved, cascade: cascade);
          if (s == null) break;
          score += s.points;
          cascade++;
          moved = {};
        }
        if (!b.hasMove()) b.shuffle();
      }
      scores.add(score);
    }
    scores.sort();
    // Jugando al azar se llega a 1 estrella; para 3 hay que buscar cadenas.
    final stars = loadBalance().section('pond').list('stars');
    // ignore: avoid_print
    print('pond al azar: mediana ${scores[30]}, p90 ${scores[54]}');
    expect(scores[30], inInclusiveRange(stars[0], stars[1]));
    expect(scores[54], lessThan(stars[2]));
  });
}
