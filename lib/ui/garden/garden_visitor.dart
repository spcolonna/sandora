part of 'garden_view.dart';

/// Dónde espera el visitante: frente al portón del patio pintado (o a la
/// derecha del terreno, sin el arte).
Offset _visitorFoot(GardenLayout layout) {
  final s = layout.size, g = layout.ground;
  return layout.painted
      ? Offset(s.width * 0.76, s.height * 0.565)
      : Offset(g.right - s.width * 0.1, g.top + g.height * 0.2);
}

/// El visitante en la entrada: llega con un pedido (burbuja con "?"), se va
/// mientras se espera (queda su nota) y vuelve cuando se cumplió ("!").
class _VisitorSpot extends StatelessWidget {
  final GardenLayout layout;
  final Animation<double> life;
  final double Function() seconds;
  const _VisitorSpot({required this.layout, required this.life, required this.seconds});

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final state = p.visitorState;
    final foot = _visitorFoot(layout);
    final h = layout.size.width * (state == VisitorState.waiting ? 0.06 : 0.1);
    final w = h * 0.75;
    return Positioned(
      left: foot.dx - w,
      top: foot.dy - h * 1.6,
      width: w * 2,
      height: h * 1.7,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
          showVisitorSheet(context);
        },
        child: AnimatedBuilder(
          animation: life,
          builder: (context, _) => CustomPaint(painter: _VisitorPainter(state, p.visitorWho ?? 'monk', seconds(), h)),
        ),
      ),
    );
  }
}

class _VisitorPainter extends CustomPainter {
  final VisitorState state;
  final String who;
  final double t, h;
  _VisitorPainter(this.state, this.who, this.t, this.h);

  static const _robes = {
    'monk': Color(0xFFC77A2E),
    'traveler': Color(0xFF6C7A8A),
    'potter': Color(0xFF8A5A3C),
    'gardener': Color(0xFF5E7A44),
    'fisher': Color(0xFF3F6C80),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final foot = Offset(size.width / 2, size.height - 2);
    if (state == VisitorState.waiting) return _note(canvas, foot);
    canvas.drawOval(
      Rect.fromCenter(center: foot, width: h * 0.55, height: h * 0.1),
      Paint()..color = const Color(0x33000000),
    );
    final art = SceneArt.instance['char_visitor_$who'];
    if (art != null) {
      drawArtIn(canvas, art, Rect.fromCenter(center: foot - Offset(0, h * 0.5), width: h, height: h));
    } else {
      _figure(canvas, foot);
    }
    _bubble(canvas, foot);
  }

  /// Sin el arte: la túnica, la cabeza y el sombrero, con código.
  void _figure(Canvas canvas, Offset foot) {
    final robe = _robes[who] ?? const Color(0xFF7A6A5A);
    // La túnica, ancha abajo, y las mangas.
    final body = Path()
      ..moveTo(foot.dx - h * 0.24, foot.dy)
      ..quadraticBezierTo(foot.dx - h * 0.2, foot.dy - h * 0.45, foot.dx - h * 0.12, foot.dy - h * 0.72)
      ..lineTo(foot.dx + h * 0.12, foot.dy - h * 0.72)
      ..quadraticBezierTo(foot.dx + h * 0.2, foot.dy - h * 0.45, foot.dx + h * 0.24, foot.dy)
      ..close();
    // Con luz de un costado, para que no quede plano sobre el arte pintado.
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: [Color.lerp(robe, Colors.white, 0.18)!, robe, Color.lerp(robe, Colors.black, 0.3)!],
        ).createShader(body.getBounds()),
    );
    canvas.drawLine(
      Offset(foot.dx, foot.dy - h * 0.72),
      Offset(foot.dx - h * 0.05, foot.dy - h * 0.4),
      Paint()
        ..color = Color.lerp(robe, Colors.black, 0.25)!
        ..strokeWidth = h * 0.025,
    );
    // Cabeza y, salvo el monje, el sombrero de paja.
    final head = Offset(foot.dx, foot.dy - h * 0.82);
    canvas.drawCircle(head, h * 0.1, Paint()..color = const Color(0xFFE9C9A5));
    if (who != 'monk') {
      final hat = Path()
        ..moveTo(head.dx - h * 0.22, head.dy - h * 0.02)
        ..lineTo(head.dx, head.dy - h * 0.2)
        ..lineTo(head.dx + h * 0.22, head.dy - h * 0.02)
        ..close();
      canvas.drawPath(hat, Paint()..color = const Color(0xFFCDB077));
    }
  }

  void _bubble(Canvas canvas, Offset foot) {
    // La burbuja: "?" si trae un pedido, "!" si vuelve por su regalo.
    final bob = sin(t * 2.4) * h * 0.04;
    final c = Offset(foot.dx + h * 0.28, foot.dy - h * 1.22 + bob);
    final done = state == VisitorState.done;
    if (done) {
      canvas.drawCircle(
        c,
        h * 0.32,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Palette.lantern.withValues(alpha: 0.5 + 0.2 * sin(t * 3)),
              Palette.lantern.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: h * 0.32)),
      );
    }
    canvas.drawCircle(c, h * 0.16, Paint()..color = Palette.paper);
    canvas.drawCircle(
      c,
      h * 0.16,
      Paint()
        ..color = Palette.lantern
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: done ? '!' : '?',
        style: TextStyle(fontSize: h * 0.2, fontWeight: FontWeight.w900, color: Palette.ink),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  /// Mientras se espera: la nota del pedido, atada al poste.
  void _note(Canvas canvas, Offset foot) {
    final r = Rect.fromCenter(center: foot - Offset(0, h * 0.55), width: h * 0.7, height: h * 0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r.shift(const Offset(1.5, 2)), const Radius.circular(3)),
      Paint()..color = const Color(0x33000000),
    );
    canvas.save();
    canvas.translate(r.center.dx, r.top);
    canvas.rotate(sin(t * 1.3) * 0.06);
    canvas.translate(-r.center.dx, -r.top);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = Palette.paper);
    final ink = Paint()
      ..color = Palette.ink.withValues(alpha: 0.6)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 3; i++) {
      final x = r.left + r.width * (0.3 + 0.2 * i);
      canvas.drawLine(Offset(x, r.top + r.height * 0.2), Offset(x, r.bottom - r.height * 0.2), ink);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_VisitorPainter old) => true;
}
