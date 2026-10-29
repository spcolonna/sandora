part of 'garden_view.dart';

/// Un regalo puesto en el jardín: una gota de rocío que brilla en el pasto,
/// una luciérnaga que flota, agua de lluvia sobre las vasijas o un copo que
/// brilla al caer. Se toca para juntarlo.
class _GiftSpot extends StatelessWidget {
  final DayGift gift;
  final int index;
  final GardenLayout layout;
  final Animation<double> life;
  final double Function() seconds;
  final void Function(Offset at) onTake;

  const _GiftSpot({
    super.key,
    required this.gift,
    required this.index,
    required this.layout,
    required this.life,
    required this.seconds,
    required this.onTake,
  });

  static const _size = 48.0;

  /// Lugares fijos (fracciones del jardín) para cada regalo; el agua de lluvia
  /// va sobre las vasijas.
  static const _spots = {
    'dew': [Offset(0.05, 0.64), Offset(0.37, 0.57), Offset(0.95, 0.9)],
    'firefly': [Offset(0.3, 0.5), Offset(0.62, 0.42), Offset(0.88, 0.62)],
    'snowflake': [Offset(0.24, 0.36), Offset(0.7, 0.3)],
    'rainbow': [Offset(0.5, 0.27)],
    'seed': [Offset(0.15, 0.4), Offset(0.6, 0.46)],
    'lastray': [Offset(0.82, 0.4)],
  };

  GiftLook get _look => giftLook(gift.id);

  Offset _base() {
    if (gift.id == 'rainjar') {
      // Sobre la boca de las vasijas (ver _paintJars en garden_scene.dart).
      final r = layout.places[Place.rain]!;
      final slot = r.width * 0.6 / 4;
      final jh = min(slot * 0.74, r.height * 1.1) * 0.82;
      return Offset(r.left + slot * ([0, 2, 3][index % 3] + 0.5), r.center.dy - jh / 2 - 16);
    }
    final spots = _spots[gift.id] ?? _spots['dew']!;
    final f = spots[index % spots.length];
    return Offset(f.dx * layout.size.width, f.dy * layout.size.height);
  }

  Offset _at(double t) {
    final base = _base();
    return switch (_look) {
      GiftLook.firefly => base + Offset(18 * sin(t * 0.5 + index * 2.1), 12 * sin(t * 0.8 + index * 1.3)),
      // El copo baja despacio meciéndose y vuelve a empezar.
      GiftLook.flake => base + Offset(14 * sin(t * 0.7 + index), 40 * (((t * 0.06 + index * 0.37) % 1) - 0.5)),
      GiftLook.rain => base + Offset(0, 3 * sin(t * 1.6 + index)),
      // La semilla de diente de león flota y va y viene con la brisa.
      GiftLook.seed => base + Offset(30 * sin(t * 0.25 + index * 2), 10 * sin(t * 0.9 + index)),
      GiftLook.rainbow || GiftLook.ray => base + Offset(0, 4 * sin(t * 0.8 + index)),
      GiftLook.dew => base,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: life,
      builder: (context, _) {
        final t = seconds();
        final at = _at(t);
        final pulse = 0.6 + 0.4 * sin(t * (_look == GiftLook.dew ? 1.4 : 2.2) + index * 1.7);
        return Positioned(
          left: at.dx - _size / 2,
          top: at.dy - _size / 2,
          width: _size,
          height: _size,
          child: Semantics(
            button: true,
            label: tr('gift.${gift.id}'),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTake(at),
              child: CustomPaint(
                painter: GiftPainter(look: _look, pulse: pulse),
              ),
            ),
          ),
        );
      },
    );
  }
}

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

class _Pop {
  final int id;
  final DayGift gift;
  final Offset at;
  _Pop(this.id, this.gift, this.at);
}

/// Lo que dio un regalo, subiendo y desvaneciéndose donde se tocó.
class _PopUp extends StatelessWidget {
  final _Pop pop;
  const _PopUp({super.key, required this.pop});

  @override
  Widget build(BuildContext context) {
    final e = pop.gift.give.entries.first;
    return Positioned(
      left: pop.at.dx,
      top: pop.at.dy - 20,
      child: IgnorePointer(
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOut,
            builder: (context, v, child) => Opacity(
              opacity: v < 0.25 ? v / 0.25 : (1 - v) / 0.75,
              child: Transform.translate(offset: Offset(0, -26 * v), child: child),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Palette.paper.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: CurrencyChip.of(e.key, e.value, prefix: '+'),
            ),
          ),
        ),
      ),
    );
  }
}
