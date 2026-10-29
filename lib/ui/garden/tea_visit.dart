import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../fx/calm.dart';
import '../fx/reward_flight.dart';
import '../fx/sfx.dart';
import '../theme/palette.dart';
import '../widgets/currency.dart';
import 'garden_scene.dart';

/// El té servido en la tarima de la casa de té. Mientras humea espera una
/// visita; cuando la visita pasa, queda el cuenco vacío y su ofrenda envuelta
/// en tela, que se toca para juntarla.
class TeaSpot extends StatefulWidget {
  final GardenLayout layout;
  final DateTime now;
  final Animation<double> life;
  final double Function() seconds;

  const TeaSpot({super.key, required this.layout, required this.now, required this.life, required this.seconds});

  @override
  State<TeaSpot> createState() => _TeaSpotState();
}

class _TeaSpotState extends State<TeaSpot> {
  /// Lo que dice la burbuja (la espera o quién pasó) y lo que dejó.
  String? _say;
  Map<String, int> _gift = const {};
  Timer? _hide;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  void _bubble(String text, {Map<String, int> gift = const {}, int ms = 2600}) {
    _hide?.cancel();
    setState(() {
      _say = text;
      _gift = gift;
    });
    _hide = Timer(Duration(milliseconds: ms), () {
      if (mounted) setState(() => _say = null);
    });
  }

  void _tap(TeaState state, Offset at) {
    final p = Progress.instance;
    if (state == TeaState.served) {
      SoundBoard.instance.play(Sfx.uiTap, volume: 0.4);
      final m = max(1, p.teaArrivesIn(now: widget.now).inMinutes);
      _bubble(tr('tea.waiting', {'n': m}));
      return;
    }
    final who = p.teaVisitor(now: widget.now);
    final gift = p.takeVisit(now: widget.now);
    if (gift == null) return;
    SoundBoard.instance.play(Sfx.great, volume: 0.45);
    Haptics.medium();
    final box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      var wait = 250;
      for (final e in gift.entries) {
        Timer(Duration(milliseconds: wait), () {
          if (mounted) RewardFlight.fly(context, from: box.localToGlobal(at), currency: e.key, amount: e.value);
        });
        wait += 180;
      }
    }
    _bubble(tr('tea.visit.${who.id}'), gift: gift, ms: 3800);
  }

  @override
  Widget build(BuildContext context) {
    final state = Progress.instance.teaState(now: widget.now);
    final r = widget.layout.places[Place.matcha]!;
    // Sobre la tarima, a la derecha de la entrada (ver paintTeahouse).
    final floor = r.bottom - r.height * 0.17;
    final bowl = Offset(r.left + r.width * 0.8, floor);
    final gift = Offset(r.left + r.width * 0.66, floor);
    const size = 52.0;
    final shown = state == TeaState.served || state == TeaState.visit;
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (shown)
            for (final (at, isGift) in [(bowl, false), if (state == TeaState.visit) (gift, true)])
              Positioned(
                left: at.dx - size / 2,
                top: at.dy - size + 8,
                width: size,
                height: size,
                child: Semantics(
                  button: true,
                  label: isGift ? tr('tea.gift') : tr('tea.served'),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _tap(state, at - const Offset(0, size / 2)),
                    child: AnimatedBuilder(
                      animation: widget.life,
                      builder: (context, _) => CustomPaint(
                        painter: _TeaPainter(gift: isGift, full: state == TeaState.served, t: widget.seconds()),
                      ),
                    ),
                  ),
                ),
              ),
          if (_say != null)
            Positioned(
              left: 12,
              right: 12,
              top: max(8, r.top - 40),
              child: Center(
                child: CalmAppear(
                  key: ValueKey(_say),
                  rise: 10,
                  child: IgnorePointer(
                    child: _Bubble(text: _say!, gift: _gift),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final Map<String, int> gift;
  const _Bubble({required this.text, required this.gift});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Palette.paper,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Palette.ink.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Palette.ink),
          ),
          if (gift.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [for (final e in gift.entries) CurrencyChip.of(e.key, e.value, prefix: '+')]),
          ],
        ],
      ),
    );
  }
}

