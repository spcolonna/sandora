import 'dart:async';
import 'dart:math';
import 'dart:ui' show FontFeature, lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../garden/care.dart';
import '../../garden/day_cycle.dart';
import '../../garden/progress.dart';
import '../../garden/weather.dart';
import '../../garden/visitors.dart';
import '../../garden/weather_service.dart';
import '../../i18n/i18n.dart';
import '../../minigames/enso/enso_ink.dart';
import '../fx/calm.dart';
import '../fx/reward_flight.dart';
import '../fx/sfx.dart';
import '../rest_sheet.dart';
import '../theme/palette.dart';
import '../widgets/currency.dart';
import '../widgets/glass.dart';
import '../visitor_sheet.dart';
import '../widgets/washi.dart';
import 'garden_decor.dart';
import 'garden_scene.dart';
import 'garden_touch.dart';
import 'scene_art.dart';
import 'tea_visit.dart';

part 'garden_care.dart';
part 'garden_gifts.dart';
part 'garden_moment.dart';
part 'garden_model_table.dart';
part 'garden_sky.dart';
part 'garden_upgrades.dart';
part 'garden_visitor.dart';
part 'garden_walk.dart';

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

  /// Abre la Maqueta (la mesa del patio).
  final VoidCallback? onModel;

  /// La decoración que se pidió ver desde la Maqueta (índice y un número que
  /// cambia en cada pedido): la cámara se acerca y se marca un rato.
  final (int, int)? focus;

  /// Un paseo por esta vista (un número que cambia en cada pedido; null, sin
  /// paseo): la cámara camina de lo de adelante a lo del fondo, parándose en
  /// cada lugar y decoración. [onWalkStop] dice en qué se paró (nombre y qué
  /// es) y [onWalkDone], que terminó la vista.
  final int? walk;
  final void Function(String name, String kind)? onWalkStop;
  final VoidCallback? onWalkDone;

  /// Lo que ocupan arriba y abajo los controles que flotan sobre el jardín.
  final double top, bottom;

  const GardenView({
    super.key,
    required this.onPlace,
    this.onZoom,
    required this.now,
    required this.weather,
    this.side = 0,
    this.onModel,
    this.focus,
    this.walk,
    this.onWalkStop,
    this.onWalkDone,
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

  /// La decoración marcada después de pedirla desde la Maqueta.
  int? _marked;
  Timer? _markEnd;

  /// Dónde quedó cada decoración en el último dibujo (para acercar la cámara).
  final _decorRects = <int, Rect>{};

  @override
  void didUpdateWidget(GardenView old) {
    super.didUpdateWidget(old);
    if (widget.focus != null && widget.focus != old.focus) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showDecor(widget.focus!.$1));
    }
    if (widget.walk != old.walk) {
      if (widget.walk case final id?) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _startWalk(id));
      } else {
        _stopWalk();
      }
    }
  }

  /// Se acerca a la decoración [i] y la marca unos segundos.
  Future<void> _showDecor(int i) async {
    if (!mounted) return;
    setState(() => _marked = i);
    _markEnd?.cancel();
    _markEnd = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _marked = null);
    });
    final r = _decorRects[i];
    if (r == null) return;
    final c = (r.center + _stageOrigin) * _visitZoom;
    await _glide(_visitZoom, _box.center(Offset.zero) - c);
    // Fuera del patio pintado la cámara no se maneja con los dedos: vuelve sola.
    if (!_painted && mounted && _walking == null) {
      await Future<void>.delayed(const Duration(milliseconds: 2600));
      if (mounted && _walking == null) await _glide(1, Offset.zero);
    }
  }

  @override
  void dispose() {
    _life.dispose();
    _cam.dispose();
    _markEnd?.cancel();
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

  /// Hasta dónde llega la cámara: el lienzo del patio pintado o, en las otras
  /// vistas, la pantalla.
  Rect get _camBounds => _painted ? _stageRect : Offset.zero & _box;

  /// Sin salirse del jardín: siempre cubre toda la vista (si el arte es más
  /// ancho o más alto que la vista, se puede recorrer lo que sobra).
  Offset _clampShift(Offset s, double z) {
    final r = _camBounds;
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

  /// Lleva la cámara a acercamiento [z] y corrimiento [s]. Con [steps], va
  /// caminando: se mece un poco y suenan los pasos.
  Future<void> _glide(double z, Offset s, {int ms = 520, int steps = 0}) async {
    final z0 = _zoom, s0 = _shift, s1 = _clampShift(s, z.clamp(1.0, _maxZoom));
    _cam.duration = Duration(milliseconds: ms);
    var stepped = 0;
    void step() {
      final v = _cam.value;
      final t = (steps > 0 ? Curves.easeInOutSine : Curves.easeInOutCubic).transform(v);
      var bob = Offset.zero;
      if (steps > 0) {
        // Cada paso, la vista baja y sube un poquito.
        bob = Offset(0, -sin(v * steps * pi).abs() * 4.0);
        final n = (v * steps).floor();
        if (n > stepped && n < steps) {
          stepped = n;
          SoundBoard.instance.play(Sfx.stoneSand, volume: 0.08);
        }
      }
      _setCam(lerpDouble(z0, z, t)!, Offset.lerp(s0, s1, t)! + bob);
    }

    if (_camStep != null) _cam.removeListener(_camStep!);
    _cam.addListener(_camStep = step);
    try {
      await _cam.forward(from: 0).orCancel;
    } on TickerCanceled {
      // Lo frenó un dedo u otro viaje.
    }
  }

  /// La vista de la última vez que se dibujó (para el paseo).
  GardenLayout? _layout;

  /// El paseo en curso (su número), si hay uno.
  int? _walking;

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
    if (before == null) return;
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

  /// Cuidados recién arreglados: lo que salta en su lugar.
  final _bursts = <(int, Offset, CareKind)>[];

  void _fixCare(CareTask t, Offset at) {
    final p = Progress.instance;
    final gain = p.fixCare(t.id, now: widget.now);
    SoundBoard.instance.play(switch (t.kind) {
      CareKind.weed => Sfx.pluck,
      CareKind.leaves || CareKind.sand => Sfx.sweep,
      CareKind.jar => Sfx.waterDrop,
      CareKind.stone || CareKind.decor => Sfx.stoneSand,
    }, volume: 0.55);
    Haptics.medium();
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && gain > 0) {
      RewardFlight.fly(
        context,
        from: box.localToGlobal(_shift + (at + _stageOrigin) * _zoom),
        currency: 'pebbles',
        amount: gain,
      );
    }
    if (p.care.isEmpty) {
      // El jardín quedó en orden: se festeja un poco más.
      Future.delayed(const Duration(milliseconds: 250), () => SoundBoard.instance.play(Sfx.great, volume: 0.45));
    }
    final burst = (_popId++, at, t.kind);
    setState(() => _bursts.add(burst));
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _bursts.remove(burst));
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
    final sky = _SkyState(widget.now);
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
        _layout = layout;
        final size = layout.size;
        final decor = [
          for (final (i, d) in p.decor.indexed)
            if (p.modelRules.inViews && d.side == widget.side)
              if (p.decorRules.byId(d.id) case final item?)
                (i, d.id, decorRect(item, clampFoot(Offset(d.x * size.width, d.y * size.height), layout), layout)),
        ];
        _decorRects
          ..clear()
          ..addEntries([for (final (i, _, r) in decor) MapEntry(i, r)]);
        final world = Stack(
          children: [
            Positioned.fromRect(
              rect: stage,
              child: Stack(clipBehavior: Clip.none, children: _stage(p, layout, decor, sky, afterRain)),
            ),
          ],
        );
        // Fuera del patio pintado, la cámara solo se mueve sola (paseo, ver
        // una decoración).
        if (!painted) {
          return ClipRect(
            child: Transform(
              transform: Matrix4.diagonal3Values(_zoom, _zoom, 1)..setTranslationRaw(_shift.dx, _shift.dy, 0),
              child: world,
            ),
          );
        }
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
                  scale: _zoom > 1.01 && _walking == null ? 1 : 0,
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
      snow: sky.snow,
      wet: wet,
      streakObjects: p.streakObjects,
      ensoInk: _ensoInk(p.ensoInk),
      decor: [
        for (final (i, id, r) in decor)
          // Las tumbadas las dibuja su cuidado, inclinadas.
          if (!p.care.any((t) => t.decor == i)) (id, r, p.decor[i].flip),
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
      // Las mejoras de cada lugar.
      for (final e in layout.places.entries)
        if (p.upgradeTier(e.key.name) > 0)
          _UpgradeDeco(place: e.value, tier: p.upgradeTier(e.key.name), daylight: daylight),
      // Fuera de los lugares, el jardín responde al toque.
      Positioned.fill(
        child: GardenTouch(groundTop: layout.ground.top, daylight: daylight, weather: weather, wet: wet > 0.3),
      ),
      ...[
        for (final e in layout.places.entries)
          Positioned.fromRect(
            rect: e.value,
            child: _PlaceArea(onTap: () => _visit(e.key, e.value)),
          ),
        // Paseando, el nombre va abajo, en el marco: los cartelitos se esconden.
        if (_walking == null)
          for (final e in layout.labels.entries)
            _Label(at: e.value, place: e.key, scale: 1 / _zoom, onTap: () => _visit(e.key, layout.places[e.key]!)),
        for (final t in p.careOn(widget.side))
          if (_careRect(t, layout, p) case final r?)
            _CareSpot(key: ValueKey('care${t.id}'), task: t, rect: r, onFix: (at) => _fixCare(t, at)),
        for (final (id, at, kind) in _bursts)
          _CareBurst(key: ValueKey('burst$id'), at: at, kind: kind, serenity: p.careRules.serenityPerFix),
        if (widget.side == 0 && p.visitorState != VisitorState.none)
          _VisitorSpot(layout: layout, life: _life, seconds: () => _t),
        if (widget.side == 0) _TowerCollect(above: layout.places[Place.stack]!),
        for (final place in [Place.sand, Place.stack])
          if (layout.places[place] case final r? when p.restLeft(place.name) > Duration.zero)
            _RestBadge(key: ValueKey('rest${place.name}'), game: place.name, under: r),
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
        // La guía del comienzo marca dónde jugar: el arenero para empezar y
        // para subir de nivel, y Gotas cuando se abre.
        // La mesa de la Maqueta, en el patio.
        if (widget.side == 0 && p.decorUnlocked && widget.onModel != null)
          _ModelTable(rect: _tableRect(p, layout), daylight: daylight, onTap: widget.onModel!),
        for (final (i, _, r) in decor)
          if (i == _marked) _DecorMark(key: ValueKey('mark$i'), around: r),
        if (widget.side == 0 && p.gardenNameOffered)
          ?switch (p.guideStep) {
            Guide.play => _GuideHint(
              key: const ValueKey('guide.play'),
              around: layout.places[Place.sand]!,
              text: tr('guide.play'),
            ),
            Guide.level2 => _GuideHint(
              key: const ValueKey('guide.level2'),
              around: layout.places[Place.sand]!,
              text: tr('guide.level2'),
            ),
            Guide.place || Guide.decor when p.decorUnlocked && widget.onModel != null => _GuideHint(
              key: ValueKey('guide.model${p.guideStep}'),
              around: _tableRect(p, layout),
              text: tr(p.guideStep == Guide.place ? 'guide.placeOpen' : 'guide.decor'),
            ),
            Guide.tryRain => _GuideHint(
              key: const ValueKey('guide.rain'),
              around: layout.places[Place.rain]!,
              text: tr('guide.rain', {'game': tr('mg.rain.name')}),
            ),
            _ => null,
          },
      ],
    ];
  }

  /// Dónde va la mesa de la Maqueta en el patio.
  Rect _tableRect(Progress p, GardenLayout layout) {
    final (w, x, bottom) = p.modelRules.table;
    final size = layout.size;
    final tw = size.width * w, th = tw * 0.8;
    return Rect.fromLTWH(size.width * x - tw / 2, size.height * bottom - th, tw, th);
  }
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

