part of 'garden_view.dart';

/// La mesa baja con la Maqueta del jardín, en el patio: se toca para
/// decorar. Usa el arte `obj_model_table` si está; si no, una pintada.
class _ModelTable extends StatelessWidget {
  final Rect rect;
  final double daylight;
  final VoidCallback onTap;
  const _ModelTable({required this.rect, required this.daylight, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: rect,
      child: Semantics(
        button: true,
        label: tr('model.title'),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
            onTap();
          },
          child: CustomPaint(painter: _ModelTablePainter(daylight)),
        ),
      ),
    );
  }
}

class _ModelTablePainter extends CustomPainter {
  final double daylight;
  _ModelTablePainter(this.daylight);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final dim = Paint()
      ..colorFilter = ColorFilter.mode(
        Color.lerp(const Color(0xFF6F7896), Colors.white, daylight)!,
        BlendMode.modulate,
      );
    final art = SceneArt.instance['obj_model_table'];
    if (art != null) {
      final h = r.width * art.height / art.width;
      drawArt(canvas, art, Rect.fromLTWH(r.left, r.bottom - h, r.width, h), paint: dim);
      return;
    }
    canvas.saveLayer(r.inflate(4), dim);
    final w = r.width, b = r.bottom;
    // Sombra, patas, tablero y la bandeja con arena y tres piezas chiquitas.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(r.center.dx, b - w * 0.02), width: w * 1.05, height: w * 0.16),
      Paint()..color = Palette.ink.withValues(alpha: 0.18),
    );
    final wood = Paint()..color = Palette.wood;
    final dark = Paint()..color = Color.lerp(Palette.wood, Palette.ink, 0.35)!;
    for (final fx in [0.12, 0.84]) {
      canvas.drawRect(Rect.fromLTWH(r.left + w * fx, b - w * 0.32, w * 0.05, w * 0.3), dark);
    }
    final top = Path()
      ..addPolygon([
        Offset(r.left + w * 0.1, b - w * 0.5),
        Offset(r.right - w * 0.1, b - w * 0.5),
        Offset(r.right, b - w * 0.32),
        Offset(r.left, b - w * 0.32),
      ], true);
    canvas.drawPath(top, wood);
    canvas.drawRect(Rect.fromLTRB(r.left, b - w * 0.32, r.right, b - w * 0.27), dark);
    final sand = Path()
      ..addPolygon([
        Offset(r.left + w * 0.17, b - w * 0.47),
        Offset(r.right - w * 0.17, b - w * 0.47),
        Offset(r.right - w * 0.08, b - w * 0.35),
        Offset(r.left + w * 0.08, b - w * 0.35),
      ], true);
    canvas.drawPath(sand, Paint()..color = const Color(0xFFEDE3CB));
    canvas.drawCircle(Offset(r.left + w * 0.35, b - w * 0.41), w * 0.035, Paint()..color = Palette.stoneDark);
    canvas.drawCircle(Offset(r.left + w * 0.62, b - w * 0.43), w * 0.045, Paint()..color = Palette.moss);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(r.left + w * 0.5, b - w * 0.39), width: w * 0.04, height: w * 0.07),
      Paint()..color = Palette.stone,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ModelTablePainter old) => old.daylight != daylight;
}

/// Un aro que late alrededor de la decoración pedida desde la Maqueta.
class _DecorMark extends StatefulWidget {
  final Rect around;
  const _DecorMark({super.key, required this.around});

  @override
  State<_DecorMark> createState() => _DecorMarkState();
}

class _DecorMarkState extends State<_DecorMark> with SingleTickerProviderStateMixin {
  late final _beat = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.around;
    final ring = Rect.fromCenter(center: r.bottomCenter, width: r.width * 1.3, height: r.width * 0.36);
    return Positioned.fromRect(
      rect: ring.inflate(8),
      child: IgnorePointer(
        child: FadeTransition(
          opacity: Tween(begin: 0.35, end: 1.0).animate(_beat),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.all(Radius.elliptical(ring.width, ring.height)),
              border: Border.all(color: Palette.lantern, width: 3),
            ),
          ),
        ),
      ),
    );
  }
}
