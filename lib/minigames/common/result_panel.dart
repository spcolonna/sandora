import 'dart:async';

import 'package:flutter/material.dart';

import '../../garden/daily_goals.dart';
import '../../garden/economy.dart';
import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../../ui/fx/calm.dart';
import '../../ui/fx/sfx.dart';
import '../../ui/theme/palette.dart';
import '../../ui/widgets/currency.dart';
import '../../ui/widgets/daily_goals.dart';
import '../../ui/widgets/level_up.dart';
import '../../ui/widgets/next_goal.dart';
import '../../ui/widgets/washi.dart';
import '../catalog.dart';
import 'minigame_screen.dart';

/// El final de una partida, en el orden en que se festeja: las estrellas se
/// encienden de a una con su nota, aparece el récord, después lo ganado, la
/// barra de nivel que se llena y la próxima meta. "Otra vez" queda a mano.
class ResultPanel extends StatefulWidget {
  final String id;
  final RunOutcome outcome;
  final Reward reward;

  /// La Calma antes de la partida, para llenar la barra desde ahí.
  final int calmBefore;

  /// Metas del día que se cumplieron con esta partida.
  final List<GoalDef> goals;

  /// Si el matcha quedó servido en la casa de té, esperando una visita.
  final bool teaServed;
  final VoidCallback onAgain, onGarden;

  const ResultPanel({
    super.key,
    required this.id,
    required this.outcome,
    required this.reward,
    required this.calmBefore,
    this.goals = const [],
    this.teaServed = false,
    required this.onAgain,
    required this.onGarden,
  });

  @override
  State<ResultPanel> createState() => _ResultPanelState();
}

class _ResultPanelState extends State<ResultPanel> {
  static const _starAt = 550, _starEvery = 280;
  final _timers = <Timer>[];

  int get _afterStars => _starAt + _starEvery * 3 + 150;

  /// Cuándo termina de llenarse la barra de nivel.
  int get _barDone => _afterStars + 700 + 1300;

  /// Cuándo aparece cada meta cumplida, después de la barra de nivel (y del
  /// cartel de nivel nuevo, si lo hay).
  int _goalAt(int i) => (widget.reward.newLevel != null ? _barDone + 900 : _afterStars + 1500) + 350 * i;

  /// Los botones esperan un instante: el último toque de una partida rápida
  /// no debe saltearse el resultado.
  bool _armed = false;

  @override
  void initState() {
    super.initState();
    // Cada estrella suena una nota más alta al encenderse; la tercera, con
    // todo: es la partida perfecta.
    for (var i = 0; i < widget.outcome.stars; i++) {
      _at(_starAt + _starEvery * i + 120, () {
        SoundBoard.instance.play(Sfx.rainNote, variant: 2 + i, volume: 0.45);
        if (i == 2) {
          SoundBoard.instance.play(Sfx.perfect, volume: 0.4);
          Haptics.perfect();
        } else {
          Haptics.light();
        }
      });
    }
    // Lo ganado cuenta con un tic suave por moneda.
    for (var i = 0; i < _chipCount; i++) {
      _at(_afterStars + 150 + 120 * i + 60, () => SoundBoard.instance.play(Sfx.pluck, volume: 0.18));
    }
    // El nivel nuevo suena cuando la barra se llena, junto con su cartel.
    if (widget.reward.newLevel != null) {
      _at(_barDone, () {
        SoundBoard.instance.play(Sfx.bell, volume: 0.7);
        Haptics.perfect();
      });
    }
    _at(900, () {
      if (mounted) setState(() => _armed = true);
    });
    if (widget.outcome.record) {
      _at(_afterStars, () {
        SoundBoard.instance.play(Sfx.great, volume: 0.5);
        Haptics.medium();
      });
    }
    for (var i = 0; i < widget.goals.length; i++) {
      _at(_goalAt(i), () {
        SoundBoard.instance.play(Sfx.rainNote, variant: 5, volume: 0.45);
        Haptics.medium();
      });
    }
  }

  int get _chipCount => 2 + (widget.reward.essenceAmount > 0 ? 1 : 0) + (widget.reward.lotus > 0 ? 1 : 0);

