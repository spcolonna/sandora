import 'package:flutter/material.dart';

import '../garden/economy.dart';
import '../i18n/i18n.dart';
import '../ui/theme/palette.dart';
import 'common/minigame_screen.dart';
import 'rain/rain_game.dart';
import 'sand/sand_game.dart';
import 'stack/stack_game.dart';

/// Un minijuego del jardín. El id es el que usan las claves de texto
/// (`mg.<id>.name`) y `game_balance.json`.
class MinigameInfo {
  final String id;
  final Essence essence;
  final IconData icon;
  final Widget Function() screen;
  const MinigameInfo(this.id, this.essence, this.icon, this.screen);

  String get name => tr('mg.$id.name');
  String get description => tr('mg.$id.desc');
}

/// Los 3 minijuegos del prototipo (fase 1).
final minigames = [
  MinigameInfo('stack', Essence.sand, Icons.filter_hdr_rounded, () {
    return MinigameScreen(
      id: 'stack',
      build: StackGame.new,
      overlay: (context, game) => _StackOverlay(game as StackGame),
    );
  }),
  MinigameInfo(
    'sand',
    Essence.sand,
    Icons.gesture_rounded,
    () => const MinigameScreen(id: 'sand', build: SandGame.new),
  ),
  MinigameInfo(
    'rain',
    Essence.water,
    Icons.water_drop_rounded,
    () => const MinigameScreen(id: 'rain', build: RainGame.new),
  ),
];

class _StackOverlay extends StatelessWidget {
  final StackGame game;
  const _StackOverlay(this.game);

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return ValueListenableBuilder(
      valueListenable: game.hud,
      builder: (context, hud, _) => Stack(
        children: [
          Positioned(
            top: pad.top + 16,
            left: 20,
            child: Text(
              trN('stack.height', hud.height),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Palette.ink),
            ),
          ),
          if (hud.windWarning || hud.windBlowing)
            Positioned(
              top: pad.top + 64,
              left: 20,
              right: 20,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Palette.paper.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(tr('stack.wind'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
          if (!hud.over && hud.height > 0)
            Positioned(
              bottom: pad.bottom + 20,
              right: 20,
              child: FilledButton.tonal(onPressed: game.endRun, child: Text(tr('stack.finish'))),
            ),
        ],
      ),
    );
  }
}
