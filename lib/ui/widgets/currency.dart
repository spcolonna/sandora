import 'package:flutter/material.dart';

import '../../garden/economy.dart';
import '../../i18n/i18n.dart';

/// Monto de una moneda con su ícono.
class CurrencyChip extends StatelessWidget {
  final Widget icon;
  final String text;
  final String tooltip;

  const CurrencyChip._(this.icon, this.text, this.tooltip);

  factory CurrencyChip.pebbles(int n, {String prefix = ''}) =>
      CurrencyChip._(const _Art('icon_pebble'), '$prefix$n', tr('currency.pebbles'));

  factory CurrencyChip.lotus(int n, {String prefix = ''}) =>
      CurrencyChip._(const _Art('icon_lotus'), '$prefix$n', tr('currency.lotus'));

  /// Cualquier moneda del Mercado por su clave ('pebbles', 'lotus' o una esencia).
  factory CurrencyChip.of(String key, int n, {String prefix = ''}) => switch (key) {
    'pebbles' => CurrencyChip.pebbles(n, prefix: prefix),
    'lotus' => CurrencyChip.lotus(n, prefix: prefix),
    _ => CurrencyChip.essence(Essence.values.byName(key), n, prefix: prefix),
  };

  factory CurrencyChip.essence(Essence e, int n, {String prefix = ''}) =>
      CurrencyChip._(_Art('icon_essence_${e.name}'), '$prefix$n', tr('essence.${e.name}'));

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
