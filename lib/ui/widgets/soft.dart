import 'package:flutter/material.dart';

/// Muestra u oculta [child] con un fundido y un leve desplazamiento, en vez de
/// que aparezca o desaparezca de golpe (pilar 8: nada es brusco). Mientras está
/// oculto no atrapa toques.
class SoftShow extends StatelessWidget {
  final bool visible;
  final Widget child;
  final Duration duration;

  /// Cuánto sube al aparecer, en fracción de su alto.
  final double rise;

  const SoftShow({
    super.key,
    required this.visible,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
    this.rise = 0.25,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : Offset(0, rise),
        duration: duration,
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(opacity: visible ? 1 : 0, duration: duration, curve: Curves.easeOut, child: child),
      ),
    );
  }
}

/// Un número que, al cambiar, cuenta hasta el nuevo valor y late una vez: el
/// puntaje se siente ganado en vez de saltar.
class CountUp extends StatefulWidget {
  final int value;
  final String Function(int shown) format;
  final TextStyle? style;

  /// Cuánto crece en el latido (0 = sin latido).
  final double pulse;

  const CountUp({super.key, required this.value, required this.format, this.style, this.pulse = 0.12});

  @override
  State<CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<CountUp> with SingleTickerProviderStateMixin {
  late final _beat = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  late double _from = widget.value.toDouble();

  @override
  void didUpdateWidget(CountUp old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _from = old.value.toDouble();
      // Solo late al subir: perder algo no se festeja.
      if (widget.value > old.value && widget.pulse > 0) _beat.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _beat,
      builder: (context, child) {
        final t = _beat.value;
        // Sube rápido y se asienta despacio.
        final s = 1 + widget.pulse * (t < 0.3 ? t / 0.3 : 1 - Curves.easeOut.transform((t - 0.3) / 0.7));
        return Transform.scale(scale: s, alignment: Alignment.centerLeft, child: child);
      },
      child: TweenAnimationBuilder<double>(
        key: ValueKey(widget.value),
        tween: Tween(begin: _from, end: widget.value.toDouble()),
        duration: Duration(milliseconds: (180 + 40 * (widget.value - _from).abs()).clamp(180, 650).round()),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => Text(widget.format(v.round()), style: widget.style),
      ),
    );
  }
}
