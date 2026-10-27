import 'dart:math';
import 'dart:ui';

import '../../ui/theme/palette.dart';
import 'sand_shapes.dart';

/// Dibujo de la arena con código mientras no esté `tex_sand_base` (Lote 1).
/// Lo usan el minijuego y el jardín.

/// Arena con granitos claros y oscuros, grabada una vez en un Picture.
Picture sandTexture(Size size, {int seed = 3}) {
  final rec = PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(Offset.zero & size, Paint()..color = Palette.sand);
  final rng = Random(seed);
  final dark = Paint()..color = Palette.sandShadow.withValues(alpha: 0.35);
  final light = Paint()..color = Palette.sandLight.withValues(alpha: 0.7);
  final n = (size.width * size.height / 90).round();
  for (var i = 0; i < n; i++) {
    final o = Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height);
    c.drawCircle(o, 0.6 + rng.nextDouble() * 0.9, rng.nextBool() ? dark : light);
  }
  return rec.endRecording();
}

Path pathOf(List<P> pts, Rect r) {
  final path = Path();
  for (var i = 0; i < pts.length; i++) {
    final o = Offset(r.left + pts[i].x * r.width, r.top + pts[i].y * r.height);
    i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
  }
  return path;
}

/// Surcos del rastrillo: 5 líneas paralelas por trazo, cada una con sombra
/// y brillo para que se lea el relieve. [progress] (0..1) es cuánto del
/// recorrido total ya pasó el rastrillo. Devuelve la posición y el ángulo de
/// la punta, o null si no hay trazo.
(Offset, double)? drawGrooves(Canvas canvas, List<List<P>> strokes, Rect r, double progress, {int tines = 5}) {
  final lines = [for (final s in strokes) resample(s, 0.008)].where((s) => s.length > 1).toList();
  final total = lines.fold<int>(0, (a, s) => a + s.length);
  if (total == 0) return null;
  var budget = (total * progress).round();
  final spacing = r.width * 0.013;
  final shadow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(1.2, r.width * 0.006)
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = Palette.sandShadow;
  final shine = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(1.0, r.width * 0.004)
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = Palette.sandLight;
  (Offset, double)? head;
  for (final s in lines) {
    if (budget <= 1) break;
    final pts = [for (final p in s.take(budget)) Offset(r.left + p.x * r.width, r.top + p.y * r.height)];
    budget -= s.length;
    if (pts.length < 2) continue;
    final normals = <Offset>[];
    for (var i = 0; i < pts.length; i++) {
      final a = pts[max(0, i - 1)], b = pts[min(pts.length - 1, i + 1)];
      final d = b - a;
      final len = d.distance == 0 ? 1 : d.distance;
      normals.add(Offset(-d.dy / len, d.dx / len));
    }
    for (var k = 0; k < tines; k++) {
      final off = (k - (tines - 1) / 2) * spacing;
      final groove = Path(), ridge = Path();
      for (var i = 0; i < pts.length; i++) {
        final o = pts[i] + normals[i] * off;
        final o2 = o + normals[i] * (shine.strokeWidth * 0.9);
        if (i == 0) {
          groove.moveTo(o.dx, o.dy);
          ridge.moveTo(o2.dx, o2.dy);
        } else {
          groove.lineTo(o.dx, o.dy);
          ridge.lineTo(o2.dx, o2.dy);
        }
      }
      canvas.drawPath(ridge, shine);
      canvas.drawPath(groove, shadow);
    }
    final last = pts.last, prev = pts[pts.length - 2];
    head = (last, atan2(last.dy - prev.dy, last.dx - prev.dx));
  }
  return head;
}

/// Rastrillo placeholder (hasta `spr_sand_rake_01`): travesaño con dientes,
/// perpendicular al avance, y un mango hacia atrás.
void drawRake(Canvas canvas, Offset at, double angle) {
  canvas.save();
  canvas.translate(at.dx, at.dy);
  canvas.rotate(angle);
  final wood = Paint()..color = Palette.wood;
  canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-6, -26, 10, 52), const Radius.circular(3)), wood);
  for (var k = -2; k <= 2; k++) {
    canvas.drawRect(Rect.fromLTWH(2, k * 10.0 - 1.5, 8, 3), wood);
  }
  canvas.drawRRect(
    RRect.fromRectAndRadius(const Rect.fromLTWH(-90, -3, 86, 6), const Radius.circular(3)),
    Paint()..color = Color.lerp(Palette.wood, Palette.sand, 0.25)!,
  );
  canvas.restore();
}
