import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../garden/weather.dart';
import '../fx/sfx.dart';
import '../theme/palette.dart';

enum _Kind { birds, stars, petals, snow, drops }

class _Touch {
  final Offset at;
  final double born;
  final _Kind kind;
  final int seed;
  _Touch(this.at, this.born, this.kind, this.seed);

  double get life => switch (kind) {
    _Kind.birds => 1.8,
    _Kind.stars => 1.5,
    _ => 1.2,
  };
}

/// El jardín responde donde se lo toca fuera de los lugares: en el cielo se
/// vuelan unos pájaros (o titilan estrellas, de noche); en el suelo saltan
/// pétalos, gotas o nieve según el clima. Cada toque suena una nota que sube
/// de izquierda a derecha, así el jardín se puede "tocar" como un instrumento.
class GardenTouch extends StatefulWidget {
  /// Desde dónde empieza el suelo (más arriba es cielo).
  final double groundTop;
  final double daylight;
  final Weather weather;

  /// Si mojado (lluvia o charcos), del suelo saltan gotas.
  final bool wet;

  const GardenTouch({
    super.key,
    required this.groundTop,
    required this.daylight,
    required this.weather,
    this.wet = false,
  });

  @override
  State<GardenTouch> createState() => _GardenTouchState();
}

class _GardenTouchState extends State<GardenTouch> with SingleTickerProviderStateMixin {
  final _touches = <_Touch>[];
  final _clock = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker(_tick);
  var _seed = 0;

  void _tick(Duration elapsed) {
    _clock.value = elapsed.inMicroseconds / 1e6;
    _touches.removeWhere((t) => _clock.value - t.born > t.life);
    if (_touches.isEmpty) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _touch(Offset at, double width) {
    final sky = at.dy < widget.groundTop;
    final kind = switch (widget.weather) {
      _ when sky && widget.daylight < 0.35 => _Kind.stars,
      Weather.rain || Weather.storm when sky => _Kind.stars,
      _ when sky => _Kind.birds,
      Weather.snow => _Kind.snow,
      _ when widget.wet => _Kind.drops,
      _ => _Kind.petals,
    };
    if (!_ticker.isActive) {
      _clock.value = 0;
      _ticker.start();
    }
    if (_touches.length > 12) _touches.removeAt(0);
    _touches.add(_Touch(at, _clock.value, kind, _seed++));
    // Cinco notas de izquierda a derecha; el cielo suena más bajito.
    final note = (at.dx / max(width, 1) * 5).floor().clamp(0, 4) + 1;
    SoundBoard.instance.play(Sfx.rainNote, variant: note, volume: sky ? 0.16 : 0.24);
    Haptics.light();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _touch(d.localPosition, box.maxWidth),
        child: CustomPaint(size: box.biggest, painter: _TouchPainter(_touches, _clock)),
      ),
    );
  }
}

class _TouchPainter extends CustomPainter {
  final List<_Touch> touches;
  final ValueNotifier<double> clock;
  _TouchPainter(this.touches, this.clock) : super(repaint: clock);

  @override
  void paint(Canvas canvas, Size size) {
    for (final t in touches) {
      final age = clock.value - t.born;
      if (age < 0 || age > t.life) continue;
      final rng = Random(t.seed);
      switch (t.kind) {
        case _Kind.birds:
          _birds(canvas, t.at, age, rng);
        case _Kind.stars:
          _stars(canvas, t.at, age, t.life, rng);
        case _Kind.petals || _Kind.snow || _Kind.drops:
          _burst(canvas, t, age, rng);
      }
    }
  }

  /// Un anillo que se abre despacio donde se tocó.
  void _ring(Canvas canvas, Offset at, double age, double life, Color color) {
    final e = Curves.easeOutCubic.transform((age / life).clamp(0, 1));
    canvas.drawCircle(
      at,
      10 + 56 * e,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * (1 - e) + 1
        ..color = color.withValues(alpha: 0.75 * (1 - e)),
    );
  }

