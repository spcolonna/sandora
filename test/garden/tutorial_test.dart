import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/progress.dart';

import '../helpers.dart';

void main() {
  final balance = loadBalance();
  final day = DateTime(2026, 10, 27, 10);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('los juegos del comienzo se abren por nivel, de a uno', () async {
    final p = Progress.instance;
    await p.load(balance, now: day);
    expect(p.gameUnlocked('sand'), isTrue);
    expect(p.gameUnlocked('rain'), isFalse);
    expect(p.lockedByLevel('rain'), isTrue);
    expect(p.unlockLevel('rain'), 2);
    expect(p.gameUnlocked('stack'), isFalse);
    // Dos partidas de tres estrellas: nivel 2, se abre Gotas (y su aviso).
    p.finishRun('sand', 3, now: day);
    p.finishRun('sand', 3, now: day);
    expect(p.level, 2);
    expect(p.gameUnlocked('rain'), isTrue);
    expect(p.gameUnlocked('stack'), isFalse);
    expect(p.newUnlocks(['rain']), isEmpty, reason: 'se anuncia con el nivel');
    expect(p.milestones, contains('level:2'));
  });

  test('un juego que ya se jugó no se vuelve a cerrar', () async {
    SharedPreferences.setMockInitialValues({'best.stack': 5});
    final p = Progress.instance;
    await p.load(balance, now: day);
    expect(p.gameUnlocked('stack'), isTrue);
  });

  test('la guía se juega: partida, Mercado, decoración, nivel 2, Gotas, nivel 3', () async {
    final p = Progress.instance;
    await p.load(balance, now: day);
    expect(p.guideStep, Guide.play);
    expect(p.decorUnlocked, isFalse);
    p.finishRun('sand', 1, now: day);
    expect(p.guideStep, Guide.market);
    p.advanceGuide(Guide.buy);
    // La primera decoración sale lo que da una partida.
    expect(p.tutorialDecor, isNotNull);
    expect(p.canBuyTutorial, isTrue);
    expect(p.buyTutorialDecor(), isTrue);
    expect(p.tutorialDecor, isNull, reason: 'una sola vez');
    expect(p.guideStep, Guide.place);
    expect(p.decorUnlocked, isTrue);
    expect(p.decorOpen, isFalse);
    expect(p.placeDecor(p.decor.first.id, 0, p.modelRules.start.first), isNotNull);
    expect(p.milestones, contains('decor:first'));
    p.advanceGuide(Guide.level2);
    // Sube al nivel 2: a probar Gotas.
    while (p.level < 2) {
      p.finishRun('sand', 3, now: day);
    }
    expect(p.guideStep, Guide.tryRain);
    p.finishRun('rain', 2, now: day);
    expect(p.guideStep, Guide.level3);
    while (p.level < 3) {
      p.finishRun('rain', 3, now: day);
    }
    expect(p.guideStep, Guide.decor);
    expect(p.decorOpen, isTrue);
    expect(p.gameUnlocked('stack'), isTrue);
  });

  test('la guía nunca vuelve atrás', () async {
    final p = Progress.instance;
    await p.load(balance, now: day);
    p.advanceGuide(Guide.place);
    p.advanceGuide(Guide.market);
    expect(p.guideStep, Guide.place);
  });

  test('quien jugaba con la guía vieja no repite el comienzo', () async {
    SharedPreferences.setMockInitialValues({'calm': 200, 'guide.step': 3});
    final p = Progress.instance;
    await p.load(balance, now: day);
    expect(p.guideStep, Guide.done);
    SharedPreferences.setMockInitialValues({'calm': 80, 'guide.step': 2});
    await p.load(balance, now: day);
    expect(p.guideStep, Guide.level3);
    SharedPreferences.setMockInitialValues({'calm': 200});
    await p.load(balance, now: day);
    expect(p.guideStep, Guide.decor);
  });

  test('los avisos grandes se guardan y salen en orden', () async {
    final p = Progress.instance;
    await p.load(balance, now: day);
    p.queueMilestone('level:2');
    p.queueMilestone('exp:patio1');
    await p.load(balance, now: day);
    expect(p.takeMilestone(), 'level:2');
    expect(p.takeMilestone(), 'exp:patio1');
    expect(p.takeMilestone(), isNull);
  });
}
