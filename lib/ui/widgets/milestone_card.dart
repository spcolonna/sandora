import 'dart:math';

import 'package:flutter/material.dart';

import '../../garden/achievements.dart';
import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../../minigames/catalog.dart';
import '../achievements_sheet.dart';
import '../fx/sfx.dart';
import '../garden/garden_decor.dart';
import '../theme/palette.dart';
import 'level_up.dart';
import 'washi.dart';

bool _showing = false;

/// Muestra, uno tras otro, los avisos grandes que esperan en [Progress]
/// (subir de nivel, un lugar nuevo, una mejora, la primera decoración). Cada
/// uno queda en el centro hasta que se toca.
Future<void> showPendingMilestones(BuildContext context) async {
  if (_showing) return;
  _showing = true;
  try {
    final p = Progress.instance;
    while (context.mounted) {
      final m = p.takeMilestone();
      if (m == null) break;
      final card = _cardFor(m);
      if (card == null) continue;
      await showMilestone(context, card);
    }
  } finally {
    _showing = false;
  }
}

/// Lo que dice un aviso grande.
class Milestone {
  final String title;
  final List<String> lines;

  /// Una línea más chica al pie: qué viene después.
  final String? next;
  final Widget art;
  const Milestone({required this.title, this.lines = const [], this.next, required this.art});
}

Milestone? _cardFor(String m) {
  final p = Progress.instance;
  final parts = m.split(':');
  switch (parts.first) {
    case 'level':
      final n = int.parse(parts[1]);
      final games = p.gamesAtLevel(n);
      final decor = [
        for (final d in p.decorRules.items)
          if (d.level == n && n > p.decorRules.minLevel) tr('decor.${d.id}'),
      ];
      return Milestone(
        title: tr('level.up', {'n': n}),
        lines: [
          for (final g in games) tr('milestone.newGame', {'game': tr('mg.$g.name')}),
          for (final u in p.levels.unlocksAt(n)) tr('level.unlocked', {'list': unlockName(u)}),
          if (n == p.decorRules.minLevel) tr('level.decorOpen'),
          if (decor.isNotEmpty) tr('level.newDecor', {'list': decor.join(', ')}),
        ],
        next: _nextLevelHint(n),
        art: _LevelSeal(n),
      );
    case 'game':
      final g = minigames.where((g) => g.id == parts[1]).firstOrNull;
      if (g == null) return null;
      return Milestone(title: tr('milestone.game'), lines: [g.name, g.description], art: _GlyphSeal(g.icon));
    case 'exp':
      return Milestone(
        title: tr('milestone.place'),
        lines: [tr('exp.${parts[1]}.name'), tr('exp.${parts[1]}.desc')],
        art: const _GlyphSeal(Icons.landscape_rounded),
      );
    case 'up':
      final game = parts[1];
      final tier = int.parse(parts[2]);
      return Milestone(
        title: tr('milestone.upgrade'),
        lines: [tr('mg.$game.name'), tr('up.t$tier')],
        art: _GlyphSeal(minigames.where((g) => g.id == game).firstOrNull?.icon ?? Icons.auto_awesome_rounded),
      );
    case 'ach':
      return Milestone(
        title: tr('milestone.ach'),
        lines: [
          tr('ach.${parts[1]}'),
          if (Achievements.all.where((a) => a.id == parts[1]).firstOrNull case final a?)
            tr('ach.${a.id}.how', {'n': Achievements.instance.measure(a).target}),
        ],
        art: _GlyphSeal(achievementIcon(parts[1])),
      );
    case 'chest':
      return Milestone(
        title: tr('milestone.chest'),
        lines: [
          tr('milestone.chest.sub', {'n': p.dailyGoals.chest.target}),
        ],
        next: tr('milestone.chest.next'),
        art: const _GlyphSeal(Icons.inventory_2_rounded),
      );
    case 'cloud':
      return Milestone(
        title: tr('milestone.cloud'),
        lines: [tr('milestone.cloud.sub')],
        art: const _GlyphSeal(Icons.cloud_done_rounded),
      );
    case 'decor':
      final d = p.decor.where((d) => d.placed).lastOrNull;
      final item = d == null ? null : p.decorRules.byId(d.id);
      return Milestone(
        title: tr('milestone.firstDecor'),
        lines: [tr('milestone.firstDecor.sub')],
        next: tr('milestone.firstDecor.next'),
        art: item == null
            ? const _GlyphSeal(Icons.spa_rounded)
            : SizedBox(width: 96, height: 96, child: CustomPaint(painter: DecorPainter(item.id, item.aspect))),
      );
  }
  return null;
}

