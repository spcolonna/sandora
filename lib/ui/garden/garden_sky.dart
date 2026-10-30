part of 'garden_view.dart';

/// Lo vivo del cielo: nubes que pasan, estrellas que titilan de noche y el
/// clima (lluvia, nieve, niebla, relámpagos lejanos).
class _SkyLifePainter extends CustomPainter {
  final Animation<double> life;
  final double daylight, warmth;
  final Weather weather;

  /// Si cruzan hojas con el viento.
  final bool windy;
  _SkyLifePainter(this.life, {required this.daylight, required this.warmth, required this.weather, this.windy = false})
    : super(repaint: life);

  bool get _wet => weather == Weather.rain || weather == Weather.storm;

  @override
  void paint(Canvas canvas, Size size) {
    final t = life.value * 120;
    final w = size.width, h = size.height;
    final night = 1 - daylight;
    if (night > 0.05 && (weather == Weather.clear || weather == Weather.cloudy)) {
      final rng = Random(21);
      final shown = weather == Weather.clear ? 1.0 : 0.35;
      for (var i = 0; i < 34; i++) {
        final o = Offset(rng.nextDouble() * w, rng.nextDouble() * h * 0.3);
        final tw = 0.55 + 0.45 * sin(t * (0.6 + rng.nextDouble()) + i);
        canvas.drawCircle(
          o,
          0.6 + rng.nextDouble() * 1.1,
          Paint()..color = Colors.white.withValues(alpha: night * tw * 0.85 * shown),
        );
      }
    }
    _paintClouds(canvas, size, t);
    if (windy) _paintWindLeaves(canvas, size, t);
    switch (weather) {
      case Weather.rain || Weather.storm:
        _paintRain(canvas, size, t);
        if (weather == Weather.storm) _paintFlash(canvas, size, t);
      case Weather.snow:
        _paintSnow(canvas, size, t);
      case Weather.fog:
        _paintFog(canvas, size, t);
      default:
    }
  }

