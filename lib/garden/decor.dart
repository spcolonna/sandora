import 'dart:math';

import '../balance/balance.dart';

/// Una decoración del catálogo: se compra con Piedritas y esencias y se pone
/// desde la Maqueta en una parcela de cualquiera de las tres vistas.
class DecorItem {
  final String id;
  final int level;

  /// Precio de la primera; cada copia más en el mismo jardín sale más cara.
  final Map<String, int> cost;

  /// Ancho, en fracción del ancho de la vista, y alto sobre ancho.
  final double size, aspect;

  const DecorItem(this.id, {required this.level, required this.cost, required this.size, required this.aspect});

  factory DecorItem.from(BalanceSection s) => DecorItem(
    s.s('id'),
    level: s.i('level'),
    cost: s.nums('cost').map((k, v) => MapEntry(k, v.round())),
    size: s.d('size'),
    aspect: s.d('aspect'),
  );
}

/// Una decoración del jardín: guardada en la caja ([side] null) o puesta en
/// la parcela [cell] de una vista, con el pie en ([x], [y]) como fracción del
/// tamaño de la vista (sale de la parcela).
class PlacedDecor {
  final String id;
  int? side, cell;
  double x, y;

  /// Espejada: mira para el otro lado.
  bool flip;

  PlacedDecor(this.id, {this.side, this.cell, this.x = 0.5, this.y = 0.8, this.flip = false});

  bool get placed => side != null;

  List<Object> toJson() => [id, side ?? -1, (x * 1000).round(), (y * 1000).round(), cell ?? -1, if (flip) 1];

  /// Las guardadas antes de la Maqueta no traen parcela: se les busca una al cargar.
  factory PlacedDecor.fromJson(List<dynamic> j) {
    final side = j[1] as int, cell = j.length > 4 ? j[4] as int : -1;
    return PlacedDecor(
      j[0] as String,
      side: side < 0 ? null : side,
      cell: side < 0 || cell < 0 ? null : cell,
      x: (j[2] as num) / 1000,
      y: (j[3] as num) / 1000,
      flip: j.length > 5 && j[5] == 1,
    );
  }
}

/// La Maqueta: cada vista es una grilla de parcelas. Las de [start] vienen
/// abiertas; las demás se compran. Dart puro.
class ModelRules {
  final int cols, rows;
  final List<int> start;
  final int pebbles, lotusLast, lotus;
  final double growth;

  /// Dónde queda el pie de cada parcela (x, y) en cada vista.
  final List<List<(double, double)>> feet;

  /// La mesa en el patio pintado: ancho, centro x y base y.
  final (double, double, double) table;

  /// Si las decoraciones también se ven en las vistas de actividades (si no,
  /// solo en el Sendero).
  final bool inViews;

  ModelRules(Balance balance)
    : cols = balance.section('model').i('cols'),
      rows = balance.section('model').i('rows'),
      start = [for (final c in balance.section('model').list('start')) c.round()],
      pebbles = balance.section('model').i('pebbles'),
      growth = balance.section('model').d('growth'),
      lotusLast = balance.section('model').i('lotusLast'),
      lotus = balance.section('model').i('lotus'),
      feet = [
        for (final side in (balance.section('model').raw('feet') as List))
          [
            for (final f in side as List)
              if (f case [final num x, final num y]) (x.toDouble(), y.toDouble()) else (0.5, 0.8),
          ],
      ],
      inViews = balance.section('model').raw('inViews') != false,
      table = switch (balance.section('model').list('table')) {
        [final w, final x, final y] => (w, x, y),
        _ => (0.15, 0.15, 0.9),
      };

  static const sides = 3;

  int get cells => cols * rows;

  int col(int cell) => cell % cols;
  int row(int cell) => cell ~/ cols;

  /// Dónde queda el pie de lo puesto en [cell] de la vista [side].
  (double, double) foot(int side, int cell) => feet[side][cell];

  /// La parcela de [side] más cerca de ([x], [y]) entre [among].
  int nearest(int side, double x, double y, Iterable<int> among) {
    double dist(int c) {
      final (fx, fy) = foot(side, c);
      return (fx - x) * (fx - x) + (fy - y) * (fy - y);
    }

    return among.reduce((a, b) => dist(b) < dist(a) ? b : a);
  }

  /// Precio de una parcela: Piedritas que suben con cada una comprada en el
  /// jardín ([bought]), de a 5; las últimas [lotusLast] cerradas de una vista
  /// ([lockedHere] cuenta cuántas quedan cerradas ahí), lotos.
  Map<String, int> cost(int bought, int lockedHere) =>
      lockedHere <= lotusLast ? {'lotus': lotus} : {'pebbles': ((pebbles * pow(growth, bought)) / 5).round() * 5};
}

/// El catálogo y sus precios. Dart puro.
class DecorRules {
  final List<DecorItem> items;

  /// Cuánto sube el precio con cada copia que ya se tiene.
  final double growth;

  final int minLevel;

  /// La que se regala al llegar a [minLevel], para estrenar la Maqueta.
  final String welcomeGift;

  /// Cuántas ofrece el Mercado cada día, además de la oferta.
  final int marketCount;

  DecorRules(Balance balance)
    : items = [for (final s in balance.section('decor').sections('items')) DecorItem.from(s)],
      growth = balance.section('decor').d('growth'),
      minLevel = balance.section('decor').i('minLevel'),
      welcomeGift = balance.section('decor').s('welcomeGift'),
      marketCount = balance.section('decor').i('marketCount');

  DecorItem? byId(String id) => items.where((d) => d.id == id).firstOrNull;

  /// Precio de la copia número [owned] + 1, redondeado de a 5 (las esencias,
  /// de a 1).
  Map<String, int> cost(DecorItem d, int owned) {
    final k = pow(growth, owned);
    return {
      for (final c in d.cost.entries)
        c.key: c.key == 'pebbles' ? ((c.value * k) / 5).round() * 5 : (c.value * k).round(),
    };
  }
}
