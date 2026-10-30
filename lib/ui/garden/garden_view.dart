import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
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
import '../widgets/glass.dart';
import '../widgets/washi.dart';
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
  /// Entra a un lugar; termina al volver de él.
  final Future<void> Function(Place place) onPlace;

  /// En el patio pintado, avisa si la cámara se acercó (true) o volvió a ver
  /// todo: acercado, deslizar mueve la cámara y no cambia de vista.
  final ValueChanged<bool>? onZoom;

  /// Hora que ve el jardín; se actualiza desde afuera cada tanto.
  final DateTime now;
  final Weather weather;

  /// 0 el patio, 1 el estanque, 2 el bosque.
  final int side;

  /// Modo Decorar: los lugares no se tocan; las decoraciones se arrastran.
  final bool decorating;

  /// La decoración recién puesta desde la bandeja, para destacarla.
  final int? fresh;

  /// Lo que ocupan arriba y abajo los controles que flotan sobre el jardín.
  final double top, bottom;

  const GardenView({
    super.key,
    required this.onPlace,
    this.onZoom,
    required this.now,
    required this.weather,
    this.side = 0,
    this.decorating = false,
    this.fresh,
    this.top = 0,
    this.bottom = 0,
  });

  @override
  State<GardenView> createState() => _GardenViewState();
}