  void _paintClouds(Canvas canvas, Size size, double t) {
    final w = size.width, h = size.height;
    final grey = switch (weather) {
      Weather.clear => 0.0,
      Weather.cloudy || Weather.fog || Weather.snow => 0.35,
      Weather.rain => 0.6,
      Weather.storm => 0.8,
    };
    final base = Color.lerp(Colors.white, const Color(0xFFF6D3B8), warmth * (1 - grey))!;
    final cloud = Color.lerp(base, const Color(0xFF6E7781), grey)!;
    final a = weather == Weather.clear ? (0.08 + 0.6 * daylight).clamp(0.0, 0.7) : 0.25 + 0.55 * daylight;
    final count = weather == Weather.clear ? 3 : 6;
    for (var i = 0; i < count; i++) {
      final speed = (3.0 + i * 1.6) * (_wet ? 1.6 : 1);
      final span = w + 160;
      final x = (i * 157 + t * speed) % span - 80;
      final y = h * (0.06 + 0.05 * (i % 3)) + (i >= 3 ? h * 0.02 : 0);
      final scale = 0.8 + 0.1 * (i % 3) + (i >= 3 ? 0.35 : 0);
      // Difusas, como pintadas en húmedo (círculos nítidos se ven pegados).
      final p = Paint()
        ..color = cloud.withValues(alpha: a * 0.8)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 9 * scale);
      for (final (dx, dy, r) in [(0.0, 0.0, 16.0), (18.0, -6.0, 20.0), (38.0, 0.0, 15.0), (20.0, 6.0, 16.0)]) {
        canvas.drawCircle(Offset(x + dx * scale, y + dy * scale), r * scale, p);
      }
    }
  }

  void _paintRain(Canvas canvas, Size size, double t) {
    final storm = weather == Weather.storm;
    final rng = Random(7);
    final n = storm ? 110 : 70;
    final len = storm ? 18.0 : 13.0;
    final slant = storm ? 0.32 : 0.18;
    final paint = Paint()
      ..color = const Color(0xFFDDE8F0).withValues(alpha: 0.34 + 0.24 * daylight)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < n; i++) {
      final speed = (storm ? 520 : 380) * (0.8 + 0.4 * rng.nextDouble());
      final y = (rng.nextDouble() * (size.height + 40) + t * speed) % (size.height + 40) - 20;
      final x = (rng.nextDouble() * (size.width + 60) + y * slant) % (size.width + 60) - 30;
      canvas.drawLine(Offset(x, y), Offset(x - len * slant, y - len), paint);
    }
  }

  /// Algunas hojas que cruzan el jardín con el viento, girando.
  void _paintWindLeaves(Canvas canvas, Size size, double t) {
    final w = size.width, h = size.height;
    final rng = Random(37);
    for (var i = 0; i < 7; i++) {
      final speed = 40 + 30 * rng.nextDouble();
      final y0 = h * (0.25 + 0.6 * rng.nextDouble());
      final span = w + 80;
      final x = (rng.nextDouble() * span + t * speed) % span - 40;
      final y = y0 + 18 * sin(t * 1.3 + i * 2) + x * 0.06;
      final spin = t * (2 + rng.nextDouble() * 2) + i;
      final color = [Palette.moss, Palette.lantern, Palette.wood][i % 3];
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spin);
      canvas.scale(1, 0.4 + 0.6 * cos(spin * 0.7).abs());
      final leaf = Path()
        ..moveTo(-6, 0)
        ..quadraticBezierTo(0, -4, 6, 0)
        ..quadraticBezierTo(0, 4, -6, 0);
      canvas.drawPath(leaf, Paint()..color = color.withValues(alpha: 0.75));
      canvas.restore();
    }
  }

  void _paintSnow(Canvas canvas, Size size, double t) {
    final rng = Random(11);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (var i = 0; i < 70; i++) {
      final speed = 18 + 22 * rng.nextDouble();
      final r = 1.0 + 1.8 * rng.nextDouble();
      final y = (rng.nextDouble() * (size.height + 20) + t * speed) % (size.height + 20) - 10;
      final x = rng.nextDouble() * size.width + 10 * sin(t * (0.5 + rng.nextDouble()) + i);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _paintFog(Canvas canvas, Size size, double t) {
    final w = size.width, h = size.height;
    final fog = Color.lerp(const Color(0xFF8A93A0), const Color(0xFFF2F2EE), daylight)!;
    // Un velo parejo y bandas que se corren despacio.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.3, w, h * 0.7),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fog.withValues(alpha: 0), fog.withValues(alpha: 0.3), fog.withValues(alpha: 0.2)],
        ).createShader(Rect.fromLTWH(0, h * 0.3, w, h * 0.7)),
    );
    for (var i = 0; i < 4; i++) {
      final y = h * (0.42 + 0.14 * i);
      final drift = 30 * sin(t * 0.05 + i * 1.7);
      final band = Rect.fromCenter(center: Offset(w / 2 + drift, y), width: w * 1.6, height: h * 0.16);
      canvas.drawOval(
        band,
        Paint()
          ..shader = RadialGradient(colors: [fog.withValues(alpha: 0.45), fog.withValues(alpha: 0)]).createShader(band),
      );
    }
  }

  /// Relámpago lejano cada tanto: un parpadeo de luz, sin rayo, para no asustar.
  void _paintFlash(Canvas canvas, Size size, double t) {
    const every = 13.0;
    final since = t % every;
    if (since > 0.6) return;
    final a = since < 0.1
        ? since / 0.1
        : (since < 0.2 ? 1 - (since - 0.1) / 0.1 * 0.6 : 0.4 * (1 - (since - 0.2) / 0.4));
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white.withValues(alpha: 0.28 * a));
  }

  @override
  bool shouldRepaint(_SkyLifePainter old) =>
      old.daylight != daylight || old.warmth != warmth || old.weather != weather || old.windy != windy;
}
