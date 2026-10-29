import 'package:flutter/material.dart';

import '../../garden/levels.dart';
import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../expansions_sheet.dart';
import '../fx/calm.dart';
import '../theme/palette.dart';
import 'currency.dart';
import 'level_up.dart';

/// La próxima meta: lo que ya se puede abrir, lo que falta juntar o el nivel
/// que viene. Siempre a la vista, para saber qué hacer después.
class NextGoal extends StatelessWidget {
  /// Si se puede tocar para abrir las ampliaciones.
  final bool tappable;
  const NextGoal({super.key, this.tappable = true});

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final goal = p.nextGoal;
    if (goal == null) return const SizedBox(height: 4);
    final style = TextStyle(fontSize: 13, color: Palette.ink.withValues(alpha: 0.7), fontWeight: FontWeight.w600);
    final Widget line = switch (goal.kind) {
      GoalKind.buy => ReadyGlow(
        child: Text(
          tr('goal.buy', {'name': unlockName(goal.id)}),
          style: style.copyWith(color: Palette.ink, fontWeight: FontWeight.w700),
        ),
      ),
      GoalKind.gather => Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(tr('goal.gather', {'name': unlockName(goal.id)}), style: style),
          for (final m in p.missingFor(p.levels.expansions.firstWhere((e) => e.id == goal.id)).entries)
            Transform.scale(scale: 0.8, child: CurrencyChip.of(m.key, m.value)),
        ],
      ),
      GoalKind.reach => Text(
        tr('goal.reach', {
          'n': goal.level,
          'name': unlockName(goal.id),
          'calm': p.levels.calmToReach(goal.level) - p.calm,
        }),
        style: style,
      ),
    };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tappable ? () => showExpansionsSheet(context) : null,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(Icons.flag_rounded, size: 15, color: Palette.moss.withValues(alpha: 0.8)),
            const SizedBox(width: 6),
            Expanded(
              child: AnimatedSwitcher(
                duration: Calm.appear,
                layoutBuilder: (current, previous) =>
                    Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
                child: KeyedSubtree(key: ValueKey('${goal.kind}${goal.id}'), child: line),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un brillo de farol que late despacio detrás de lo que ya se puede abrir.
class ReadyGlow extends StatefulWidget {
  final Widget child;
  const ReadyGlow({super.key, required this.child});

  @override
  State<ReadyGlow> createState() => _ReadyGlowState();
}

class _ReadyGlowState extends State<ReadyGlow> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Palette.lantern.withValues(alpha: 0.18 + 0.17 * _c.value),
          borderRadius: BorderRadius.circular(10),
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Una barra que se llena despacio hasta el valor nuevo.
class CalmBar extends StatelessWidget {
  final double value;
  final Color color;
  const CalmBar(this.value, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    // Se llena despacio hasta el valor nuevo (Calma ganada, Serenidad).
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeInOutCubic,
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: v,
          minHeight: 10,
          color: color,
          backgroundColor: Palette.sandShadow.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
