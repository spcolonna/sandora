import 'package:flutter/material.dart';

import '../garden/progress.dart';
import '../i18n/i18n.dart';
import 'theme/palette.dart';
import 'widgets/currency.dart';
import 'widgets/milestone_card.dart';
import 'widgets/washi.dart';

/// Las mejoras de un lugar del jardín: sus tres niveles, qué cambia en cada
/// uno y el botón para el próximo.
Future<void> showUpgradeSheet(BuildContext context, String game) {
  return showWashiSheet(
    context,
    builder: (context) => ListenableBuilder(
      listenable: Progress.instance,
      builder: (context, _) {
        final p = Progress.instance;
        final text = Theme.of(context).textTheme;
        final tier = p.upgradeTier(game);
        final next = p.upgradeRules.next(tier);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr('up.title', {'place': tr('mg.$game.name')}),
                  style: text.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(tr('up.desc'), style: text.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                for (final (i, t) in p.upgradeRules.tiers.indexed)
                  Opacity(
                    opacity: i < tier || i == tier ? 1 : 0.5,
                    child: WashiTile(
                      glow: i < tier,
                      child: Row(
                        children: [
                          Icon(
                            i < tier ? Icons.check_circle_rounded : Icons.construction_rounded,
                            color: i < tier ? Palette.wood : Palette.ink,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tr('up.t${i + 1}'), style: text.titleMedium),
                                Text(tr('up.bonus', {'n': (t.bonus * 100).round()}), style: text.bodySmall),
                              ],
                            ),
                          ),
                          if (i >= tier) Text(tr('level.abbr', {'n': t.level}), style: text.labelMedium),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                if (next == null)
                  Text(tr('up.max'), style: text.titleSmall, textAlign: TextAlign.center)
                else ...[
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    children: [for (final c in p.upgradeCost(game).entries) CurrencyChip.price(c.key, c.value)],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: InkButton.small(
                      label: p.level < next.level ? tr('up.needLevel', {'n': next.level}) : tr('up.buy'),
                      whyNot: p.level < next.level ? null : shortNote(p.upgradeCost(game)),
                      onPressed: p.canUpgrade(game)
                          ? () {
                              if (p.buyUpgrade(game)) {
                                // Se cierra la hoja para ver el jardín cambiado, con el aviso grande.
                                final nav = Navigator.of(context);
                                nav.pop();
                                showPendingMilestones(nav.context);
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}
