import 'package:flutter/material.dart';

import '../garden/progress.dart';
import '../garden/shop.dart';
import '../i18n/i18n.dart';
import 'fx/sfx.dart';
import 'theme/palette.dart';
import 'widgets/currency.dart';

/// Mercado: trueques para conseguir lo que los minijuegos no dan. Los de
/// monedas comunes tienen límite diario; los de lotos, no (el loto ya es escaso).
Future<void> showShopSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => ListenableBuilder(
      listenable: Progress.instance,
      builder: (context, _) {
        final p = Progress.instance;
        final text = Theme.of(context).textTheme;
        final daily = p.shop.offers.where((o) => o.daily != null);
        final lotus = p.shop.offers.where((o) => o.daily == null);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.92,
          builder: (context, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text(tr('shop.title'), style: text.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(tr('shop.desc'), style: text.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Center(child: CurrencyChip.lotus(p.lotus)),
              const SizedBox(height: 12),
              Text(tr('shop.trades'), style: text.titleSmall),
              for (final o in daily) _OfferRow(o),
              const SizedBox(height: 12),
              Text(tr('shop.withLotus'), style: text.titleSmall),
              for (final o in lotus) _OfferRow(o),
              const SizedBox(height: 10),
              Text(tr('shop.lotusHint'), style: text.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        );
      },
    ),
  );
}

class _OfferRow extends StatelessWidget {
  final ShopOffer o;
  const _OfferRow(this.o);

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final text = Theme.of(context).textTheme;
    final left = p.shopLeft(o);
    final soldOut = left == 0;
    return Opacity(
      opacity: soldOut ? 0.55 : 1,
      child: Card(
        color: Colors.white.withValues(alpha: 0.6),
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final g in o.give.entries) CurrencyChip.of(g.key, g.value, prefix: '+'),
                        const Icon(Icons.swap_horiz_rounded, size: 18, color: Palette.stone),
                        for (final c in o.cost.entries) CurrencyChip.of(c.key, c.value),
                      ],
                    ),
                    if (left != null) ...[
                      const SizedBox(height: 4),
                      Text(soldOut ? tr('shop.soldOut') : tr('shop.left', {'n': left}), style: text.bodySmall),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: p.canTrade(o)
                    ? () {
                        if (p.trade(o)) {
                          SoundBoard.instance.play(Sfx.good, volume: 0.5);
                          Haptics.light();
                        }
                      }
                    : null,
                child: Text(tr('shop.trade')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
