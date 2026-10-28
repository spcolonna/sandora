import 'package:flutter/material.dart';

import '../garden/progress.dart';
import '../i18n/i18n.dart';
import '../minigames/catalog.dart';
import 'theme/palette.dart';

/// Tablón del jardín: los récords propios. El ranking con otros jardines
/// llega con el backend; mientras tanto se avisa que viene.
Future<void> showBoardSheet(BuildContext context) {
  final p = Progress.instance;
  final text = Theme.of(context).textTheme;
  final rows = [
    // Los que todavía no se abrieron no tienen récord.
    for (final m in minigames) (m.icon, m.name, p.gameUnlocked(m.id) ? m.record : '—'),
    (Icons.self_improvement_rounded, tr('meditation.title'), trN('board.days', p.meditationStreak)),
  ];
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('board.title'), style: text.titleLarge),
            const SizedBox(height: 4),
            Text(tr('board.desc'), style: text.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            for (final (icon, name, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(icon, color: Palette.moss),
                    const SizedBox(width: 12),
                    Expanded(child: Text(name, style: text.titleSmall)),
                    Text(value, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Palette.sand.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.public_rounded, color: Palette.stoneDark),
                  const SizedBox(width: 10),
                  Expanded(child: Text(tr('board.soon'), style: text.bodySmall)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
