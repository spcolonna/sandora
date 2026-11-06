part of 'garden_view.dart';

/// Dónde va cada cuidado de la vista: un rectángulo para tocar o deslizar.
/// Los sueltos (maleza, hojas) se reparten por el suelo; los de un lugar se
/// apoyan en él.
Rect? _careRect(CareTask t, GardenLayout layout, Progress p) {
  final size = layout.size, g = layout.ground;
  Offset onGround() => Offset(size.width * t.x, g.top + g.height * (0.25 + (t.y - 0.74) / 0.2 * 0.62).clamp(0.2, 0.9));
  switch (t.kind) {
    case CareKind.weed:
      final w = size.width * 0.11;
      return Rect.fromCenter(center: onGround() - Offset(0, w * 0.35), width: w, height: w);
    case CareKind.leaves:
      final w = size.width * 0.13;
      return Rect.fromCenter(center: onGround(), width: w, height: w * 0.6);
    case CareKind.sand:
      return layout.places[Place.sand];
    case CareKind.stone:
      final tower = layout.places[Place.stack];
      if (tower == null) return null;
      // Sobre la arena, a la derecha de la laja de la torre.
      final w = size.width * 0.05;
      final at = Offset(
        tower.center.dx + tower.width * (0.34 + 0.17 * t.x),
        tower.bottom - tower.height * (0.14 + 0.05 * (t.x % 2)),
      );
      return Rect.fromCenter(center: at, width: w, height: w * 0.75);
    case CareKind.jar:
      final jars = layout.places[Place.rain];
      if (jars == null) return null;
      final w = jars.width * 0.42;
      return Rect.fromLTWH(jars.left - w * 0.55, jars.bottom - w * 0.62, w, w * 0.62);
    case CareKind.decor:
      final d = p.decor[t.decor!];
      final item = p.decorRules.byId(d.id);
      if (item == null) return null;
      return decorRect(item, clampFoot(Offset(d.x * size.width, d.y * size.height), layout), layout);
  }
}

/// Un cuidado pendiente: se dibuja y se arregla con su gesto (arrancar hacia
/// arriba, barrer, rastrillar) o con un toque (lo que se levanta).
class _CareSpot extends StatefulWidget {
  final CareTask task;
  final Rect rect;
  final void Function(Offset at) onFix;
  const _CareSpot({super.key, required this.task, required this.rect, required this.onFix});

  @override
  State<_CareSpot> createState() => _CareSpotState();
}

class _CareSpotState extends State<_CareSpot> with SingleTickerProviderStateMixin {
  /// Cuánto se avanzó con el gesto (0 a 1): la maleza sube, las hojas se
  /// corren, la arena se alisa.
  double _done = 0;
  late final _wiggle = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

  CareKind get _kind => widget.task.kind;
  bool get _byGesture => _kind == CareKind.weed || _kind == CareKind.leaves || _kind == CareKind.sand;

  @override
  void dispose() {
    _wiggle.dispose();
    super.dispose();
  }

  void _fix() => widget.onFix(widget.rect.center);

  void _tap() {
    if (!_byGesture) return _fix();
    // Un toque no alcanza: se mueve un poco y se dice cómo.
    _wiggle.forward(from: 0);
    Haptics.light();
    showWashiToast(context, tr('care.how.${_kind.name}'), duration: const Duration(seconds: 2));
  }

  /// Al soltar sin terminar, la maleza y las hojas vuelven (la arena queda
  /// como se la dejó).
  void _release() {
    if (_kind != CareKind.sand && _done < 1) setState(() => _done = 0);
  }

