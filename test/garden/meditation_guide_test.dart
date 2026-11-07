import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/meditation_guide.dart';
import 'package:sandora/garden/progress.dart';

import '../helpers.dart';

void main() {
  final balance = loadBalance();

  test('guía: en orden, sin pisarse y dentro de la sesión, de 1 a 20 min', () {
    for (final m in [1, 3, 5, 10, 15, 20]) {
      final s = MeditationGuide.script(m);
      expect(s.first.$2, 0, reason: '$m min arranca con la llegada');
      expect(s.last.$2, MeditationGuide.phrases - 1, reason: '$m min cierra con la despedida');
      for (var i = 1; i < s.length; i++) {
        expect(s[i].$1 - s[i - 1].$1, greaterThanOrEqualTo(MeditationGuide.visible + 2), reason: '$m min, frase $i');
        expect(s[i].$2, greaterThan(s[i - 1].$2), reason: 'las frases avanzan');
      }
      expect(s.last.$1 + MeditationGuide.visible, lessThanOrEqualTo(m * 60));
    }
    expect(MeditationGuide.script(1).length, 5);
    expect(MeditationGuide.script(20).length, 12, reason: 'la sesión larga usa todas las frases');
  });

  test('guía: phraseAt muestra la frase un rato y después silencio', () {
    expect(MeditationGuide.phraseAt(0, 5), isNull);
    expect(MeditationGuide.phraseAt(4, 5), 0);
    expect(MeditationGuide.phraseAt(12, 5), isNull);
    expect(MeditationGuide.phraseAt(55, 1), MeditationGuide.phrases - 1);
  });

  group('desbloqueo', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('cuesta lotos, una sola vez, y se guarda', () async {
      final p = Progress.instance;
      await p.load(balance);
      p.lotus = p.guidedCost - 1;
      expect(p.unlockGuided(), isFalse);
      p.lotus = p.guidedCost + 2;
      expect(p.unlockGuided(), isTrue);
      expect(p.lotus, 2);
      expect(p.guidedOn, isTrue);
      expect(p.unlockGuided(), isFalse, reason: 'ya está');
      expect(p.lotus, 2);
      await p.load(balance);
      expect(p.guidedUnlocked, isTrue);
    });
  });
}
