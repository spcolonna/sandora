import 'dart:math';
import 'dart:ui';

import '../../ui/garden/scene_art.dart';
import 'stack_rules.dart';

/// Arte de cada tipo de piedra (`obj_stack_stone_NN`), en el orden de [StoneKind].
const _art = [1, 4, 3, 5, 2, 6];

/// Colores de cada tono: base, sombra y motas.
const _tones = [
  (Color(0xFF8C8A85), Color(0xFF5E5C58), Color(0xFFB9B6AE)), // granito
  (Color(0xFF5B5955), Color(0xFF3B3A37), Color(0xFF7D7A74)), // basalto
  (Color(0xFFB09A7A), Color(0xFF7E6A4F), Color(0xFFD6C4A4)), // arenisca
  (Color(0xFFC9C5BC), Color(0xFF9A958B), Color(0xFFEDEAE3)), // cuarzo
  (Color(0xFF7D857A), Color(0xFF545C52), Color(0xFFA3AB9C)), // piedra verde
];

/// Pinta una piedra centrada en el origen, en metros. Las motas, la veta y el
/// musgo salen de su `seed`, así cada piedra es siempre la misma.
void paintStone(Canvas canvas, StoneShape s, {double opacity = 1}) {
  final a = opacity.clamp(0.0, 1.0);
  final path = s.path;
  final img = SceneArt.instance['obj_stack_stone_0${_art[s.kind.index]}'];
  if (img != null) {
    // El arte se estira a la silueta de la física. La cuña se da vuelta hacia
    // donde se inclina; las demás, según la piedra, para que no se repitan.
    final top = s.outline.where((o) => o.dy < -s.height * 0.2);
    final lean = top.fold(0.0, (t, o) => t + o.dx);
    final flip = s.kind == StoneKind.wedge ? lean > 0 : s.seed.isOdd;
    final b = path.getBounds();
    canvas.save();
    if (flip) canvas.scale(-1, 1);
    drawArt(
      canvas,
      img,
      flip ? Rect.fromLTRB(-b.right, b.top, -b.left, b.bottom) : b,
      paint: Paint()..color = Color.fromRGBO(255, 255, 255, a),
    );
    canvas.restore();
    return;
  }
  final (base, dark, light) = _tones[s.tone % _tones.length];
  canvas.drawPath(path, Paint()..color = base.withValues(alpha: a));
  canvas.save();
  canvas.clipPath(path);
  final w = s.width, h = s.height;
  // Sombra abajo y brillo arriba para que se lea el volumen.
  canvas.drawRect(Rect.fromLTWH(-w, h * 0.12, w * 2, h), Paint()..color = dark.withValues(alpha: 0.55 * a));
  canvas.drawOval(
    Rect.fromCenter(center: Offset(-w * 0.12, -h * 0.3), width: w * 0.75, height: h * 0.45),
    Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.22 * a),
  );
  final rng = Random(s.seed);
  // Motas.
  final speck = Paint()..color = (rng.nextBool() ? light : dark).withValues(alpha: 0.5 * a);
  for (var i = 0; i < 9 + rng.nextInt(10); i++) {
    final p = Offset((rng.nextDouble() - 0.5) * w, (rng.nextDouble() - 0.5) * h);
    canvas.drawCircle(p, 0.012 + rng.nextDouble() * 0.025, speck);
  }
  // A veces una veta de cuarzo.
  if (rng.nextDouble() < 0.3) {
    final y0 = (rng.nextDouble() - 0.5) * h * 0.6;
    final y1 = y0 + (rng.nextDouble() - 0.5) * h * 0.5;
    canvas.drawPath(
      Path()
        ..moveTo(-w / 2, y0)
        ..quadraticBezierTo(0, (y0 + y1) / 2 + h * 0.1, w / 2, y1),
      Paint()
        ..color = const Color(0xFFF2EEE4).withValues(alpha: 0.55 * a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.025 + rng.nextDouble() * 0.03,
    );
  }
  // Y a veces musgo arriba.
  if (rng.nextDouble() < 0.2) {
    final x = (rng.nextDouble() - 0.5) * w * 0.4;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, -h * 0.5), width: w * (0.3 + rng.nextDouble() * 0.3), height: h * 0.32),
      Paint()..color = const Color(0xFF6E8B5B).withValues(alpha: 0.8 * a),
    );
  }
  canvas.restore();
  // Contorno apenas marcado.
  canvas.drawPath(
    path,
    Paint()
      ..color = dark.withValues(alpha: 0.35 * a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.02,
  );
}
