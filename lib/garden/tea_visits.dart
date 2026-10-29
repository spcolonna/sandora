import 'dart:math';

import '../balance/balance.dart';
import 'shop.dart';

/// Quien pasa por la casa de té a tomar el té servido y deja una ofrenda.
class Visitor {
  final String id;

  /// Lo que deja por cada estrella del té.
  final Map<String, int> give;

  const Visitor(this.id, this.give);

  factory Visitor.from(BalanceSection s) {
    final give = s.nums('give').map((k, v) => MapEntry(k, v.round()));
    final bad = give.keys.where((k) => !walletKeys.contains(k));
    if (bad.isNotEmpty) throw FormatException('Moneda desconocida en ${s.s('id')}: $bad');
    return Visitor(s.s('id'), give);
  }

  /// La ofrenda por un té de [stars] estrellas.
  Map<String, int> gift(int stars) => give.map((k, v) => MapEntry(k, v * stars));
}

/// Visitas a la casa de té (sección `teaVisits` del balance): un matcha de al
/// menos [minStars] estrellas queda servido y, [arrive] después, alguien pasa,
/// lo toma y deja una ofrenda. Una visita por día del jardín.
class TeaVisits {
  final int minStars;
  final Duration arrive;
  final List<Visitor> visitors;

  TeaVisits._(this.minStars, this.arrive, this.visitors);

  factory TeaVisits(Balance balance) {
    final s = balance.section('teaVisits');
    return TeaVisits._(s.i('minStars'), Duration(minutes: s.i('arriveMinutes')), [
      for (final v in s.sections('visitors')) Visitor.from(v),
    ]);
  }

  /// Quien viene el día [day], siempre el mismo para ese día.
  Visitor visitorFor(int day) => visitors[Random(day * 4111 + 3).nextInt(visitors.length)];
}