  void _drag(Offset delta) {
    final r = widget.rect;
    final step = switch (_kind) {
      CareKind.weed => -delta.dy / (r.height * 0.7),
      CareKind.leaves => delta.distance / (r.width * 0.6),
      _ => delta.distance / (r.width * 1.2),
    };
    if (step <= 0) return;
    setState(() => _done = (_done + step).clamp(0.0, 1.0));
    if (_kind == CareKind.sand && _rngCare.nextDouble() < 0.08) Haptics.light();
    if (_done >= 1) _fix();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rect;
    return Positioned.fromRect(
      rect: r.inflate(r.shortestSide * 0.25),
      // Barrer y rastrillar son de costado, igual que cambiar de vista: este
      // detector está más adentro, recibe el movimiento primero y gana.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        onVerticalDragUpdate: _kind == CareKind.weed ? (e) => _drag(e.delta) : null,
        onVerticalDragEnd: _kind == CareKind.weed ? (_) => _release() : null,
        onHorizontalDragUpdate: _byGesture && _kind != CareKind.weed ? (e) => _drag(e.delta) : null,
        onHorizontalDragEnd: _byGesture && _kind != CareKind.weed ? (_) => _release() : null,
        child: AnimatedBuilder(
          animation: _wiggle,
          builder: (context, _) => CustomPaint(
            painter: _CarePainter(
              widget.task,
              _done,
              sin(_wiggle.value * pi * 4) * (1 - _wiggle.value),
              pad: r.shortestSide * 0.25,
            ),
          ),
        ),
      ),
    );
  }
}

final _rngCare = Random();

