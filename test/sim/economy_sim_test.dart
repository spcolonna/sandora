import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sandora/balance/balance.dart';

import '../helpers.dart';
import 'economy_sim.dart';

/// Simula jugadores tipo con el código y el balance reales. Con
/// `SANDORA_SIM=1 flutter test test/sim` imprime el informe completo; con
/// `SANDORA_SIM_BALANCE=<archivo>` simula otro balance (para probar cambios).
void main() {
  final other = Platform.environment['SANDORA_SIM_BALANCE'];
  final balance = other == null ? loadBalance() : Balance.parse(File(other).readAsStringSync());
  final full = Platform.environment['SANDORA_SIM'] == '1';

  test('cada perfil avanza y el dedicado compra todas las ampliaciones', () async {
    final runs = [
      for (final profile in Profile.all)
        [
          for (var seed = 1; seed <= (full ? 7 : 1); seed++)
            await simulate(balance, profile, days: full ? 90 : 60, seed: seed),
        ],
    ];
    if (full) {
      // ignore: avoid_print
      print(report(balance, runs));
    }
    for (final rs in runs) {
      expect(rs.first.level, greaterThan(5), reason: rs.first.profile.name);
    }
    final devoted = runs.last.first;
    expect(devoted.boughtDay.length, balance.expansions.length);
    expect(devoted.decorBought, greaterThan(0), reason: 'las Piedritas que sobran van a decoraciones');
  });
}
