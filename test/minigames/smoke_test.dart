import 'dart:convert';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sandora/balance/balance.dart';
import 'package:sandora/minigames/common/minigame_screen.dart';
import 'package:sandora/minigames/bell/bell_game.dart';
import 'package:sandora/minigames/bonsai/bonsai_game.dart';
import 'package:sandora/minigames/enso/enso_game.dart';
import 'package:sandora/minigames/flute/flute_game.dart';
import 'package:sandora/minigames/lanterns/lanterns_game.dart';
import 'package:sandora/minigames/leaves/leaves_game.dart';
import 'package:sandora/minigames/matcha/matcha_game.dart';
import 'package:sandora/minigames/moss/moss_game.dart';
import 'package:sandora/minigames/pond/pond_game.dart';
import 'package:sandora/minigames/rain/rain_game.dart';
import 'package:sandora/minigames/sand/sand_game.dart';
import 'package:sandora/minigames/shishi/shishi_game.dart';
import 'package:sandora/minigames/stack/stack_game.dart';

import '../helpers.dart';

/// Claves repetidas dentro de un mismo objeto JSON (jsonDecode se queda con la
/// última sin avisar: así se perdió el startGrace de musgo y bonsái).
List<String> duplicateKeys(String json) {
  final dups = <String>[];
  final stack = <Set<String>>[];
  var i = 0;
  while (i < json.length) {
    final c = json[i];
    if (c == '"') {
      final start = ++i;
      while (json[i] != '"') {
        if (json[i] == r'\') i++;
        i++;
      }
      final s = json.substring(start, i);
      var j = i + 1;
      while (j < json.length && ' \n\r\t'.contains(json[j])) {
        j++;
      }
      if (j < json.length && json[j] == ':' && stack.isNotEmpty) {
        if (!stack.last.add(s)) dups.add(s);
      }
    } else if (c == '{') {
      stack.add(<String>{});
    } else if (c == '}') {
      stack.removeLast();
    }
    i++;
  }
  return dups;
}

void main() {
  test('el balance no tiene claves repetidas', () {
    final text = File('assets/balance/game_balance.json').readAsStringSync();
    jsonDecode(text);
    expect(duplicateKeys(text), isEmpty);
  });

  final games = <String, GameBuilder>{
    'stack': StackGame.new,
    'sand': SandGame.new,
    'rain': RainGame.new,
    'pond': PondGame.new,
    'shishi': ShishiGame.new,
    'leaves': LeavesGame.new,
    'moss': MossGame.new,
    'bonsai': BonsaiGame.new,
    'enso': EnsoGame.new,
    'bell': BellGame.new,
    'matcha': MatchaGame.new,
    'flute': FluteGame.new,
    'lanterns': LanternsGame.new,
  };

  TestWidgetsFlutterBinding.ensureInitialized();
  Balance.instance = loadBalance();

  for (final e in games.entries) {
    test('${e.key}: carga y avanza sin errores', () async {
      final FlameGame game = e.value((_) {});
      game.onGameResize(Vector2(390, 844));
      await game.onLoad();
      for (var k = 0; k < 120; k++) {
        game.update(1 / 60);
      }
    });
  }
}
