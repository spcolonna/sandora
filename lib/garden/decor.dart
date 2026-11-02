import 'dart:math';

import '../balance/balance.dart';

/// Una decoración del catálogo: se compra en el modo Decorar con Piedritas y
/// esencias y se pone donde uno quiera en cualquiera de las tres vistas.
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
/// una vista, con el pie en ([x], [y]) como fracción del tamaño de la vista.
class PlacedDecor {
  final String id;
  int? side;
  double x, y;

  PlacedDecor(this.id, {this.side, this.x = 0.5, this.y = 0.8});

  bool get placed => side != null;

  List<Object> toJson() => [id, side ?? -1, (x * 1000).round(), (y * 1000).round()];

  factory PlacedDecor.fromJson(List<dynamic> j) {
    final side = j[1] as int;
    return PlacedDecor(j[0] as String, side: side < 0 ? null : side, x: (j[2] as num) / 1000, y: (j[3] as num) / 1000);
  }
}

/// El catálogo y sus precios. Dart puro.
class DecorRules {
  final List<DecorItem> items;

  /// Cuánto sube el precio con cada copia que ya se tiene.
  final double growth;

  /// Cuántas decoraciones entran en cada vista.
  final int perSide;

  /// Cuántas más entran por cada ampliación de patio.
  final int perPatio;

  final int minLevel;

  /// La que se regala al llegar a [minLevel], para estrenar el modo Decorar.
  final String welcomeGift;

  /// Cuántas ofrece el Mercado cada día, además de la oferta.
  final int marketCount;

  DecorRules(Balance balance)
    : items = [for (final s in balance.section('decor').sections('items')) DecorItem.from(s)],
      growth = balance.section('decor').d('growth'),
      perSide = balance.section('decor').i('perSide'),
      perPatio = balance.section('decor').i('perPatio'),
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
