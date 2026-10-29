import 'package:flutter/material.dart';

import '../garden/progress.dart';
import '../i18n/i18n.dart';
import '../minigames/sand/sand_shapes.dart';
import 'fx/calm.dart';
import 'fx/sfx.dart';
import 'garden/garden_view.dart';
import 'theme/palette.dart';

/// Una cosa del álbum: si ya se tiene, cómo se dibuja, cómo se llama y cómo
/// se consigue.
class _Item {
  final bool owned;
  final String name, how;
  final Widget art;

  /// Si se dibuja sobre fondo de noche (los regalos son claros y brillan).
  final bool night;
  const _Item({required this.owned, required this.name, required this.how, required this.art, this.night = false});
}

/// El álbum: las figuras dibujadas en la arena, los regalos del jardín, las
/// visitas a la casa de té y los objetos de la racha. Lo que falta se ve como
/// una sombra con la pista para conseguirlo.
Future<void> showAlbumSheet(BuildContext context) {
  Progress.instance.markAlbumSeen();
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => const _Album(),
  );
}

class _Album extends StatefulWidget {
  const _Album();

  @override
  State<_Album> createState() => _AlbumState();
}

class _AlbumState extends State<_Album> {
  /// La casilla tocada: debajo de su sección se dice qué es o cómo se consigue.
  (int, int)? _picked;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Progress.instance,
      builder: (context, _) {
        final p = Progress.instance;
        final text = Theme.of(context).textTheme;
        final sections = _sections(p);
        final owned = sections.fold(0, (n, s) => n + s.$2.where((i) => i.owned).length);
        final total = sections.fold(0, (n, s) => n + s.$2.length);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          builder: (context, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text(tr('album.title'), style: text.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                tr('album.count', {'n': owned, 't': total}),
                style: text.bodyMedium?.copyWith(color: Palette.ink.withValues(alpha: 0.65)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : owned / total,
                  minHeight: 6,
                  color: Palette.lantern,
                  backgroundColor: Palette.sandShadow.withValues(alpha: 0.35),
                ),
              ),
              for (final (si, (title, items)) in sections.indexed) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(title, style: text.titleSmall),
                    const Spacer(),
                    Text(
                      '${items.where((i) => i.owned).length}/${items.length}',
                      style: text.bodySmall?.copyWith(color: Palette.ink.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: [
                    for (final (i, item) in items.indexed)
                      CalmAppear(
                        delay: Duration(milliseconds: 60 * si + 30 * i),
                        fromScale: 0.9,
                        rise: 6,
                        child: _Tile(
                          item,
                          picked: _picked == (si, i),
                          onTap: () {
                            SoundBoard.instance.play(Sfx.uiTap, volume: 0.4);
                            setState(() => _picked = _picked == (si, i) ? null : (si, i));
                          },
                        ),
                      ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Calm.curve,
                  alignment: Alignment.topCenter,
                  child: _picked?.$1 == si ? _Caption(items[_picked!.$2]) : const SizedBox(width: double.infinity),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Qué es lo tocado o, si falta, cómo conseguirlo.
class _Caption extends StatelessWidget {
  final _Item item;
  const _Caption(this.item);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Palette.lantern.withValues(alpha: item.owned ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            item.owned ? Icons.check_circle_rounded : Icons.lightbulb_outline_rounded,
            size: 18,
            color: Palette.wood,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.owned ? item.name : item.how,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

List<(String, List<_Item>)> _sections(Progress p) {
  final objects = p.economy.balance.meditation.strings('streakObjects');
  final every = p.economy.balance.meditation.i('streakObjectEvery');
  return [
    (
      tr('album.shapes'),
      [
        for (final s in SandShape.values)
          _Item(
            owned: p.found.contains('shape.${s.name}'),
            name: tr('sand.shape.${s.name}'),
            how: tr('album.how.shape'),
            art: CustomPaint(painter: _ShapePainter(s)),
          ),
      ],
    ),
    (
      tr('album.gifts'),
      [
        for (final g in p.dayCycle.gifts)
          _Item(
            owned: p.found.contains('gift.${g.id}'),
            name: tr('gift.${g.id}'),
            how: tr('gift.${g.id}.hint'),
            art: CustomPaint(painter: GiftPainter(look: giftLook(g.id), pulse: 0.8)),
            night: true,
          ),
      ],
    ),
    (
      tr('album.visitors'),
      [
        for (final v in p.teaVisits.visitors)
          _Item(
            owned: p.found.contains('visitor.${v.id}'),
            name: tr('album.visitor.${v.id}'),
            how: tr('album.how.visitor'),
            art: Icon(_visitorIcon(v.id), size: 30, color: Palette.ink),
          ),
      ],
    ),
    (
      tr('album.objects'),
      [
        for (final (i, o) in objects.indexed)
          _Item(
            owned: p.streakObjects.contains(o),
            name: tr('album.object.$o'),
            how: tr('album.how.object', {'n': every * (i + 1)}),
            art: Icon(_objectIcon(o), size: 30, color: Palette.wood),
          ),
      ],
    ),
  ];
}

IconData _visitorIcon(String id) => switch (id) {
  'monk' => Icons.self_improvement_rounded,
  'traveler' => Icons.hiking_rounded,
  'potter' => Icons.emoji_food_beverage_rounded,
  'gardener' => Icons.yard_rounded,
  'fisher' => Icons.phishing_rounded,
  _ => Icons.person_rounded,
};

IconData _objectIcon(String id) => switch (id) {
  'bowl' => Icons.notifications_rounded,
  'cushion' => Icons.event_seat_rounded,
  'lantern' => Icons.light_rounded,
  _ => Icons.star_rounded,
};

/// Una casilla del álbum. Lo que falta se ve apagado, con un signo de
/// pregunta; al tocarla se cuenta qué es o cómo conseguirlo.
class _Tile extends StatelessWidget {
  final _Item item;
  final bool picked;
  final VoidCallback onTap;
  const _Tile(this.item, {required this.picked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = !item.owned
        ? Palette.sandShadow.withValues(alpha: 0.3)
        : item.night
        ? Palette.dusk
        : Palette.paper;
    return Semantics(
      button: true,
      label: item.owned ? item.name : tr('album.locked'),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 66,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: picked
                        ? Palette.wood
                        : item.owned
                        ? Palette.lantern.withValues(alpha: 0.7)
                        : Colors.transparent,
                    width: picked ? 2.5 : 1.5,
                  ),
                ),
                child: item.owned
                    ? Padding(padding: const EdgeInsets.all(8), child: item.art)
                    : Icon(Icons.question_mark_rounded, color: Palette.ink.withValues(alpha: 0.3)),
              ),
              const SizedBox(height: 4),
              Text(
                item.owned ? item.name : '?',
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: Palette.ink.withValues(alpha: item.owned ? 0.85 : 0.4)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La figura de la arena, como un surco oscuro sobre fondo de arena.
class _ShapePainter extends CustomPainter {
  final SandShape shape;
  _ShapePainter(this.shape);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      Paint()..color = Palette.sand,
    );
    final pts = shapePoints(shape);
    final path = Path();
    for (final (i, q) in pts.indexed) {
      final o = Offset(q.x * size.width, q.y * size.height);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Palette.wood.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ShapePainter old) => old.shape != shape;
}