  /// Pétalos, gotas o copos que saltan y caen.
  void _burst(Canvas canvas, _Touch t, double age, Random rng) {
    _ring(canvas, t.at, age, t.life, Colors.white);
    final fade = (1 - age / t.life).clamp(0.0, 1.0);
    final gravity = t.kind == _Kind.snow ? 60.0 : 320.0;
    for (var i = 0; i < 12; i++) {
      final a = -pi / 2 + (rng.nextDouble() - 0.5) * 2.4;
      final v = (t.kind == _Kind.snow ? 60 : 140) + rng.nextDouble() * 110;
      final p = t.at + Offset(cos(a) * v * age, sin(a) * v * age + gravity * age * age / 2);
      final paint = Paint();
      switch (t.kind) {
        case _Kind.snow:
          canvas.drawCircle(p, 3 + rng.nextDouble() * 3, paint..color = Colors.white.withValues(alpha: 0.9 * fade));
        case _Kind.drops:
          canvas.drawCircle(
            p,
            2.5 + rng.nextDouble() * 2.5,
            paint..color = const Color(0xFF9CC3DB).withValues(alpha: 0.9 * fade),
          );
        default:
          final color = [const Color(0xFFF2B8C6), const Color(0xFF8FAE6A), const Color(0xFFF6D9A8)][i % 3];
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(a + age * (4 + rng.nextDouble() * 4));
          canvas.drawOval(const Rect.fromLTWH(-7, -3.5, 14, 7), paint..color = color.withValues(alpha: fade));
          canvas.restore();
      }
    }
  }

  /// Tres pájaros que levantan vuelo aleteando.
  void _birds(Canvas canvas, Offset at, double age, Random rng) {
    final fade = (1 - age / 1.8).clamp(0.0, 1.0);
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..color = Palette.ink.withValues(alpha: 0.7 * fade);
    for (var i = 0; i < 3; i++) {
      final dir = rng.nextBool() ? 1.0 : -1.0;
      final vx = dir * (60 + rng.nextDouble() * 60), vy = -(80 + rng.nextDouble() * 50);
      final p = at + Offset(vx * age + (i - 1) * 18, vy * age - 20 * age * age);
      final flap = sin(age * 16 + i * 2) * 7;
      final s = 11 + rng.nextDouble() * 4;
      canvas.drawPath(
        Path()
          ..moveTo(p.dx - s, p.dy - flap)
          ..quadraticBezierTo(p.dx - s / 2, p.dy - 2, p.dx, p.dy)
          ..quadraticBezierTo(p.dx + s / 2, p.dy - 2, p.dx + s, p.dy - flap),
        ink,
      );
    }
  }

  /// Estrellitas que se abren desde el toque y titilan.
  void _stars(Canvas canvas, Offset at, double age, double life, Random rng) {
    _ring(canvas, at, age, life, Palette.lantern);
    final e = Curves.easeOutCubic.transform((age / life).clamp(0, 1));
    for (var i = 0; i < 8; i++) {
      final a = i / 8 * 2 * pi + rng.nextDouble() * 0.5;
      final p = at + Offset(cos(a), sin(a)) * (10 + 50 * e);
      final s = (5 + rng.nextDouble() * 3) * (0.7 + 0.3 * sin(age * 12 + i)) * (1 - e * 0.7);
      final paint = Paint()..color = Color.lerp(Colors.white, Palette.lantern, rng.nextDouble())!;
      canvas.drawPath(
        Path()
          ..moveTo(p.dx, p.dy - s * 2)
          ..lineTo(p.dx + s / 2, p.dy)
          ..lineTo(p.dx, p.dy + s * 2)
          ..lineTo(p.dx - s / 2, p.dy)
          ..close()
          ..moveTo(p.dx - s * 2, p.dy)
          ..lineTo(p.dx, p.dy + s / 2)
          ..lineTo(p.dx + s * 2, p.dy)
          ..lineTo(p.dx, p.dy - s / 2)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TouchPainter old) => true;
}
