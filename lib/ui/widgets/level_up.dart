import 'package:flutter/material.dart';

import '../../i18n/i18n.dart';
import '../fx/calm.dart';
import '../theme/palette.dart';

/// Nombre de algo que se destraba por nivel ('meditation' o el id de una ampliación).
String unlockName(String id) => id == 'meditation' ? tr('meditation.title') : tr('exp.$id.name');

/// "Nivel N" en el resultado de la partida: lo que se destrabó se celebra en
/// grande al volver al jardín. El cartel aparece con un fundido y un halo
/// cálido late una sola vez detrás.
class LevelUpBanner extends StatelessWidget {
  final int level;

  /// Cuándo aparece: en el resultado, cuando la barra termina de llenarse.
  final Duration delay;
  const LevelUpBanner(this.level, {super.key, this.delay = const Duration(milliseconds: 900)});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return CalmAppear(
      delay: delay,
      duration: const Duration(milliseconds: 900),
      fromScale: 0.94,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: delay + const Duration(milliseconds: 1700),
        builder: (context, t, child) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Palette.lantern.withValues(alpha: 0.45 * _swell(_after(t))),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Palette.lantern.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Palette.lantern),
          ),
          child: Column(
            children: [
              Text(tr('level.up', {'n': level}), style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              Text(tr('milestone.seeGarden'), style: text.bodyMedium, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  /// El avance del halo desde que aparece el cartel.
  double _after(double t) {
    final total = delay.inMilliseconds + 1700;
    return ((t * total - delay.inMilliseconds + 140) / 1700).clamp(0.0, 1.0);
  }

  /// Sube y baja una vez, despacio (respira).
  static double _swell(double t) =>
      t < 0.4 ? Curves.easeOut.transform(t / 0.4) : 1 - Curves.easeInOut.transform((t - 0.4) / 0.6) * 0.6;
}

/// Monto de Calma ganado, con el mismo formato que las monedas.
class CalmChip extends StatelessWidget {
  static const _style = TextStyle(fontWeight: FontWeight.w700, fontSize: 16);

  final int amount;

  /// Si se da, cuenta desde 0 después de esta espera.
  final Duration? delay;
  const CalmChip(this.amount, {super.key, this.delay});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.spa_rounded, size: 18, color: Palette.moss),
        const SizedBox(width: 4),
        if (delay == null)
          Text('+$amount ${tr('level.calm')}', style: _style)
        else
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: amount.toDouble()),
            duration: delay! + const Duration(milliseconds: 1300),
            curve: Interval(
              (delay!.inMilliseconds + 150) / (delay!.inMilliseconds + 1300),
              1,
              curve: Curves.easeOutCubic,
            ),
            builder: (context, v, _) => Text('+${v.round()} ${tr('level.calm')}', style: _style),
          ),
      ],
    );
  }
}
