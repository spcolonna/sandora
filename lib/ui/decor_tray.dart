import 'dart:math';

import 'package:flutter/material.dart';

import '../garden/decor.dart';
import '../garden/progress.dart';
import '../i18n/i18n.dart';
import 'fx/sfx.dart';
import 'garden/garden_decor.dart';
import 'theme/palette.dart';
import 'widgets/currency.dart';
import 'widgets/washi.dart';

/// La bandeja del modo Decorar: todo el catálogo. Lo que está en la caja se
/// pone con un toque en la vista [side]; lo demás se compra y se pone con el
/// mismo toque. Después se arrastra en el jardín.
class DecorTray extends StatelessWidget {
  final int side;

  /// Avisa qué decoración se acaba de poner (su índice), para destacarla.
  final void Function(int index) onPlaced;

  const DecorTray({super.key, required this.side, required this.onPlaced});

  static final _rng = Random();

  void _tap(BuildContext context, DecorItem d) {
    final p = Progress.instance;
    void tell(String text) => showWashiToast(context, text, duration: const Duration(seconds: 2));

    if (p.decorOn(side) >= p.decorRules.perSide) {
      SoundBoard.instance.play(Sfx.uiTap, volume: 0.3);
      return tell(tr('decor.full'));
    }
    if (p.decorStored(d.id) == 0) {
      if (p.level < d.level) {
        SoundBoard.instance.play(Sfx.uiTap, volume: 0.3);
        return tell(tr('decor.needLevel', {'n': d.level}));
      }
      if (!p.buyDecor(d)) {
        SoundBoard.instance.play(Sfx.uiTap, volume: 0.3);
        return tell(tr('decor.needMore'));
      }
      SoundBoard.instance.play(Sfx.good, volume: 0.5);
    } else {
      SoundBoard.instance.play(Sfx.stackPlace, volume: 0.5);
    }
    Haptics.light();
    // Cae cerca del centro del suelo, un poco al azar para no taparse.
    final i = p.placeDecor(d.id, side, 0.3 + 0.4 * _rng.nextDouble(), 0.74 + 0.12 * _rng.nextDouble());
    if (i != null) onPlaced(i);
  }

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    return SizedBox(
      height: 138,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        itemCount: p.decorRules.items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = p.decorRules.items[i];
          return _Card(d, onTap: () => _tap(context, d));
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final DecorItem item;
  final VoidCallback onTap;
  const _Card(this.item, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final stored = p.decorStored(item.id);
    final locked = p.level < item.level;
    final can = stored > 0 || p.canBuyDecor(item);
    return Semantics(
      button: true,
      label: tr('decor.${item.id}'),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: can ? 1 : 0.55,
          child: Container(
            width: 92,
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
            decoration: BoxDecoration(
              color: Palette.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: stored > 0 ? Palette.lantern : Palette.sandShadow.withValues(alpha: 0.6),
                width: stored > 0 ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: locked
                            ? Icon(Icons.lock_rounded, color: Palette.ink.withValues(alpha: 0.25))
                            : CustomPaint(painter: DecorPainter(item.id, item.aspect)),
                      ),
                      if (stored > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: Palette.lantern, borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              '×$stored',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Palette.ink),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  tr('decor.${item.id}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 16,
                  child: stored > 0
                      ? Text(tr('decor.place'), style: const TextStyle(fontSize: 11, color: Palette.wood))
                      : locked
                      ? Text(
                          tr('level.short', {'n': item.level}),
                          style: TextStyle(fontSize: 11, color: Palette.ink.withValues(alpha: 0.6)),
                        )
                      : FittedBox(
                          child: Row(
                            children: [
                              for (final (j, c) in p.decorCost(item).entries.indexed) ...[
                                if (j > 0) const SizedBox(width: 5),
                                SizedBox(width: 16, height: 16, child: FittedBox(child: CurrencyIcon(c.key))),
                                const SizedBox(width: 2),
                                Text(
                                  '${c.value}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: p.walletOf(c.key) >= c.value ? Palette.ink : const Color(0xFFB0503C),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