class _CarePainter extends CustomPainter {
  final CareTask task;
  final double done, wiggle, pad;
  _CarePainter(this.task, this.done, this.wiggle, {required this.pad});

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(pad, pad, size.width - 2 * pad, size.height - 2 * pad);
    final rng = Random(task.id * 7919);
    switch (task.kind) {
      case CareKind.weed:
        _weed(canvas, r, rng);
      case CareKind.leaves:
        _leaves(canvas, r, rng);
      case CareKind.sand:
        _sand(canvas, r, rng);
      case CareKind.stone:
        _stone(canvas, r);
      case CareKind.jar:
        _jar(canvas, r);
      case CareKind.decor:
        _decor(canvas, r);
    }
  }

  void _weed(Canvas canvas, Rect r, Random rng) {
    final base = r.bottomCenter - Offset(0, r.height * 0.55 * done);
    canvas.drawOval(
      Rect.fromCenter(center: r.bottomCenter, width: r.width * 0.6, height: r.height * 0.14),
      Paint()..color = const Color(0xFF5A4630).withValues(alpha: 0.35 + 0.3 * done),
    );
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(wiggle * 0.25);
    final art = SceneArt.instance['obj_care_weeds'];
    if (art != null) {
      // La mata pintada, con la base de los tallos en la tierra.
      final w = r.width * 1.05, h = w * art.height / art.width;
      drawArt(canvas, art, Rect.fromLTWH(-w / 2, -h * 0.97, w, h));
    }
    for (var i = 0; i < (art == null ? 7 : 0); i++) {
      final lean = (i - 3) / 3 + (rng.nextDouble() - 0.5) * 0.3;
      final h = r.height * (0.55 + rng.nextDouble() * 0.4);
      final tip = Offset(lean * r.width * 0.45, -h);
      final path = Path()
        ..moveTo(-r.width * 0.04, 0)
        ..quadraticBezierTo(lean * r.width * 0.1, -h * 0.5, tip.dx, tip.dy)
        ..quadraticBezierTo(lean * r.width * 0.16, -h * 0.45, r.width * 0.04, 0)
        ..close();
      canvas.drawPath(path, Paint()..color = Color.lerp(const Color(0xFF4E6B2E), const Color(0xFF8FA650), i / 6)!);
    }
    // Dos florcitas amarillas: se distingue del pasto pintado.
    for (final (fx, fy) in art == null ? const [(-0.22, -0.95), (0.18, -0.8)] : const <(double, double)>[]) {
      final at = Offset(fx * r.width, fy * r.height);
      canvas.drawLine(
        Offset.zero,
        at,
        Paint()
          ..color = const Color(0xFF5C7A34)
          ..strokeWidth = 1.4,
      );
      canvas.drawCircle(at, r.width * 0.07, Paint()..color = const Color(0xFFF2C94C));
      canvas.drawCircle(at, r.width * 0.03, Paint()..color = const Color(0xFFC98A1E));
    }
    if (done > 0) {
      // Raíces que asoman al tirar.
      final roots = Paint()
        ..color = const Color(0xFF7A6248)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      for (var i = -1; i <= 1; i++) {
        canvas.drawLine(Offset.zero, Offset(i * r.width * 0.08, r.height * 0.2 * done), roots);
      }
    }
    canvas.restore();
  }

  void _leaves(Canvas canvas, Rect r, Random rng) {
    final art = SceneArt.instance['obj_care_leaves'];
    if (art != null) {
      // El montón pintado: al barrer se corre de costado, se levanta y se apaga.
      final w = r.width * 1.1, h = w * art.height / art.width;
      final c = r.bottomCenter + Offset(r.width * 0.9 * done, -h * 0.45 - r.height * 0.3 * done);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(wiggle * 0.15 + done * 0.3);
      drawArt(
        canvas,
        art,
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        paint: Paint()..color = Color.fromRGBO(255, 255, 255, (1 - done * 0.8).clamp(0, 1)),
      );
      canvas.restore();
      return;
    }
    const colors = [Color(0xFFC8642E), Color(0xFFD99A3A), Color(0xFF9C4A2A), Color(0xFFB9852F)];
    final push = Offset(r.width * 0.9 * done, 0);
    for (var i = 0; i < 9; i++) {
      final at = Offset(
        r.left + r.width * (0.15 + rng.nextDouble() * 0.7),
        r.top + r.height * (0.25 + rng.nextDouble() * 0.6),
      );
      final spread = 1 + done * (0.5 + rng.nextDouble());
      canvas.save();
      canvas.translate(at.dx + push.dx * spread, at.dy - r.height * 0.3 * done * rng.nextDouble());
      canvas.rotate(rng.nextDouble() * pi + wiggle * 0.4);
      final w = r.width * (0.16 + rng.nextDouble() * 0.08);
      final leaf = Path()
        ..moveTo(-w / 2, 0)
        ..quadraticBezierTo(0, -w * 0.32, w / 2, 0)
        ..quadraticBezierTo(0, w * 0.32, -w / 2, 0);
      canvas.drawPath(leaf, Paint()..color = colors[i % colors.length].withValues(alpha: 1 - done * 0.6));
      canvas.drawLine(
        Offset(-w / 2, 0),
        Offset(w / 2, 0),
        Paint()
          ..color = const Color(0x55402010)
          ..strokeWidth = 0.8,
      );
      canvas.restore();
    }
  }

  void _sand(Canvas canvas, Rect r, Random rng) {
    final a = 1 - done;
    final area = RRect.fromRectAndRadius(r.deflate(r.width * 0.06), Radius.circular(r.width * 0.2));
    canvas.save();
    canvas.clipRRect(area);
    canvas.drawRRect(area, Paint()..color = const Color(0xFFE6D6B4).withValues(alpha: 0.85 * a));
    // Las marcas de las gotas sobre la arena lisa.
    final pock = Paint()..color = const Color(0xFF9E8A66).withValues(alpha: 0.45 * a);
    for (var i = 0; i < 40; i++) {
      final at = Offset(r.left + rng.nextDouble() * r.width, r.top + rng.nextDouble() * r.height);
      canvas.drawOval(
        Rect.fromCenter(center: at, width: 3 + rng.nextDouble() * 3, height: 2 + rng.nextDouble() * 2),
        pock,
      );
    }
    canvas.restore();
  }

  void _stone(Canvas canvas, Rect r) {
    final body = Rect.fromCenter(center: r.center, width: r.width * 0.8, height: r.height * 0.62);
    canvas.drawOval(body.shift(Offset(0, r.height * 0.18)), Paint()..color = const Color(0x33000000));
    canvas.save();
    canvas.translate(body.center.dx, body.center.dy);
    canvas.rotate(0.3 + wiggle * 0.3);
    final local = Rect.fromCenter(center: Offset.zero, width: body.width, height: body.height);
    canvas.drawOval(
      local,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.5),
          colors: [Color(0xFFD3CEC3), Color(0xFFA29D93), Color(0xFF77736B)],
        ).createShader(local),
    );
    canvas.restore();
  }

  void _jar(Canvas canvas, Rect r) {
    // El agua derramada.
    canvas.drawOval(
      Rect.fromLTWH(r.left + r.width * 0.3, r.bottom - r.height * 0.28, r.width * 0.75, r.height * 0.26),
      Paint()..color = const Color(0xFF6E9AA6).withValues(alpha: 0.45),
    );
    canvas.save();
    canvas.translate(r.left + r.width * 0.42, r.bottom - r.height * 0.36);
    canvas.rotate(-pi / 2 + 0.25 + wiggle * 0.2);
    final h = r.width * 0.62, w = r.height * 0.78;
    final body = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      topLeft: Radius.circular(w * 0.25),
      topRight: Radius.circular(w * 0.25),
      bottomLeft: Radius.circular(w * 0.45),
      bottomRight: Radius.circular(w * 0.45),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFB0643C), Color(0xFF8A4628), Color(0xFF6B3520)],
        ).createShader(body.outerRect),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, -h / 2), width: w * 0.62, height: w * 0.24),
      Paint()..color = const Color(0xFF2E1A10),
    );
    canvas.restore();
  }

  void _decor(Canvas canvas, Rect r) {
    canvas.save();
    canvas.translate(r.bottomCenter.dx, r.bottom);
    canvas.rotate(0.42 + wiggle * 0.15);
    canvas.translate(-r.bottomCenter.dx, -r.bottom);
    paintDecor(canvas, Progress.instance.decor[task.decor!].id, r);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CarePainter old) => old.done != done || old.wiggle != wiggle || old.task != task;
}

