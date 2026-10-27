import 'package:flutter/material.dart';

/// Movimientos del juego (GDD, pilar 8: nada es brusco). Todo entra con un
/// fundido y frena despacio; nada rebota, sacude ni aparece de golpe.
abstract final class Calm {
  static const curve = Curves.easeOutCubic;
  static const appear = Duration(milliseconds: 700);
  static const page = Duration(milliseconds: 550);
}

/// Cambio de pantalla con fundido y un leve ascenso, en lugar del deslizamiento
/// de la plataforma.
Route<T> calmRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: Calm.page,
  reverseTransitionDuration: const Duration(milliseconds: 420),
  pageBuilder: (_, _, _) => page,
  transitionsBuilder: (_, a, _, child) => _calmTransition(a, child),
);

Widget _calmTransition(Animation<double> a, Widget child) {
  final t = CurvedAnimation(parent: a, curve: Calm.curve, reverseCurve: Curves.easeInCubic);
  return FadeTransition(
    opacity: t,
    child: SlideTransition(
      position: Tween(begin: const Offset(0, 0.015), end: Offset.zero).animate(t),
      child: child,
    ),
  );
}

/// La misma transición para las rutas que arma Material (tema de la app).
class CalmPageTransitionsBuilder extends PageTransitionsBuilder {
  const CalmPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _calmTransition(animation, child);
}

/// Aparece con fundido, subiendo unos pocos píxeles y creciendo apenas.
/// [delay] escalona varias cosas (las estrellas del resultado, por ejemplo).
class CalmAppear extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double rise;
  final double fromScale;

  const CalmAppear({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = Calm.appear,
    this.rise = 10,
    this.fromScale = 0.97,
  });

  @override
  State<CalmAppear> createState() => _CalmAppearState();
}

class _CalmAppearState extends State<CalmAppear> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.duration);
  late final _t = CurvedAnimation(parent: _c, curve: Calm.curve);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, widget.rise * (1 - _t.value)),
          child: Transform.scale(scale: widget.fromScale + (1 - widget.fromScale) * _t.value, child: child),
        ),
      ),
      child: widget.child,
    );
  }
}
