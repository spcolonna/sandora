import 'dart:math';

import 'package:flutter/material.dart';

import '../../garden/day_cycle.dart';
import '../../garden/progress.dart';
import '../../garden/weather.dart';
import '../../garden/weather_service.dart';
import '../../i18n/i18n.dart';
import '../../minigames/enso/enso_ink.dart';
import '../fx/calm.dart';
import '../fx/sfx.dart';
import '../theme/palette.dart';
import '../widgets/currency.dart';
import '../widgets/garden_sign.dart';
import 'garden_scene.dart';

/// El jardín es el menú: cada lugar se toca para entrar (minijuegos, Mercado,
/// tablón, meditación). Cambia con la hora del dispositivo y el clima y, según
/// el momento, deja regalos para juntar (rocío al amanecer, luciérnagas de
/// noche, agua de lluvia en las vasijas, copos que brillan).
class GardenView extends StatefulWidget {
  final void Function(Place place) onPlace;

  /// Hora que ve el jardín; se actualiza desde afuera cada tanto.
  final DateTime now;
  final Weather weather;

  /// 0 el patio, 1 el estanque.
  final int side;

  const GardenView({super.key, required this.onPlace, required this.now, required this.weather, this.side = 0});

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

  /// Cuándo paró la lluvia y si todavía se ve el arcoíris.
  DateTime? get _stoppedAt => WeatherService.instance.rainStoppedAt(widget.now);
  bool get _afterRain => _rainbowTime(widget.now);

  void _take(DayGift g, int index, Offset at) {
    if (!Progress.instance.takeGift(g, weather: widget.weather, afterRain: _afterRain, now: widget.now)) return;
    _gone.add('${g.id}$index');
    SoundBoard.instance.play(Sfx.good, volume: 0.4);
    Haptics.light();
    final pop = _Pop(_popId++, g, at);
    setState(() => _pops.add(pop));
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _pops.remove(pop));
    });
  }

  List<double>? _inkFlat;
  SavedInk? _ink;

  /// El ensō guardado, decodificado una sola vez por trazo.
  SavedInk? _ensoInk(List<double>? flat) {
    if (!identical(flat, _inkFlat)) {
      _inkFlat = flat;
      _ink = SavedInk.fromFlat(flat);
    }
    return _ink;
  }

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final cycle = p.dayCycle;
    final now = widget.now;
    final weather = widget.weather;
    final daylight = cycle.daylight(now), warmth = cycle.warmth(now);
    final overcast = switch (weather) {
      Weather.clear => 0.0,
      Weather.cloudy => 0.45,
      Weather.fog => 0.55,
      Weather.snow => 0.6,
      Weather.rain => 0.75,
      Weather.storm => 0.95,
    };
    final rules = WeatherService.instance.rules;
    final afterRain = _afterRain;
    final wet = rules.wetness(weather, now, _stoppedAt);
    // El arcoíris se ve de día y se va apagando a medida que pasa el rato.
    final rainbow = afterRain && (weather == Weather.clear || weather == Weather.cloudy)
        ? daylight * (1 - now.difference(_stoppedAt!).inSeconds / rules.rainbowFor.inSeconds).clamp(0.0, 1.0)
        : 0.0;
    return LayoutBuilder(
      builder: (context, box) {
        final layout = GardenLayout(box.biggest, p.patioSize, side: widget.side);
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
                    moss: p.best('moss') / 100,
                    daylight: daylight,
                    warmth: warmth,
                    arc: cycle.arc(now),
                    morning: now.hour < 12,
                    overcast: overcast,
                    snowy: weather == Weather.snow,
                    wet: wet,
                    rainbow: rainbow,
                    streakObjects: p.streakObjects,
                    ensoInk: _ensoInk(p.ensoInk),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SkyLifePainter(
                    _life,
                    daylight: daylight,
                    warmth: warmth,
                    weather: weather,
                    windy: rules.windy(weather, now),
                  ),
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
            if (widget.side == 0) _TowerCollect(above: layout.places[Place.stack]!),
            if (widget.side == 0)
              for (final g in cycle.giftsAt(now, weather, afterRain: afterRain))
                for (final i in [
                  for (var i = 0; i < g.daily; i++)
                    if (!_gone.contains('${g.id}$i')) i,
                ].take(p.giftsLeft(g, weather: weather, afterRain: afterRain, now: now)))
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
            // Primera partida guiada: primero un lugar para jugar, después el Mercado.
            if (widget.side == 0 && p.gardenNameOffered && p.guideStep == 0)
              _GuideHint(key: const ValueKey('guide0'), around: layout.places[Place.sand]!, text: tr('guide.play')),
            if (widget.side == 0 && p.guideStep == 1)
              _GuideHint(
                key: const ValueKey('guide1'),
                around: layout.places[Place.market]!,
                text: tr('guide.market'),
                below: true,
                onTap: () => p.advanceGuide(2),
              ),
            const Positioned(left: 12, top: 4, child: GardenSign()),
            Positioned(
              right: 10,
              top: 10,
              child: _MomentChip(now: now, weather: weather),
            ),
          ],
        );
      },
    );
  }
}

