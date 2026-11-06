import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../garden/decor.dart';
import '../garden/economy.dart';
import '../garden/lotus_store.dart';
import '../garden/progress.dart';
import '../garden/shop.dart';
import '../i18n/i18n.dart';
import 'fx/sfx.dart';
import 'garden/garden_decor.dart';
import 'garden/scene_art.dart';
import 'theme/palette.dart';
import 'widgets/currency.dart';
import 'widgets/glass.dart';
import 'widgets/washi.dart';

/// Mercado: trueques para conseguir lo que los minijuegos no dan. Los de
/// monedas comunes tienen límite diario; los de lotos, no (el loto ya es escaso).
/// Es una vista aparte que entra deslizando desde el costado (y se vuelve
/// deslizando hacia el otro lado). Devuelve true si se eligió "Poner ahora":
/// el jardín entra al modo Decorar.
Future<bool?> openMarket(BuildContext context) {
  Progress.instance.markDealSeen();
  return Navigator.of(context).push(CupertinoPageRoute<bool>(builder: (_) => const MarketScreen()));
}

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: Palette.paper,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage(washiTexture), fit: BoxFit.cover),
        ),
        child: ListenableBuilder(
          listenable: Progress.instance,
          builder: (context, _) {
            final p = Progress.instance;
            final text = Theme.of(context).textTheme;
            final daily = p.shop.offers.where((o) => o.daily != null);
            final lotus = p.shop.offers.where((o) => o.daily == null);
            final deal = p.dealToday();
            final decor = p.marketDecor();
            return CustomScrollView(
              slivers: [
                // El toldo del puesto, con el título y lo que se tiene para cambiar.
                SliverToBoxAdapter(
                  child: CustomPaint(
                    painter: _AwningPainter(),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(8, top + 4, 16, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                                child: InkIconButton(
                                  glyph: InkGlyph.back,
                                  size: 42,
                                  tooltip: tr('result.garden'),
                                  onPressed: () => Navigator.of(context).maybePop(),
                                ),
                              ),
                              Text(tr('shop.title'), style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 46),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Glass(
                              opacity: 0.8,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Wrap(
                                spacing: 14,
                                runSpacing: 6,
                                children: [
                                  CurrencyChip.pebbles(p.pebbles),
                                  for (final e in Essence.values) CurrencyChip.essence(e, p.essences[e]!),
                                  CurrencyChip.lotus(p.lotus),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.paddingOf(context).bottom + 24),
                  sliver: SliverList.list(
                    children: [
                      Text(tr('shop.desc'), style: text.bodyMedium, textAlign: TextAlign.center),
                      if (deal != null) ...[const SizedBox(height: 14), _DealCard(deal)],
                      if (decor.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(tr('shop.decor'), style: text.titleSmall),
                        for (final d in decor) _DecorRow(d),
                      ] else if (!p.decorOpen) ...[
                        if (p.tutorialDecor != null || p.decor.any((d) => !d.placed)) ...[
                          const SizedBox(height: 14),
                          if (p.guideStep == Guide.buy)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                tr('guide.buy'),
                                style: text.titleSmall?.copyWith(color: Palette.wood),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const _TutorialCard(),
                        ],
                        const SizedBox(height: 14),
                        WashiTile(
                          margin: EdgeInsets.zero,
                          child: Text(
                            tr('shop.decorSoon', {'n': p.decorRules.minLevel}),
                            style: text.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
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
                                WashiTile(
                                  child: Row(
                                    children: [
                                      CurrencyChip.lotus(LotusStore.instance.lotusOf(pr), prefix: '+'),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(pr.title, style: text.titleMedium)),
                                      InkButton.small(label: pr.price, onPressed: () => LotusStore.instance.buy(pr)),
                                    ],
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Toldo a rayas con borde ondulado y una sombra suave debajo, como el
/// puesto visto desde adentro.
class _AwningPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final bottom = size.height * 0.52;
    const stripes = 8;
    final sw = w / stripes;
    final art = SceneArt.instance['ui_market_awning'];
    if (art != null) {
      // El toldo pintado, estirado a lo ancho, con su sombra debajo.
      final dst = Rect.fromLTWH(0, 0, w, bottom + sw * 0.55);
      drawArt(
        canvas,
        art,
        dst.shift(const Offset(0, 5)),
        paint: Paint()
          ..colorFilter = ColorFilter.mode(Palette.ink.withValues(alpha: 0.28), BlendMode.srcIn)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      drawArt(canvas, art, dst);
      return;
    }
    final shape = Path()
      ..lineTo(w, 0)
      ..lineTo(w, bottom);
    for (var i = stripes - 1; i >= 0; i--) {
      shape.arcToPoint(Offset(sw * i, bottom), radius: Radius.circular(sw / 2));
    }
    shape.close();
    canvas.drawShadow(shape, Palette.ink, 6, false);
    canvas.save();
    canvas.clipPath(shape);
    for (var i = 0; i < stripes; i++) {
      canvas.drawRect(
        Rect.fromLTWH(sw * i, 0, sw + 1, bottom + sw),
        Paint()..color = i.isEven ? Palette.lotus : const Color(0xFFF7EEDD),
      );
    }
    // Luz de arriba: el toldo se oscurece hacia el borde.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, bottom + sw),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.18), Palette.ink.withValues(alpha: 0.12)],
        ).createShader(Rect.fromLTWH(0, 0, w, bottom + sw)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AwningPainter old) => false;
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
      child: WashiTile(
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
            InkButton.small(
              label: tr('shop.trade'),
              onPressed: p.canTrade(o)
                  ? () {
                      if (p.trade(o)) {
                        SoundBoard.instance.play(Sfx.good, volume: 0.5);
                        Haptics.light();
                      }
                    }
                  : null,
            ),
          ],
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
    return WashiTile(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
      border: Palette.lantern.withValues(alpha: 0.7),
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
          if (taken && p.decorStored(d.id) > 0)
            _PlaceNow()
          else if (!taken)
            InkButton.small(
              label: tr('shop.dealBuy'),
              onPressed: p.canBuyDeal()
                  ? () {
                      if (p.buyDeal()) {
                        SoundBoard.instance.play(Sfx.good, volume: 0.5);
                        Haptics.light();
                      }
                    }
                  : null,
            )
          else
            const Icon(Icons.check_circle_rounded, color: Palette.wood),
        ],
      ),
    );
  }
}

/// La primera decoración, en el tutorial: a precio de comienzo, una sola vez,
/// con lo que dio la primera partida. Después, a ponerla en el jardín.
class _TutorialCard extends StatelessWidget {
  const _TutorialCard();

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final text = Theme.of(context).textTheme;
    final d = p.tutorialDecor ?? p.decorRules.byId(p.decor.firstWhere((d) => !d.placed).id)!;
    final bought = p.tutorialDecor == null;
    return WashiTile(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
      border: Palette.lantern,
      glow: p.guideStep == Guide.buy,
      child: Row(
        children: [
          SizedBox(width: 84, height: 84, child: CustomPaint(painter: DecorPainter(d.id, d.aspect))),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('shop.tutorial'), style: text.labelLarge),
                Text(tr('decor.${d.id}'), style: text.titleMedium),
                const SizedBox(height: 4),
                if (bought)
                  Text(tr('shop.tutorialPlace'), style: text.bodySmall)
                else
                  Wrap(spacing: 8, children: [for (final c in p.tutorialCost.entries) CurrencyChip.of(c.key, c.value)]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (bought)
            const _PlaceNow()
          else
            InkButton.small(
              label: tr('shop.dealBuy'),
              onPressed: p.canBuyTutorial
                  ? () {
                      if (p.buyTutorialDecor()) {
                        SoundBoard.instance.play(Sfx.good, volume: 0.5);
                        Haptics.light();
                      }
                    }
                  : null,
            ),
        ],
      ),
    );
  }
}

/// Vuelve al jardín en modo Decorar, con lo comprado listo en la caja.
class _PlaceNow extends StatelessWidget {
  const _PlaceNow();

  @override
  Widget build(BuildContext context) =>
      InkButton.small(label: tr('shop.placeNow'), onPressed: () => Navigator.of(context).pop(true));
}

/// Una de las decoraciones del día: se compra (va a la caja) y, si ya hay en
/// la caja, se puede ir a ponerla.
class _DecorRow extends StatelessWidget {
  final DecorItem d;
  const _DecorRow(this.d);

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final text = Theme.of(context).textTheme;
    final stored = p.decorStored(d.id);
    return WashiTile(
      padding: const EdgeInsets.fromLTRB(6, 8, 12, 8),
      child: Row(
        children: [
          SizedBox(width: 60, height: 60, child: CustomPaint(painter: DecorPainter(d.id, d.aspect))),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('decor.${d.id}'), style: text.titleMedium),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  children: [for (final c in p.decorCost(d).entries) CurrencyChip.of(c.key, c.value)],
                ),
                if (stored > 0) Text(tr('shop.inBox', {'n': stored}), style: text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkButton.small(
                label: tr('shop.dealBuy'),
                onPressed: p.canBuyDecor(d)
                    ? () {
                        if (p.buyDecor(d)) {
                          SoundBoard.instance.play(Sfx.good, volume: 0.5);
                          Haptics.light();
                        }
                      }
                    : null,
              ),
              if (stored > 0) ...[const SizedBox(height: 6), const _PlaceNow()],
            ],
          ),
        ],
      ),
    );
  }
}
