import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/decor.dart';
import 'package:sandora/garden/progress.dart';

import '../helpers.dart';

void main() {
  final balance = loadBalance();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<Progress> rich() async {
    final p = Progress.instance;
    await p.load(balance);
    p.calm = p.levels.calmToReach(20);
    p.pebbles = 100000;
    for (final e in p.essences.keys) {
      p.essences[e] = 10000;
    }
    p.lotus = 100;
    return p;
  }

  test('las reglas de la maqueta son coherentes', () {
    final m = ModelRules(balance);
    expect(m.feet.length, ModelRules.sides);
    for (var s = 0; s < ModelRules.sides; s++) {
      expect(m.feet[s].length, m.cells);
      for (var c = m.cols; c < m.cells; c++) {
        expect(m.foot(s, c).$2, greaterThan(m.foot(s, c - m.cols).$2), reason: 'la fila 0 es la del fondo ($s, $c)');
      }
      for (var c = 0; c < m.cells; c++) {
        final (x, y) = m.foot(s, c);
        expect(x, inInclusiveRange(0.05, 0.95), reason: 'el pie queda dentro de la vista');
        expect(y, inInclusiveRange(0.55, 0.95));
        if (m.col(c) > 0) expect(x, greaterThan(m.foot(s, c - 1).$1), reason: 'la columna 0 es la de la izquierda');
      }
    }
    expect(m.start.every((c) => c >= 0 && c < m.cells), isTrue);
    expect(m.cells - m.start.length, greaterThan(m.lotusLast));
  });

  test('cada vista empieza con sus parcelas abiertas; las demás cuestan, cada vez más, y las últimas, lotos', () async {
    final p = await rich();
    final m = p.modelRules;
    for (var s = 0; s < ModelRules.sides; s++) {
      expect(p.parcels[s], m.start.toSet());
    }
    final locked = [
      for (var c = 0; c < m.cells; c++)
        if (!p.parcelOpen(0, c)) c,
    ];
    var last = 0;
    for (final (k, c) in locked.indexed) {
      final cost = p.parcelCost(0);
      final lotusOne = locked.length - k <= m.lotusLast;
      if (lotusOne) {
        expect(cost, {'lotus': m.lotus}, reason: 'parcela $c');
      } else {
        expect(cost['pebbles']!, greaterThanOrEqualTo(last), reason: 'parcela $c');
        expect(cost['pebbles']! % 5, 0);
        last = cost['pebbles']!;
      }
      expect(p.buyParcel(0, c), isTrue);
      expect(p.buyParcel(0, c), isFalse, reason: 'ya está abierta');
    }
    expect(p.parcels[0].length, m.cells);
    expect(
      p.parcelCost(1)['pebbles'],
      greaterThan(m.pebbles),
      reason: 'lo comprado en otra vista también sube el precio',
    );
    await p.load(balance);
    expect(p.parcels[0].length, m.cells, reason: 'se guarda');
  });

  test('sin monedas no se abre', () async {
    final p = await rich();
    final c = [for (var c = 0; c < p.modelRules.cells; c++) c].firstWhere((c) => !p.parcelOpen(0, c));
    p.pebbles = 0;
    expect(p.canBuyParcel(0, c), isFalse);
    expect(p.buyParcel(0, c), isFalse);
    expect(p.parcelOpen(0, c), isFalse);
  });

  test('no se pone en una parcela cerrada ni ocupada; mover a una ocupada las intercambia', () async {
    final p = await rich();
    final a = p.decorRules.items[0], b = p.decorRules.items[1];
    p.buyDecor(a);
    p.buyDecor(b);
    final closed = [for (var c = 0; c < p.modelRules.cells; c++) c].firstWhere((c) => !p.parcelOpen(2, c));
    final [c1, c2, ...] = p.modelRules.start;
    expect(p.placeDecor(a.id, 2, closed), isNull);
    final ia = p.placeDecor(a.id, 2, c1)!;
    expect(p.placeDecor(b.id, 2, c1), isNull, reason: 'ocupada');
    final ib = p.placeDecor(b.id, 2, c2)!;
    expect(p.moveDecor(ia, closed), isFalse);
    expect(p.moveDecor(ia, c2), isTrue);
    expect(p.decorAt(2, c2), ia);
    expect(p.decorAt(2, c1), ib);
  });

  test('las parcelas son de cada jardín', () async {
    final p = await rich();
    final c = [for (var c = 0; c < p.modelRules.cells; c++) c].firstWhere((c) => !p.parcelOpen(0, c));
    p.buyParcel(0, c);
    p.lotus = p.gardenCost;
    expect(await p.buyGarden(), isTrue);
    expect(p.parcelOpen(0, c), isFalse);
    await p.switchGarden(0);
    expect(p.parcelOpen(0, c), isTrue);
  });

  test('lo puesto antes de la maqueta pasa a la parcela libre más cercana, sin perder nada', () async {
    final m = ModelRules(balance);
    // Nueve en el patio, guardadas con el formato viejo (sin parcela), y una en la caja.
    final old = [
      for (var i = 0; i < 9; i++) ['step', 0, 200 + 70 * i, 900],
      ['rocks', 1, 840, 930],
      ['moss', -1, 0, 0],
    ];
    SharedPreferences.setMockInitialValues({'decor': jsonEncode(old)});
    final p = Progress.instance;
    await p.load(balance);
    final placed = p.decor.where((d) => d.placed).toList();
    expect(placed.length, 10, reason: 'ninguna vuelve a la caja');
    expect(p.decor.where((d) => !d.placed).single.id, 'moss');
    for (final d in placed) {
      expect(d.cell, isNotNull);
      expect(p.parcelOpen(d.side!, d.cell!), isTrue);
    }
    final patio = placed.where((d) => d.side == 0).map((d) => d.cell).toSet();
    expect(patio.length, 9, reason: 'cada una en su parcela');
    expect(p.parcels[0].length, greaterThanOrEqualTo(9), reason: 'se abrieron las que hacían falta, sin cobrar');
    final rocks = placed.firstWhere((d) => d.side == 1);
    expect(rocks.cell, m.nearest(1, 0.84, 0.93, m.start), reason: 'la más cercana entre las abiertas');
    // Ya migrado, no se mueve más.
    final cells = [for (final d in p.decor) d.cell];
    await p.load(balance);
    expect([for (final d in p.decor) d.cell], cells);
  });

  test('una pieza se da vuelta y queda así al volver a abrir', () async {
    final p = await rich();
    final a = p.decorRules.items[0];
    p.buyDecor(a);
    final i = p.placeDecor(a.id, 0, p.modelRules.start.first)!;
    expect(p.decor[i].flip, isFalse);
    p.flipDecor(i);
    expect(p.decor[i].flip, isTrue);
    await p.load(balance);
    expect(p.decor[i].flip, isTrue, reason: 'se guarda');
    p.flipDecor(i);
    await p.load(balance);
    expect(p.decor[i].flip, isFalse);
  });
}