class _GardenViewState extends State<GardenView> with TickerProviderStateMixin {
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
    if (widget.decorating && !old.decorating && _zoom > 1) {
      _cam.stop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _setCam(1, Offset.zero);
      });
    }
  }

  @override
  void dispose() {
    _life.dispose();
    _cam.dispose();
    super.dispose();
  }

  // Cámara del patio pintado: lo que se ve es `_shift + punto * _zoom` (en la
  // vista). Se acerca con dos dedos o tocando un lugar, y se mueve con uno.
  static const _maxZoom = 2.8, _visitZoom = 2.1;
  double _zoom = 1;
  Offset _shift = Offset.zero;
  Size _box = Size.zero;
  Rect _stageRect = Rect.zero;
  Offset get _stageOrigin => _stageRect.topLeft;
  late final _cam = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  VoidCallback? _camStep;
  final _fingers = <int, Offset>{};

  bool get _painted => widget.side == 0 && GardenLayout.hasCourtArt;

  /// Sin salirse del jardín: siempre cubre toda la vista (si el arte es más
  /// ancho o más alto que la vista, se puede recorrer lo que sobra).
  Offset _clampShift(Offset s, double z) {
    final r = _stageRect;
    return Offset(
      s.dx.clamp(min(_box.width - r.right * z, -r.left * z), -r.left * z),
      s.dy.clamp(min(_box.height - r.bottom * z, -r.top * z), -r.top * z),
    );
  }

  void _setCam(double z, Offset s) {
    final was = _zoom > 1.01;
    z = z.clamp(1.0, _maxZoom);
    setState(() {
      _zoom = z;
      _shift = _clampShift(s, z);
    });
    if ((_zoom > 1.01) != was) widget.onZoom?.call(!was);
  }

  Future<void> _glide(double z, Offset s) async {
    final z0 = _zoom, s0 = _shift, s1 = _clampShift(s, z.clamp(1.0, _maxZoom));
    void step() {
      final t = Curves.easeInOutCubic.transform(_cam.value);
      _setCam(lerpDouble(z0, z, t)!, Offset.lerp(s0, s1, t)!);
    }

    if (_camStep != null) _cam.removeListener(_camStep!);
    _cam.addListener(_camStep = step);
    try {
      await _cam.forward(from: 0).orCancel;
    } on TickerCanceled {
      // Lo frenó un dedo u otro viaje.
    }
  }

  /// Tocar un lugar: la cámara se acerca a él, se entra y, al volver, se
  /// aleja hasta ver todo el jardín.
  Future<void> _visit(Place place, Rect at) async {
    if (!_painted || placeLocked(place)) return widget.onPlace(place);
    final c = (at.center + _stageOrigin) * _visitZoom;
    await _glide(_visitZoom, _box.center(Offset.zero) - c);
    await widget.onPlace(place);
    if (mounted) await _glide(1, Offset.zero);
  }

  void _fingerDown(PointerDownEvent e) {
    _cam.stop();
    _fingers[e.pointer] = e.localPosition;
  }

  void _fingerMove(PointerMoveEvent e) {
    final before = _fingers[e.pointer];
    if (widget.decorating || before == null) return;
    if (_fingers.length >= 2) {
      final other = _fingers.entries.firstWhere((f) => f.key != e.pointer).value;
      final d0 = (before - other).distance, d1 = (e.localPosition - other).distance;
      if (d0 > 1) {
        final f0 = (before + other) / 2, f1 = (e.localPosition + other) / 2;
        final z = (_zoom * d1 / d0).clamp(1.0, _maxZoom);
        _setCam(z, f1 - (f0 - _shift) / _zoom * z);
      }
    } else if (_zoom > 1.01) {
      _setCam(_zoom, _shift + e.localDelta);
    }
    _fingers[e.pointer] = e.localPosition;
  }

  void _fingerUp(PointerEvent e) {
    _fingers.remove(e.pointer);
    // Casi sin acercar: vuelve a ver todo.
    if (_fingers.isEmpty && _zoom > 1 && _zoom < 1.12) _glide(1, Offset.zero);
  }

  bool get _afterRain => _rainbowTime(widget.now);

  /// Dónde empieza el jardín en la vista (lo de arriba es cielo).
  double _stageTop = 0;

  void _take(DayGift g, int index, Offset at) {
    if (!Progress.instance.takeGift(g, weather: widget.weather, afterRain: _afterRain, now: widget.now)) return;
    _gone.add('${g.id}$index');
    SoundBoard.instance.play(Sfx.good, volume: 0.4);
    Haptics.light();
    final box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      for (final e in g.give.entries) {
        final local = _shift + (at + _stageOrigin) * _zoom;
        RewardFlight.fly(context, from: box.localToGlobal(local), currency: e.key, amount: e.value);
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
    final sky = _SkyState(widget.now, widget.weather);
    final afterRain = _afterRain;
    return LayoutBuilder(
      builder: (context, box) {
        final painted = _painted;
        final stage = painted ? _courtStage(box.biggest) : gardenStage(box.biggest, top: widget.top);
        _box = box.biggest;
        _stageRect = stage;
        _stageTop = stage.top;
        final layout = painted
            ? GardenLayout.court(stage.size)
            : GardenLayout(stage.size, p.patioSize, side: widget.side, bottom: widget.bottom);
        final size = layout.size;
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
        final world = Stack(
          children: [
            Positioned.fromRect(
              rect: stage,
              child: Stack(clipBehavior: Clip.none, children: _stage(p, layout, decor, sky, afterRain)),
            ),
          ],
        );
        if (!painted) return world;
        return Listener(
          onPointerDown: _fingerDown,
          onPointerMove: _fingerMove,
          onPointerUp: _fingerUp,
          onPointerCancel: _fingerUp,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRect(
                  child: Transform(
                    transform: Matrix4.diagonal3Values(_zoom, _zoom, 1)..setTranslationRaw(_shift.dx, _shift.dy, 0),
                    child: world,
                  ),
                ),
              ),
              // Acercado: un botón para volver a ver todo el jardín.
              Positioned(
                right: 18,
                bottom: widget.bottom + 6,
                child: AnimatedScale(
                  scale: _zoom > 1.01 && !widget.decorating ? 1 : 0,
                  duration: Calm.appear,
                  curve: Calm.curve,
                  child: GestureDetector(
                    onTap: () {
                      SoundBoard.instance.play(Sfx.uiTap, volume: 0.35);
                      _glide(1, Offset.zero);
                    },
                    child: const Glass(
                      radius: BorderRadius.all(Radius.circular(22)),
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.zoom_out_map_rounded, size: 22, color: Palette.ink),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// El patio pintado cubre toda la vista sin deformarse: apoyado abajo (lo
  /// que sobra arriba es cielo) y centrado a lo ancho.
  Rect _courtStage(Size box) {
    const a = GardenLayout.courtAspect;
    if (box.width / box.height >= a) {
      final h = box.width / a;
      return Rect.fromLTWH(0, box.height - h, box.width, h);
    }
    final w = box.height * a;
    return Rect.fromLTWH((box.width - w) / 2, 0, w, box.height);
  }

  /// Lo de cada vista: la tierra con sus lugares, los regalos y, decorando,
  /// lo que se arrastra.
  List<Widget> _stage(Progress p, GardenLayout layout, List<(int, String, Rect)> decor, _SkyState sky, bool afterRain) {
    final cycle = p.dayCycle;
    final now = widget.now, weather = widget.weather;
    final daylight = sky.daylight, wet = sky.wet;
    final decorating = widget.decorating;
    final painted = layout.painted;
    final painter = GardenPainter(
      layer: GardenLayer.land,
      skyTop: painted ? 0 : -_stageTop,
      camZoom: painted ? _zoom : 1,
      camCenter: painted ? (_box.center(Offset.zero) - _shift) / _zoom - _stageOrigin : null,
      layout: layout,
      tower: p.tower,
      drawing: p.sandDrawing,
      meditationOpen: p.meditationUnlocked,
      moss: p.best('moss') / 100,
      daylight: daylight,
      warmth: sky.warmth,
      arc: cycle.arc(now),
      morning: now.hour < 12,
      overcast: sky.overcast,
      snowy: weather == Weather.snow,
      wet: wet,
      streakObjects: p.streakObjects,
      ensoInk: _ensoInk(p.ensoInk),
      decor: [
        for (final (i, id, r) in decor)
          if (i != _dragging) (id, r),
      ],
    );
    return [
      // El lienzo sube hasta arriba de la pantalla (el follaje cuelga desde
      // ahí); el patio pintado ya trae su cielo.
      if (painted)
        Positioned.fill(
          child: RepaintBoundary(child: CustomPaint(painter: painter)),
        )
      else
        Positioned(
          left: 0,
          right: 0,
          top: -_stageTop,
          bottom: 0,
          child: RepaintBoundary(child: CustomPaint(painter: _ShiftedPainter(_stageTop, painter))),
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
            child: _PlaceArea(onTap: () => _visit(e.key, e.value)),
          ),
        for (final e in layout.labels.entries)
          _Label(
            at: e.value,
            place: e.key,
            scale: painted ? 1 / _zoom : 1,
            onTap: () => _visit(e.key, layout.places[e.key]!),
          ),
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
      ],
    ];
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
          child: Center(
            child: InkButton.paper(
              label: tr('decor.store'),
              height: 38,
              onPressed: () {
                SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
                p.storeDecor(picked.$1);
                setState(() => _picked = null);
              },
            ),
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
/// No tapa los toques: el lugar se sigue pudiendo tocar.
class _GuideHint extends StatefulWidget {
  final Rect around;
  final String text;
  const _GuideHint({super.key, required this.around, required this.text});

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
            top: max(8, r.top - 64),
            child: Center(
              child: CalmAppear(
                delay: const Duration(milliseconds: 400),
                child: IgnorePointer(child: bubble),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La luz y el clima de un momento, como los usa el dibujo.
class _SkyState {
  final double daylight, warmth, overcast, wet, rainbow;

  factory _SkyState(DateTime now, Weather weather) {
    final cycle = Progress.instance.dayCycle;
    final daylight = cycle.daylight(now);
    final overcast = switch (weather) {
      Weather.clear => 0.0,
      Weather.cloudy => 0.45,
      Weather.fog => 0.55,
      Weather.snow => 0.6,
      Weather.rain => 0.75,
      Weather.storm => 0.95,
    };
    final rules = WeatherService.instance.rules;
    final stoppedAt = WeatherService.instance.rainStoppedAt(now);
    // El arcoíris se ve de día y se va apagando a medida que pasa el rato.
    final rainbow = _rainbowTime(now) && (weather == Weather.clear || weather == Weather.cloudy)
        ? daylight * (1 - now.difference(stoppedAt!).inSeconds / rules.rainbowFor.inSeconds).clamp(0.0, 1.0)
        : 0.0;
    return _SkyState._(daylight, cycle.warmth(now), overcast, rules.wetness(weather, now, stoppedAt), rainbow);
  }

  const _SkyState._(this.daylight, this.warmth, this.overcast, this.wet, this.rainbow);
}

/// El fondo lejano, uno solo detrás de las tres vistas: cielo, sol o luna,
/// arcoíris y lomas. Al deslizar entre vistas se corre más lento que el
/// jardín, y eso le da profundidad.
class GardenBackdrop extends StatelessWidget {
  final DateTime now;
  final Weather weather;

  /// En qué vista está el deslizamiento (0 a 2).
  final ValueListenable<double> page;
  final double top;
  const GardenBackdrop({super.key, required this.now, required this.weather, required this.page, this.top = 0});

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final sky = _SkyState(now, weather);
    return LayoutBuilder(
      builder: (context, box) {
        final stage = gardenStage(box.biggest, top: top);
        return ValueListenableBuilder(
          valueListenable: page,
          builder: (context, drift, _) => CustomPaint(
            size: box.biggest,
            painter: _ShiftedPainter(
              stage.top,
              GardenPainter(
                layer: GardenLayer.sky,
                layout: GardenLayout(stage.size, p.patioSize),
                tower: const [],
                drawing: const [],
                meditationOpen: false,
                daylight: sky.daylight,
                warmth: sky.warmth,
                arc: p.dayCycle.arc(now),
                morning: now.hour < 12,
                overcast: sky.overcast,
                snowy: weather == Weather.snow,
                rainbow: sky.rainbow,
                drift: drift,
                skyTop: -stage.top,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Pinta el jardín corrido hasta donde empieza en la pantalla, en un lienzo
/// que llega hasta arriba (el cielo y el follaje siguen por encima).
class _ShiftedPainter extends CustomPainter {
  final double top;
  final GardenPainter garden;
  _ShiftedPainter(this.top, this.garden);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(0, top);
    garden.paint(canvas, garden.size);
  }

  @override
  bool shouldRepaint(_ShiftedPainter old) => old.top != top || garden.shouldRepaint(old.garden);
}

/// Lo vivo del cielo sobre las tres vistas (nubes, estrellas, lluvia, nieve)
/// y una viñeta suave en los bordes, como mirado a través de una lente.
class GardenSkyLife extends StatefulWidget {
  final DateTime now;
  final Weather weather;
  const GardenSkyLife({super.key, required this.now, required this.weather});

  @override
  State<GardenSkyLife> createState() => _GardenSkyLifeState();
}

class _GardenSkyLifeState extends State<GardenSkyLife> with SingleTickerProviderStateMixin {
  late final _life = AnimationController(vsync: this, duration: const Duration(seconds: 120))..repeat();

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sky = _SkyState(widget.now, widget.weather);
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: _SkyLifePainter(
                _life,
                daylight: sky.daylight,
                warmth: sky.warmth,
                weather: widget.weather,
                windy: WeatherService.instance.rules.windy(widget.weather, widget.now),
              ),
            ),
          ),
          CustomPaint(painter: _VignettePainter(1 - sky.daylight)),
        ],
      ),
    );
  }
}

/// Bordes apenas más oscuros (más de noche) y un velo de luz arriba: el ojo
/// va al centro del jardín.
class _VignettePainter extends CustomPainter {
  final double night;
  _VignettePainter(this.night);

  @override
  void paint(Canvas canvas, Size size) {
    final all = Offset.zero & size;
    canvas.drawRect(
      all,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.1),
          radius: 0.95,
          colors: [
            Colors.transparent,
            const Color(0xFF1A1F16).withValues(alpha: 0.22 + 0.18 * night),
          ],
          stops: const [0.62, 1],
        ).createShader(Rect.fromCenter(center: all.center, width: size.width * 1.25, height: size.height)),
    );
  }

  @override
  bool shouldRepaint(_VignettePainter old) => (old.night - night).abs() > 0.01;
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

/// Si [place] todavía no se puede usar (al tocarlo se avisa por qué).
bool placeLocked(Place place) {
  final p = Progress.instance;
  return switch (place) {
    Place.meditation => !p.meditationUnlocked,
    Place.board => false,
    _ => !p.gameUnlocked(place.name),
  };
}

/// Cartelito de papel con el nombre del lugar.
class _Label extends StatelessWidget {
  final Offset at;
  final Place place;
  final VoidCallback onTap;

  /// Con la cámara acercada, el cartelito sigue del mismo tamaño.
  final double scale;
  const _Label({required this.at, required this.place, required this.onTap, this.scale = 1});

  static String nameOf(Place p) => switch (p) {
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
      Place.board => (false, ''),
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
          child: Transform.scale(
            scale: scale,
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
