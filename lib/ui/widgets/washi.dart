import 'dart:math';

import 'package:flutter/material.dart';

import '../fx/sfx.dart';
import '../theme/palette.dart';

/// Papel washi pintado: la textura con fibras y bordes tostados que usa la
/// caligrafía, para que paneles y botones parezcan parte del patio.
const washiTexture = 'assets/images/temple/bg_enso_paper.webp';

/// Una hoja de washi con sombra suave, para paneles y tarjetas.
class WashiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding, margin;
  final double radius;
  const WashiCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(22, 22, 22, 14),
    this.margin = EdgeInsets.zero,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Palette.paper,
        borderRadius: r,
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 24, offset: Offset(0, 8))],
        image: const DecorationImage(image: AssetImage(washiTexture), fit: BoxFit.fill),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: r,
        border: Border.all(color: Palette.wood.withValues(alpha: 0.18), width: 1),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Glifos de tinta, pintados a pincel en vez de los íconos de sistema.
enum InkGlyph { pause, back, close, replay, play, garden }

/// Botón principal: un trazo ancho de tinta tibia sobre el papel. El
/// secundario ([quiet]) es solo la palabra en tinta; el de papel ([paper]),
/// una píldora de washi para apoyar sobre la escena sin robarle la mirada.
class InkButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final InkGlyph? glyph;
  final bool quiet, paper;
  final double height;
  const InkButton({super.key, required this.label, required this.onPressed, this.glyph, this.height = 54})
    : quiet = false,
      paper = false;

  const InkButton.quiet({super.key, required this.label, required this.onPressed, this.glyph, this.height = 44})
    : quiet = true,
      paper = false;

  const InkButton.paper({super.key, required this.label, required this.onPressed, this.glyph, this.height = 44})
    : quiet = true,
      paper = true;

  @override
  State<InkButton> createState() => _InkButtonState();
}

class _InkButtonState extends State<InkButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.quiet ? Palette.ink.withValues(alpha: 0.72) : Palette.sandLight;
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.glyph != null) ...[
          CustomPaint(size: const Size.square(20), painter: _GlyphPainter(widget.glyph!, color)),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            widget.label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: widget.quiet ? 16 : 18,
              fontWeight: widget.quiet ? FontWeight.w600 : FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: () {
          Haptics.light();
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 90),
          child: SizedBox(
            height: widget.height,
            width: widget.paper ? null : double.infinity,
            child: widget.paper
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      color: Palette.paper,
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      image: const DecorationImage(image: AssetImage(washiTexture), fit: BoxFit.cover),
                      border: Border.all(color: Palette.wood.withValues(alpha: 0.25)),
                      boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 10, offset: Offset(0, 3))],
                    ),
                    child: Center(
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: label),
                    ),
                  )
                : widget.quiet
                ? Center(child: label)
                : CustomPaint(
                    painter: _BrushFill(pressed: _down),
                    child: Center(
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: label),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// El fondo del botón principal: una pincelada de tinta tibia con bordes
/// irregulares, más cargada abajo y con el pelo del pincel en los extremos.
class _BrushFill extends CustomPainter {
  final bool pressed;
  _BrushFill({required this.pressed});

  static const _base = Color(0xFFB8673A), _deep = Color(0xFF8A4526);

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height, w = size.width;
    final path = _wobblyCapsule(Rect.fromLTWH(0, 0, w, h), seed: 3, amp: 1.6);
    canvas.drawShadow(path, const Color(0xFF000000), pressed ? 2 : 5, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: pressed ? [_deep, _deep] : [_base, _deep],
        ).createShader(Offset.zero & size),
    );
    // Vetas del pincel: pasadas finas más claras a lo largo del trazo.
    final rnd = Random(11);
    canvas.save();
    canvas.clipPath(path);
    for (var i = 0; i < 9; i++) {
      final y = h * (0.15 + 0.7 * rnd.nextDouble());
      final x0 = w * 0.04 * rnd.nextDouble(), x1 = w * (0.7 + 0.3 * rnd.nextDouble());
      canvas.drawLine(
        Offset(x0, y),
        Offset(x1, y + (rnd.nextDouble() - 0.5) * 3),
        Paint()
          ..color = const Color(0xFFF2C79A).withValues(alpha: 0.06 + 0.07 * rnd.nextDouble())
          ..strokeWidth = 1 + 2 * rnd.nextDouble()
          ..strokeCap = StrokeCap.round,
      );
    }
    // Brillo de tinta fresca arriba.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.45),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0x33FFF3E0), const Color(0x00FFF3E0)],
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.45)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BrushFill old) => old.pressed != pressed;
}

