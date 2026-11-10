import 'package:flutter/material.dart';

import '../../garden/economy.dart';
import '../../garden/progress.dart';
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

  /// Lo que todavía no alcanza: la cifra va en rojo tierra.
  final bool short;

  const CurrencyChip._(
    this.currency,
    this.value,
    this.prefix, {
    this.from,
    this.delay = Duration.zero,
    this.short = false,
  });

  factory CurrencyChip.pebbles(int n, {String prefix = '', int? from, Duration delay = Duration.zero}) =>
      CurrencyChip._('pebbles', n, prefix, from: from, delay: delay);

  factory CurrencyChip.lotus(
    int n, {
    String prefix = '',
    int? from,
    Duration delay = Duration.zero,
    bool short = false,
  }) => CurrencyChip._('lotus', n, prefix, from: from, delay: delay, short: short);

  /// Cualquier moneda del Mercado por su clave ('pebbles', 'lotus' o una esencia).
  factory CurrencyChip.of(String key, int n, {String prefix = '', bool short = false}) =>
      CurrencyChip._(key, n, prefix, short: short);

  /// Un precio: en rojo si todavía no alcanza.
  factory CurrencyChip.price(String key, int n) =>
      CurrencyChip._(key, n, '', short: Progress.instance.walletOf(key) < n);

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
    final style = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: short ? shortColor : null,
    );
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

/// El rojo tierra de lo que no alcanza.
const shortColor = Color(0xFFB0503C);

/// Qué falta para pagar [cost] («Te faltan 12 Piedritas y 3 Agua»), o null
/// si alcanza.
String? shortNote(Map<String, int> cost) {
  final p = Progress.instance;
  final parts = [
    for (final c in cost.entries)
      if (p.walletOf(c.key) < c.value) '${c.value - p.walletOf(c.key)} ${_name(c.key)}',
  ];
  if (parts.isEmpty) return null;
  final list = parts.length == 1
      ? parts.first
      : tr('wallet.and', {'a': parts.sublist(0, parts.length - 1).join(', '), 'b': parts.last});
  return tr('wallet.short', {'list': list});
}

String _name(String key) => switch (key) {
  'pebbles' => tr('currency.pebbles'),
  'lotus' => tr('currency.lotus'),
  _ => tr('essence.$key'),
};

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
