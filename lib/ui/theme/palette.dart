import 'package:flutter/material.dart';

import '../fx/calm.dart';

/// Paleta del prototipo. Es provisoria hasta tener la guía de estilo (Lote 0);
/// los mismos valores van en los prompts de `docs/prompts.md`.
abstract final class Palette {
  static const ink = Color(0xFF2F2B28);
  static const paper = Color(0xFFF3ECDD);
  static const sand = Color(0xFFE8DCC2);
  static const sandShadow = Color(0xFFC9B894);
  static const sandLight = Color(0xFFF7F0DE);
  static const stone = Color(0xFF8C8A85);
  static const stoneDark = Color(0xFF5E5C58);
  static const stoneLight = Color(0xFFB9B6AE);
  static const moss = Color(0xFF6E8B5B);
  static const mossDark = Color(0xFF4C6640);
  static const wood = Color(0xFF8A5A3C);
  static const water = Color(0xFF5C9EA8);
  static const lantern = Color(0xFFE9A84C);
  static const skyTop = Color(0xFFBFD8DC);
  static const skyBottom = Color(0xFFF4E7CF);
  static const dusk = Color(0xFF3A4660);

  static const good = Color(0xFF9DBF8A);
  static const great = Color(0xFF5C9EA8);
  static const perfect = Color(0xFFE9A84C);

  static ThemeData theme() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: moss, surface: paper),
    scaffoldBackgroundColor: paper,
    textTheme: const TextTheme().apply(bodyColor: ink, displayColor: ink),
    // Toques suaves: la onda de los botones es tenue (pilar 8).
    splashFactory: InkRipple.splashFactory,
    splashColor: moss.withValues(alpha: 0.10),
    highlightColor: moss.withValues(alpha: 0.05),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CalmPageTransitionsBuilder(),
        TargetPlatform.iOS: CalmPageTransitionsBuilder(),
      },
    ),
  );
}