/// Una cápsula con el borde apenas tembloroso, como pintada a mano.
Path _wobblyCapsule(Rect r, {required int seed, double amp = 1.4}) {
  final rnd = Random(seed);
  final phases = [for (var i = 0; i < 3; i++) rnd.nextDouble() * 2 * pi];
  double wob(double a) => amp * (sin(a * 3 + phases[0]) + 0.6 * sin(a * 7 + phases[1]) + 0.3 * sin(a * 13 + phases[2]));
  final rad = r.height / 2;
  final path = Path();
  const n = 120;
  // Se recorre el contorno como una "pista": recta arriba, curva, recta abajo, curva.
  final straight = r.width - 2 * rad, perim = 2 * straight + 2 * pi * rad;
  for (var i = 0; i <= n; i++) {
    final s = perim * i / n;
    final a = 2 * pi * i / n;
    late Offset p, normal;
    if (s < straight) {
      p = Offset(r.left + rad + s, r.top);
      normal = const Offset(0, -1);
    } else if (s < straight + pi * rad) {
      final t = (s - straight) / rad - pi / 2;
      normal = Offset(cos(t), sin(t));
      p = Offset(r.right - rad, r.top + rad) + normal * rad;
    } else if (s < 2 * straight + pi * rad) {
      p = Offset(r.right - rad - (s - straight - pi * rad), r.bottom);
      normal = const Offset(0, 1);
    } else {
      final t = (s - 2 * straight - pi * rad) / rad + pi / 2;
      normal = Offset(cos(t), sin(t));
      p = Offset(r.left + rad, r.top + rad) + normal * rad;
    }
    final q = p + normal * (wob(a) - amp);
    i == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
  }
  return path..close();
}

/// Botón redondo de papel con un glifo de tinta (pausa, volver, cerrar).
class InkIconButton extends StatefulWidget {
  final InkGlyph glyph;
  final VoidCallback onPressed;
  final String? tooltip;
  final double size;
  const InkIconButton({super.key, required this.glyph, required this.onPressed, this.tooltip, this.size = 46});

  @override
  State<InkIconButton> createState() => _InkIconButtonState();
}

class _InkIconButtonState extends State<InkIconButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final button = GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _down ? 0.9 : 1,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Palette.paper,
            image: const DecorationImage(image: AssetImage(washiTexture), fit: BoxFit.cover),
            border: Border.all(color: Palette.wood.withValues(alpha: 0.25)),
            boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 10, offset: Offset(0, 3))],
          ),
          child: Center(
            child: CustomPaint(
              size: Size.square(s * 0.44),
              painter: _GlyphPainter(widget.glyph, Palette.ink.withValues(alpha: 0.85)),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      label: widget.tooltip,
      child: widget.tooltip == null ? button : Tooltip(message: widget.tooltip!, child: button),
    );
  }
}