/// El cuenco (lleno y humeante, o vacío) o la ofrenda envuelta en furoshiki.
class _TeaPainter extends CustomPainter {
  final bool gift, full;
  final double t;
  _TeaPainter({required this.gift, required this.full, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final base = Offset(size.width / 2, size.height - 8);
    // Un poco más grandes que el dibujo de la casa, para que se vean y se toquen.
    canvas.translate(base.dx, base.dy);
    canvas.scale(1.25);
    canvas.translate(-base.dx, -base.dy);
    if (gift) {
      _paintGift(canvas, base);
    } else {
      _paintBowl(canvas, base);
    }
  }

  void _paintBowl(Canvas canvas, Offset base) {
    canvas.drawOval(
      Rect.fromCenter(center: base + const Offset(0, 1), width: 26, height: 5),
      Paint()..color = Palette.ink.withValues(alpha: 0.25),
    );
    // Cuenco de cerámica oscura, con el borde de arriba como una elipse.
    final top = base.dy - 11;
    final body = Path()
      ..moveTo(base.dx - 11, top)
      ..quadraticBezierTo(base.dx - 10, base.dy, base.dx, base.dy)
      ..quadraticBezierTo(base.dx + 10, base.dy, base.dx + 11, top)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFF4A3B33));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(base.dx, top), width: 22, height: 6),
      Paint()..color = full ? const Color(0xFF8DB04A) : const Color(0xFF2E2420),
    );
    if (full) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(base.dx - 2, top - 0.5), width: 10, height: 2.4),
        Paint()..color = const Color(0xFFC4DB86),
      );
      // Vapor: dos hilos que suben ondulando y se desvanecen.
      for (var i = 0; i < 2; i++) {
        final k = (t * 0.35 + i * 0.5) % 1;
        final steam = Path();
        for (var j = 0; j <= 10; j++) {
          final y = top - 3 - j * 2.0 - k * 6;
          final x = base.dx + (i == 0 ? -4 : 4) + 2.5 * sin(j * 0.7 + t * 1.5 + i * 2);
          j == 0 ? steam.moveTo(x, y) : steam.lineTo(x, y);
        }
        canvas.drawPath(
          steam,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.55 * (1 - k))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _paintGift(Canvas canvas, Offset base) {
    final pulse = 0.6 + 0.4 * sin(t * 2.2);
    final c = base + const Offset(0, -9);
    canvas.drawCircle(
      c,
      22,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Palette.lantern.withValues(alpha: 0.55 * pulse),
            Palette.lantern.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: 22)),
    );
    canvas.drawOval(
      Rect.fromCenter(center: base + const Offset(0, 1), width: 24, height: 5),
      Paint()..color = Palette.ink.withValues(alpha: 0.25),
    );
    // Bulto de tela atado arriba, con sus dos puntas.
    const cloth = Color(0xFFB4533C);
    final bundle = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c + const Offset(0, 2), width: 20, height: 15),
      const Radius.circular(6),
    );
    canvas.drawRRect(bundle, Paint()..color = cloth);
    final knot = c + const Offset(0, -6);
    final ears = Paint()..color = const Color(0xFF9C4331);
    canvas.drawPath(
      Path()
        ..moveTo(knot.dx, knot.dy)
        ..lineTo(knot.dx - 8, knot.dy - 6)
        ..lineTo(knot.dx - 3, knot.dy + 1)
        ..close(),
      ears,
    );
    canvas.drawPath(
      Path()
        ..moveTo(knot.dx, knot.dy)
        ..lineTo(knot.dx + 8, knot.dy - 6)
        ..lineTo(knot.dx + 3, knot.dy + 1)
        ..close(),
      ears,
    );
    canvas.drawCircle(knot, 2.6, Paint()..color = const Color(0xFF7E3324));
    // Lunares claros del estampado.
    final dot = Paint()..color = Palette.paper.withValues(alpha: 0.7);
    for (final d in const [Offset(-5, 3), Offset(4, 6), Offset(5, -1), Offset(-2, 8)]) {
      canvas.drawCircle(c + d, 1.2, dot);
    }
  }

  @override
  bool shouldRepaint(_TeaPainter old) => old.t != t || old.gift != gift || old.full != full;
}
