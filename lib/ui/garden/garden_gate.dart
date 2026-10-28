import 'dart:math';

import 'package:flutter/material.dart';

import '../fx/sfx.dart';
import '../theme/palette.dart';

/// Entrada al jardín: dos puertas shoji con luz detrás que se corren a los
/// lados; al abrirse entra un brillo que encandila y se va despacio, y el
/// jardín se asienta. Tocar acelera el final.
class GardenGate extends StatefulWidget {
  final Widget child;
  const GardenGate({super.key, required this.child});

  @override
  State<GardenGate> createState() => _GardenGateState();
}

class _GardenGateState extends State<GardenGate> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
  bool _open = false;

  /// El jardín vive siempre bajo la misma llave: al terminar la puerta no se
  /// vuelve a crear (antes se perdía el toque que caía en ese cuadro).
  final _garden = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Por estado y no por el future de forward(): apurar con animateTo cancela
    // ese future y la puerta quedaba encima para siempre.
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) setState(() => _open = true);
    });
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _c.forward();
    });
    // Un golpe suave cuando las puertas se destraban.
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted && !_open) Haptics.light();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _hurry() {
    if (_c.isAnimating && _c.value < 0.9) {
      _c.animateTo(1, duration: const Duration(milliseconds: 600), curve: Curves.easeOut);
    }
  }

  /// Avance de 0 a 1 entre [from] y [to] del total, con [curve].
  double _span(double from, double to, [Curve curve = Curves.easeInOutCubic]) =>
      curve.transform(((_c.value - from) / (to - from)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final garden = KeyedSubtree(key: _garden, child: widget.child);
    if (_open) return garden;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _hurry,
      child: AnimatedBuilder(
        animation: _c,
        child: garden,
        builder: (context, garden) {
          // Luz que se cuela por el papel y la rendija, puertas que se corren,
          // destello que crece al abrirse y se apaga mientras el jardín se asienta.
          final light = _span(0.0, 0.3, Curves.easeIn);
          final slide = _span(0.22, 0.62);
          final flash = _span(0.3, 0.5, Curves.easeOut) * (1 - _span(0.5, 1.0, Curves.easeInOut));
          final settle = _span(0.3, 1.0, Curves.easeOutCubic);
          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: Palette.paper),
              // Mientras las puertas tapan el jardín, el toque apura la entrada;
              // en cuanto se corren, ya se puede tocar el jardín.
              IgnorePointer(
                ignoring: slide < 1,
                child: Transform.scale(scale: 1.08 - 0.08 * settle, child: garden),
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _DoorsPainter(slide: slide, light: light, flash: flash),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DoorsPainter extends CustomPainter {
  final double slide, light, flash;
  _DoorsPainter({required this.slide, required this.light, required this.flash});

  static const _frame = Color(0xFF5B3E2B);
  static const _frameLight = Color(0xFF7A563D);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final half = w / 2;
    final gap = half * slide;
    // Rendija de luz entre las puertas (y lo que asoma al abrirse).
    if (slide < 1) {
      final beam = Rect.fromLTRB(half - gap - 6, 0, half + gap + 6, h);
      canvas.drawRect(
        beam,
        Paint()
          ..shader = LinearGradient(
            colors: [
              const Color(0xFFFFF6DE).withValues(alpha: 0),
              const Color(0xFFFFF6DE).withValues(alpha: 0.9 * light),
              const Color(0xFFFFF6DE).withValues(alpha: 0),
            ],
          ).createShader(beam.inflate(20)),
      );
    }
    _door(canvas, Rect.fromLTWH(-gap, 0, half, h), left: true);
    _door(canvas, Rect.fromLTWH(half + gap, 0, half, h), left: false);
    if (flash > 0) {
      final c = Offset(half, h * 0.45);
      final r = max(w, h) * (0.5 + 0.6 * flash);
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: flash),
              const Color(0xFFFFF1D0).withValues(alpha: 0.85 * flash),
              const Color(0xFFFFE6B0).withValues(alpha: 0.3 * flash),
            ],
            stops: const [0, 0.45, 1],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
  }

  /// Una puerta shoji: marco de madera y papel con la cuadrícula kumiko; el
  /// papel se ilumina con la luz de atrás.
  void _door(Canvas canvas, Rect r, {required bool left}) {
    if (r.right <= 0 || r.left >= r.width * 2) return;
    final frame = r.width * 0.07;
    canvas.drawRect(r, Paint()..color = _frame);
    final paper = r.deflate(frame);
    canvas.drawRect(
      paper,
      Paint()
        ..shader = RadialGradient(
          center: left ? Alignment.centerRight : Alignment.centerLeft,
          radius: 1.3,
          colors: [
            Color.lerp(Palette.paper, const Color(0xFFFFF8E6), light)!,
            Color.lerp(const Color(0xFFE2D6BC), Palette.paper, light)!,
          ],
        ).createShader(paper),
    );
    final bar = Paint()..color = _frameLight;
    const cols = 3, rows = 7;
    final bw = r.width * 0.016;
    for (var i = 1; i < cols; i++) {
      final x = paper.left + paper.width * i / cols;
      canvas.drawRect(Rect.fromLTRB(x - bw / 2, paper.top, x + bw / 2, paper.bottom), bar);
    }
    for (var j = 1; j < rows; j++) {
      final y = paper.top + paper.height * j / rows;
      canvas.drawRect(Rect.fromLTRB(paper.left, y - bw / 2, paper.right, y + bw / 2), bar);
    }
    // Zócalo de madera abajo.
    canvas.drawRect(Rect.fromLTRB(r.left, r.bottom - r.height * 0.12, r.right, r.bottom), Paint()..color = _frame);
    // Tirador hundido.
    final handle = Offset(left ? r.right - frame * 2.2 : r.left + frame * 2.2, r.center.dy);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: handle, width: frame * 0.9, height: frame * 2.4),
        Radius.circular(frame),
      ),
      Paint()..color = const Color(0xFF3E2A1D),
    );
    // Sombra del borde que se abre.
    final edge = left
        ? Rect.fromLTRB(r.right - 4, 0, r.right, r.bottom)
        : Rect.fromLTRB(r.left, 0, r.left + 4, r.bottom);
    canvas.drawRect(edge, Paint()..color = Palette.ink.withValues(alpha: 0.25));
  }

  @override
  bool shouldRepaint(_DoorsPainter old) => old.slide != slide || old.light != light || old.flash != flash;
}