/// Pinta un glifo en una caja cuadrada, con trazos de pincel que se afinan.
class _GlyphPainter extends CustomPainter {
  final InkGlyph glyph;
  final Color color;
  _GlyphPainter(this.glyph, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width;
    Offset p(double x, double y) => Offset(x * u, y * u);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = u * 0.13;
    // Un trazo que empieza grueso y termina fino, como el pincel al levantarse.
    void brush(Offset a, Offset b) {
      for (var i = 0; i < 3; i++) {
        final k = i / 3;
        canvas.drawLine(a, Offset.lerp(a, b, 1 - 0.18 * k)!, stroke..strokeWidth = u * (0.15 - 0.035 * i));
      }
    }

    switch (glyph) {
      case InkGlyph.pause:
        brush(p(0.32, 0.12), p(0.3, 0.88));
        brush(p(0.7, 0.12), p(0.68, 0.88));
      case InkGlyph.close:
        brush(p(0.14, 0.14), p(0.86, 0.86));
        brush(p(0.86, 0.14), p(0.14, 0.86));
      case InkGlyph.back:
        brush(p(0.88, 0.52), p(0.14, 0.5));
        brush(p(0.14, 0.5), p(0.46, 0.18));
        brush(p(0.14, 0.5), p(0.46, 0.82));
      case InkGlyph.play:
        final tri = Path()
          ..moveTo(u * 0.26, u * 0.12)
          ..lineTo(u * 0.88, u * 0.5)
          ..lineTo(u * 0.26, u * 0.88)
          ..close();
        canvas.drawPath(tri, Paint()..color = color);
      case InkGlyph.replay:
        // Un ensō casi cerrado con la punta de flecha en el final.
        final rect = Rect.fromCircle(center: p(0.5, 0.52), radius: u * 0.36);
        canvas.drawArc(rect, -pi * 0.35, pi * 1.6, false, stroke..strokeWidth = u * 0.13);
        final end = p(0.5, 0.52) + Offset(cos(-pi * 0.35), sin(-pi * 0.35)) * u * 0.36;
        final head = Path()
          ..moveTo(end.dx + u * 0.02, end.dy - u * 0.26)
          ..lineTo(end.dx + u * 0.12, end.dy + u * 0.08)
          ..lineTo(end.dx - u * 0.2, end.dy + u * 0.02)
          ..close();
        canvas.drawPath(head, Paint()..color = color);
      case InkGlyph.garden:
        // Una piedra con su ondita de arena: volver al jardín.
        canvas.drawOval(Rect.fromLTRB(u * 0.22, u * 0.3, u * 0.78, u * 0.66), Paint()..color = color);
        brush(p(0.06, 0.84), p(0.94, 0.84));
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.glyph != glyph || old.color != color;
}

/// Barra de progreso pintada: un surco de aguada clara y el trazo que lo
/// llena, tibio y con el borde irregular.
class BrushBar extends StatelessWidget {
  final double value;
  final double height;
  final Color color;
  const BrushBar({super.key, required this.value, this.height = 12, this.color = Palette.lantern});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _BrushBarPainter(value.clamp(0.0, 1.0), color)),
    );
  }
}

class _BrushBarPainter extends CustomPainter {
  final double value;
  final Color color;
  _BrushBarPainter(this.value, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final track = _wobblyCapsule(Offset.zero & size, seed: 5, amp: 0.7);
    canvas.drawPath(track, Paint()..color = Palette.sandShadow.withValues(alpha: 0.35));
    if (value <= 0) return;
    final w = max(size.height, size.width * value);
    final fill = _wobblyCapsule(Rect.fromLTWH(0, 0, w, size.height), seed: 9, amp: 0.8);
    final dark = Color.lerp(color, Palette.wood, 0.35)!;
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          colors: [color.withValues(alpha: 0.85), dark],
        ).createShader(Rect.fromLTWH(0, 0, w, size.height)),
    );
    // La punta del trazo, más cargada de tinta.
    canvas.drawCircle(
      Offset(w - size.height / 2, size.height / 2),
      size.height * 0.36,
      Paint()..color = dark.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(_BrushBarPainter old) => old.value != value || old.color != color;
}

/// Diálogo sobre papel washi, con un título y botones en columna.
Future<T?> showWashiDialog<T>(BuildContext context, {required String title, required List<Widget> actions}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Palette.ink.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, _, _) => SafeArea(
      child: Center(
        child: Material(
          type: MaterialType.transparency,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: WashiCard(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 22),
                  for (final (i, a) in actions.indexed) ...[if (i > 0) const SizedBox(height: 6), a],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, anim, _, child) {
      final t = Curves.easeOutCubic.transform(anim.value);
      return Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
      );
    },
  );
}
