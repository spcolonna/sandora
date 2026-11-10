import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/currency.dart';
import 'sfx.dart';

/// Lo que se junta en el jardín vuela hasta su contador de arriba: unos
/// íconos salen de donde se tocó, hacen una curva suave y, al llegar, el
/// contador se ilumina y suma.
abstract final class RewardFlight {
  static final _keys = <String, GlobalKey>{};
  static final _arrivals = <String, ValueNotifier<int>>{};
  static final _held = <String, ValueNotifier<int>>{};

  /// Lo que todavía está en el aire hacia el contador de [currency]: el
  /// contador lo descuenta y lo suma cuando llega cada ícono, así el número
  /// sube junto con lo que vuela y no antes.
  static ValueNotifier<int> heldOf(String currency) => _held.putIfAbsent(currency, () => ValueNotifier(0));

  /// Retiene [amount] de [currency] hasta que su vuelo llegue (ver [heldOf]).
  static void hold(String currency, int amount) => heldOf(currency).value += amount;

  static void _release(String currency, int amount) {
    final h = heldOf(currency);
    h.value = max(0, h.value - amount);
  }

  /// La llave del contador de [currency] ('pebbles', 'lotus' o una esencia).
  static GlobalKey keyFor(String currency) => _keys.putIfAbsent(currency, () => GlobalKey(debugLabel: currency));

  /// Avisa cada vez que algo llega al contador de [currency].
  static ValueNotifier<int> arrivalsOf(String currency) => _arrivals.putIfAbsent(currency, () => ValueNotifier(0));

  /// Hace volar [amount] de [currency] desde [from] (coordenadas globales).
  /// Si su contador no está a la vista (la billetera cerrada), va a la
  /// billetera ('wallet').
  /// Con [held], lo retenido ya se apartó antes con [hold].
  static void fly(
    BuildContext context, {
    required Offset from,
    required String currency,
    required int amount,
    bool held = false,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    var to = currency;
    RenderBox? target;
    for (final k in [currency, 'wallet']) {
      final box = keyFor(k).currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.attached) {
        (to, target) = (k, box);
        break;
      }
    }
    if (overlay == null || target == null) {
      if (held) _release(currency, amount);
      arrivalsOf(currency).value++;
      return;
    }
    if (!held) hold(currency, amount);
    final at = target.localToGlobal(target.size.centerLeft(const Offset(11, 0)));
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Flight(
        from: from,
        to: at,
        currency: currency,
        target: to,
        count: amount.clamp(1, 6),
        amount: amount,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _Flight extends StatefulWidget {
  final Offset from, to;

  /// Qué vuela y a qué contador llega (el suyo o la billetera).
  final String currency, target;
  final int count, amount;
  final VoidCallback onDone;
  const _Flight({
    required this.amount,
    required this.from,
    required this.to,
    required this.currency,
    required this.target,
    required this.count,
    required this.onDone,
  });

  @override
  State<_Flight> createState() => _FlightState();
}

class _FlightState extends State<_Flight> with SingleTickerProviderStateMixin {
  static const _each = 0.62, _stagger = 0.09;
  late final _total = _each + _stagger * (widget.count - 1);
  late final _c =
      AnimationController(
          vsync: this,
          duration: Duration(milliseconds: (_total * 1000).round()),
        )
        ..addListener(_arrive)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        })
        ..forward();
  final _rng = Random();
  late final _bends = [for (var i = 0; i < widget.count; i++) (_rng.nextDouble() - 0.5) * 120];
  var _landed = 0;

  /// Cada ícono que llega suena una nota que sube y enciende el contador.
  void _arrive() {
    final t = _c.value * _total;
    while (_landed < widget.count && t >= _stagger * _landed + _each) {
      _landed++;
      SoundBoard.instance.play(Sfx.rainNote, variant: min(_landed, 5), volume: 0.18);
      Haptics.light();
      RewardFlight.arrivalsOf(widget.target).value++;
      _pay(_landed == widget.count ? widget.amount - _paid : widget.amount ~/ widget.count);
    }
  }

  var _paid = 0;

  /// Cada ícono que llega suma su parte al contador.
  void _pay(int n) {
    if (n <= 0) return;
    _paid += n;
    RewardFlight._release(widget.currency, n);
  }

  @override
  void dispose() {
    // Si se cortó antes de llegar, lo retenido no queda colgado.
    _pay(widget.amount - _paid);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final now = _c.value * _total;
          return Stack(
            children: [
              for (var i = 0; i < widget.count; i++)
                if (now >= _stagger * i && now < _stagger * i + _each) _icon(i, (now - _stagger * i) / _each),
            ],
          );
        },
      ),
    );
  }

  Widget _icon(int i, double raw) {
    final t = Curves.easeInOutCubic.transform(raw);
    // Sale un poco hacia arriba y hacia un costado antes de ir al contador.
    final mid = Offset((widget.from.dx + widget.to.dx) / 2 + _bends[i], min(widget.from.dy, widget.to.dy) - 60);
    final a = Offset.lerp(widget.from, mid, t)!, b = Offset.lerp(mid, widget.to, t)!;
    final p = Offset.lerp(a, b, t)!;
    final scale = 1.25 - 0.45 * t;
    final opacity = raw < 0.15 ? raw / 0.15 : 1.0;
    return Positioned(
      left: p.dx - 11,
      top: p.dy - 11,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(scale: scale, child: CurrencyIcon(widget.currency)),
      ),
    );
  }
}

/// El contador de arriba: se ilumina y crece apenas cada vez que le llega algo.
class RewardTarget extends StatefulWidget {
  final String currency;
  final Widget child;
  const RewardTarget({super.key, required this.currency, required this.child});

  @override
  State<RewardTarget> createState() => _RewardTargetState();
}

class _RewardTargetState extends State<RewardTarget> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  late final _arrivals = RewardFlight.arrivalsOf(widget.currency);

  @override
  void initState() {
    super.initState();
    _arrivals.addListener(_glow);
  }

  void _glow() => _c.forward(from: 0);

  @override
  void dispose() {
    _arrivals.removeListener(_glow);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: RewardFlight.keyFor(widget.currency),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final k = sin(_c.value * pi);
          return Transform.scale(
            scale: 1 + 0.12 * k,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (k > 0) BoxShadow(color: const Color(0xFFFFE7A8).withValues(alpha: 0.7 * k), blurRadius: 14),
                ],
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Un monto de la billetera que descuenta lo que todavía vuela hacia él.
class HeldAmount extends StatelessWidget {
  final String currency;
  final int value;
  final Widget Function(int shown) builder;
  const HeldAmount({super.key, required this.currency, required this.value, required this.builder});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: RewardFlight.heldOf(currency),
    builder: (context, held, _) => builder(max(0, value - held)),
  );
}
