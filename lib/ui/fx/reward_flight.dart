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

  /// La llave del contador de [currency] ('pebbles', 'lotus' o una esencia).
  static GlobalKey keyFor(String currency) => _keys.putIfAbsent(currency, () => GlobalKey(debugLabel: currency));

  /// Avisa cada vez que algo llega al contador de [currency].
  static ValueNotifier<int> arrivalsOf(String currency) => _arrivals.putIfAbsent(currency, () => ValueNotifier(0));

  /// Hace volar [amount] de [currency] desde [from] (coordenadas globales).
  static void fly(BuildContext context, {required Offset from, required String currency, required int amount}) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final target = keyFor(currency).currentContext?.findRenderObject() as RenderBox?;
    if (overlay == null || target == null || !target.attached) {
      arrivalsOf(currency).value++;
      return;
    }
    final to = target.localToGlobal(target.size.centerLeft(const Offset(11, 0)));
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) =>
          _Flight(from: from, to: to, currency: currency, count: amount.clamp(1, 6), onDone: () => entry.remove()),
    );
    overlay.insert(entry);
  }
}

class _Flight extends StatefulWidget {
  final Offset from, to;
  final String currency;
  final int count;
  final VoidCallback onDone;
  const _Flight({
    required this.from,
    required this.to,
    required this.currency,
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
      RewardFlight.arrivalsOf(widget.currency).value++;
    }
  }

  @override
  void dispose() {
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
