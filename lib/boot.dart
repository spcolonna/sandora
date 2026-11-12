import 'dart:async';

import 'package:flutter/foundation.dart';

import 'balance/balance.dart';
import 'garden/achievements.dart';
import 'garden/cloud_save.dart';
import 'garden/game_center.dart';
import 'garden/lotus_store.dart';
import 'garden/progress.dart';
import 'garden/reminders.dart';
import 'garden/weather_service.dart';
import 'minigames/catalog.dart';
import 'ui/fx/sfx.dart';
import 'ui/garden/scene_art.dart';

/// La carga pesada del arranque. Corre después de `runApp`, mientras se ven
/// la intro de Oraki y el título (como en Hexiege): así la pantalla nativa
/// no queda clavada y la animación no compite con la carga. El jardín espera
/// [ready]; las intros no.
class Boot {
  Boot._();
  static final instance = Boot._();

  final _done = Completer<void>();
  bool _started = false;

  Future<void> get ready => _done.future;
  bool get isReady => _done.isCompleted;

  Future<void> run() async {
    if (_started) return;
    _started = true;
    final b = Balance.instance;
    // Cada paso por su cuenta: si uno falla, el jardín abre igual.
    Future<void> step(String what, FutureOr<void> Function() f) async {
      try {
        await f();
      } catch (e, s) {
        debugPrint('Arranque, $what: $e\n$s');
      }
    }

    // Si la copia de iCloud va más adelantada (otro aparato, reinstalación),
    // entra antes de cargar la partida.
    await step('iCloud', CloudSave.instance.pull);
    await step('partida', () => Progress.instance.load(b));
    await step('copia', CloudSave.instance.start);
    await step('logros', () => Achievements.instance.start(minigames.map((m) => m.id)));
    // El audio carga de a un reproductor por vez, en segundo plano.
    unawaited(SoundBoard.instance.init());
    await step('clima', () => WeatherService.instance.load(b));
    await step('recordatorios', () => Reminders.instance.load(b));
    await step('arte', SceneArt.instance.load);
    if (!_done.isCompleted) _done.complete();
    // Lo que puede esperar: la venta de lotos, el clima real y Game Center
    // (que puede mostrar su cartel de bienvenida: después de la intro).
    unawaited(step('lotos', () => LotusStore.instance.load(b)));
    unawaited(step('clima real', WeatherService.instance.refresh));
    Future<void>.delayed(const Duration(seconds: 4), GameCenter.instance.start);
  }
}
