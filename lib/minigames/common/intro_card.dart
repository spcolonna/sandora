import 'dart:math';

import 'package:flutter/material.dart';

import '../../i18n/i18n.dart';
import '../../ui/fx/calm.dart';
import '../../ui/theme/palette.dart';

/// El gesto de cada minijuego, para la tarjeta de cómo se juega.
enum IntroGesture { tap, hold, trace, swipe, paint, swap, pull }

const introGestures = {
  'stack': IntroGesture.tap,
  'sand': IntroGesture.trace,
  'rain': IntroGesture.tap,
  'pond': IntroGesture.swap,
  'shishi': IntroGesture.hold,
  'leaves': IntroGesture.swipe,
  'moss': IntroGesture.paint,
  'bonsai': IntroGesture.swipe,
  'enso': IntroGesture.trace,
  'bell': IntroGesture.pull,
};

/// Tarjeta que se ve la primera vez que se abre un minijuego: nombre, qué hay
/// que hacer y una mano que muestra el gesto.
class IntroCard extends StatelessWidget {
  final String id;
  final VoidCallback onStart;
  const IntroCard({super.key, required this.id, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ColoredBox(
      color: Palette.sand,
      child: Center(
        child: CalmAppear(
          rise: 18,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            decoration: BoxDecoration(color: Palette.paper, borderRadius: BorderRadius.circular(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tr('mg.$id.name'), style: text.headlineSmall),
                const SizedBox(height: 16),
                SizedBox(width: 180, height: 120, child: _GestureDemo(introGestures[id] ?? IntroGesture.tap)),
                const SizedBox(height: 16),
                Text(tr('mg.$id.desc'), style: text.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: onStart, child: Text(tr('intro.start'))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Una mano que repite el gesto despacio, con su rastro.
class _GestureDemo extends StatefulWidget {
  final IntroGesture gesture;
  const _GestureDemo(this.gesture);

  @override
  State<_GestureDemo> createState() => _GestureDemoState();
}

class _GestureDemoState extends State<_GestureDemo> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(painter: _DemoPainter(widget.gesture, _c.value)),
    );
  }
}

class _DemoPainter extends CustomPainter {
  final IntroGesture gesture;
  final double t;
  _DemoPainter(this.gesture, this.t);

  /// Dónde está el dedo en [k] (0 a 1) del gesto, en una caja de 1×1.
  Offset _finger(double k) => switch (gesture) {
    IntroGesture.tap || IntroGesture.hold => const Offset(0.5, 0.55),
    IntroGesture.trace => Offset(0.5 + 0.32 * cos(k * 2 * pi - pi / 2), 0.5 + 0.32 * sin(k * 2 * pi - pi / 2)),
    IntroGesture.swipe => Offset(0.15 + 0.7 * k, 0.6 - 0.2 * sin(k * pi)),
    IntroGesture.paint => Offset(0.2 + 0.6 * k, 0.5 + 0.18 * sin(k * 6 * pi)),
    IntroGesture.swap => Offset(0.35 + 0.3 * k, 0.5),
    IntroGesture.pull => Offset(0.75 - 0.5 * k, 0.5),
  };

  @override
  void paint(Canvas canvas, Size size) {
    Offset at(Offset p) => Offset(p.dx * size.width, p.dy * size.height);
    final ink = Palette.ink;
    // El gesto ocupa el 70% del ciclo; el resto, la mano descansa.
    final k = Curves.easeInOut.transform((t / 0.7).clamp(0.0, 1.0));
    final fade = t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3;

    switch (gesture) {
      case IntroGesture.tap:
        final ring = (t * 2) % 1;
        canvas.drawCircle(
          at(_finger(0)),
          8 + 26 * ring,
          Paint()
            ..color = Palette.water.withValues(alpha: 0.5 * (1 - ring))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      case IntroGesture.hold:
        canvas.drawArc(
          Rect.fromCircle(center: at(_finger(0)), radius: 30),
          -pi / 2,
          2 * pi * k,
          false,
          Paint()
            ..color = Palette.water.withValues(alpha: 0.7 * fade)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 5,
        );
      case IntroGesture.swap:
        for (final (x, c) in [(0.35, Palette.lotus), (0.65, Palette.moss)]) {
          final dx = (x == 0.35 ? 1 : -1) * 0.3 * k;
          canvas.drawCircle(at(Offset(x + dx, 0.5)), 16, Paint()..color = c);
        }
      case IntroGesture.pull:
        canvas.drawLine(
          at(const Offset(0.1, 0.5)),
          at(_finger(k)),
          Paint()
            ..color = Palette.wood
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round,
        );
      default:
        // Rastro del dedo hasta donde va.
        final path = Path();
        for (var i = 0; i <= 40; i++) {
          final p = at(_finger(k * i / 40));
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = (gesture == IntroGesture.paint ? Palette.moss : ink).withValues(alpha: 0.45 * fade)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = gesture == IntroGesture.paint ? 14 : 4,
        );
    }

    // La mano: la punta del índice en el dedo.
    final tip = at(_finger(gesture == IntroGesture.tap || gesture == IntroGesture.hold ? 0 : k));
    final press = gesture == IntroGesture.tap ? 1 - 0.12 * sin(((t * 2) % 1) * pi) : 1.0;
    final icon = Icons.touch_app_rounded;
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: 44 * press,
          color: ink.withValues(alpha: 0.85 * max(0.3, fade)),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // En el ícono, la punta del índice queda arriba, un poco a la izquierda del centro.
    tp.paint(canvas, tip - Offset(tp.width * 0.42, tp.height * 0.08));
  }

  @override
  bool shouldRepaint(_DemoPainter old) => old.t != t || old.gesture != gesture;
}
