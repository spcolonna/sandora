import 'dart:math';

import '../balance/balance.dart';

/// En qué está el visitante: no hay, llegó con un pedido, se fue a esperar
/// que se cumpla, o volvió porque ya se cumplió.
enum VisitorState { none, offering, waiting, done }

/// Qué pide un visitante.
enum RequestKind {
  /// Poner una decoración ([VisitorRequest.target]) en el jardín.
  decor,

  /// Tener [VisitorRequest.n] decoraciones puestas.
  decorCount,

  /// Llegar a [VisitorRequest.n] de serenidad.
  serenity,

  /// Sacar [VisitorRequest.n] estrellas en el minijuego [VisitorRequest.target].
  stars,

  /// Dejar el jardín sin cuidados pendientes.
  noCare,

  /// Mejorar cualquier lugar.
  upgrade,
}

/// Un pedido del catálogo, con lo que deja al cumplirse.
class VisitorRequest {
  final String id;
  final RequestKind kind;
  final String? target;
  final int n;
  final Map<String, int> give;

  const VisitorRequest(this.id, this.kind, {this.target, this.n = 0, this.give = const {}});

  factory VisitorRequest.from(BalanceSection s) => VisitorRequest(
    s.s('id'),
    RequestKind.values.byName(s.s('kind')),
    target: s.has('target') ? s.s('target') : null,
    n: s.has('n') ? s.i('n') : 0,
    give: s.nums('give').map((k, v) => MapEntry(k, v.round())),
  );
}

/// Lo que sabe el jardín para decidir qué se puede pedir y si ya se cumplió.
class GardenFacts {
  final int level, serenity, decorPlaced, pendingCare;
  final Set<String> decorPlacedIds;
  final bool Function(String decorId) decorUnlocked;
  final bool Function(String game) gameOpen;
  final bool canEverUpgrade;

  const GardenFacts({
    required this.level,
    required this.serenity,
    required this.decorPlaced,
    required this.pendingCare,
    required this.decorPlacedIds,
    required this.decorUnlocked,
    required this.gameOpen,
    required this.canEverUpgrade,
  });
}

/// Visitantes con pedidos: desde [fromDay], como mucho uno por día; el pedido
/// aceptado vence a los [expireDays] días. Dart puro.
class VisitorRules {
  final int fromDay, expireDays;
  final List<String> who;
  final List<VisitorRequest> requests;

  VisitorRules(Balance balance)
    : fromDay = balance.section('visitors').i('fromDay'),
      expireDays = balance.section('visitors').i('expireDays'),
      who = balance.section('visitors').strings('who'),
      requests = [for (final s in balance.section('visitors').sections('requests')) VisitorRequest.from(s)];

  VisitorRequest? byId(String id) => requests.where((r) => r.id == id).firstOrNull;

  /// Si el pedido tiene sentido ahora (se puede cumplir y no está cumplido ya).
  bool fits(VisitorRequest r, GardenFacts f) => switch (r.kind) {
    RequestKind.decor => f.decorUnlocked(r.target!) && !f.decorPlacedIds.contains(r.target),
    RequestKind.decorCount => f.level >= 3 && f.decorPlaced < r.n,
    RequestKind.serenity => f.serenity < r.n,
    RequestKind.stars => f.gameOpen(r.target!),
    RequestKind.noCare => f.pendingCare > 0,
    RequestKind.upgrade => f.canEverUpgrade,
  };

  /// Si lo que se ve en el jardín ya cumple [r] (los de estrellas y mejoras
  /// se cumplen al jugar o al comprar, no mirando el jardín).
  bool satisfied(VisitorRequest r, GardenFacts f) => switch (r.kind) {
    RequestKind.decor => f.decorPlacedIds.contains(r.target),
    RequestKind.decorCount => f.decorPlaced >= r.n,
    RequestKind.serenity => f.serenity >= r.n,
    RequestKind.noCare => f.pendingCare == 0,
    RequestKind.stars || RequestKind.upgrade => false,
  };

  /// El visitante y el pedido del día [day]: siempre los mismos ese día, sin
  /// repetir el último pedido. Null si no hay ninguno que tenga sentido.
  (String, VisitorRequest)? pick(int day, GardenFacts f, {String? lastId}) {
    final pool = [
      for (final r in requests)
        if (r.id != lastId && fits(r, f)) r,
    ];
    if (pool.isEmpty) return null;
    final rng = Random(day * 92821 + 17);
    return (who[rng.nextInt(who.length)], pool[rng.nextInt(pool.length)]);
  }
}