/// Lo que abre el próximo nivel, para saber a qué jugar.
String? _nextLevelHint(int n) {
  final p = Progress.instance;
  final next = n + 1;
  final what = [
    for (final g in p.gamesAtLevel(next)) tr('mg.$g.name'),
    for (final u in p.levels.unlocksAt(next)) unlockName(u),
    if (next == p.decorRules.minLevel) tr('milestone.decorAll'),
  ];
  if (what.isEmpty) return null;
  return tr('milestone.nextLevel', {'n': next, 'list': what.join(', ')});
}

/// El aviso grande: una tarjeta de washi que entra con un rebote suave, con
/// un halo que respira y rayos que giran despacio detrás. Se cierra al tocar.
Future<void> showMilestone(BuildContext context, Milestone m) {
  SoundBoard.instance.play(Sfx.bell, volume: 0.7);
  Haptics.perfect();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: m.title,
    barrierColor: Palette.ink.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 520),
    pageBuilder: (context, _, _) => _MilestoneView(m),
    transitionBuilder: (context, anim, _, child) {
      final t = anim.value;
      return Opacity(
        opacity: Curves.easeOut.transform(t.clamp(0.0, 1.0)),
        child: Transform.scale(scale: 0.92 + 0.08 * Curves.easeOutCubic.transform(t), child: child),
      );
    },
  );
}

class _MilestoneView extends StatefulWidget {
  final Milestone m;
  const _MilestoneView(this.m);

  @override
  State<_MilestoneView> createState() => _MilestoneViewState();
}

class _MilestoneViewState extends State<_MilestoneView> with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(vsync: this, duration: const Duration(seconds: 24))..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SoundBoard.instance.play(Sfx.uiTap, volume: 0.3);
        Navigator.of(context).pop();
      },
      child: SafeArea(
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    left: -80,
                    right: -80,
                    top: -80,
                    bottom: -80,
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _spin,
                        builder: (context, _) => CustomPaint(painter: _RaysPainter(_spin.value)),
                      ),
                    ),
                  ),
                  WashiCard(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        m.art,
                        const SizedBox(height: 14),
                        Text(
                          m.title,
                          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        if (m.lines.isNotEmpty) const SizedBox(height: 10),
                        for (final l in m.lines)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(l, style: text.titleMedium, textAlign: TextAlign.center),
                          ),
                        if (m.next != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            m.next!,
                            style: text.bodyMedium?.copyWith(color: Palette.ink.withValues(alpha: 0.75)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          tr('milestone.tap'),
                          style: text.labelMedium?.copyWith(color: Palette.ink.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un halo cálido que respira con rayos suaves que giran.
class _RaysPainter extends CustomPainter {
  final double t;
  _RaysPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * 0.62;
    final breathe = 0.85 + 0.15 * sin(t * 2 * pi * 6);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Palette.lantern.withValues(alpha: 0.55 * breathe),
            Palette.lantern.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(t * 2 * pi);
    final ray = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFFFF4D6).withValues(alpha: 0.5), const Color(0x00FFF4D6)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r * 1.2));
    for (var i = 0; i < 12; i++) {
      final a = i * pi / 6;
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(cos(a - 0.09) * r * 1.2, sin(a - 0.09) * r * 1.2)
        ..lineTo(cos(a + 0.09) * r * 1.2, sin(a + 0.09) * r * 1.2)
        ..close();
      canvas.drawPath(path, ray);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.t != t;
}

/// El número del nivel, en un sello de farol.
class _LevelSeal extends StatelessWidget {
  final int level;
  const _LevelSeal(this.level);

  @override
  Widget build(BuildContext context) => _Seal(
    child: Text(
      '$level',
      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Palette.paper, height: 1),
    ),
  );
}

class _GlyphSeal extends StatelessWidget {
  final IconData icon;
  const _GlyphSeal(this.icon);

  @override
  Widget build(BuildContext context) => _Seal(child: Icon(icon, size: 40, color: Palette.paper));
}

class _Seal extends StatelessWidget {
  final Widget child;
  const _Seal({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: 84,
    height: 84,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(colors: [Color(0xFFE8A85A), Palette.lantern, Color(0xFFB0662A)]),
      border: Border.all(color: Palette.paper, width: 3),
      boxShadow: [BoxShadow(color: Palette.lantern.withValues(alpha: 0.6), blurRadius: 18)],
    ),
    child: child,
  );
}