  void _at(int ms, VoidCallback f) => _timers.add(Timer(Duration(milliseconds: ms), f));

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final outcome = widget.outcome, reward = widget.reward;
    final info = minigames.where((m) => m.id == widget.id).firstOrNull;
    Duration after(int ms) => Duration(milliseconds: _afterStars + ms);
    return Positioned.fill(
      // El velo se oscurece de a poco y el panel sube con un fundido.
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        builder: (context, t, child) => ColoredBox(
          color: Palette.ink.withValues(alpha: 0.35 * t),
          child: child,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: CalmAppear(
                delay: const Duration(milliseconds: 150),
                rise: 18,
                child: WashiCard(
                  frame: WashiFrame.result,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tr('mg.${widget.id}.name'), style: text.titleMedium),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Las estrellas se encienden de a una, como faroles.
                          for (var i = 0; i < 3; i++)
                            CalmAppear(
                              delay: Duration(milliseconds: _starAt + _starEvery * i),
                              fromScale: 0.6,
                              rise: 0,
                              child: _Star(lit: i < outcome.stars, delay: _starAt + _starEvery * i),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(outcome.headline, style: text.headlineSmall, textAlign: TextAlign.center),
                      if (outcome.detail?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(outcome.detail!, style: text.bodyMedium, textAlign: TextAlign.center),
                        ),
                      const SizedBox(height: 4),
                      CalmAppear(
                        delay: after(0),
                        child: outcome.record
                            ? ReadyGlow(
                                child: Text(
                                  tr('result.record'),
                                  style: text.titleSmall?.copyWith(color: Palette.wood, fontWeight: FontWeight.w800),
                                ),
                              )
                            : info == null
                            ? const SizedBox.shrink()
                            : Text(
                                tr('result.best', {'v': info.record}),
                                style: text.bodySmall?.copyWith(color: Palette.ink.withValues(alpha: 0.6)),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(tr('result.rewards'), style: text.labelLarge),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final (i, chip) in <Widget Function(Duration)>[
                            (d) => CurrencyChip.pebbles(reward.pebbles, prefix: '+', from: 0, delay: d),
                            if (reward.essenceAmount > 0)
                              (d) => CurrencyChip.essence(
                                reward.essence,
                                reward.essenceAmount,
                                prefix: '+',
                                from: 0,
                                delay: d,
                              ),
                            if (reward.lotus > 0)
                              (d) => CurrencyChip.lotus(reward.lotus, prefix: '+', from: 0, delay: d),
                            (d) => CalmChip(reward.calm, delay: d),
                          ].indexed)
                            CalmAppear(
                              delay: after(150 + 120 * i),
                              fromScale: 0.85,
                              rise: 6,
                              child: chip(after(150 + 120 * i)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      CalmAppear(
                        delay: after(500),
                        child: _LevelGain(before: widget.calmBefore, gained: reward.calm, delay: after(700)),
                      ),
                      if (reward.newLevel != null) ...[
                        const SizedBox(height: 12),
                        LevelUpBanner(reward.newLevel!, delay: Duration(milliseconds: _barDone - 80)),
                      ],
                      for (final (i, g) in widget.goals.indexed)
                        CalmAppear(
                          delay: Duration(milliseconds: _goalAt(i)),
                          fromScale: 0.9,
                          child: GoalDoneRow(g),
                        ),
                      if (widget.teaServed)
                        CalmAppear(
                          delay: after(700),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.emoji_food_beverage_rounded, size: 18, color: Palette.moss),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    tr('tea.result'),
                                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      CalmAppear(delay: after(900), child: const NextGoal(tappable: false)),
                      if (reward.tired) ...[
                        const SizedBox(height: 8),
                        Text(tr('result.tired'), style: text.bodySmall, textAlign: TextAlign.center),
                      ],
                      const SizedBox(height: 16),
                      // "Otra vez" es lo más grande y está a mano; el jardín, debajo.
                      IgnorePointer(
                        ignoring: !_armed,
                        child: Column(
                          children: [
                            InkButton(label: tr('result.again'), glyph: InkGlyph.replay, onPressed: widget.onAgain),
                            const SizedBox(height: 4),
                            InkButton.quiet(label: tr('result.garden'), onPressed: widget.onGarden),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Una estrella. Encendida, deja un halo cálido que late una vez.
class _Star extends StatelessWidget {
  final bool lit;
  final int delay;
  const _Star({required this.lit, required this.delay});

  @override
  Widget build(BuildContext context) {
    final star = Image.asset(
      'assets/images/icons/icon_star.webp',
      width: 50,
      height: 50,
      filterQuality: FilterQuality.medium,
    );
    if (!lit) return Opacity(opacity: 0.22, child: star);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: delay + 900),
      builder: (context, t, child) {
        final k = ((t * (delay + 900) - delay) / 900).clamp(0.0, 1.0);
        final glow = k * (1 - k) * 4;
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              if (glow > 0)
                BoxShadow(color: Palette.lantern.withValues(alpha: 0.55 * glow), blurRadius: 22, spreadRadius: 2),
            ],
          ),
          child: child,
        );
      },
      child: star,
    );
  }
}

/// El nivel y su barra, que se llena desde donde estaba con la Calma ganada.
class _LevelGain extends StatelessWidget {
  final int before, gained;
  final Duration delay;
  const _LevelGain({required this.before, required this.gained, required this.delay});

  @override
  Widget build(BuildContext context) {
    final levels = Progress.instance.levels;
    final level = levels.levelFor(before);
    final from = levels.progress(before);
    // Si sube de nivel, se llena entera: el cartel del nivel nuevo sigue.
    final to = levels.levelFor(before + gained) > level ? 1.0 : levels.progress(before + gained);
    final total = delay + const Duration(milliseconds: 1300);
    final wait = delay.inMilliseconds / total.inMilliseconds;
    return Row(
      children: [
        Text(tr('level.short', {'n': level}), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(width: 10),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: from, end: to),
            duration: total,
            curve: Interval(wait, 1, curve: Curves.easeInOutCubic),
            builder: (context, v, _) => StoneBar(value: v),
          ),
        ),
      ],
    );
  }
}
