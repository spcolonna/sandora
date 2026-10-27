import 'dart:io';

import 'package:zen_garden/balance/balance.dart';

/// El balance real del juego, leído del archivo (sin assets de Flutter).
Balance loadBalance() => Balance.parse(File('assets/balance/game_balance.json').readAsStringSync());
