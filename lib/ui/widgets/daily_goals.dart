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
String dailyLabel(GoalDef g) => switch (g.id) {
  'all' => tr('daily.all'),
  'chest' => tr('daily.chest'),
  _ => tr('daily.${g.id}', {'n': g.target}),
};

IconData _iconOf(GoalDef g) => switch (g.kind) {
  _ when g.id == 'all' => Icons.auto_awesome_rounded,
  _ when g.id == 'chest' => Icons.inventory_2_rounded,
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
/// Se toca para verlas. Si las de hoy todavía no se miraron, brilla suave.
class DailyGoalsLine extends StatefulWidget {
  const DailyGoalsLine({super.key});

  @override
  State<DailyGoalsLine> createState() => _DailyGoalsLineState();
}

class _DailyGoalsLineState extends State<DailyGoalsLine> with SingleTickerProviderStateMixin {
  late final _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final goals = p.goalsToday();
    final done = p.goalsDone();
    final all = done == goals.length;
    final fresh = p.goalsUnseen();
    if (fresh && !_glow.isAnimating) {
      _glow.repeat(reverse: true);
    } else if (!fresh && _glow.isAnimating) {
      _glow
        ..stop()
        ..value = 0;
    }
    final style = TextStyle(fontSize: 13, color: Palette.ink.withValues(alpha: 0.7), fontWeight: FontWeight.w600);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
        showDailyGoalsSheet(context);
      },
      child: AnimatedBuilder(
        animation: _glow,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_glow.value);
          return Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Palette.lantern.withValues(alpha: 0.22 * t),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (t > 0)
                  BoxShadow(
                    color: Palette.lantern.withValues(alpha: 0.35 * t),
                    blurRadius: 10 * t,
                  ),
              ],
            ),
            child: child,
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wb_twilight_rounded, size: 15, color: Palette.lantern.withValues(alpha: 0.9)),
            const SizedBox(width: 6),
            Text(
              all
                  ? tr('daily.allDone')
                  : fresh
                  ? tr('daily.new')
                  : tr('daily.title'),
              style: style,
            ),
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
  Progress.instance.markGoalsSeen();
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
                const SizedBox(height: 10),
                CalmAppear(
                  delay: const Duration(milliseconds: 340),
                  rise: 8,
                  child: _ChestRow(seals: p.goalSeals, chest: p.dailyGoals.chest),
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

/// El cofre del jardín: un sello por cada día completo y lo que da al abrirse.
class _ChestRow extends StatelessWidget {
  final int seals;
  final GoalDef chest;
  const _ChestRow({required this.seals, required this.chest});

  @override
  Widget build(BuildContext context) {
    final left = chest.target - seals;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Palette.lantern.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded, size: 20, color: Palette.wood),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('daily.chest'), style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      tr(left == 1 ? 'daily.chestOne' : 'daily.chestHint', {'n': left}),
                      style: TextStyle(fontSize: 12, color: Palette.ink.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              _gives(chest, scale: 0.8),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < chest.target; i++)
                TweenAnimationBuilder<double>(
                  tween: Tween(end: i < seals ? 1 : 0),
                  duration: Calm.appear + Duration(milliseconds: 90 * i),
                  curve: Curves.easeOutBack,
                  builder: (context, v, _) => Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.lerp(Colors.transparent, Palette.lantern, v.clamp(0, 1)),
                      border: Border.all(color: Palette.lantern.withValues(alpha: 0.7), width: 1.5),
                    ),
                    child: Transform.scale(
                      scale: 0.6 + 0.4 * v,
                      child: Icon(
                        i == chest.target - 1 ? Icons.inventory_2_rounded : Icons.check_rounded,
                        size: 15,
                        color: v > 0.5 ? Palette.paper : Palette.lantern.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
    final chest = goal.id == 'chest';
    final bonus = goal.id == 'all' || chest;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Palette.lantern.withValues(alpha: bonus ? 0.28 : 0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(bonus ? _iconOf(goal) : Icons.check_circle_rounded, color: Palette.wood, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chest
                      ? tr('daily.chestOpen')
                      : bonus
                      ? tr('daily.allDone')
                      : tr('daily.done'),
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