/// Lo que salta al arreglar un cuidado: puntitos del color de lo que se sacó
/// y la serenidad que vuelve.
class _CareBurst extends StatelessWidget {
  final Offset at;
  final CareKind kind;
  final int serenity;
  const _CareBurst({super.key, required this.at, required this.kind, required this.serenity});

  static Color colorOf(CareKind k) => switch (k) {
    CareKind.weed => const Color(0xFF6B5236),
    CareKind.leaves => const Color(0xFFD08A3A),
    CareKind.sand => const Color(0xFFE2CFA6),
    CareKind.stone => const Color(0xFF8A857C),
    CareKind.jar => const Color(0xFF7FB0BE),
    CareKind.decor => Palette.lantern,
  };

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: at.dx - 60,
      top: at.dy - 70,
      width: 120,
      height: 120,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1300),
          curve: Curves.easeOut,
          builder: (context, v, _) => Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: CustomPaint(painter: _BurstPainter(v, colorOf(kind)))),
              Positioned(
                left: 0,
                right: 0,
                top: 40 - 34 * v,
                child: Opacity(
                  opacity: v < 0.2 ? v / 0.2 : (1 - v) / 0.8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.spa_rounded, size: 16, color: Palette.moss),
                      const SizedBox(width: 2),
                      Text(
                        '+$serenity',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Palette.ink,
                          shadows: [Shadow(color: Color(0xCCFFFFFF), blurRadius: 6)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final double v;
  final Color color;
  _BurstPainter(this.v, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.6);
    final paint = Paint()..color = color.withValues(alpha: (1 - v).clamp(0.0, 1.0));
    for (var i = 0; i < 12; i++) {
      final a = -pi / 2 + (i / 11 - 0.5) * pi * 1.3;
      final d = 14 + 34 * v * (0.7 + 0.3 * ((i * 37) % 10) / 10);
      final at = c + Offset(cos(a), sin(a)) * d + Offset(0, 30 * v * v);
      canvas.drawCircle(at, 2.6 * (1 - v * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.v != v;
}
