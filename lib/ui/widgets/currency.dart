import 'package:flutter/material.dart';

import '../../garden/economy.dart';
import '../../i18n/i18n.dart';

/// Monto de una moneda con su ícono. Cuando el monto cambia, cuenta hasta el
/// nuevo. Lo que vuela al contador llega de a poco (`RewardFlight.hold`), así
/// que no hace falta esperar.
class CurrencyChip extends StatelessWidget {
  final String currency;
  final int value;
  final String prefix;

  /// Si se da, al aparecer cuenta desde acá (lo ganado en una partida sube
  /// desde 0), después de [delay].
  final int? from;
  final Duration delay;

  const CurrencyChip._(this.currency, this.value, this.prefix, {this.from, this.delay = Duration.zero});

  factory CurrencyChip.pebbles(int n, {String prefix = '', int? from, Duration delay = Duration.zero}) =>
      CurrencyChip._('pebbles', n, prefix, from: from, delay: delay);

  factory CurrencyChip.lotus(int n, {String prefix = '', int? from, Duration delay = Duration.zero}) =>
      CurrencyChip._('lotus', n, prefix, from: from, delay: delay);

  /// Cualquier moneda del Mercado por su clave ('pebbles', 'lotus' o una esencia).
  factory CurrencyChip.of(String key, int n, {String prefix = ''}) => CurrencyChip._(key, n, prefix);

  factory CurrencyChip.essence(Essence e, int n, {String prefix = '', int? from, Duration delay = Duration.zero}) =>
      CurrencyChip._(e.name, n, prefix, from: from, delay: delay);

  String get _tooltip => switch (currency) {
    'pebbles' => tr('currency.pebbles'),
    'lotus' => tr('currency.lotus'),
    _ => tr('essence.$currency'),
  };

  @override
  Widget build(BuildContext context) {
    // Cifras de ancho fijo: la píldora no tiembla mientras cuenta.
    const style = TextStyle(fontWeight: FontWeight.w700, fontSize: 16, fontFeatures: [FontFeature.tabularFigures()]);
    return Tooltip(
      message: _tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CurrencyIcon(currency),
          const SizedBox(width: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: (from ?? value).toDouble(), end: value.toDouble()),
            duration: delay + Duration(milliseconds: from == null ? 600 : 1300),
            curve: Interval(
              (delay.inMilliseconds + (from == null ? 0 : 150)) / (delay.inMilliseconds + 1300),
              1,
              curve: Curves.easeOutCubic,
            ),
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
