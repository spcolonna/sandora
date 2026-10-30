import 'package:flutter/material.dart';

import '../garden/decor.dart';
import '../garden/lotus_store.dart';
import '../garden/progress.dart';
import '../garden/shop.dart';
import '../i18n/i18n.dart';
import 'fx/sfx.dart';
import 'garden/garden_decor.dart';
import 'theme/palette.dart';
import 'widgets/currency.dart';

/// Mercado: trueques para conseguir lo que los minijuegos no dan. Los de
/// monedas comunes tienen límite diario; los de lotos, no (el loto ya es escaso).
Future<void> showShopSheet(BuildContext context) {
  Progress.instance.markDealSeen();
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
        final deal = p.dealToday();
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
              if (deal != null) ...[const SizedBox(height: 12), _DealCard(deal)],
              const SizedBox(height: 12),
              Text(tr('shop.trades'), style: text.titleSmall),
              for (final o in daily) _OfferRow(o),
              const SizedBox(height: 12),
              Text(tr('shop.withLotus'), style: text.titleSmall),
              for (final o in lotus) _OfferRow(o),
              // Paquetes de lotos: solo si la venta está prendida y la tienda los devolvió.
              ValueListenableBuilder(
                valueListenable: LotusStore.instance.products,
                builder: (context, products, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (products.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(tr('shop.buyLotus'), style: text.titleSmall),
                      for (final pr in products)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CurrencyChip.lotus(LotusStore.instance.lotusOf(pr), prefix: '+'),
                          title: Text(pr.title),
                          trailing: FilledButton.tonal(
                            onPressed: () => LotusStore.instance.buy(pr),
                            child: Text(pr.price),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
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

/// La oferta del día: una decoración con descuento, una sola vez. Va a la caja
/// del jardín y se pone desde el modo Decorar.
class _DealCard extends StatelessWidget {
  final DecorItem d;
  const _DealCard(this.d);

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final text = Theme.of(context).textTheme;
    final taken = p.dealTaken();
    final off = (p.shop.dealDiscount * 100).round();
    return Card(
      color: Palette.paper,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Palette.lantern.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
        child: Row(
          children: [
            SizedBox(width: 84, height: 84, child: CustomPaint(painter: DecorPainter(d.id, d.aspect))),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(tr('shop.deal'), style: text.labelLarge)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: Palette.lantern, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          '-$off %',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Palette.ink),
                        ),
                      ),
                    ],
                  ),
                  Text(tr('decor.${d.id}'), style: text.titleMedium),
                  const SizedBox(height: 4),
                  if (taken)
                    Text(tr('shop.dealTaken'), style: text.bodySmall)
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final c in p.dealCost(d).entries) CurrencyChip.of(c.key, c.value),
                        Text(
                          '${p.decorCost(d)['pebbles'] ?? ''}',
                          style: text.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: Palette.stoneDark,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!taken)
              FilledButton(
                onPressed: p.canBuyDeal()
                    ? () {
                        if (p.buyDeal()) {
                          SoundBoard.instance.play(Sfx.good, volume: 0.5);
                          Haptics.light();
                        }
                      }
                    : null,
                child: Text(tr('shop.dealBuy')),
              )
            else
              const Icon(Icons.check_circle_rounded, color: Palette.moss),
          ],
        ),
      ),
    );
  }
}
