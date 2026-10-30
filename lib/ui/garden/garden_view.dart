import 'dart:math';

import 'package:flutter/material.dart';

import '../../garden/day_cycle.dart';
import '../../garden/progress.dart';
import '../../garden/weather.dart';
import '../../garden/weather_service.dart';
import '../../i18n/i18n.dart';
import '../../minigames/enso/enso_ink.dart';
import '../fx/calm.dart';
import '../fx/reward_flight.dart';
import '../fx/sfx.dart';
import '../theme/palette.dart';
import '../widgets/currency.dart';
import '../widgets/garden_sign.dart';
import 'garden_decor.dart';
import 'garden_scene.dart';
import 'garden_touch.dart';
import 'tea_visit.dart';

part 'garden_gifts.dart';
part 'garden_moment.dart';
part 'garden_sky.dart';

/// El jardín es el menú: cada lugar se toca para entrar (minijuegos, Mercado,
/// tablón, meditación). Cambia con la hora del dispositivo y el clima y, según
/// el momento, deja regalos para juntar (rocío al amanecer, luciérnagas de
/// noche, agua de lluvia en las vasijas, copos que brillan).
class GardenView extends StatefulWidget {
  final void Function(Place place) onPlace;

  /// Hora que ve el jardín; se actualiza desde afuera cada tanto.
  final DateTime now;
  final Weather weather;

  /// 0 el patio, 1 el estanque, 2 el bosque.
  final int side;

  /// Modo Decorar: los lugares no se tocan; las decoraciones se arrastran.
  final bool decorating;

  /// La decoración recién puesta desde la bandeja, para destacarla.
  final int? fresh;

  const GardenView({
    super.key,
    required this.onPlace,
    required this.now,
    required this.weather,
    this.side = 0,
    this.decorating = false,
    this.fresh,
  });

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

  /// En el modo Decorar: la decoración elegida y, mientras se arrastra, dónde
  /// está su pie.
  int? _picked, _dragging;
  Offset? _dragAt;

  @override
  void didUpdateWidget(GardenView old) {
    super.didUpdateWidget(old);
    if (!widget.decorating) _picked = _dragging = null;
    if (widget.fresh != old.fresh && widget.fresh != null) _picked = widget.fresh;
  }

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
    final box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      for (final e in g.give.entries) {
        RewardFlight.fly(context, from: box.localToGlobal(at), currency: e.key, amount: e.value);
      }
    }
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
        final size = layout.size;
        final decorating = widget.decorating;
        if ((_picked ?? -1) >= p.decor.length) _picked = _dragging = null;
        final decor = [
          for (final (i, d) in p.decor.indexed)
            if (d.side == widget.side)
              if (p.decorRules.byId(d.id) case final item?)
                (
                  i,
                  d.id,
                  decorRect(
                    item,
                    clampFoot(i == _dragging ? _dragAt! : Offset(d.x * size.width, d.y * size.height), layout),
                    layout,
                  ),
                ),
        ];
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
                    decor: [
                      for (final (i, id, r) in decor)
                        if (i != _dragging) (id, r),
                    ],
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
            if (decorating) ..._decorHandles(p, layout, decor),
            // Fuera de los lugares, el jardín responde al toque.
            if (!decorating)
              Positioned.fill(
                child: GardenTouch(groundTop: layout.ground.top, daylight: daylight, weather: weather, wet: wet > 0.3),
              ),
            if (!decorating) ...[
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
              if (widget.side == 2) TeaSpot(layout: layout, now: now, life: _life, seconds: () => _t),
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
            ],
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

  /// Lo que se toca en el modo Decorar: el suelo marcado, cada decoración (se
  /// elige con un toque y se arrastra) y, sobre la elegida, el botón para
  /// guardarla en la caja.
  List<Widget> _decorHandles(Progress p, GardenLayout layout, List<(int, String, Rect)> decor) {
    final size = layout.size;
    final picked = [
      for (final d in decor)
        if (d.$1 == _picked) d,
    ].firstOrNull;
    return [
      Positioned.fromRect(
        rect: Rect.fromLTRB(
          size.width * 0.03,
          layout.ground.top + layout.ground.height * 0.02,
          size.width * 0.97,
          size.height - 4,
        ),
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Palette.paper.withValues(alpha: 0.7), width: 1.5),
              color: Palette.paper.withValues(alpha: 0.08),
            ),
          ),
        ),
      ),
      // De atrás hacia adelante, así se agarra la de adelante.
      for (final (i, id, r) in [...decor]..sort((a, b) => a.$3.bottom.compareTo(b.$3.bottom)))
        Positioned.fromRect(
          key: ValueKey('decor$i'),
          rect: r.inflate(10),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              SoundBoard.instance.play(Sfx.uiTap, volume: 0.35);
              setState(() => _picked = _picked == i ? null : i);
            },
            onPanStart: (_) {
              final d = p.decor[i];
              Haptics.light();
              setState(() {
                _picked = _dragging = i;
                _dragAt = clampFoot(Offset(d.x * size.width, d.y * size.height), layout);
              });
            },
            onPanUpdate: (e) => setState(() => _dragAt = clampFoot(_dragAt! + e.delta, layout)),
            onPanEnd: (_) => _drop(p, i, size),
            onPanCancel: () => _drop(p, i, size),
            child: Stack(
              children: [
                if (i == _picked)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Palette.lantern.withValues(alpha: 0.14),
                        border: Border.all(color: Palette.lantern, width: 2),
                      ),
                    ),
                  ),
                if (i == _dragging) Positioned.fill(child: CustomPaint(painter: _LiftedDecor(id))),
              ],
            ),
          ),
        ),
      if (picked != null && _dragging == null)
        Positioned(
          left: (picked.$3.center.dx - 80).clamp(4.0, size.width - 164),
          top: (picked.$3.top - 46).clamp(4.0, size.height - 40),
          width: 160,
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              backgroundColor: Palette.paper,
              foregroundColor: Palette.ink,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () {
              SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
              p.storeDecor(picked.$1);
              setState(() => _picked = null);
            },
            icon: const Icon(Icons.inventory_2_rounded, size: 18),
            label: Text(tr('decor.store')),
          ),
        ),
    ];
  }

  void _drop(Progress p, int i, Size size) {
    final at = _dragAt;
    if (_dragging != i || at == null) return;
    SoundBoard.instance.play(Sfx.stackPlace, volume: 0.45);
    p.moveDecor(i, at.dx / size.width, at.dy / size.height);
    setState(() => _dragging = null);
  }
}

/// La decoración que se está arrastrando, un poco levantada (dentro de su
/// zona tocable, que tiene 10 de margen).
class _LiftedDecor extends CustomPainter {
  final String id;
  _LiftedDecor(this.id);

  @override
  void paint(Canvas canvas, Size size) {
    final r = (Offset.zero & size).deflate(10);
    paintDecor(canvas, id, r.shift(Offset(0, -r.height * 0.06)));
  }

  @override
  bool shouldRepaint(_LiftedDecor old) => old.id != id;
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
    Place.bell ||
    Place.matcha ||
    Place.flute ||
    Place.lanterns => tr('mg.${p.name}.name'),
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
                // Oferta del día sin mirar.
                if (place == Place.market && p.dealNew) ...[
                  const SizedBox(width: 5),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Palette.lantern, shape: BoxShape.circle),
                  ),
                ],
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
                  onTapUp: (d) {
                    final gain = p.collectTower();
                    SoundBoard.instance.play(Sfx.stackPlace, volume: 0.6);
                    Haptics.medium();
                    RewardFlight.fly(context, from: d.globalPosition, currency: 'pebbles', amount: gain);
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
