import 'package:flutter/material.dart';

import '../../garden/economy.dart';
import '../../i18n/i18n.dart';

/// Monto de una moneda con su ícono. Cuando el monto cambia, cuenta hasta el
/// nuevo (después de una pausa, para que llegue junto con lo que vuela).
class CurrencyChip extends StatelessWidget {
  final String currency;
  final int value;
  final String prefix;

  const CurrencyChip._(this.currency, this.value, this.prefix);

  factory CurrencyChip.pebbles(int n, {String prefix = ''}) => CurrencyChip._('pebbles', n, prefix);

  factory CurrencyChip.lotus(int n, {String prefix = ''}) => CurrencyChip._('lotus', n, prefix);

  /// Cualquier moneda del Mercado por su clave ('pebbles', 'lotus' o una esencia).
  factory CurrencyChip.of(String key, int n, {String prefix = ''}) => CurrencyChip._(key, n, prefix);

  factory CurrencyChip.essence(Essence e, int n, {String prefix = ''}) => CurrencyChip._(e.name, n, prefix);

  String get _tooltip => switch (currency) {
    'pebbles' => tr('currency.pebbles'),
    'lotus' => tr('currency.lotus'),
    _ => tr('essence.$currency'),
  };

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontWeight: FontWeight.w700, fontSize: 16);
    return Tooltip(
      message: _tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CurrencyIcon(currency),
          const SizedBox(width: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(end: value.toDouble()),
            duration: const Duration(milliseconds: 1300),
            curve: const Interval(0.45, 1, curve: Curves.easeOutCubic),
            builder: (context, v, _) => Text('$prefix${v.round()}', style: style),
          ),
        ],
      ),
    );
  }
}

/// El ícono de una moneda ('pebbles', 'lotus' o una esencia).
class CurrencyIcon extends StatelessWidget {
  final String currency;
  const CurrencyIcon(this.currency, {super.key});

  @override
  Widget build(BuildContext context) {
    final name = switch (currency) {
      'pebbles' => 'icon_pebble',
      'lotus' => 'icon_lotus',
      _ => 'icon_essence_$currency',
    };
    return Image.asset('assets/images/icons/$name.webp', width: 22, height: 22, filterQuality: FilterQuality.medium);
  }
}