/// Un brillo que late alrededor de un lugar y una burbuja que dice qué hacer.
/// Sin [onTap] no tapa los toques: el lugar se sigue pudiendo tocar.
class _GuideHint extends StatefulWidget {
  final Rect around;
  final String text;
  final bool below;
  final VoidCallback? onTap;
  const _GuideHint({super.key, required this.around, required this.text, this.below = false, this.onTap});

  @override
  State<_GuideHint> createState() => _GuideHintState();
}

class _GuideHintState extends State<_GuideHint> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.around;
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Palette.paper,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Palette.ink.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Text(
        widget.text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Palette.ink),
      ),
    );
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fromRect(
            rect: r.inflate(6),
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Palette.lantern.withValues(alpha: 0.4 + 0.5 * _c.value), width: 3),
                    color: Palette.lantern.withValues(alpha: 0.08 * _c.value),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: widget.below ? r.bottom + 12 : max(8, r.top - 64),
            child: Center(
              child: CalmAppear(
                delay: const Duration(milliseconds: 400),
                child: widget.onTap == null
                    ? IgnorePointer(child: bubble)
                    : GestureDetector(onTap: widget.onTap, child: bubble),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Si paró de llover hace poco (todavía se ve el arcoíris).
bool _rainbowTime(DateTime now) {
  final ws = WeatherService.instance;
  final at = ws.rainStoppedAt(now);
  return at != null && now.difference(at) < ws.rules.rainbowFor;
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
    Place.pond ||
    Place.shishi ||
    Place.leaves ||
    Place.moss ||
    Place.bonsai ||
    Place.enso ||
    Place.bell => tr('mg.${p.name}.name'),
  };

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final zone = p.unlockZone(place.name);
    final (locked, why) = switch (place) {
      Place.meditation => (!p.meditationUnlocked, tr('level.short', {'n': p.levels.meditationLevel})),
      Place.market || Place.board => (false, ''),
      _ when zone != null => (!p.gameUnlocked(place.name), tr('level.short', {'n': zone.level})),
      _ => (!p.gameUnlocked(place.name), tr('garden.lockedDay', {'n': p.unlockDay(place.name)})),
    };
    final text = locked ? '${nameOf(place)} · $why' : nameOf(place);
    // Centrado en su lugar, pero sin salirse del jardín (los nombres largos
    // con candado no entran cerca de los bordes).
    return Positioned.fill(
      child: CustomSingleChildLayout(
        delegate: _LabelLayout(at),
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

class _LabelLayout extends SingleChildLayoutDelegate {
  final Offset at;
  _LabelLayout(this.at);

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size child) =>
      Offset((at.dx - child.width / 2).clamp(6, max(6, size.width - child.width - 6)), at.dy - child.height / 2);

  @override
  bool shouldRelayout(_LabelLayout old) => old.at != at;
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

/// Un regalo puesto en el jardín: una gota de rocío que brilla en el pasto,
/// una luciérnaga que flota, agua de lluvia sobre las vasijas o un copo que
/// brilla al caer. Se toca para juntarlo.
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

  /// Lugares fijos (fracciones del jardín) para cada regalo; el agua de lluvia
  /// va sobre las vasijas.
  static const _spots = {
    'dew': [Offset(0.05, 0.64), Offset(0.37, 0.57), Offset(0.95, 0.9)],
    'firefly': [Offset(0.3, 0.5), Offset(0.62, 0.42), Offset(0.88, 0.62)],
    'snowflake': [Offset(0.24, 0.36), Offset(0.7, 0.3)],
    'rainbow': [Offset(0.5, 0.27)],
    'seed': [Offset(0.15, 0.4), Offset(0.6, 0.46)],
    'lastray': [Offset(0.82, 0.4)],
  };

  _GiftLook get _look => switch (gift.id) {
    'firefly' => _GiftLook.firefly,
    'snowflake' => _GiftLook.flake,
    'rainjar' => _GiftLook.rain,
    'rainbow' => _GiftLook.rainbow,
    'seed' => _GiftLook.seed,
    'lastray' => _GiftLook.ray,
    _ => _GiftLook.dew,
  };

  Offset _base() {
    if (gift.id == 'rainjar') {
      // Sobre la boca de las vasijas (ver _paintJars en garden_scene.dart).
      final r = layout.places[Place.rain]!;
      final slot = r.width * 0.6 / 4;
      final jh = min(slot * 0.74, r.height * 1.1) * 0.82;
      return Offset(r.left + slot * ([0, 2, 3][index % 3] + 0.5), r.center.dy - jh / 2 - 16);
    }
    final spots = _spots[gift.id] ?? _spots['dew']!;
    final f = spots[index % spots.length];
    return Offset(f.dx * layout.size.width, f.dy * layout.size.height);
  }

  Offset _at(double t) {
    final base = _base();
    return switch (_look) {
      _GiftLook.firefly => base + Offset(18 * sin(t * 0.5 + index * 2.1), 12 * sin(t * 0.8 + index * 1.3)),
      // El copo baja despacio meciéndose y vuelve a empezar.
      _GiftLook.flake => base + Offset(14 * sin(t * 0.7 + index), 40 * (((t * 0.06 + index * 0.37) % 1) - 0.5)),
      _GiftLook.rain => base + Offset(0, 3 * sin(t * 1.6 + index)),
      // La semilla de diente de león flota y va y viene con la brisa.
      _GiftLook.seed => base + Offset(30 * sin(t * 0.25 + index * 2), 10 * sin(t * 0.9 + index)),
      _GiftLook.rainbow || _GiftLook.ray => base + Offset(0, 4 * sin(t * 0.8 + index)),
      _GiftLook.dew => base,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: life,
      builder: (context, _) {
        final t = seconds();
        final at = _at(t);
        final pulse = 0.6 + 0.4 * sin(t * (_look == _GiftLook.dew ? 1.4 : 2.2) + index * 1.7);
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
                painter: _GiftPainter(look: _look, pulse: pulse),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _GiftLook { dew, firefly, rain, flake, rainbow, seed, ray }

class _GiftPainter extends CustomPainter {
  final _GiftLook look;
  final double pulse;
  _GiftPainter({required this.look, required this.pulse});

  void _glow(Canvas canvas, Offset c, Color color, double r, double a) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: a),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    switch (look) {
      case _GiftLook.firefly:
        _glow(canvas, c, const Color(0xFFE4F59A), 16, 0.55 * pulse);
        canvas.drawCircle(c, 3, Paint()..color = const Color(0xFFF7FFD6));
      case _GiftLook.flake:
        _glow(canvas, c, Colors.white, 16, 0.6 * pulse);
        final arm = Paint()
          ..color = Colors.white
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 6; i++) {
          final d = Offset.fromDirection(i * pi / 3, 7);
          canvas.drawLine(c - d, c + d, arm);
          canvas.drawLine(c + d * 0.55, c + d * 0.55 + Offset.fromDirection(i * pi / 3 + 0.7, 3), arm);
          canvas.drawLine(c + d * 0.55, c + d * 0.55 + Offset.fromDirection(i * pi / 3 - 0.7, 3), arm);
        }
      case _GiftLook.rainbow:
        // Una gota que refleja el arcoíris.
        _glow(canvas, c, const Color(0xFFFFF3C4), 18, 0.55 * pulse);
        canvas.drawCircle(
          c,
          7,
          Paint()
            ..shader = const SweepGradient(
              colors: [
                Color(0xFFE57373),
                Color(0xFFFFB74D),
                Color(0xFFFFF176),
                Color(0xFF81C784),
                Color(0xFF64B5F6),
                Color(0xFF9575CD),
                Color(0xFFE57373),
              ],
            ).createShader(Rect.fromCircle(center: c, radius: 7)),
        );
        canvas.drawCircle(c + const Offset(-2, -2), 2, Paint()..color = Colors.white.withValues(alpha: 0.8));
      case _GiftLook.seed:
        // Vilano: un tallito con pelos finos en abanico.
        _glow(canvas, c, Colors.white, 14, 0.35 * pulse);
        final hair = Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round;
        final top = c + const Offset(0, -2);
        for (var i = 0; i < 9; i++) {
          canvas.drawLine(top, top + Offset.fromDirection(-pi + pi * i / 8, 8), hair);
        }
        canvas.drawLine(top, c + const Offset(0, 8), hair..color = const Color(0xFFD8CBB0));
        canvas.drawCircle(c + const Offset(0, 8), 1.6, Paint()..color = Palette.wood);
      case _GiftLook.ray:
        // Destello dorado del último rayo de sol.
        _glow(canvas, c, Palette.lantern, 18, 0.6 * pulse);
        final beam = Paint()
          ..color = const Color(0xFFFFE6A8).withValues(alpha: 0.9)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 4; i++) {
          final d = Offset.fromDirection(i * pi / 4, 4 + 5 * pulse);
          canvas.drawLine(c - d, c + d, beam);
        }
        canvas.drawCircle(c, 2.4, Paint()..color = Colors.white);
      case _GiftLook.dew || _GiftLook.rain:
        final rain = look == _GiftLook.rain;
        final drop = Path()
          ..moveTo(c.dx, c.dy - 8)
          ..quadraticBezierTo(c.dx + 6, c.dy + 1, c.dx, c.dy + 5)
          ..quadraticBezierTo(c.dx - 6, c.dy + 1, c.dx, c.dy - 8);
        if (rain) {
          _glow(canvas, c, const Color(0xFFBFE6F5), 15, 0.5 * pulse);
        } else {
          canvas.drawCircle(c, 13, Paint()..color = Colors.white.withValues(alpha: 0.18 * pulse));
        }
        canvas.drawPath(
          drop,
          Paint()..color = (rain ? const Color(0xFF9FD3EA) : const Color(0xFFD6F0F4)).withValues(alpha: 0.95),
        );
        canvas.drawCircle(c + const Offset(-1.5, -1), 1.6, Paint()..color = Colors.white.withValues(alpha: pulse));
    }
  }

  @override
  bool shouldRepaint(_GiftPainter old) => old.pulse != pulse || old.look != look;
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

IconData _weatherIcon(Weather w, DayPhase phase) => switch (w) {
  Weather.clear => switch (phase) {
    DayPhase.night => Icons.nightlight_round,
    DayPhase.day => Icons.wb_sunny_rounded,
    _ => Icons.wb_twilight_rounded,
  },
  Weather.cloudy => Icons.cloud_rounded,
  Weather.rain => Icons.water_drop_rounded,
  Weather.storm => Icons.thunderstorm_rounded,
  Weather.fog => Icons.foggy,
  Weather.snow => Icons.ac_unit_rounded,
};

/// Momento del día, clima y, si hay, el regalo que dejaron en el jardín. Se
/// toca para ver qué pasa y elegir el clima de donde está el jugador.
class _MomentChip extends StatelessWidget {
  final DateTime now;
  final Weather weather;
  const _MomentChip({required this.now, required this.weather});

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final phase = p.dayCycle.phaseAt(now);
    final after = _rainbowTime(now);
    final gifts = p.dayCycle.giftsAt(now, weather, afterRain: after);
    final left = gifts.fold(0, (n, g) => n + p.giftsLeft(g, weather: weather, afterRain: after, now: now));
    final open = gifts.where((g) => p.giftsLeft(g, weather: weather, afterRain: after, now: now) > 0).firstOrNull;
    return GestureDetector(
      onTap: () => _showNowSheet(context, now: now, weather: weather),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Palette.paper.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _weatherIcon(weather, phase),
              size: 16,
              color: weather == Weather.clear && phase != DayPhase.night ? Palette.lantern : Palette.dusk,
            ),
            const SizedBox(width: 6),
            Text(
              weather == Weather.clear ? tr('moment.${phase.name}') : tr('weather.${weather.name}'),
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            if (open != null) ...[
              const SizedBox(width: 6),
              Text('· ${tr('gift.${open.id}')} ×$left', style: const TextStyle(fontSize: 12.5)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Qué pasa ahora en el jardín (momento, clima, regalos) y la opción de usar
/// el clima de donde está el jugador.
Future<void> _showNowSheet(BuildContext context, {required DateTime now, required Weather weather}) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => ListenableBuilder(
      listenable: WeatherService.instance,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final ws = WeatherService.instance;
        final p = Progress.instance;
        final phase = p.dayCycle.phaseAt(now);
        final w = ws.at(now);
        final gifts = p.dayCycle.giftsAt(now, w, afterRain: _rainbowTime(now));
        final hint = gifts.isEmpty ? tr('moment.${phase.name}.hint') : tr('gift.${gifts.first.id}.hint');
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Text(tr('weather.title'), style: text.titleLarge)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(_weatherIcon(w, phase), color: Palette.moss),
                    const SizedBox(width: 12),
                    Text('${tr('moment.${phase.name}')} · ${tr('weather.${w.name}')}', style: text.titleSmall),
                  ],
                ),
                const SizedBox(height: 8),
                Text(hint, style: text.bodyMedium),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('weather.real.title')),
                  subtitle: Text(
                    ws.useReal ? tr('weather.real.desc') : '${tr('weather.own')} ${tr('weather.real.desc')}',
                  ),
                  value: ws.useReal,
                  onChanged: (on) async {
                    if (!on) return ws.disableReal();
                    final result = await ws.enableReal();
                    if (result == RealWeatherResult.ok || !context.mounted) return;
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            tr(result == RealWeatherResult.denied ? 'weather.real.denied' : 'weather.real.failed'),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                  },
                ),
                if (ws.isReal(now)) Text(tr('weather.source'), style: text.bodySmall),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Lo vivo del cielo: nubes que pasan, estrellas que titilan de noche y el
/// clima (lluvia, nieve, niebla, relámpagos lejanos).
class _SkyLifePainter extends CustomPainter {
  final Animation<double> life;
  final double daylight, warmth;
  final Weather weather;

  /// Si cruzan hojas con el viento.
  final bool windy;
  _SkyLifePainter(this.life, {required this.daylight, required this.warmth, required this.weather, this.windy = false})
    : super(repaint: life);

  bool get _wet => weather == Weather.rain || weather == Weather.storm;

  @override
  void paint(Canvas canvas, Size size) {
    final t = life.value * 120;
    final w = size.width, h = size.height;
    final night = 1 - daylight;
    if (night > 0.05 && (weather == Weather.clear || weather == Weather.cloudy)) {
      final rng = Random(21);
      final shown = weather == Weather.clear ? 1.0 : 0.35;
      for (var i = 0; i < 34; i++) {
        final o = Offset(rng.nextDouble() * w, rng.nextDouble() * h * 0.3);
        final tw = 0.55 + 0.45 * sin(t * (0.6 + rng.nextDouble()) + i);
        canvas.drawCircle(
          o,
          0.6 + rng.nextDouble() * 1.1,
          Paint()..color = Colors.white.withValues(alpha: night * tw * 0.85 * shown),
        );
      }
    }
    _paintClouds(canvas, size, t);
    if (windy) _paintWindLeaves(canvas, size, t);
    switch (weather) {
      case Weather.rain || Weather.storm:
        _paintRain(canvas, size, t);
        if (weather == Weather.storm) _paintFlash(canvas, size, t);
      case Weather.snow:
        _paintSnow(canvas, size, t);
      case Weather.fog:
        _paintFog(canvas, size, t);
      default:
    }
  }

  void _paintClouds(Canvas canvas, Size size, double t) {
    final w = size.width, h = size.height;
    final grey = switch (weather) {
      Weather.clear => 0.0,
      Weather.cloudy || Weather.fog || Weather.snow => 0.35,
      Weather.rain => 0.6,
      Weather.storm => 0.8,
    };
    final base = Color.lerp(Colors.white, const Color(0xFFF6D3B8), warmth * (1 - grey))!;
    final cloud = Color.lerp(base, const Color(0xFF6E7781), grey)!;
    final a = weather == Weather.clear ? (0.08 + 0.6 * daylight).clamp(0.0, 0.7) : 0.25 + 0.55 * daylight;
    final count = weather == Weather.clear ? 3 : 6;
    for (var i = 0; i < count; i++) {
      final speed = (3.0 + i * 1.6) * (_wet ? 1.6 : 1);
      final span = w + 160;
      final x = (i * 157 + t * speed) % span - 80;
      final y = h * (0.06 + 0.05 * (i % 3)) + (i >= 3 ? h * 0.02 : 0);
      final p = Paint()..color = cloud.withValues(alpha: a);
      final scale = 0.8 + 0.1 * (i % 3) + (i >= 3 ? 0.35 : 0);
      for (final (dx, dy, r) in [(0.0, 0.0, 16.0), (18.0, -6.0, 20.0), (38.0, 0.0, 15.0), (20.0, 6.0, 16.0)]) {
        canvas.drawCircle(Offset(x + dx * scale, y + dy * scale), r * scale, p);
      }
    }
  }

  void _paintRain(Canvas canvas, Size size, double t) {
    final storm = weather == Weather.storm;
    final rng = Random(7);
    final n = storm ? 110 : 70;
    final len = storm ? 18.0 : 13.0;
    final slant = storm ? 0.32 : 0.18;
    final paint = Paint()
      ..color = const Color(0xFFDDE8F0).withValues(alpha: 0.34 + 0.24 * daylight)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < n; i++) {
      final speed = (storm ? 520 : 380) * (0.8 + 0.4 * rng.nextDouble());
      final y = (rng.nextDouble() * (size.height + 40) + t * speed) % (size.height + 40) - 20;
      final x = (rng.nextDouble() * (size.width + 60) + y * slant) % (size.width + 60) - 30;
      canvas.drawLine(Offset(x, y), Offset(x - len * slant, y - len), paint);
    }
  }

  /// Algunas hojas que cruzan el jardín con el viento, girando.
  void _paintWindLeaves(Canvas canvas, Size size, double t) {
    final w = size.width, h = size.height;
    final rng = Random(37);
    for (var i = 0; i < 7; i++) {
      final speed = 40 + 30 * rng.nextDouble();
      final y0 = h * (0.25 + 0.6 * rng.nextDouble());
      final span = w + 80;
      final x = (rng.nextDouble() * span + t * speed) % span - 40;
      final y = y0 + 18 * sin(t * 1.3 + i * 2) + x * 0.06;
      final spin = t * (2 + rng.nextDouble() * 2) + i;
      final color = [Palette.moss, Palette.lantern, Palette.wood][i % 3];
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spin);
      canvas.scale(1, 0.4 + 0.6 * cos(spin * 0.7).abs());
      final leaf = Path()
        ..moveTo(-6, 0)
        ..quadraticBezierTo(0, -4, 6, 0)
        ..quadraticBezierTo(0, 4, -6, 0);
      canvas.drawPath(leaf, Paint()..color = color.withValues(alpha: 0.75));
      canvas.restore();
    }
  }

  void _paintSnow(Canvas canvas, Size size, double t) {
    final rng = Random(11);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (var i = 0; i < 70; i++) {
      final speed = 18 + 22 * rng.nextDouble();
      final r = 1.0 + 1.8 * rng.nextDouble();
      final y = (rng.nextDouble() * (size.height + 20) + t * speed) % (size.height + 20) - 10;
      final x = rng.nextDouble() * size.width + 10 * sin(t * (0.5 + rng.nextDouble()) + i);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _paintFog(Canvas canvas, Size size, double t) {
    final w = size.width, h = size.height;
    final fog = Color.lerp(const Color(0xFF8A93A0), const Color(0xFFF2F2EE), daylight)!;
    // Un velo parejo y bandas que se corren despacio.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.3, w, h * 0.7),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fog.withValues(alpha: 0), fog.withValues(alpha: 0.3), fog.withValues(alpha: 0.2)],
        ).createShader(Rect.fromLTWH(0, h * 0.3, w, h * 0.7)),
    );
    for (var i = 0; i < 4; i++) {
      final y = h * (0.42 + 0.14 * i);
      final drift = 30 * sin(t * 0.05 + i * 1.7);
      final band = Rect.fromCenter(center: Offset(w / 2 + drift, y), width: w * 1.6, height: h * 0.16);
      canvas.drawOval(
        band,
        Paint()
          ..shader = RadialGradient(colors: [fog.withValues(alpha: 0.45), fog.withValues(alpha: 0)]).createShader(band),
      );
    }
  }

  /// Relámpago lejano cada tanto: un parpadeo de luz, sin rayo, para no asustar.
  void _paintFlash(Canvas canvas, Size size, double t) {
    const every = 13.0;
    final since = t % every;
    if (since > 0.6) return;
    final a = since < 0.1
        ? since / 0.1
        : (since < 0.2 ? 1 - (since - 0.1) / 0.1 * 0.6 : 0.4 * (1 - (since - 0.2) / 0.4));
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white.withValues(alpha: 0.28 * a));
  }

  @override
  bool shouldRepaint(_SkyLifePainter old) =>
      old.daylight != daylight || old.warmth != warmth || old.weather != weather || old.windy != windy;
}
