import 'dart:convert';
import 'dart:io';

import 'package:sandora/balance/balance.dart';

/// El balance real del juego, leído del archivo (sin assets de Flutter).
Balance loadBalance() => Balance.parse(File('assets/balance/game_balance.json').readAsStringSync());

/// El balance real con algún cambio para probar otra variante.
Balance loadBalanceWith(void Function(Map<String, dynamic> root) change) {
  final root = jsonDecode(File('assets/balance/game_balance.json').readAsStringSync()) as Map<String, dynamic>;
  change(root);
  return Balance(root);
}
