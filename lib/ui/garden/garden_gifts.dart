part of 'garden_view.dart';

/// Cómo se ve cada regalo del momento del día (también en el álbum).
GiftLook giftLook(String id) => switch (id) {
  'firefly' => GiftLook.firefly,
  'snowflake' => GiftLook.flake,
  'rainjar' => GiftLook.rain,
  'rainbow' => GiftLook.rainbow,
  'seed' => GiftLook.seed,
  'lastray' => GiftLook.ray,
  _ => GiftLook.dew,
};

enum GiftLook { dew, firefly, rain, flake, rainbow, seed, ray }

class GiftPainter extends CustomPainter {
  final GiftLook look;
  final double pulse;
  GiftPainter({required this.look, required this.pulse});

  void _glow(Canvas canvas, Offset c, Color color, double r, double a) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: a),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    switch (look) {
      case GiftLook.firefly:
        _glow(canvas, c, const Color(0xFFE4F59A), 16, 0.55 * pulse);
        canvas.drawCircle(c, 3, Paint()..color = const Color(0xFFF7FFD6));
      case GiftLook.flake:
        _glow(canvas, c, Colors.white, 16, 0.6 * pulse);
        final arm = Paint()
          ..color = Colors.white
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 6; i++) {
          final d = Offset.fromDirection(i * pi / 3, 7);
          canvas.drawLine(c - d, c + d, arm);
          canvas.drawLine(c + d * 0.55, c + d * 0.55 + Offset.fromDirection(i * pi / 3 + 0.7, 3), arm);
          canvas.drawLine(c + d * 0.55, c + d * 0.55 + Offset.fromDirection(i * pi / 3 - 0.7, 3), arm);
        }
      case GiftLook.rainbow:
        // Una gota que refleja el arcoíris.
        _glow(canvas, c, const Color(0xFFFFF3C4), 18, 0.55 * pulse);
        canvas.drawCircle(
          c,
          7,
          Paint()
            ..shader = const SweepGradient(
              colors: [
                Color(0xFFE57373),
                Color(0xFFFFB74D),
                Color(0xFFFFF176),
                Color(0xFF81C784),
                Color(0xFF64B5F6),
                Color(0xFF9575CD),
                Color(0xFFE57373),
              ],
            ).createShader(Rect.fromCircle(center: c, radius: 7)),
        );
        canvas.drawCircle(c + const Offset(-2, -2), 2, Paint()..color = Colors.white.withValues(alpha: 0.8));
      case GiftLook.seed:
        // Vilano: un tallito con pelos finos en abanico.
        _glow(canvas, c, Colors.white, 14, 0.35 * pulse);
        final hair = Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round;
        final top = c + const Offset(0, -2);
        for (var i = 0; i < 9; i++) {
          canvas.drawLine(top, top + Offset.fromDirection(-pi + pi * i / 8, 8), hair);
        }
        canvas.drawLine(top, c + const Offset(0, 8), hair..color = const Color(0xFFD8CBB0));
        canvas.drawCircle(c + const Offset(0, 8), 1.6, Paint()..color = Palette.wood);
      case GiftLook.ray:
        // Destello dorado del último rayo de sol.
        _glow(canvas, c, Palette.lantern, 18, 0.6 * pulse);
        final beam = Paint()
          ..color = const Color(0xFFFFE6A8).withValues(alpha: 0.9)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 4; i++) {
          final d = Offset.fromDirection(i * pi / 4, 4 + 5 * pulse);
          canvas.drawLine(c - d, c + d, beam);
        }
        canvas.drawCircle(c, 2.4, Paint()..color = Colors.white);
      case GiftLook.dew || GiftLook.rain:
        final rain = look == GiftLook.rain;
        final drop = Path()
          ..moveTo(c.dx, c.dy - 8)
          ..quadraticBezierTo(c.dx + 6, c.dy + 1, c.dx, c.dy + 5)
          ..quadraticBezierTo(c.dx - 6, c.dy + 1, c.dx, c.dy - 8);
        if (rain) {
          _glow(canvas, c, const Color(0xFFBFE6F5), 15, 0.5 * pulse);
        } else {
          canvas.drawCircle(c, 13, Paint()..color = Colors.white.withValues(alpha: 0.18 * pulse));
        }
        canvas.drawPath(
          drop,
          Paint()..color = (rain ? const Color(0xFF9FD3EA) : const Color(0xFFD6F0F4)).withValues(alpha: 0.95),
        );
        canvas.drawCircle(c + const Offset(-1.5, -1), 1.6, Paint()..color = Colors.white.withValues(alpha: pulse));
    }
  }

  @override
  bool shouldRepaint(GiftPainter old) => old.pulse != pulse || old.look != look;
}
