part of 'garden_view.dart';

/// Lo que se ve de cada mejora en su lugar: un borde de piedras, después un
/// farolito al costado y al final un brillo cálido con flores.
class _UpgradeDeco extends StatelessWidget {
  final Rect place;
  final int tier;
  final double daylight;
  const _UpgradeDeco({required this.place, required this.tier, required this.daylight});

  @override
  Widget build(BuildContext context) {
    final pad = place.width * 0.35;
    return Positioned.fromRect(
      rect: place.inflate(pad),
      child: IgnorePointer(child: CustomPaint(painter: _UpgradePainter(tier, daylight, pad))),
    );
  }
}

class _UpgradePainter extends CustomPainter {
  final int tier;
  final double daylight, pad;
  _UpgradePainter(this.tier, this.daylight, this.pad);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(pad, pad, size.width - 2 * pad, size.height - 2 * pad);
    final base = r.bottomCenter;
    final rx = r.width * 0.55, ry = r.width * 0.11;
    if (tier >= 3) {
      // Un brillo cálido que sale del suelo.
      final glow = Rect.fromCenter(center: base, width: rx * 2.6, height: ry * 5);
      canvas.drawOval(
        glow,
        Paint()
          ..shader = RadialGradient(
            colors: [Palette.lantern.withValues(alpha: 0.35), Palette.lantern.withValues(alpha: 0)],
          ).createShader(glow),
      );
    }
    // Borde de piedritas por delante del lugar (con flores en el nivel 3).
    final border = SceneArt.instance[tier >= 3 ? 'obj_upgrade_bloom' : 'obj_upgrade_border'];
    if (border != null) {
      final w = rx * 2.2, bh = w * border.height / border.width;
      drawArt(canvas, border, Rect.fromLTWH(base.dx - w / 2, base.dy + ry * 0.7 - bh, w, bh));
    }
    for (var i = 0; i <= 8 && border == null; i++) {
      final a = pi * (0.08 + 0.84 * i / 8);
      final at = base + Offset(cos(a) * rx, sin(a) * ry * 0.6);
      final s = r.width * (0.045 + 0.012 * ((i * 5) % 3));
      final stone = Rect.fromCenter(center: at, width: s * 1.5, height: s);
      canvas.drawOval(stone.shift(Offset(0, s * 0.25)), Paint()..color = const Color(0x33000000));
      canvas.drawOval(
        stone,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.3, -0.5),
            colors: [Color(0xFFE2DDD2), Color(0xFFA9A398), Color(0xFF7E786E)],
          ).createShader(stone),
      );
      if (tier >= 3 && i.isOdd) {
        // Flores entre las piedras.
        final f = at + Offset(0, -s * 0.9);
        for (var k = 0; k < 5; k++) {
          final pa = k * 2 * pi / 5;
          canvas.drawCircle(
            f + Offset(cos(pa), sin(pa)) * s * 0.28,
            s * 0.22,
            Paint()..color = const Color(0xFFF2B8C6),
          );
        }
        canvas.drawCircle(f, s * 0.16, Paint()..color = const Color(0xFFF2C94C));
      }
    }
    if (tier >= 2) _lantern(canvas, Offset(r.right + r.width * 0.12, base.dy - ry * 0.2), r.width * 0.11);
  }

  /// Un farolito de piedra; de noche, la ventana encendida.
  void _lantern(Canvas canvas, Offset foot, double w) {
    final art = SceneArt.instance['obj_court_lantern_small'];
    if (art != null) {
      final ah = w * 2.4, aw = ah * art.width / art.height;
      canvas.drawOval(
        Rect.fromCenter(center: foot, width: aw * 1.1, height: w * 0.35),
        Paint()..color = const Color(0x33000000),
      );
      drawArt(canvas, art, Rect.fromLTWH(foot.dx - aw / 2, foot.dy - ah, aw, ah));
      _night(canvas, foot - Offset(0, ah * 0.62), w);
      return;
    }
    final stone = Paint()..color = const Color(0xFF8E887D);
    final dark = Paint()..color = const Color(0xFF6E685E);
    canvas.drawOval(
      Rect.fromCenter(center: foot, width: w * 1.6, height: w * 0.4),
      Paint()..color = const Color(0x33000000),
    );
    canvas.drawRect(Rect.fromCenter(center: foot - Offset(0, w * 0.5), width: w * 0.35, height: w), stone);
    final box = Rect.fromCenter(center: foot - Offset(0, w * 1.25), width: w * 0.8, height: w * 0.6);
    canvas.drawRect(box, stone);
    final night = (1 - daylight).clamp(0.0, 1.0);
    final window = box.deflate(w * 0.14);
    canvas.drawRect(
      window,
      Paint()..color = Color.lerp(const Color(0xFF4A453E), const Color(0xFFFFD27A), 0.25 + 0.75 * night)!,
    );
    _night(canvas, window.center, w);
    final roof = Path()
      ..moveTo(box.left - w * 0.25, box.top)
      ..lineTo(box.center.dx, box.top - w * 0.45)
      ..lineTo(box.right + w * 0.25, box.top)
      ..close();
    canvas.drawPath(roof, dark);
  }

  /// De noche, la luz de la ventana del farolito.
  void _night(Canvas canvas, Offset window, double w) {
    final night = (1 - daylight).clamp(0.0, 1.0);
    if (night > 0.2) {
      canvas.drawCircle(
        window,
        w * 1.2,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Palette.lantern.withValues(alpha: 0.4 * night),
              Palette.lantern.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: window, radius: w * 1.2)),
      );
    }
  }

  @override
  bool shouldRepaint(_UpgradePainter old) => old.tier != tier || old.daylight != daylight;
}

/// En el modo Decorar, sobre cada lugar que se puede mejorar: un martillito
/// que abre sus mejoras (late si ya alcanza para la próxima).
class _UpgradeBadge extends StatelessWidget {
  final Offset at;
  final String game;
  final double scale;
  const _UpgradeBadge({required this.at, required this.game, this.scale = 1});

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final ready = p.canUpgrade(game);
    final tier = p.upgradeTier(game);
    return Positioned(
      left: at.dx - 22,
      top: at.dy - 22,
      child: Transform.scale(
        scale: scale,
        child: GestureDetector(
          onTap: () {
            SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
            showUpgradeSheet(context, game);
          },
          child: Badge(
            isLabelVisible: ready,
            smallSize: 10,
            backgroundColor: Palette.lantern,
            child: Glass(
              radius: BorderRadius.circular(22),
              child: SizedBox.square(
                dimension: 44,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.construction_rounded, size: 20, color: Palette.ink),
                    Text(
                      '$tier/${p.upgradeRules.maxTier}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Palette.ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
