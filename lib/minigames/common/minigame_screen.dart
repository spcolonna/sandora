import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../garden/economy.dart';
import '../../garden/progress.dart';
import '../../garden/reminders.dart';
import '../../i18n/i18n.dart';
import '../../ui/fx/sfx.dart';
import '../../ui/widgets/soft.dart';
import '../../ui/widgets/washi.dart';
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

  /// Un renglón chico debajo del titular, con el detalle de la partida.
  final String? detail;

  const RunOutcome({
    required this.score,
    required this.stars,
    required this.headline,
    this.detail,
    this.record = false,
  });
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

  /// Si la hoja de pausa está abierta (para no abrirla dos veces).
  bool _paused = false;

  /// Una llamada, el centro de control o salir de la app pausan la partida:
  /// al volver, la pausa espera y nada se perdió.
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(onInactive: _autoPause, onHide: _autoPause);

  void _autoPause() {
    if (!mounted || _intro || _outcome != null || _paused) return;
    _pause(quiet: true);
  }

  @override
  void initState() {
    super.initState();
    _lifecycle;
    _start();
    // La música del jardín se funde con la de este juego.
    SoundBoard.instance.music(set: widget.id, volume: 0.24);
  }

  void _start() {
    _outcome = null;
    _reward = null;
    _round++;
    _calmBefore = Progress.instance.calm;
    // Un final que llega tarde (los juegos esperan un poco antes de cerrar)
    // no paga ni muestra nada si en el medio se reinició la partida.
    final round = _round;
    _game = widget.build((o) {
      if (round == _round) _finish(o);
    });
  }

  void _finish(RunOutcome outcome) {
    if (!mounted || _outcome != null) return;
    final reward = Progress.instance.finishRun(widget.id, outcome.stars, record: outcome.record);
    final p = Progress.instance;
    if (p.lastRunTea) Reminders.instance.teaServed(p.teaArrivesAt, p.teaVisitor().id);
    setState(() {
      _outcome = outcome;
      _reward = reward;
    });
  }

  Future<void> _pause({bool quiet = false}) async {
    if (_paused) return;
    _paused = true;
    if (!quiet) SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
    _game.pauseEngine();
    SoundBoard.instance.holdLoops();
    final choice = await showWashiDialog<_PauseChoice>(
      context,
      title: tr('pause.title'),
      actions: [
        InkButton(
          label: tr('pause.resume'),
          glyph: InkGlyph.play,
          onPressed: () => Navigator.pop(context, _PauseChoice.resume),
        ),
        InkButton.quiet(
          label: tr('pause.restart'),
          glyph: InkGlyph.replay,
          onPressed: () => Navigator.pop(context, _PauseChoice.restart),
        ),
        InkButton.quiet(label: tr('pause.quit'), onPressed: () => Navigator.pop(context, _PauseChoice.quit)),
      ],
    );
    _paused = false;
    if (!mounted) return;
    switch (choice) {
      case _PauseChoice.quit:
        SoundBoard.instance.play(Sfx.uiTap, volume: 0.35);
        Navigator.pop(context);
      case _PauseChoice.restart:
        // Lo jugado se descarta sin pagar: empezar de nuevo es inmediato.
        SoundBoard.instance.stopAllLoops(fade: const Duration(milliseconds: 200), music: false);
        setState(_start);
      case _PauseChoice.resume || null:
        SoundBoard.instance.play(Sfx.uiTap, volume: 0.35);
        SoundBoard.instance.releaseLoops();
        _game.resumeEngine();
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _hush();
    super.dispose();
  }

  bool _hushed = false;

  /// Apaga los ambientes del juego al salir; la música no (el jardín funde la
  /// suya). Se hace al cerrar la pantalla y no al desarmarla, que llega
  /// después: si no, apagaba lo que el jardín ya había vuelto a prender.
  void _hush() {
    if (_hushed) return;
    _hushed = true;
    SoundBoard.instance.stopAllLoops(music: false);
  }

  void _closeIntro() {
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
    Progress.instance.markIntroSeen(widget.id);
    setState(() => _intro = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // En plena partida, el gesto de volver pausa en vez de salir sin aviso.
      canPop: _intro || _outcome != null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _hush();
        } else {
          _pause();
        }
      },
      child: _screen(context),
    );
  }

  Widget _screen(BuildContext context) {
    // De la tarjeta al juego, y de una partida a la siguiente, con un fundido:
    // nada se corta de golpe.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _intro
          ? Scaffold(
              key: const ValueKey('intro'),
              body: IntroCard(id: widget.id, onStart: _closeIntro, onBack: () => Navigator.pop(context)),
            )
          : KeyedSubtree(key: ValueKey(_round), child: _play(context)),
    );
  }

  Widget _play(BuildContext context) {
    final playing = _outcome == null;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: _game)),
          if (widget.overlay != null)
            Positioned.fill(
              child: SoftShow(visible: playing, rise: 0, child: widget.overlay!(context, _game)),
            ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 12,
            child: SoftShow(
              visible: playing,
              rise: 0,
              child: InkIconButton(glyph: InkGlyph.pause, onPressed: _pause, tooltip: tr('pause.title')),
            ),
          ),
          if (_outcome != null)
            ResultPanel(
              id: widget.id,
              outcome: _outcome!,
              reward: _reward!,
              calmBefore: _calmBefore,
              goals: Progress.instance.lastRunGoals,
              teaServed: Progress.instance.lastRunTea,
              onAgain: () {
                SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
                setState(_start);
              },
              onGarden: () {
                SoundBoard.instance.play(Sfx.uiTap, volume: 0.35);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}

enum _PauseChoice { resume, restart, quit }
