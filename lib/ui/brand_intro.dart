import 'dart:math';

import 'package:flutter/material.dart';

/// Fondo de la pantalla de carga nativa (`flutter_native_splash.yaml`).
const _splashColor = Color(0xFF231E1A);

/// Ancho con que la pantalla nativa muestra el logo: lienzo de 768 px a 192 pt
/// con el logo de 520 px centrado. Así la intro arranca exactamente donde
/// termina la pantalla de carga y no se nota el cambio.
const _logoWidth = 130.0;

/// Presentación del estudio al abrir la app: el logo de Oraki Games que dejó la
/// pantalla de carga brilla un momento y da paso a [next]. Tocar la salta.
class BrandIntro extends StatefulWidget {
  final Widget next;
  const BrandIntro({super.key, required this.next});

  @override
  State<BrandIntro> createState() => _BrandIntroState();
}

class _BrandIntroState extends State<BrandIntro> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))
    ..forward().whenComplete(_leave);
  bool _left = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/brand/oraki_logo_light_on_dark.webp'), context);
  }

  void _leave() {
    if (_left || !mounted) return;
    _left = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, _, _) => widget.next,
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _leave,
      child: ColoredBox(
        color: _splashColor,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            // 0–0.15 quieto (igual a la pantalla nativa) · brillo y "GAMES" · se apaga al final.
            final glow = Curves.easeOut.transform(((t - 0.12) / 0.4).clamp(0.0, 1.0));
            final games = Curves.easeOutCubic.transform(((t - 0.25) / 0.3).clamp(0.0, 1.0));
            final out = Curves.easeIn.transform(((t - 0.8) / 0.2).clamp(0.0, 1.0));
            final scale = 1 + 0.035 * glow - 0.02 * out;
            return Opacity(
              opacity: 1 - out * 0.35,
              child: Center(
                child: Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    width: _logoWidth,
                    // "GAMES" va fuera del Stack para no mover el logo, que queda
                    // centrado como en la pantalla nativa.
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Positioned.fill(child: CustomPaint(painter: _GlowPainter(glow, t))),
                        Image.asset(
                          'assets/brand/oraki_logo_light_on_dark.webp',
                          width: _logoWidth,
                          filterQuality: FilterQuality.high,
                        ),
                        Positioned(
                          left: -60,
                          right: -60,
                          bottom: -26 - 6 * (1 - games),
                          child: Opacity(
                            opacity: games,
                            child: const Text(
                              'GAMES',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'ZenKakuGothic',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 9,
                                decoration: TextDecoration.none,
                                color: Color(0xFFD9A84E),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Halo cálido detrás del logo y destello de la estrella dorada.
class _GlowPainter extends CustomPainter {
  final double glow, t;
  _GlowPainter(this.glow, this.t);

  // Centro de la estrella dentro del logo (medido sobre la imagen).
  static const _star = Offset(0.712, 0.119);

  @override
  void paint(Canvas canvas, Size size) {
    if (glow <= 0) return;
    final c = Offset(size.width / 2, size.height * 0.38);
    canvas.drawCircle(
      c,
      size.width * 0.9,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFE07A3A).withValues(alpha: 0.16 * glow),
            const Color(0x00E07A3A),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: size.width * 0.9)),
    );
    // La estrella titila una vez: cruz de luz que crece y se apaga.
    final s = Offset(_star.dx * size.width, _star.dy * size.height);
    final k = sin(((t - 0.18) / 0.45).clamp(0.0, 1.0) * pi);
    if (k <= 0) return;
    final p = Paint()
      ..color = const Color(0xFFFFE3A0).withValues(alpha: 0.85 * k)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    final len = size.width * 0.22 * k;
    canvas.drawRect(Rect.fromCenter(center: s, width: len * 2, height: 1.6), p);
    canvas.drawRect(Rect.fromCenter(center: s, width: 1.6, height: len * 2), p);
    canvas.drawCircle(
      s,
      6 * k,
      Paint()
        ..color = const Color(0xFFFFE3A0).withValues(alpha: 0.5 * k)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.glow != glow || old.t != t;
}
