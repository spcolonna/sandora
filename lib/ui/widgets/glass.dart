import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/palette.dart';
import 'washi.dart';

/// Vidrio esmerilado sobre el jardín: lo de arriba (nivel, billetera, botones)
/// se lee sin tapar lo que hay detrás.
class Glass extends StatelessWidget {
  final Widget child;
  final BorderRadius radius;
  final EdgeInsetsGeometry padding;

  /// Más opaco para paneles con texto largo.
  final double opacity;
  const Glass({
    super.key,
    required this.child,
    this.radius = const BorderRadius.all(Radius.circular(22)),
    this.padding = EdgeInsets.zero,
    this.opacity = 0.62,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [BoxShadow(color: Palette.ink.withValues(alpha: 0.14), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Palette.paper.withValues(alpha: opacity + 0.12),
                  Palette.paper.withValues(alpha: opacity),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 0.8),
              // Las fibras del washi, apenas, para que el vidrio sea papel.
              image: DecorationImage(
                image: const AssetImage(washiTexture),
                fit: BoxFit.cover,
                opacity: (opacity * 0.7).clamp(0.0, 1.0),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
