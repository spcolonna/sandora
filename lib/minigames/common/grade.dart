import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/animation.dart' show Cubic, Curves;
import 'package:flutter/painting.dart';

import '../../i18n/i18n.dart';
import '../../ui/fx/sfx.dart';
import '../../ui/theme/palette.dart';

/// Calidad de un acierto. Cada nivel tiene partículas, sonido y vibración
/// claramente distintos (GDD, pilar 5), pero ninguno explota: las partículas
/// son lucecitas que flotan y se apagan despacio (pilar 8).
enum Grade {
  good(6, 1, Palette.good),
  great(11, 2, Palette.great),
  perfect(18, 3, Palette.perfect);

  final int particles;
  final int points;
  final Color color;
  const Grade(this.particles, this.points, this.color);

  String get label => tr('grade.$name');
}

final _rng = Random();

/// Festeja [grade] en [position] (coordenadas de [parent]). Con [sound] en
/// false solo hay partículas, texto y vibración: en la lluvia el sonido es la
/// nota de la vasija.
///
/// Con [streak] (aciertos seguidos) hay más lucecitas, un "×n" debajo y una
/// nota que sube con cada acierto de la racha ([streakNote] en false la calla,
/// si el juego ya tiene su melodía).
void celebrate(
  Component parent,
  Vector2 position,
  Grade grade, {
  bool sound = true,
  double scale = 1,
  int streak = 0,
  bool streakNote = true,
  bool label = true,
}) {
  final count = grade.particles + 2 * min(streak, 6).toInt();
  _ripple(parent, position, grade.color, scale * (1 + 0.15 * grade.index));
  parent.add(
    ParticleSystemComponent(
      position: position.clone(),
      particle: Particle.generate(
        count: count,
        lifespan: 1.0 + 0.3 * grade.index,
        generator: (i) {
          // Salen hacia los costados y hacia arriba, frenan y suben flotando.
          final angle = -pi / 2 + (_rng.nextDouble() - 0.5) * pi * 1.4;
          final speed = (25 + _rng.nextDouble() * 30 * (grade.index + 1)) * scale;
          return AcceleratedParticle(
            speed: Vector2(cos(angle), sin(angle)) * speed,
            acceleration: Vector2(0, -18 * scale),
            child: ComputedParticle(
              renderer: (canvas, p) {
                // Aparece y se apaga con curva suave, sin cortes.
                final a = sin(pi * pow(p.progress, 0.6));
                final r = (2 + 0.8 * grade.index) * scale;
                canvas.drawCircle(
                  Offset.zero,
                  r * 2.2,
                  Paint()
                    ..color = grade.color.withValues(alpha: 0.18 * a)
                    ..maskFilter = MaskFilter.blur(BlurStyle.normal, r),
                );
                canvas.drawCircle(Offset.zero, r, Paint()..color = grade.color.withValues(alpha: 0.85 * a));
              },
            ),
          );
        },
      ),
    ),
  );
  final text = TextComponent(
    text: grade.label,
    anchor: Anchor.center,
    position: position + Vector2(0, -24 * scale),
    textRenderer: TextPaint(
      style: TextStyle(
        fontSize: (16 + 5 * grade.index) * scale,
        fontWeight: FontWeight.w700,
        color: grade == Grade.good ? Palette.mossDark : grade.color,
        shadows: const [Shadow(color: Color(0x88FFFFFF), blurRadius: 4)],
      ),
    ),
  );
  text.add(
    MoveByEffect(Vector2(0, -28 * scale), EffectController(duration: 1.2, curve: const Cubic(0.2, 0.8, 0.4, 1))),
  );
  text.add(
    OpacityEffect.fadeOut(
      EffectController(duration: 0.5, startDelay: 0.7, curve: Curves.easeIn),
      onComplete: text.removeFromParent,
    ),
  );
  if (label) parent.add(text);
  if (streak >= 2) {
    _float(parent, '×$streak', position + Vector2(0, 2 * scale), 15 * scale, Palette.lantern, delay: 0.12);
    // Pentatónica que sube y vuelve a empezar: la racha se escucha.
    if (streakNote) SoundBoard.instance.play(Sfx.rainNote, variant: (streak - 2) % 5 + 1, volume: 0.32);
  }

  switch (grade) {
    case Grade.good:
      if (sound) SoundBoard.instance.play(Sfx.good, volume: 0.45);
      Haptics.light();
    case Grade.great:
      if (sound) SoundBoard.instance.play(Sfx.great, volume: 0.5);
      Haptics.medium();
    case Grade.perfect:
      if (sound) SoundBoard.instance.play(Sfx.perfect, volume: 0.55);
      Haptics.perfect();
  }
}

/// Estrellas (0 a 3) según los umbrales crecientes [thresholds].
int starsFor(double value, List<double> thresholds) => thresholds.where((t) => value >= t).length;

/// Un anillo que se abre despacio donde se acertó.
void _ripple(Component parent, Vector2 position, Color color, double scale) {
  parent.add(
    ParticleSystemComponent(
      position: position.clone(),
      particle: ComputedParticle(
        lifespan: 0.9,
        renderer: (canvas, p) {
          final e = Curves.easeOutCubic.transform(p.progress);
          canvas.drawCircle(
            Offset.zero,
            (8 + 46 * e) * scale,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3 * (1 - e) + 1
              ..color = color.withValues(alpha: 0.6 * (1 - e)),
          );
        },
      ),
    ),
  );
}

/// Un texto que sube flotando y se apaga.
void _float(Component parent, String label, Vector2 position, double size, Color color, {double delay = 0}) {
  final text = TextComponent(
    text: label,
    anchor: Anchor.center,
    position: position,
    textRenderer: TextPaint(
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        shadows: const [Shadow(color: Color(0x88FFFFFF), blurRadius: 4)],
      ),
    ),
  );
  text.add(MoveByEffect(Vector2(0, -26), EffectController(duration: 1.3, startDelay: delay, curve: Curves.easeOut)));
  text.add(
    OpacityEffect.fadeOut(
      EffectController(duration: 0.5, startDelay: delay + 0.8, curve: Curves.easeIn),
      onComplete: text.removeFromParent,
    ),
  );
  parent.add(text);
}

/// Aciertos seguidos. Un muy bien o un perfecto la suman, un bien la sostiene
/// y un fallo la corta: perder la racha no castiga, solo deja de sonar.
class Streak {
  int count = 0;
  int best = 0;

  /// Anota [grade] (null es un fallo) y devuelve la racha actual.
  int hit(Grade? grade) {
    if (grade == null) {
      count = 0;
    } else if (grade != Grade.good) {
      count++;
      best = max(best, count);
    }
    return count;
  }

  void miss() => count = 0;
}

/// Las estrellas que se van ganando mientras se juega, para festejar cada una
/// en el momento y no recién al final.
class StarMilestones {
  final List<double> thresholds;
  int reached = 0;
  StarMilestones(this.thresholds);

  /// Si con [value] se ganó una estrella nueva, la festeja en [position].
  void update(double value, Component parent, Vector2 position) {
    final n = starsFor(value, thresholds);
    if (n <= reached) return;
    reached = n;
    _ripple(parent, position, Palette.lantern, 1.6);
    _float(parent, '★' * n, position, 30, Palette.lantern);
    SoundBoard.instance.play(Sfx.rainNote, variant: 2 + n, volume: 0.45);
    Haptics.medium();
  }
}
