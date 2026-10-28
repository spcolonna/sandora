import 'dart:math';

import 'package:flutter/material.dart';

import '../../garden/day_cycle.dart';
import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../fx/calm.dart';
import '../fx/sfx.dart';
import '../theme/palette.dart';
import '../widgets/currency.dart';
import '../widgets/garden_sign.dart';
import 'garden_scene.dart';

/// El jardín es el menú: cada lugar se toca para entrar (minijuegos, Mercado,
/// tablón, meditación). Cambia con la hora del dispositivo y, según el
/// momento, deja regalos para juntar (rocío al amanecer, luciérnagas de noche).
class GardenView extends StatefulWidget {
  final void Function(Place place) onPlace;

  /// Hora que ve el jardín; se actualiza desde afuera cada tanto.
  final DateTime now;

  const GardenView({super.key, required this.onPlace, required this.now});

  @override
  State<GardenView> createState() => _GardenViewState();
}

class _GardenViewState extends State<GardenView> with SingleTickerProviderStateMixin {
  /// Reloj de lo que se mueve (nubes, estrellas, luciérnagas), en segundos.
  late final _life = AnimationController(vsync: this, duration: const Duration(seconds: 120))..repeat();
  final _pops = <_Pop>[];

  /// Regalos tocados en esta visita (id + lugar), para que los que quedan no
  /// cambien de sitio.
  final _gone = <String>{};
  var _popId = 0;

  double get _t => _life.value * 120;

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  void _take(DayGift g, int index, Offset at) {
    if (!Progress.instance.takeGift(g, now: widget.now)) return;
    _gone.add('${g.id}$index');
    SoundBoard.instance.play(Sfx.good, volume: 0.4);
    Haptics.light();
    final pop = _Pop(_popId++, g, at);
    setState(() => _pops.add(pop));
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _pops.remove(pop));
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final cycle = p.dayCycle;
    final now = widget.now;
    final daylight = cycle.daylight(now), warmth = cycle.warmth(now);
    return LayoutBuilder(
      builder: (context, box) {
        final layout = GardenLayout(box.biggest, p.patioSize);
        return Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: GardenPainter(
                    layout: layout,
                    tower: p.tower,
                    drawing: p.sandDrawing,
                    meditationOpen: p.meditationUnlocked,
                    daylight: daylight,
                    warmth: warmth,
                    arc: cycle.arc(now),
                    morning: now.hour < 12,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SkyLifePainter(_life, daylight: daylight, warmth: warmth),
                ),
              ),
            ),
            for (final e in layout.places.entries)
              Positioned.fromRect(
                rect: e.value,
                child: _PlaceArea(onTap: () => widget.onPlace(e.key)),
              ),
            for (final e in layout.labels.entries)
              _Label(at: e.value, place: e.key, onTap: () => widget.onPlace(e.key)),
            _TowerCollect(above: layout.places[Place.stack]!),
            for (final g in cycle.giftsAt(now))
              for (final i in [
                for (var i = 0; i < g.daily; i++)
                  if (!_gone.contains('${g.id}$i')) i,
              ].take(p.giftsLeft(g, now: now)))
                _GiftSpot(
                  key: ValueKey('${g.id}$i'),
                  gift: g,
                  index: i,
                  layout: layout,
                  life: _life,
                  seconds: () => _t,
                  onTake: (at) => _take(g, i, at),
                ),
            for (final pop in _pops) _PopUp(key: ValueKey(pop.id), pop: pop),
            const Positioned(left: 12, top: 4, child: GardenSign()),
            Positioned(right: 10, top: 10, child: _MomentChip(now: now)),
          ],
        );
      },
    );
  }
}

/// Zona tocable de un lugar: un velo de luz suave mientras se apoya el dedo.
class _PlaceArea extends StatefulWidget {
  final VoidCallback onTap;
  const _PlaceArea({required this.onTap});

  @override
  State<_PlaceArea> createState() => _PlaceAreaState();
}

class _PlaceAreaState extends State<_PlaceArea> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedOpacity(
        opacity: _down ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Calm.curve,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: RadialGradient(colors: [Colors.white.withValues(alpha: 0.28), Colors.white.withValues(alpha: 0)]),
          ),
        ),
      ),
    );
  }
}

/// Cartelito de papel con el nombre del lugar.
class _Label extends StatelessWidget {
  final Offset at;
  final Place place;
  final VoidCallback onTap;
  const _Label({required this.at, required this.place, required this.onTap});

