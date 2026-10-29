import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../garden/economy.dart';
import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../../ui/fx/sfx.dart';
import '../../ui/theme/palette.dart';
import 'intro_card.dart';
import 'result_panel.dart';

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

  /// La Calma al empezar la partida, para que el resultado llene la barra desde ahí.
  int _calmBefore = 0;

  /// La primera vez, antes de jugar, la tarjeta de cómo se juega.
  late bool _intro = !Progress.instance.introSeen.contains(widget.id);

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _outcome = null;
    _reward = null;
    _round++;
    _calmBefore = Progress.instance.calm;
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
    final choice = await showDialog<_PauseChoice>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Palette.paper,
        title: Text(tr('pause.title')),
        actionsOverflowButtonSpacing: 8,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, _PauseChoice.quit), child: Text(tr('pause.quit'))),
          TextButton(onPressed: () => Navigator.pop(context, _PauseChoice.restart), child: Text(tr('pause.restart'))),
          FilledButton(onPressed: () => Navigator.pop(context, _PauseChoice.resume), child: Text(tr('pause.resume'))),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case _PauseChoice.quit:
        Navigator.pop(context);
      case _PauseChoice.restart:
        // Lo jugado se descarta sin pagar: empezar de nuevo es inmediato.
        SoundBoard.instance.stopAllLoops(fade: const Duration(milliseconds: 200));
        setState(_start);
      case _PauseChoice.resume || null:
        _game.resumeEngine();
    }
  }

  @override
  void dispose() {
    SoundBoard.instance.stopAllLoops();
    super.dispose();
  }

  void _closeIntro() {
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
    Progress.instance.markIntroSeen(widget.id);
    setState(() => _intro = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_intro) {
      return Scaffold(
        body: IntroCard(id: widget.id, onStart: _closeIntro, onBack: () => Navigator.pop(context)),
      );
    }
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
            ResultPanel(
              id: widget.id,
              outcome: _outcome!,
              reward: _reward!,
              calmBefore: _calmBefore,
              onAgain: () {
                SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
                setState(_start);
              },
              onGarden: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

enum _PauseChoice { resume, restart, quit }
