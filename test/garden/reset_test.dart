import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/progress.dart';

import '../helpers.dart';

void main() {
  test('reiniciar borra la partida y deja los ajustes', () async {
    SharedPreferences.setMockInitialValues({'pebbles': 500, 'calm': 12, 'guide.step': 4, 'language': 'en'});
    final p = Progress.instance;
    final balance = loadBalance();
    await p.load(balance);
    expect(p.pebbles, 500);
    await p.reset(balance);
    expect(p.pebbles, 0);
    expect(p.calm, 0);
    expect(p.guideStep, 0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('language'), 'en');
  });
}
