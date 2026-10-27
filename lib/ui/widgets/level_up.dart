import 'package:flutter/material.dart';

import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../fx/calm.dart';
import '../theme/palette.dart';

/// Nombre de algo que se destraba por nivel ('meditation' o el id de una ampliación).
String unlockName(String id) => id == 'meditation' ? tr('meditation.title') : tr('exp.$id.name');

/// "Nivel N" y lo que se destrabó. Es la celebración más grande del juego,
/// pero tranquila: el cartel aparece con un fundido y un halo cálido late una
/// sola vez detrás.
class LevelUpBanner extends StatelessWidget {
  final int level;
  const LevelUpBanner(this.level, {super.key});

  @override
  Widget build(BuildContext context) {
    final unlocks = Progress.instance.levels.unlocksAt(level);
    final text = Theme.of(context).textTheme;
    return CalmAppear(
      delay: const Duration(milliseconds: 900),
      duration: const Duration(milliseconds: 900),
      fromScale: 0.94,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 2600),
        builder: (context, t, child) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Palette.lantern.withValues(alpha: 0.45 * _swell(t)), blurRadius: 28, spreadRadius: 2),
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
              if (unlocks.isNotEmpty)
                Text(
                  tr('level.unlocked', {'list': unlocks.map(unlockName).join(', ')}),
                  style: text.bodyMedium,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sube y baja una vez, despacio (respira).
  static double _swell(double t) =>
      t < 0.4 ? Curves.easeOut.transform(t / 0.4) : 1 - Curves.easeInOut.transform((t - 0.4) / 0.6) * 0.6;
}

/// Monto de Calma ganado, con el mismo formato que las monedas.
class CalmChip extends StatelessWidget {
  final int amount;
  const CalmChip(this.amount, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.spa_rounded, size: 18, color: Palette.moss),
        const SizedBox(width: 4),
        Text('+$amount ${tr('level.calm')}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ],
    );
  }
}
