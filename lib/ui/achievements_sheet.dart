import 'package:flutter/material.dart';

import '../garden/achievements.dart';
import '../garden/game_center.dart';
import '../garden/progress.dart';
import '../i18n/i18n.dart';
import 'fx/calm.dart';
import 'fx/sfx.dart';
import 'theme/palette.dart';
import 'widgets/washi.dart';

/// El sello de cada logro.
IconData achievementIcon(String id) => switch (id) {
  'firstRun' => Icons.directions_walk_rounded,
  'threeStars' || 'three50' => Icons.star_rounded,
  'firstDecor' || 'decor20' => Icons.spa_rounded,
  'level5' || 'level10' || 'level20' => Icons.terrain_rounded,
  'patio' => Icons.landscape_rounded,
  'days7' || 'days30' => Icons.wb_sunny_rounded,
  'tower' => Icons.layers_rounded,
  'meditate' => Icons.self_improvement_rounded,
  'upgradeMax' => Icons.auto_awesome_rounded,
  'shapes' => Icons.gesture_rounded,
  'gifts' => Icons.card_giftcard_rounded,
  'visitors' => Icons.emoji_food_beverage_rounded,
  'allGames' => Icons.grid_view_rounded,
  'runs500' => Icons.all_inclusive_rounded,
  _ => Icons.emoji_events_rounded,
};

/// Los logros: los conseguidos con su sello encendido, los que faltan con
/// cuánto llevan. En iOS, un botón abre los de Game Center.
Future<void> showAchievementsSheet(BuildContext context) {
  Progress.instance.markAchievementsSeen();
  return showWashiSheet(context, isScrollControlled: true, builder: (context) => const _Sheet());
}

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Progress.instance,
      builder: (context, _) {
        final p = Progress.instance;
        final text = Theme.of(context).textTheme;
        final all = Achievements.all;
        final got = all.where((a) => p.achievements.contains(a.id)).length;
        // Primero lo que está más cerca de conseguirse; lo conseguido, al final.
        final order = [...all]
          ..sort((a, b) {
            final fa = Achievements.instance.fraction(a), fb = Achievements.instance.fraction(b);
            if ((fa >= 1) != (fb >= 1)) return fa >= 1 ? 1 : -1;
            return fa >= 1 ? 0 : fb.compareTo(fa);
          });
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          builder: (context, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text(tr('ach.title'), style: text.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                tr('ach.count', {'n': got, 't': all.length}),
                style: text.bodyMedium?.copyWith(color: Palette.ink.withValues(alpha: 0.65)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              BrushBar(value: got / all.length, height: 8),
              if (GameCenter.instance.supported) const _GameCenterButton(),
              const SizedBox(height: 10),
              for (final (i, a) in order.indexed)
                CalmAppear(
                  delay: Duration(milliseconds: 30 * i.clamp(0, 12)),
                  rise: 6,
                  child: _Row(a),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GameCenterButton extends StatefulWidget {
  const _GameCenterButton();

  @override
  State<_GameCenterButton> createState() => _GameCenterButtonState();
}

class _GameCenterButtonState extends State<_GameCenterButton> {
  /// Si no hubo nada para abrir: se cuenta dónde se inicia sesión.
  bool _off = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        children: [
          InkButton.quiet(
            label: tr('ach.gameCenter'),
            onPressed: () async {
              SoundBoard.instance.play(Sfx.uiTap, volume: 0.4);
              final shown = await GameCenter.instance.show();
              if (mounted) setState(() => _off = !shown);
            },
          ),
          if (_off)
            Text(
              tr('ach.gameCenterOff'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Palette.ink.withValues(alpha: 0.65)),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final AchievementDef a;
  const _Row(this.a);

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final done = p.achievements.contains(a.id);
    final m = Achievements.instance.measure(a);
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '${tr('ach.${a.id}')}. ${tr('ach.${a.id}.how', {'n': m.target})}',
      value: done ? tr('ach.done') : '${m.value.clamp(0, m.target)}/${m.target}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
        decoration: BoxDecoration(
          color: done ? Palette.lantern.withValues(alpha: 0.14) : Palette.sandShadow.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            AchievementSeal(a.id, done: done),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('ach.${a.id}'),
                    style: text.titleSmall?.copyWith(color: Palette.ink.withValues(alpha: done ? 1 : 0.8)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr('ach.${a.id}.how', {'n': m.target}),
                    style: text.bodySmall?.copyWith(color: Palette.ink.withValues(alpha: 0.65)),
                  ),
                  if (!done) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: BrushBar(value: Achievements.instance.fraction(a), height: 6)),
                        const SizedBox(width: 8),
                        Text(
                          '${m.value.clamp(0, m.target)}/${m.target}',
                          style: text.labelSmall?.copyWith(color: Palette.ink.withValues(alpha: 0.55)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un sello redondo: encendido como farol si se consiguió, apagado si no.
class AchievementSeal extends StatelessWidget {
  final String id;
  final bool done;
  final double size;
  const AchievementSeal(this.id, {super.key, required this.done, this.size = 48});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: done ? const RadialGradient(colors: [Color(0xFFE8A85A), Palette.lantern, Color(0xFFB0662A)]) : null,
      color: done ? null : Palette.sandShadow.withValues(alpha: 0.35),
      border: Border.all(color: done ? Palette.paper : Palette.ink.withValues(alpha: 0.12), width: 2),
    ),
    child: Icon(
      achievementIcon(id),
      size: size * 0.5,
      color: done ? Palette.paper : Palette.ink.withValues(alpha: 0.3),
    ),
  );
}
