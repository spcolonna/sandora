import 'dart:async';

import 'package:flutter/material.dart';

import '../../garden/daily_goals.dart';
import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../fx/calm.dart';
import '../fx/reward_flight.dart';
import '../fx/sfx.dart';
import '../theme/palette.dart';
import 'currency.dart';
import 'washi.dart';

/// El texto de una meta del día ("Jugá 3 partidas").
String dailyLabel(GoalDef g) => g.id == 'all' ? tr('daily.all') : tr('daily.${g.id}', {'n': g.target});

IconData _iconOf(GoalDef g) => switch (g.kind) {
  _ when g.id == 'all' => Icons.auto_awesome_rounded,
  DailyKind.plays => Icons.replay_rounded,
  DailyKind.stars || DailyKind.three => Icons.star_rounded,
  DailyKind.variety => Icons.grid_view_rounded,
  DailyKind.record => Icons.emoji_events_rounded,
  DailyKind.meditate => Icons.self_improvement_rounded,
  DailyKind.gift => Icons.redeem_rounded,
  DailyKind.trade => Icons.storefront_rounded,
};

/// Lo que da una meta, como fichas de moneda.
Widget _gives(GoalDef g, {double scale = 0.85}) => Wrap(
  spacing: 6,
  children: [
    for (final e in g.give.entries)
      Transform.scale(
        scale: scale,
        child: CurrencyChip.of(e.key, e.value, prefix: '+'),
      ),
  ],
);

/// Las metas del día debajo de la próxima meta: tres puntos que se llenan.
/// Se toca para verlas.
class DailyGoalsLine extends StatelessWidget {
  const DailyGoalsLine({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final goals = p.goalsToday();
    final done = p.goalsDone();
    final all = done == goals.length;
    final style = TextStyle(fontSize: 13, color: Palette.ink.withValues(alpha: 0.7), fontWeight: FontWeight.w600);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
        showDailyGoalsSheet(context);
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(Icons.wb_twilight_rounded, size: 15, color: Palette.lantern.withValues(alpha: 0.9)),
            const SizedBox(width: 6),
            Text(all ? tr('daily.allDone') : tr('daily.title'), style: style),
            const SizedBox(width: 8),
            for (final g in goals)
              AnimatedContainer(
                duration: Calm.appear,
                margin: const EdgeInsets.only(right: 4),
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.goalDone(g) ? Palette.lantern : Colors.transparent,
                  border: Border.all(color: Palette.lantern, width: 1.4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> showDailyGoalsSheet(BuildContext context) {
  return showWashiSheet(
    context,
    builder: (context) => ListenableBuilder(
      listenable: Progress.instance,
      builder: (context, _) {
        final p = Progress.instance;
        final goals = p.goalsToday();
        final text = Theme.of(context).textTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr('daily.title'), style: text.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  tr('daily.hint'),
                  style: text.bodySmall?.copyWith(color: Palette.ink.withValues(alpha: 0.6)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                for (final (i, g) in goals.indexed)
                  CalmAppear(
                    delay: Duration(milliseconds: 80 * i),
                    rise: 8,
                    child: _GoalRow(goal: g, progress: p.goalProgress(g), done: p.goalDone(g)),
                  ),
                const Divider(height: 24),
                CalmAppear(
                  delay: const Duration(milliseconds: 260),
                  rise: 8,
                  child: _GoalRow(
                    goal: p.dailyGoals.bonus,
                    progress: p.goalsDone(),
                    done: p.goalsDone() == goals.length,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _GoalRow extends StatelessWidget {
  final GoalDef goal;
  final int progress;
  final bool done;
  const _GoalRow({required this.goal, required this.progress, required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: done ? Palette.lantern : Palette.sandShadow.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? Icons.check_rounded : _iconOf(goal),
              size: 20,
              color: done ? Palette.paper : Palette.ink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dailyLabel(goal),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: done ? Palette.ink.withValues(alpha: 0.55) : Palette.ink,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: progress / goal.target),
                        duration: Calm.appear,
                        builder: (context, v, _) => BrushBar(value: v, height: 7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$progress/${goal.target}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Opacity(opacity: done ? 0.45 : 1, child: _gives(goal)),
        ],
      ),
    );
  }
}

/// Una meta cumplida en el resultado de una partida: aparece con su nota.
class GoalDoneRow extends StatelessWidget {
  final GoalDef goal;
  const GoalDoneRow(this.goal, {super.key});

  @override
  Widget build(BuildContext context) {
    final bonus = goal.id == 'all';
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Palette.lantern.withValues(alpha: bonus ? 0.28 : 0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(bonus ? Icons.auto_awesome_rounded : Icons.check_circle_rounded, color: Palette.wood, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bonus ? tr('daily.allDone') : tr('daily.done'),
                  style: TextStyle(fontSize: 11, color: Palette.ink.withValues(alpha: 0.6)),
                ),
                Text(dailyLabel(goal), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
          _gives(goal, scale: 0.8),
        ],
      ),
    );
  }
}

/// Anuncia en el jardín las metas cumplidas fuera de una partida: una tarjeta
/// sube desde abajo, suena y lo ganado vuela a los contadores.
abstract final class GoalToast {
  static void show(BuildContext context, List<GoalDef> goals) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null || goals.isEmpty) return;
    final size = MediaQuery.sizeOf(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: 24,
        right: 24,
        bottom: 110,
        child: _Toast(goals: goals, onDone: () => entry.remove()),
      ),
    );
    overlay.insert(entry);
    SoundBoard.instance.play(Sfx.great, volume: 0.5);
    Haptics.medium();
    var wait = 700;
    for (final g in goals) {
      for (final e in g.give.entries) {
        Timer(Duration(milliseconds: wait), () {
          if (context.mounted) {
            RewardFlight.fly(
              context,
              from: Offset(size.width / 2, size.height - 140),
              currency: e.key,
              amount: e.value,
            );
          }
        });
        wait += 180;
      }
    }
  }
}

class _Toast extends StatefulWidget {
  final List<GoalDef> goals;
  final VoidCallback onDone;
  const _Toast({required this.goals, required this.onDone});

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> {
  var _visible = true;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    _hide = Timer(Duration(milliseconds: 2600 + 600 * widget.goals.length), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: Calm.appear,
        onEnd: () {
          if (!_visible) widget.onDone();
        },
        child: CalmAppear(
          rise: 24,
          child: Material(
            color: Palette.paper,
            elevation: 6,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(mainAxisSize: MainAxisSize.min, children: [for (final g in widget.goals) GoalDoneRow(g)]),
            ),
          ),
        ),
      ),
    );
  }
}
