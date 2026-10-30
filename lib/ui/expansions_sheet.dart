import 'package:flutter/material.dart';

import 'widgets/washi.dart';

import '../garden/levels.dart';
import '../garden/progress.dart';
import '../i18n/i18n.dart';
import 'fx/sfx.dart';
import 'theme/palette.dart';
import 'widgets/currency.dart';

/// Lo que trae cada nivel: ampliaciones del jardín (se compran con tokens una
/// vez alcanzado el nivel) y el Modo meditación.
Future<void> showExpansionsSheet(BuildContext context) {
  return showWashiSheet(
    context,
    isScrollControlled: true,
    builder: (context) => ListenableBuilder(
      listenable: Progress.instance,
      builder: (context, _) {
        final p = Progress.instance;
        final text = Theme.of(context).textTheme;
        final next = p.levels.calmToReach(p.level + 1) - p.calm;
        final rows = <(int, Widget)>[
          (p.levels.meditationLevel, _MeditationRow(unlocked: p.meditationUnlocked)),
          for (final e in p.levels.expansions) (e.level, _ExpansionRow(e)),
        ]..sort((a, b) => a.$1.compareTo(b.$1));
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.92,
          builder: (context, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text(tr('exp.title'), style: text.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                '${tr('level.short', {'n': p.level})} · ${tr('level.next', {'n': next, 'l': p.level + 1})}',
                style: text.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              for (final r in rows) r.$2,
            ],
          ),
        );
      },
    ),
  );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final int level;
  final bool done, locked;
  final Widget? trailing;
  final Widget? cost;

  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.level,
    this.done = false,
    this.locked = false,
    this.trailing,
    this.cost,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: Card(
        color: done ? Palette.lantern.withValues(alpha: 0.14) : Palette.sandLight.withValues(alpha: 0.7),
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Palette.wood.withValues(alpha: 0.16)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Column(
                children: [
                  Icon(locked ? Icons.lock_rounded : icon, color: Palette.ink),
                  Text(tr('level.abbr', {'n': level}), style: text.labelSmall),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleMedium),
                    Text(subtitle, style: text.bodySmall),
                    if (cost != null) ...[const SizedBox(height: 6), cost!],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class _MeditationRow extends StatelessWidget {
  final bool unlocked;
  const _MeditationRow({required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return _Row(
      icon: Icons.self_improvement_rounded,
      title: tr('meditation.title'),
      subtitle: tr('meditation.desc'),
      level: Progress.instance.levels.meditationLevel,
      done: unlocked,
      locked: !unlocked,
      trailing: unlocked ? const Icon(Icons.check_circle_rounded, color: Palette.wood) : null,
    );
  }
}

class _ExpansionRow extends StatelessWidget {
  final Expansion e;
  const _ExpansionRow(this.e);

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final owned = p.expansions.contains(e.id);
    final reached = p.level >= e.level;
    final Widget? trailing;
    if (owned) {
      trailing = const Icon(Icons.check_circle_rounded, color: Palette.wood);
    } else if (!e.ready) {
      trailing = Text(tr('exp.soon'), style: Theme.of(context).textTheme.labelMedium);
    } else if (!reached) {
      trailing = null;
    } else {
      trailing = InkButton.small(
        label: tr('exp.buy'),
        onPressed: p.canAfford(e)
            ? () {
                if (p.buyExpansion(e)) {
                  SoundBoard.instance.play(Sfx.perfect, volume: 0.6);
                  Haptics.perfect();
                }
              }
            : null,
      );
    }
    return _Row(
      icon: e.zone ? Icons.landscape_rounded : Icons.crop_free_rounded,
      title: tr('exp.${e.id}.name'),
      subtitle: tr('exp.${e.id}.desc'),
      level: e.level,
      done: owned,
      locked: !reached,
      trailing: trailing,
      cost: owned
          ? null
          : Wrap(
              spacing: 12,
              children: [
                CurrencyChip.pebbles(e.pebbles),
                for (final c in e.essences.entries) CurrencyChip.essence(c.key, c.value),
              ],
            ),
    );
  }
}
