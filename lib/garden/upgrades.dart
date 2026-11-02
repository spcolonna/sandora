import '../balance/balance.dart';

/// Un nivel de mejora de un lugar: desde qué nivel del jugador se puede,
/// cuánto cuesta (Piedritas y la esencia del lugar) y cuánto más rinden sus
/// partidas en Piedritas.
class UpgradeTier {
  final int level, pebbles, essence;
  final double bonus;
  const UpgradeTier({required this.level, required this.pebbles, required this.essence, required this.bonus});

  factory UpgradeTier.from(BalanceSection s) =>
      UpgradeTier(level: s.i('level'), pebbles: s.i('pebbles'), essence: s.i('essence'), bonus: s.d('bonus'));
}

/// Mejoras de los lugares del jardín: cada lugar con minijuego tiene los
/// mismos niveles. Dart puro.
class UpgradeRules {
  final List<UpgradeTier> tiers;

  /// Los lugares que se mejoran (ids de minijuego).
  final List<String> places;

  UpgradeRules(Balance balance)
    : tiers = [for (final s in balance.section('upgrades').sections('tiers')) UpgradeTier.from(s)],
      places = balance.section('upgrades').strings('places');

  int get maxTier => tiers.length;

  /// El próximo nivel para un lugar que ya tiene [tier] (null si está al máximo).
  UpgradeTier? next(int tier) => tier < tiers.length ? tiers[tier] : null;

  /// Cuánto más rinde en Piedritas un lugar con [tier] (0.1 = +10 %).
  double bonus(int tier) => tier == 0 ? 0 : tiers[tier - 1].bonus;
}