/// La luz y el clima de un momento, como los usa el dibujo. Mientras un
/// clima se funde en otro, cada valor queda a mitad de camino.
class _SkyState {
  final double daylight, warmth, overcast, snow, wet, rainbow;
  final WeatherBlend blend;

  static double _overcast(Weather w) => switch (w) {
    Weather.clear => 0.0,
    Weather.cloudy => 0.45,
    Weather.fog => 0.55,
    Weather.snow => 0.6,
    Weather.rain => 0.75,
    Weather.storm => 0.95,
  };

  factory _SkyState(DateTime now) {
    final cycle = Progress.instance.dayCycle;
    final daylight = cycle.daylight(now);
    final blend = WeatherService.instance.blend(now);
    final rules = WeatherService.instance.rules;
    final stoppedAt = WeatherService.instance.rainStoppedAt(now);
    // El arcoíris se ve de día y se va apagando a medida que pasa el rato.
    final clearish = blend.amount(Weather.clear) + blend.amount(Weather.cloudy);
    final rainbow = _rainbowTime(now) && clearish > 0
        ? clearish * daylight * (1 - now.difference(stoppedAt!).inSeconds / rules.rainbowFor.inSeconds).clamp(0.0, 1.0)
        : 0.0;
    return _SkyState._(
      daylight,
      cycle.warmth(now),
      blend.mix(_overcast),
      blend.amount(Weather.snow),
      blend.mix((w) => rules.wetness(w, now, stoppedAt)),
      rainbow,
      blend,
    );
  }

  const _SkyState._(this.daylight, this.warmth, this.overcast, this.snow, this.wet, this.rainbow, this.blend);
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
    final sky = _SkyState(now);
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
                snow: sky.snow,
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
    final sky = _SkyState(widget.now);
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
                blend: sky.blend,
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
/// Sello chico sobre un lugar que descansa: cuánto falta. No tapa el toque.
class _RestBadge extends StatefulWidget {
  final String game;
  final Rect under;
  const _RestBadge({super.key, required this.game, required this.under});

  @override
  State<_RestBadge> createState() => _RestBadgeState();
}

class _RestBadgeState extends State<_RestBadge> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = Progress.instance.restLeft(widget.game);
    // Al terminar el descanso el sello se va solo.
    if (left == Duration.zero) return const SizedBox.shrink();
    return Positioned(
      left: widget.under.center.dx,
      top: widget.under.bottom,
      child: IgnorePointer(
        child: FractionalTranslation(
          translation: const Offset(-0.5, -1.2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Palette.paper.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Palette.ink.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_bottom_rounded, size: 14, color: Palette.ink.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(
                  restClock(left),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Palette.ink.withValues(alpha: 0.8),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
