import 'package:flutter/material.dart';

import '../../garden/economy.dart';
import '../../i18n/i18n.dart';
import '../theme/palette.dart';

/// Monto de una moneda con su ícono. Las monedas que todavía no tienen
/// `icon_*` (Bloque 6) usan un placeholder dibujado.
class CurrencyChip extends StatelessWidget {
  final Widget icon;
  final String text;
  final String tooltip;

  const CurrencyChip._(this.icon, this.text, this.tooltip);

  factory CurrencyChip.pebbles(int n, {String prefix = ''}) =>
      CurrencyChip._(const _Art('icon_pebble'), '$prefix$n', tr('currency.pebbles'));

  factory CurrencyChip.lotus(int n, {String prefix = ''}) =>
      CurrencyChip._(const _Dot(Palette.lotus, petal: true), '$prefix$n', tr('currency.lotus'));

  /// Cualquier moneda del Mercado por su clave ('pebbles', 'lotus' o una esencia).
  factory CurrencyChip.of(String key, int n, {String prefix = ''}) => switch (key) {
    'pebbles' => CurrencyChip.pebbles(n, prefix: prefix),
    'lotus' => CurrencyChip.lotus(n, prefix: prefix),
    _ => CurrencyChip.essence(Essence.values.byName(key), n, prefix: prefix),
  };

  factory CurrencyChip.essence(Essence e, int n, {String prefix = ''}) => CurrencyChip._(
    switch (e) {
      Essence.water || Essence.sand => _Art('icon_essence_${e.name}'),
      _ => _Dot(essenceColor(e), diamond: true),
    },
    '$prefix$n',
    tr('essence.${e.name}'),
  );

  static Color essenceColor(Essence e) => switch (e) {
    Essence.water => Palette.water,
    Essence.sand => Palette.sandShadow,
    Essence.wood => Palette.wood,
    Essence.light => Palette.lantern,
  };

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    );
  }
}

class _Art extends StatelessWidget {
  final String name;
  const _Art(this.name);

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/images/icons/$name.webp', width: 22, height: 22, filterQuality: FilterQuality.medium);
}

class _Dot extends StatelessWidget {
  final Color color;
  final bool diamond, petal;
  const _Dot(this.color, {this.diamond = false, this.petal = false});

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        borderRadius: petal
            ? const BorderRadius.only(topLeft: Radius.circular(12), bottomRight: Radius.circular(12))
            : BorderRadius.circular(diamond ? 3 : 8),
        border: Border.all(color: Palette.ink.withValues(alpha: 0.25)),
      ),
    );
    return diamond ? Transform.rotate(angle: 0.785, child: dot) : dot;
  }
}