  static String nameOf(Place p) => switch (p) {
    Place.market => tr('shop.title'),
    Place.board => tr('board.title'),
    Place.meditation => tr('meditation.title'),
    Place.sand => tr('mg.sand.name'),
    Place.stack => tr('mg.stack.name'),
    Place.rain => tr('mg.rain.name'),
  };

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final locked = place == Place.meditation && !p.meditationUnlocked;
    final text = locked ? '${nameOf(place)} · ${tr('level.short', {'n': p.levels.meditationLevel})}' : nameOf(place);
    return Positioned(
      left: at.dx,
      top: at.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Palette.paper.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Palette.wood.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(color: Palette.ink.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (locked) ...[
                  const Icon(Icons.lock_rounded, size: 13, color: Palette.stoneDark),
                  const SizedBox(width: 4),
                ],
                Text(
                  text,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Palette.ink),
                ),
                if (place == Place.meditation && p.meditationStreak > 0 && !locked) ...[
                  const SizedBox(width: 6),
                  Text('· ${p.meditationStreak}', style: const TextStyle(fontSize: 12, color: Palette.stoneDark)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lo que la torre juntó: aparece arriba de ella para cobrarlo con un toque.
class _TowerCollect extends StatelessWidget {
  final Rect above;
  const _TowerCollect({required this.above});

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final pending = p.towerPending();
    return Positioned(
      left: above.center.dx,
      top: above.top,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: AnimatedSwitcher(
          duration: Calm.appear,
          child: pending <= 0
              ? const SizedBox.shrink()
              : GestureDetector(
                  key: const ValueKey('collect'),
                  onTap: () {
                    p.collectTower();
                    SoundBoard.instance.play(Sfx.stackPlace, volume: 0.6);
                    Haptics.medium();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Palette.paper,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Palette.lantern, width: 1.5),
                      boxShadow: [BoxShadow(color: Palette.lantern.withValues(alpha: 0.4), blurRadius: 10)],
                    ),
                    child: CurrencyChip.pebbles(pending, prefix: '+'),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Un regalo del momento del día puesto en el jardín: una gota de rocío que
/// brilla en el pasto o una luciérnaga que flota. Se toca para juntarlo.
class _GiftSpot extends StatelessWidget {
  final DayGift gift;
  final int index;
  final GardenLayout layout;
  final Animation<double> life;
  final double Function() seconds;
  final void Function(Offset at) onTake;

  const _GiftSpot({
    super.key,
    required this.gift,
    required this.index,
    required this.layout,
    required this.life,
    required this.seconds,
    required this.onTake,
  });

  static const _size = 48.0;

  /// Lugares fijos (fracciones del jardín) para cada regalo.
  static const _spots = {
    'dew': [Offset(0.05, 0.64), Offset(0.37, 0.57), Offset(0.95, 0.9)],
    'firefly': [Offset(0.3, 0.5), Offset(0.62, 0.42), Offset(0.88, 0.62)],
  };

  bool get _flies => gift.phase == DayPhase.night;

  Offset _at(double t) {
    final spots = _spots[gift.id] ?? _spots['dew']!;
    final f = spots[index % spots.length];
    final base = Offset(f.dx * layout.size.width, f.dy * layout.size.height);
    if (!_flies) return base;
    return base + Offset(18 * sin(t * 0.5 + index * 2.1), 12 * sin(t * 0.8 + index * 1.3));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: life,
      builder: (context, _) {
        final t = seconds();
        final at = _at(t);
        final pulse = 0.6 + 0.4 * sin(t * (_flies ? 2.2 : 1.4) + index * 1.7);
        return Positioned(
          left: at.dx - _size / 2,
          top: at.dy - _size / 2,
          width: _size,
          height: _size,
          child: Semantics(
            button: true,
            label: tr('gift.${gift.id}'),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTake(at),
              child: CustomPaint(
                painter: _GiftPainter(flies: _flies, pulse: pulse),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GiftPainter extends CustomPainter {
  final bool flies;
  final double pulse;
  _GiftPainter({required this.flies, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    if (flies) {
      const glow = Color(0xFFE4F59A);
      canvas.drawCircle(
        c,
        16,
        Paint()
          ..shader = RadialGradient(
            colors: [
              glow.withValues(alpha: 0.55 * pulse),
              glow.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: 16)),
      );
      canvas.drawCircle(c, 3, Paint()..color = const Color(0xFFF7FFD6));
    } else {
      final drop = Path()
        ..moveTo(c.dx, c.dy - 8)
        ..quadraticBezierTo(c.dx + 6, c.dy + 1, c.dx, c.dy + 5)
        ..quadraticBezierTo(c.dx - 6, c.dy + 1, c.dx, c.dy - 8);
      canvas.drawCircle(c, 13, Paint()..color = Colors.white.withValues(alpha: 0.18 * pulse));
      canvas.drawPath(drop, Paint()..color = const Color(0xFFD6F0F4).withValues(alpha: 0.95));
      canvas.drawCircle(c + const Offset(-1.5, -1), 1.6, Paint()..color = Colors.white.withValues(alpha: pulse));
    }
  }

  @override
  bool shouldRepaint(_GiftPainter old) => old.pulse != pulse || old.flies != flies;
}

class _Pop {
  final int id;
  final DayGift gift;
  final Offset at;
  _Pop(this.id, this.gift, this.at);
}

/// Lo que dio un regalo, subiendo y desvaneciéndose donde se tocó.
class _PopUp extends StatelessWidget {
  final _Pop pop;
  const _PopUp({super.key, required this.pop});

  @override
  Widget build(BuildContext context) {
    final e = pop.gift.give.entries.first;
    return Positioned(
      left: pop.at.dx,
      top: pop.at.dy - 20,
      child: IgnorePointer(
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOut,
            builder: (context, v, child) => Opacity(
              opacity: v < 0.25 ? v / 0.25 : (1 - v) / 0.75,
              child: Transform.translate(offset: Offset(0, -26 * v), child: child),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Palette.paper.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: CurrencyChip.of(e.key, e.value, prefix: '+'),
            ),
          ),
        ),
      ),
    );
  }
}

/// Momento del día y, si hay, el regalo que dejó en el jardín.
class _MomentChip extends StatelessWidget {
  final DateTime now;
  const _MomentChip({required this.now});

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final phase = p.dayCycle.phaseAt(now);
    final gifts = p.dayCycle.giftsAt(now);
    final left = gifts.fold(0, (n, g) => n + p.giftsLeft(g, now: now));
    final icon = switch (phase) {
      DayPhase.dawn => Icons.wb_twilight_rounded,
      DayPhase.day => Icons.wb_sunny_rounded,
      DayPhase.dusk => Icons.wb_twilight_rounded,
      DayPhase.night => Icons.nightlight_round,
    };
    return GestureDetector(
      onTap: () {
        final hint = gifts.isEmpty ? tr('moment.${phase.name}.hint') : tr('gift.${gifts.first.id}.hint');
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(hint), behavior: SnackBarBehavior.floating));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Palette.paper.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: phase == DayPhase.night ? Palette.dusk : Palette.lantern),
            const SizedBox(width: 6),
            Text(tr('moment.${phase.name}'), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            if (left > 0) ...[
              const SizedBox(width: 6),
              Text('· ${tr('gift.${gifts.first.id}')} ×$left', style: const TextStyle(fontSize: 12.5)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lo vivo del cielo: nubes que pasan de día y estrellas que titilan de noche.
class _SkyLifePainter extends CustomPainter {
  final Animation<double> life;
  final double daylight, warmth;
  _SkyLifePainter(this.life, {required this.daylight, required this.warmth}) : super(repaint: life);

  @override
  void paint(Canvas canvas, Size size) {
    final t = life.value * 120;
    final w = size.width, h = size.height;
    final night = 1 - daylight;
    if (night > 0.05) {
      final rng = Random(21);
      for (var i = 0; i < 34; i++) {
        final o = Offset(rng.nextDouble() * w, rng.nextDouble() * h * 0.3);
        final tw = 0.55 + 0.45 * sin(t * (0.6 + rng.nextDouble()) + i);
        canvas.drawCircle(
          o,
          0.6 + rng.nextDouble() * 1.1,
          Paint()..color = Colors.white.withValues(alpha: night * tw * 0.85),
        );
      }
    }
    final cloud = Color.lerp(Colors.white, const Color(0xFFF6D3B8), warmth)!;
    final a = (0.08 + 0.6 * daylight).clamp(0.0, 0.7);
    for (var i = 0; i < 3; i++) {
      final speed = 3.0 + i * 1.6;
      final span = w + 160;
      final x = (i * 157 + t * speed) % span - 80;
      final y = h * (0.06 + 0.05 * i);
      final p = Paint()..color = cloud.withValues(alpha: a);
      for (final (dx, dy, r) in [(0.0, 0.0, 16.0), (18.0, -6.0, 20.0), (38.0, 0.0, 15.0), (20.0, 6.0, 16.0)]) {
        canvas.drawCircle(Offset(x + dx, y + dy), r * (0.8 + 0.1 * i), p);
      }
    }
  }

  @override
  bool shouldRepaint(_SkyLifePainter old) => old.daylight != daylight || old.warmth != warmth;
}
