import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../garden/economy.dart';
import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../../ui/fx/calm.dart';
import '../../ui/fx/sfx.dart';
import '../../ui/theme/palette.dart';
import '../../ui/widgets/currency.dart';
import '../../ui/widgets/level_up.dart';

/// Cómo terminó una partida. Nunca hay game over duro: siempre hay puntaje,
/// estrellas o una altura alcanzada (GDD, pilar 6).
class RunOutcome {
  final int score;
  final int stars;

  /// Línea principal del resultado ("12 piedras", "Profundidad 84%").
  final String headline;
  final bool record;
  const RunOutcome({required this.score, required this.stars, required this.headline, this.record = false});
}

typedef GameBuilder = FlameGame Function(void Function(RunOutcome) finish);

/// Pantalla que aloja un minijuego: pausa, aviso inicial y resultado con la
/// recompensa. Cerrar la app no pierde nada: lo ganado se paga al terminar.
class MinigameScreen extends StatefulWidget {
  final String id;
  final GameBuilder build;
  final Widget Function(BuildContext context, FlameGame game)? overlay;

  const MinigameScreen({super.key, required this.id, required this.build, this.overlay});

  @override
  State<MinigameScreen> createState() => _MinigameScreenState();
}

class _MinigameScreenState extends State<MinigameScreen> {
  late FlameGame _game;
  RunOutcome? _outcome;
  Reward? _reward;
  int _round = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _outcome = null;
    _reward = null;
    _round++;
    _game = widget.build(_finish);
  }

  void _finish(RunOutcome outcome) {
    if (!mounted || _outcome != null) return;
    final reward = Progress.instance.finishRun(widget.id, outcome.stars);
    if (reward.newLevel != null) {
      SoundBoard.instance.play(Sfx.bell, volume: 0.7);
      Haptics.perfect();
    }
    setState(() {
      _outcome = outcome;
      _reward = reward;
    });
  }

  Future<void> _pause() async {
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
    _game.pauseEngine();
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Palette.paper,
        title: Text(tr('pause.title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(tr('pause.quit'))),
          FilledButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('pause.resume'))),
        ],
      ),
    );
    if (!mounted) return;
    if (quit == true) {
      Navigator.pop(context);
    } else {
      _game.resumeEngine();
    }
  }

  @override
  void dispose() {
    SoundBoard.instance.stopAllLoops();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GameWidget(key: ValueKey(_round), game: _game),
          ),
          if (widget.overlay != null && _outcome == null) widget.overlay!(context, _game),
          if (_outcome == null)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 12,
              child: IconButton.filledTonal(onPressed: _pause, icon: const Icon(Icons.pause_rounded)),
            ),
          if (_outcome != null)
            _ResultPanel(
              title: tr('mg.${widget.id}.name'),
              outcome: _outcome!,
              reward: _reward!,
              onAgain: () => setState(_start),
              onGarden: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  final String title;
  final RunOutcome outcome;
  final Reward reward;
  final VoidCallback onAgain, onGarden;

  const _ResultPanel({
    required this.title,
    required this.outcome,
    required this.reward,
    required this.onAgain,
    required this.onGarden,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Positioned.fill(
      // El velo se oscurece de a poco y el panel sube con un fundido.
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        builder: (context, t, child) => ColoredBox(
          color: Palette.ink.withValues(alpha: 0.35 * t),
          child: child,
        ),
        child: Center(
          child: CalmAppear(
            delay: const Duration(milliseconds: 150),
            rise: 18,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              decoration: BoxDecoration(color: Palette.paper, borderRadius: BorderRadius.circular(24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: text.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Las estrellas se encienden de a una, como faroles.
                      for (var i = 0; i < 3; i++)
                        CalmAppear(
                          delay: Duration(milliseconds: 550 + 280 * i),
                          fromScale: 0.8,
                          rise: 0,
                          child: Icon(
                            i < outcome.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 44,
                            color: i < outcome.stars ? Palette.perfect : Palette.stoneLight,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(outcome.headline, style: text.headlineSmall, textAlign: TextAlign.center),
                  if (outcome.record) ...[
                    const SizedBox(height: 4),
                    Text(tr('result.record'), style: text.titleSmall?.copyWith(color: Palette.wood)),
                  ],
                  const SizedBox(height: 16),
                  Text(tr('result.rewards'), style: text.labelLarge),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      CurrencyChip.pebbles(reward.pebbles, prefix: '+'),
                      if (reward.essenceAmount > 0)
                        CurrencyChip.essence(reward.essence, reward.essenceAmount, prefix: '+'),
                      CalmChip(reward.calm),
                    ],
                  ),
                  if (reward.newLevel != null) ...[const SizedBox(height: 12), LevelUpBanner(reward.newLevel!)],
                  if (reward.tired) ...[
                    const SizedBox(height: 8),
                    Text(tr('result.tired'), style: text.bodySmall, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(onPressed: onGarden, child: Text(tr('result.garden'))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(onPressed: onAgain, child: Text(tr('result.again'))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
