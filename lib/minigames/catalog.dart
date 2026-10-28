import 'package:flutter/material.dart';

import '../garden/economy.dart';
import '../garden/progress.dart';
import '../i18n/i18n.dart';
import '../ui/theme/palette.dart';
import 'bell/bell_game.dart';
import 'bonsai/bonsai_game.dart';
import 'common/minigame_screen.dart';
import 'enso/enso_game.dart';
import 'leaves/leaves_game.dart';
import 'moss/moss_game.dart';
import 'pond/pond_game.dart';
import 'rain/rain_game.dart';
import 'sand/sand_game.dart';
import 'shishi/shishi_game.dart';
import 'stack/stack_game.dart';

/// Un minijuego del jardín. El id es el que usan las claves de texto
/// (`mg.<id>.name`) y `game_balance.json`.
class MinigameInfo {
  final String id;
  final IconData icon;
  final Widget Function() screen;

  /// Unidad del récord en el tablón.
  final RecordUnit unit;
  const MinigameInfo(this.id, this.icon, this.screen, {this.unit = RecordUnit.points});

  String get name => tr('mg.$id.name');
  String get description => tr('mg.$id.desc');

  /// La esencia que da, leída del balance.
  Essence get essence => Progress.instance.economy.essenceOf(id);

  /// El récord propio, como se lee en el tablón.
  String get record {
    final p = Progress.instance;
    return switch (unit) {
      RecordUnit.stones => trN('board.stones', p.bestTower),
      RecordUnit.figures => trN('board.figures', p.sandFigures),
      RecordUnit.percent => tr('board.percent', {'n': p.best(id)}),
      RecordUnit.points => tr('board.points', {'n': id == 'rain' ? p.rainBest : p.best(id)}),
    };
  }
}

enum RecordUnit { points, stones, figures, percent }

/// Los minijuegos del jardín.
final minigames = [
  MinigameInfo('stack', Icons.filter_hdr_rounded, unit: RecordUnit.stones, () {
    return MinigameScreen(
      id: 'stack',
      build: StackGame.new,
      overlay: (context, game) => _StackOverlay(game as StackGame),
    );
  }),
  MinigameInfo(
    'sand',
    Icons.gesture_rounded,
    unit: RecordUnit.figures,
    () => const MinigameScreen(id: 'sand', build: SandGame.new),
  ),
  MinigameInfo('rain', Icons.water_drop_rounded, () => const MinigameScreen(id: 'rain', build: RainGame.new)),
  MinigameInfo('pond', Icons.local_florist_rounded, () {
    return MinigameScreen(id: 'pond', build: PondGame.new, overlay: (context, game) => _PondOverlay(game as PondGame));
  }),
  MinigameInfo('shishi', Icons.water_rounded, () => const MinigameScreen(id: 'shishi', build: ShishiGame.new)),
  MinigameInfo('leaves', Icons.eco_rounded, () {
    return MinigameScreen(
      id: 'leaves',
      build: LeavesGame.new,
      overlay: (context, game) => _LeavesOverlay(game as LeavesGame),
    );
  }),
  MinigameInfo(
    'moss',
    Icons.grass_rounded,
    unit: RecordUnit.percent,
    () => const MinigameScreen(id: 'moss', build: MossGame.new),
  ),
  MinigameInfo(
    'bonsai',
    Icons.park_rounded,
    unit: RecordUnit.percent,
    () => const MinigameScreen(id: 'bonsai', build: BonsaiGame.new),
  ),
  MinigameInfo(
    'enso',
    Icons.circle_outlined,
    unit: RecordUnit.percent,
    () => const MinigameScreen(id: 'enso', build: EnsoGame.new),
  ),
  MinigameInfo(
    'bell',
    Icons.notifications_rounded,
    unit: RecordUnit.percent,
    () => const MinigameScreen(id: 'bell', build: BellGame.new),
  ),
];

class _LeavesOverlay extends StatelessWidget {
  final LeavesGame game;
  const _LeavesOverlay(this.game);

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return IgnorePointer(
      child: ValueListenableBuilder(
        valueListenable: game.hud,
        builder: (context, hud, _) => Stack(
          children: [
            Positioned(
              top: pad.top + 16,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('leaves.pile', {'n': hud.inPile, 'total': hud.total}),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Palette.ink),
                  ),
                  Text(
                    tr('leaves.time', {'n': hud.seconds.ceil()}),
                    style: TextStyle(fontSize: 15, color: Palette.ink.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            if (hud.windWarning)
              Positioned(
                top: pad.top + 84,
                left: 20,
                right: 20,
                child: Text(
                  tr('leaves.wind'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Palette.ink),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PondOverlay extends StatelessWidget {
  final PondGame game;
  const _PondOverlay(this.game);

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return IgnorePointer(
      child: ValueListenableBuilder(
        valueListenable: game.hud,
        builder: (context, hud, _) => Stack(
          children: [
            Positioned(
              top: pad.top + 16,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('pond.points', {'n': hud.score}),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Palette.ink),
                  ),
                  Text(
                    trN('pond.moves', hud.moves),
                    style: TextStyle(fontSize: 15, color: Palette.ink.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            if (hud.current)
              Positioned(
                top: pad.top + 84,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Palette.paper.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(tr('pond.current'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trN('stack.height', hud.height),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Palette.ink),
                ),
                Text(
                  trN('stack.bag', hud.bag),
                  style: TextStyle(fontSize: 15, color: Palette.ink.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          if (hud.lostAt > 0)
            Positioned(
              top: pad.top + 130,
              left: 0,
              right: 0,
              child: IgnorePointer(
                // Aviso del derrumbe: aparece y se apaga solo.
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(hud.lostAt),
                  tween: Tween(begin: 1, end: 0),
                  duration: const Duration(milliseconds: 2600),
                  builder: (context, v, child) => Opacity(opacity: (v * 2).clamp(0, 1), child: child),
                  child: Text(
                    trN('stack.lost', hud.lost),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Palette.mossDark),
                  ),
                ),
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
          if (!hud.over)
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
