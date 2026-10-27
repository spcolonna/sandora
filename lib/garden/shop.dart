import '../balance/balance.dart';
import 'economy.dart';

/// Monedas que se pueden dar o cobrar en el Mercado: piedritas, lotos y cada
/// esencia, por su nombre en el balance.
final walletKeys = {'pebbles', 'lotus', for (final e in Essence.values) e.name};

/// Un trueque del Mercado: da [give] a cambio de [cost]. [daily] limita
/// cuántas veces se hace por día (null: sin límite), así lo escaso sigue escaso.
class ShopOffer {
  final String id;
  final Map<String, int> give, cost;
  final int? daily;

  const ShopOffer(this.id, {required this.give, required this.cost, this.daily});

  factory ShopOffer.from(BalanceSection s) {
    Map<String, int> amounts(String key) {
      final m = s.nums(key).map((k, v) => MapEntry(k, v.round()));
      final bad = m.keys.where((k) => !walletKeys.contains(k));
      if (bad.isNotEmpty) throw FormatException('Moneda desconocida en ${s.s('id')}: $bad');
      return m;
    }

    return ShopOffer(
      s.s('id'),
      give: amounts('give'),
      cost: amounts('cost'),
      daily: s.has('daily') ? s.i('daily') : null,
    );
  }
}

/// Reglas del Mercado y de los lotos (GDD, Economía). Los minijuegos no dan
/// todas las monedas: lo que falta se consigue trocando, y los lotos son la
/// moneda escasa que se gana por constancia, no por jugar mucho.
class ShopRules {
  final List<ShopOffer> offers;

  /// Lotos por la ofrenda del día (la primera partida o meditación).
  final int lotusDaily;

  /// Lotos por cada nivel que sube el jardín.
  final int lotusPerLevel;

  /// Cada cuántos días de racha de meditación se dan [lotusStreakBonus] lotos.
  final int lotusStreakEvery, lotusStreakBonus;

  ShopRules(Balance balance)
    : offers = [for (final o in balance.section('shop').sections('offers')) ShopOffer.from(o)],
      lotusDaily = balance.section('shop').sub('lotus').i('daily'),
      lotusPerLevel = balance.section('shop').sub('lotus').i('perLevel'),
      lotusStreakEvery = balance.section('shop').sub('lotus').i('streakEvery'),
      lotusStreakBonus = balance.section('shop').sub('lotus').i('streakBonus');
}
