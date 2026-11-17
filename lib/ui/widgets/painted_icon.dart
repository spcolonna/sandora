import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../garden/scene_art.dart';
import '../theme/palette.dart';

/// Un ícono pintado (`icon_*` de `SceneArt`) en un cuadrado de [size]; si el
/// arte falta, el ícono de Material [fallback]. Con [glow] lleva un halo de
/// farol detrás (para la guía, donde el ícono de código se pintaba ámbar).
class PaintedIcon extends StatelessWidget {
  final String art;
  final IconData fallback;
  final double size;
  final Color color;
  final bool glow;
  const PaintedIcon(
    this.art, {
    super.key,
    required this.fallback,
    this.size = 22,
    this.color = Palette.wood,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final img = SceneArt.instance[art];
    if (img == null) return Icon(fallback, size: size * 0.86, color: glow ? Palette.lantern : color);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _IconPainter(img, glow)),
    );
  }
}

class _IconPainter extends CustomPainter {
  final ui.Image img;
  final bool glow;
  _IconPainter(this.img, this.glow);

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    if (glow) {
      canvas.drawCircle(
        box.center,
        size.width * 0.75,
        Paint()
          ..shader = RadialGradient(
            colors: [Palette.lantern.withValues(alpha: 0.55), Palette.lantern.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: box.center, radius: size.width * 0.75)),
      );
    }
    final r = artRectIn(img, box);
    drawArt(
      canvas,
      img,
      r.translate(0, -(size.height - r.height) / 2),
      paint: Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.img != img || old.glow != glow;
}
