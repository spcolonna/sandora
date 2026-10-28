import 'package:flutter/material.dart';

import 'fx/calm.dart';
import 'fx/sfx.dart';
import 'theme/palette.dart';

const _symbol = 'assets/images/brand/logo_symbol.webp';
const _wordmark = 'assets/images/brand/logo_wordmark.webp';
const _background = 'assets/images/title/title_bg.webp';

/// Título de Sandora, después de la intro de Oraki: el jardín al amanecer
/// aparece desde el papel, el símbolo y el nombre aparecen despacio en el cielo, suena una campana suave y se pasa a [next]
/// con un fundido. Tocar la salta.
class TitleIntro extends StatefulWidget {
  final Widget next;
  const TitleIntro({super.key, required this.next});

  @override
  State<TitleIntro> createState() => _TitleIntroState();
}

class _TitleIntroState extends State<TitleIntro> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))
    ..forward().whenComplete(_leave);
  bool _left = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) SoundBoard.instance.play(Sfx.bell, volume: 0.35);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(_background), context);
    precacheImage(const AssetImage(_symbol), context);
    precacheImage(const AssetImage(_wordmark), context);
  }

  void _leave() {
    if (_left || !mounted) return;
    _left = true;
    Navigator.of(context).pushReplacement(calmRoute<void>(widget.next));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Avance de 0 a 1 entre [from] y [to] del total, con la curva calma.
  double _span(double from, double to) => Calm.curve.transform(((_c.value - from) / (to - from)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _leave,
      child: ColoredBox(
        color: Palette.paper,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final garden = _span(0.0, 0.35);
            final symbol = _span(0.1, 0.45);
            final name = _span(0.3, 0.65);
            return Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: garden,
                  child: Transform.scale(
                    scale: 1.04 - 0.04 * _c.value,
                    child: Image.asset(_background, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
                  ),
                ),
                // El logo va en el cielo, la parte calma de arriba del fondo.
                Align(
                  alignment: const Alignment(0, -0.62),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: symbol,
                        child: Transform.translate(
                          offset: Offset(0, 12 * (1 - symbol)),
                          child: Image.asset(_symbol, width: width * 0.36, filterQuality: FilterQuality.high),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Opacity(
                        opacity: name,
                        child: Transform.translate(
                          offset: Offset(0, 8 * (1 - name)),
                          child: Image.asset(_wordmark, width: width * 0.58, filterQuality: FilterQuality.high),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
