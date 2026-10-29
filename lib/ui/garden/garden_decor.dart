import 'dart:math';

import 'package:flutter/material.dart';

import '../../garden/decor.dart';
import '../theme/palette.dart';
import 'garden_scene.dart';
import 'scene_art.dart';

/// Dónde se dibuja una decoración con el pie en [foot]: las del fondo de la
/// vista se ven más chicas.
Rect decorRect(DecorItem d, Offset foot, GardenLayout layout) {
  final g = layout.ground;
  final depth = ((foot.dy - g.top) / g.height).clamp(0.0, 1.0);
  final w = d.size * layout.size.width * (0.9 + 0.5 * depth);
  final h = w * d.aspect;
  return Rect.fromLTWH(foot.dx - w / 2, foot.dy - h, w, h);
}

/// Dónde puede ir el pie de una decoración: sobre el suelo de la vista.
Offset clampFoot(Offset foot, GardenLayout layout) {
  final g = layout.ground, s = layout.size;
  return Offset(
    foot.dx.clamp(s.width * 0.05, s.width * 0.95),
    foot.dy.clamp(g.top + g.height * 0.06, s.height - g.height * 0.03),
  );
}

/// Una decoración en [r] (apoyada en su borde de abajo), con su sombra. Usa
/// el arte `obj_decor_<id>` si está; si no, una versión pintada.
void paintDecor(Canvas canvas, String id, Rect r) {
  canvas.drawOval(
    Rect.fromCenter(center: r.bottomCenter, width: r.width * 0.9, height: r.width * 0.16),
    Paint()..color = Palette.ink.withValues(alpha: 0.16),
  );
  if (drawArtIn(canvas, SceneArt.instance['obj_decor_$id'], r) != null) return;
  final w = r.width, h = r.height, b = r.bottom, cx = r.center.dx;
  Paint fill(Color c) => Paint()..color = c;
  Offset at(double fx, double fy) => Offset(r.left + w * fx, r.top + h * fy);
  void rock(Rect o, Color c) {
    canvas.drawOval(o, fill(c));
    canvas.drawOval(
      Rect.fromLTWH(o.left + o.width * 0.18, o.top + o.height * 0.12, o.width * 0.45, o.height * 0.35),
      fill(Colors.white.withValues(alpha: 0.18)),
    );
  }

  void blobs(List<(double, double, double)> pads, Color c, {Color? light}) {
    for (final (fx, fy, fr) in pads) {
      canvas.drawCircle(at(fx, fy), w * fr, fill(c));
      if (light != null) canvas.drawCircle(at(fx - fr * 0.3, fy - fr * 0.25), w * fr * 0.55, fill(light));
    }
  }

  void trunk(List<Offset> pts, double width, Color c) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  switch (id) {
    case 'step':
      rock(Rect.fromLTRB(r.left, b - h * 0.8, r.right, b), Palette.stoneDark);
    case 'rocks':
      rock(Rect.fromLTRB(r.left, b - h * 0.62, r.left + w * 0.5, b), Palette.stone);
      rock(Rect.fromLTRB(r.left + w * 0.38, b - h * 0.95, r.right - w * 0.12, b), Palette.stoneDark);
      rock(Rect.fromLTRB(r.right - w * 0.32, b - h * 0.42, r.right, b), Palette.stoneLight);
    case 'moss':
      for (final s in [-1.0, 1.0]) {
        trunk([at(0.5 + s * 0.05, 0.55), at(0.5 + s * 0.28, 0.05)], w * 0.04, Palette.mossDark);
      }
      canvas.drawOval(Rect.fromLTRB(r.left, b - h * 0.55, r.right, b), fill(Palette.moss));
      canvas.drawOval(
        Rect.fromLTRB(r.left + w * 0.15, b - h * 0.5, r.right - w * 0.3, b - h * 0.25),
        fill(const Color(0xFF8FAA6E)),
      );
    case 'boulder':
      rock(Rect.fromLTRB(r.left, b - h, r.right, b), Palette.stone);
      canvas.drawOval(Rect.fromLTRB(r.left + w * 0.2, b - h, r.right - w * 0.25, b - h * 0.72), fill(Palette.moss));
    case 'azalea':
      blobs([(0.3, 0.6, 0.3), (0.7, 0.6, 0.3), (0.5, 0.42, 0.34)], Palette.mossDark, light: Palette.moss);
      final rng = Random(id.hashCode);
      for (var i = 0; i < 9; i++) {
        canvas.drawCircle(
          at(0.2 + rng.nextDouble() * 0.6, 0.2 + rng.nextDouble() * 0.6),
          w * 0.04,
          fill(Palette.lotus),
        );
      }
    case 'peak':
      final path = Path()
        ..moveTo(r.left, b)
        ..lineTo(r.left + w * 0.2, r.top + h * 0.3)
        ..lineTo(r.left + w * 0.45, r.top)
        ..lineTo(r.left + w * 0.8, r.top + h * 0.35)
        ..lineTo(r.right, b)
        ..close();
      canvas.drawPath(path, fill(Palette.stone));
      canvas.drawPath(
        Path()
          ..moveTo(r.left + w * 0.45, r.top)
          ..lineTo(r.left + w * 0.8, r.top + h * 0.35)
          ..lineTo(r.right, b)
          ..lineTo(r.left + w * 0.55, b)
          ..close(),
        fill(Palette.stoneDark.withValues(alpha: 0.5)),
      );
      canvas.drawOval(Rect.fromLTRB(r.left, b - h * 0.1, r.right, b + h * 0.02), fill(Palette.moss));
    case 'bamboo':
      for (final (fx, top) in [(0.2, 0.25), (0.38, 0.0), (0.55, 0.12), (0.72, 0.3), (0.86, 0.45)]) {
        final x = r.left + w * fx;
        trunk([Offset(x, b), Offset(x, r.top + h * top)], w * 0.09, const Color(0xFF7FA35A));
        for (var y = b - h * 0.18; y > r.top + h * top; y -= h * 0.18) {
          canvas.drawLine(Offset(x - w * 0.05, y), Offset(x + w * 0.05, y), fill(Palette.mossDark)..strokeWidth = 1.5);
        }
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x + w * 0.08, r.top + h * top + h * 0.03), width: w * 0.22, height: h * 0.04),
          fill(Palette.moss),
        );
      }
      canvas.drawOval(Rect.fromLTRB(r.left, b - h * 0.06, r.right, b + h * 0.02), fill(Palette.wood));
    case 'lantern':
      final stone = fill(Palette.stoneLight), dark = fill(Palette.stone);
      canvas.drawRect(Rect.fromLTRB(r.left + w * 0.15, b - h * 0.08, r.right - w * 0.15, b), dark);
      canvas.drawRect(Rect.fromLTRB(cx - w * 0.12, b - h * 0.5, cx + w * 0.12, b - h * 0.08), stone);
      canvas.drawRect(Rect.fromLTRB(r.left + w * 0.15, b - h * 0.56, r.right - w * 0.15, b - h * 0.5), dark);
      canvas.drawRect(Rect.fromLTRB(r.left + w * 0.22, b - h * 0.76, r.right - w * 0.22, b - h * 0.56), stone);
      canvas.drawRect(Rect.fromLTRB(cx - w * 0.14, b - h * 0.72, cx + w * 0.14, b - h * 0.6), fill(Palette.lantern));
      canvas.drawPath(
        Path()
          ..moveTo(r.left, b - h * 0.76)
          ..lineTo(cx, r.top + h * 0.06)
          ..lineTo(r.right, b - h * 0.76)
          ..close(),
        dark,
      );
      canvas.drawCircle(Offset(cx, r.top + h * 0.05), w * 0.07, stone);
    case 'basin':
      rock(Rect.fromLTRB(r.left, b - h * 0.85, r.right, b), Palette.stone);
      canvas.drawOval(
        Rect.fromLTRB(r.left + w * 0.2, b - h * 0.8, r.right - w * 0.2, b - h * 0.6),
        fill(Palette.water),
      );
      trunk([at(0.95, 0.0), at(0.62, 0.18)], w * 0.07, const Color(0xFF9DB06A));
    case 'bench':
      final wood = fill(Palette.wood), dark = fill(const Color(0xFF5E3D28));
      canvas.drawRect(Rect.fromLTRB(r.left + w * 0.08, b - h * 0.6, r.left + w * 0.16, b), dark);
      canvas.drawRect(Rect.fromLTRB(r.right - w * 0.16, b - h * 0.6, r.right - w * 0.08, b), dark);
      canvas.drawRRect(RRect.fromLTRBR(r.left, b - h * 0.78, r.right, b - h * 0.55, Radius.circular(h * 0.06)), wood);
    case 'jizo':
      canvas.drawRect(Rect.fromLTRB(r.left, b - h * 0.14, r.right, b), fill(Palette.stoneDark));
      canvas.drawOval(
        Rect.fromLTRB(r.left + w * 0.08, b - h * 0.72, r.right - w * 0.08, b - h * 0.1),
        fill(Palette.stoneLight),
      );
      canvas.drawPath(
        Path()
          ..moveTo(r.left + w * 0.12, b - h * 0.62)
          ..lineTo(r.right - w * 0.12, b - h * 0.62)
          ..lineTo(cx, b - h * 0.42)
          ..close(),
        fill(const Color(0xFFC0473B)),
      );
      canvas.drawCircle(Offset(cx, r.top + h * 0.2), w * 0.3, fill(Palette.stoneLight));
    case 'pine':
      trunk([at(0.45, 1), at(0.4, 0.7), at(0.6, 0.45), at(0.45, 0.2)], w * 0.08, const Color(0xFF4A3A2E));
      blobs(
        [(0.25, 0.55, 0.17), (0.72, 0.42, 0.18), (0.38, 0.27, 0.16), (0.55, 0.12, 0.13)],
        const Color(0xFF3F5A3A),
        light: Palette.mossDark,
      );
    case 'bridge':
      final red = const Color(0xFFB85A45);
      final arc = Path()
        ..moveTo(r.left, b)
        ..quadraticBezierTo(cx, r.top - h * 0.3, r.right, b);
      canvas.drawPath(
        arc,
        Paint()
          ..color = const Color(0xFF5E3D28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * 0.18,
      );
      final rail = Path()
        ..moveTo(r.left + w * 0.08, b - h * 0.5)
        ..quadraticBezierTo(cx, r.top - h * 0.55, r.right - w * 0.08, b - h * 0.5);
      canvas.drawPath(
        rail,
        Paint()
          ..color = red
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * 0.07,
      );
      for (final fx in [0.12, 0.31, 0.5, 0.69, 0.88]) {
        final x = r.left + w * fx;
        final top = b - h * (0.5 + 0.55 * (1 - pow((fx - 0.5) * 2, 2)));
        final deck = b - h * (0.1 + 0.5 * (1 - pow((fx - 0.5) * 2, 2)));
        canvas.drawLine(Offset(x, top), Offset(x, deck), fill(red)..strokeWidth = w * 0.02);
      }
    case 'pagoda':
      final stone = fill(Palette.stoneLight), dark = fill(Palette.stone);
      var y = b, tw = w * 0.6;
      canvas.drawRect(Rect.fromLTRB(cx - tw / 2, b - h * 0.08, cx + tw / 2, b), dark);
      y -= h * 0.08;
      for (var i = 0; i < 4; i++) {
        final bh = h * (0.1 - i * 0.012);
        canvas.drawRect(Rect.fromLTRB(cx - tw * 0.32, y - bh, cx + tw * 0.32, y), stone);
        y -= bh;
        canvas.drawPath(
          Path()
            ..moveTo(cx - tw * 0.75, y)
            ..quadraticBezierTo(cx, y - h * 0.08, cx + tw * 0.75, y)
            ..close(),
          dark,
        );
        canvas.drawRect(Rect.fromLTRB(cx - tw * 0.75, y - h * 0.02, cx + tw * 0.75, y), dark);
        y -= h * 0.05;
        tw *= 0.86;
      }
      canvas.drawRect(Rect.fromLTRB(cx - w * 0.03, r.top, cx + w * 0.03, y), dark);
    case 'maple' || 'sakura':
      final leaf = id == 'maple' ? const Color(0xFFC4553A) : const Color(0xFFF0B8C4);
      final light = id == 'maple' ? const Color(0xFFE08A4A) : const Color(0xFFFBDDE3);
      trunk([at(0.5, 1), at(0.48, 0.65), at(0.35, 0.4)], w * 0.07, const Color(0xFF4A3A2E));
      trunk([at(0.48, 0.65), at(0.68, 0.38)], w * 0.05, const Color(0xFF4A3A2E));
      blobs(
        [(0.22, 0.42, 0.2), (0.78, 0.4, 0.2), (0.5, 0.22, 0.26), (0.32, 0.18, 0.16), (0.68, 0.16, 0.16)],
        leaf,
        light: light,
      );
  }
}

/// Las decoraciones de una vista, de atrás hacia adelante.
void paintDecorations(Canvas canvas, List<(String, Rect)> decor) {
  for (final (id, r) in [...decor]..sort((a, b) => a.$2.bottom.compareTo(b.$2.bottom))) {
    paintDecor(canvas, id, r);
  }
}

/// Una decoración sola (para la bandeja, el álbum o mientras se arrastra).
class DecorPainter extends CustomPainter {
  final String id;
  final double aspect;
  DecorPainter(this.id, this.aspect);

  @override
  void paint(Canvas canvas, Size size) {
    var w = size.width * 0.86, h = w * aspect;
    if (h > size.height * 0.9) {
      h = size.height * 0.9;
      w = h / aspect;
    }
    paintDecor(canvas, id, Rect.fromLTWH((size.width - w) / 2, size.height * 0.94 - h, w, h));
  }

  @override
  bool shouldRepaint(DecorPainter old) => old.id != id;
}
