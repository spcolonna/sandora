import 'dart:math';

/// Guion de la meditación guiada: frases cortas (`meditation.guide.N`) que
/// aparecen sobre el anillo. Llegada, respiración, cuerpo, soltar y cierre;
/// en sesiones cortas el medio se achica a una sola frase.
class MeditationGuide {
  /// Cuántas frases hay en i18n.
  static const phrases = 12;

  /// Segundos que se ve cada frase.
  static const visible = 8.0;

  static const _opening = [0, 1], _closing = [10, 11];
  static const _middleFirst = 2, _middleCount = 8;

  /// Cuándo empieza cada frase en una sesión de [minutes]: (segundo, frase).
  static List<(double, int)> script(int minutes) {
    final total = minutes * 60.0;
    final from = 27.0, to = total - 34;
    final n = (((to - from) / 30).floor() + 1).clamp(1, _middleCount);
    return [
      (3, _opening[0]),
      (15, _opening[1]),
      for (var i = 0; i < n; i++)
        (n == 1 ? from : from + (to - from) * i / (n - 1), _middleFirst + (i * _middleCount / n).floor()),
      (total - 22, _closing[0]),
      (total - 10, _closing[1]),
    ];
  }

  /// La frase que se ve a los [elapsed] segundos, o null entre frases.
  static int? phraseAt(double elapsed, int minutes) {
    for (final (at, i) in script(minutes)) {
      if (elapsed >= at && elapsed < at + min(visible, minutes * 60 - at)) return i;
    }
    return null;
  }
}
