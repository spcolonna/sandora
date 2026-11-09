import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../garden/care.dart';
import '../../garden/mirador.dart';
import '../../garden/progress.dart';
import '../../garden/visitors.dart';
import '../../garden/weather.dart';
import '../../i18n/i18n.dart';
import '../fx/calm.dart';
import '../fx/reward_flight.dart';
import '../fx/sfx.dart';
import '../garden/garden_scene.dart';
import '../garden/garden_view.dart';
import '../theme/palette.dart';
import '../visitor_sheet.dart';
import '../widgets/washi.dart';
import 'pano_painter.dart';

/// Si el lugar [place] ya se puede usar.
bool placeOpen(Progress p, String place) => switch (place) {
  'board' => true,
  'meditation' => p.meditationUnlocked,
  _ => p.gameUnlocked(place),
};

/// Lo que el jardín le pide al mirador desde afuera (el acceso rápido, la
/// Maqueta, la guía).
class MiradorController extends ChangeNotifier {
  String? _goTo;
  bool _enter = false;
  (Offset, PanoTarget?)? _lookAt;
  bool _stroll = false;

  /// Va (caminando rápido de mirador en mirador) hasta el lugar [place] y, si
  /// [enter], entra.
  void goTo(String place, {bool enter = true}) {
    _goTo = place;
    _enter = enter;
    notifyListeners();
  }

  /// Aparece en el mirador más cercano a [p] mirándolo (y resalta [glow]).
  void lookAt(Offset p, {PanoTarget? glow}) {
    _lookAt = (p, glow);
    notifyListeners();
  }

  /// Recorre todos los miradores, uno tras otro.
  void stroll() {
    _stroll = true;
    notifyListeners();
  }
}

/// El jardín visto desde sus miradores: arrastrar gira 360° alrededor,
/// pellizcar acerca, tocar un lugar entra y tocar una piedra con luz camina al
/// mirador siguiente. Con [multi] en falso es la vista Clásica: un solo
/// mirador central desde donde se ve todo.
class MiradorView extends StatefulWidget {
  final DateTime now;
  final Weather weather;
  final bool multi;

  /// Lo de arriba y abajo que tapa el HUD.
  final double top, bottom;

  final Future<void> Function(Place place) onPlace;

  /// El portón de las zonas que vienen.
  final void Function(String gate) onGate;

  /// La mesa de la Maqueta.
  final VoidCallback? onModel;

  /// Un hueco para decorar (sector y parcela) o una decoración puesta.
  final void Function(int sector, int cell)? onSlot;
  final void Function(int index)? onDecor;

  /// Los huecos se muestran (con la decoración abierta).
  final bool slots;

  final MiradorController? controller;

  const MiradorView({
    super.key,
    required this.now,
    required this.weather,
    required this.onPlace,
    required this.onGate,
    this.multi = true,
    this.onModel,
    this.onSlot,
    this.onDecor,
    this.slots = false,
    this.top = 0,
    this.bottom = 0,
    this.controller,
  });

  @override
  State<MiradorView> createState() => MiradorViewState();
}

class MiradorViewState extends State<MiradorView> with SingleTickerProviderStateMixin {
  final Progress _p = Progress.instance;
  late final MiradorWorld world = MiradorWorld.from(
    _p.economy.balance,
    cols: _p.modelRules.cols,
    rows: _p.modelRules.rows,
  );
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  /// Dónde se está: el mirador (o el último por el que se pasó caminando).
  late String _at = widget.multi ? world.entrance.id : world.hub.id;
  late Offset _pos = world.lookout(_at).at;
  late double _yaw = world.lookout(_at).yaw * pi / 180;
  double _zoom = 1, _zoomStart = 1;

  /// Girando solo después de soltar (radianes por segundo).
  double _spin = 0;

  /// Los miradores que faltan para llegar, y hacia dónde girar antes.
  final _route = <String>[];
  double? _turnTo;
  bool _fast = false;
  double _walked = 0;

  /// El lugar al que se va y si se entra al llegar.
  String? _goal;
  bool _goalEnter = false;

  PanoTarget? _glow;
  Size _size = const Size(400, 800);

  /// Regalos ya juntados en esta visita (se van enseguida).
  final _gone = <String>{};

  /// La ayuda de cómo moverse: hasta el primer giro (una vez por sesión).
  static bool _hinted = false;
  bool get _showHint => widget.multi && !_hinted;

  /// El nombre del mirador al que se acaba de llegar.
  String? _arrived;
  Timer? _arrivedTimer;

  String get lookout => _at;
  int get sector => world.lookout(_at).sector;
  bool get walking => _route.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    widget.controller?.addListener(_ask);
    _see(_at);
  }

  @override
  void didUpdateWidget(MiradorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget;
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_ask);
      widget.controller?.addListener(_ask);
    }
    if (old.multi != widget.multi) {
      _route.clear();
      _turnTo = null;
      _at = widget.multi ? world.entrance.id : world.hub.id;
      _pos = world.lookout(_at).at;
      _yaw = world.lookout(_at).yaw * pi / 180;
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_ask);
    _arrivedTimer?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  void _ask() {
    final c = widget.controller!;
    if (c._goTo case final place?) {
      c._goTo = null;
      goTo(place, enter: c._enter, fast: true);
    }
    if (c._lookAt case (final p, final glow)?) {
      c._lookAt = null;
      setState(() {
        _route.clear();
        _turnTo = null;
        _goal = null;
        if (widget.multi) {
          _at = world.nearest(p).id;
          _pos = world.lookout(_at).at;
        }
        _yaw = MiradorWorld.bearing(_pos, p) * pi / 180;
        _glow = glow;
      });
    }
    if (c._stroll) {
      c._stroll = false;
      if (!widget.multi) return;
      final tour = <String>[];
      var from = _at;
      for (final l in world.walkable) {
        final leg = world.route(from, l.id);
        tour.addAll(leg);
        if (leg.isNotEmpty) from = leg.last;
      }
      _walk(tour);
    }
  }

  void _wake() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  double get _fov => (widget.multi ? world.fov : world.hubFov) * pi / 180;
  double get _f => _size.width / _fov * _zoom;

  static double _diff(double target, double from) => PanoCamera.wrap(target - from);

  void _tick(Duration now) {
    final dt = _last == Duration.zero ? 1 / 60 : ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    var yaw = _yaw, pos = _pos, spin = _spin;
    if (_turnTo != null) {
      final d = _diff(_turnTo!, yaw);
      final step = (_fast ? 9.0 : 4.5) * dt;
      if (d.abs() <= step) {
        yaw = _turnTo!;
        _turnTo = null;
      } else {
        yaw += step * d.sign;
      }
    } else if (_route.isNotEmpty) {
      final to = world.lookout(_route.first).at;
      final left = to - pos;
      final step = world.walk * dt * (_fast ? 2.6 : 1);
      // Mira hacia donde camina.
      if (left.distance > 0.2) yaw += _diff(atan2(left.dx, left.dy), yaw) * min(1, dt * 6);
      if (left.distance <= step) {
        pos = to;
        _at = _route.removeAt(0);
        _see(_at);
        if (_route.isEmpty) _arrive();
      } else {
        pos += left / left.distance * step;
        final before = _walked;
        _walked += step;
        if ((before / 0.9).floor() != (_walked / 0.9).floor()) {
          SoundBoard.instance.play(Sfx.stoneSand, volume: 0.08);
        }
      }
    } else if (spin != 0) {
      yaw += spin * dt;
      spin *= exp(-dt * 3.5);
      if (spin.abs() < 0.02) spin = 0;
    }
    final idle = _turnTo == null && _route.isEmpty && spin == 0;
    setState(() {
      _yaw = PanoCamera.wrap(yaw);
      _pos = pos;
      _spin = spin;
    });
    if (idle) {
      _ticker.stop();
      if (_goal != null) _reach();
    }
  }

  /// Llegó al último mirador del camino: si iba a un lugar, gira hacia él.
  void _arrive() {
    _arrivedTimer?.cancel();
    _arrived = tr('mirador.$_at');
    _arrivedTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _arrived = null);
    });
    if (_goal case final place?) {
      final o = world.place(place);
      if (o != null) _turnTo = MiradorWorld.bearing(_pos, o.at) * pi / 180;
    }
  }

  /// Ya mirando el lugar al que se iba: se resalta y, si se pidió, se entra.
  void _reach() {
    final place = _goal!;
    final enter = _goalEnter;
    _goal = null;
    setState(() => _glow = PanoTarget(PanoHit.place, id: place));
    if (enter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onPlace(Place.values.byName(place));
      });
    }
  }

  /// Los lugares que se ven bien desde [id] quedan encontrados.
  void _see(String id) {
    if (!widget.multi) return;
    for (final o in world.objects) {
      final place = o.place;
      if (place == null || place == 'model') continue;
      if (world.lookoutOf(place).id == id && placeOpen(_p, place)) _p.seePlace(place);
    }
  }

  void _walk(List<String> route, {bool fast = false}) {
    if (route.isEmpty) return;
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.3);
    setState(() {
      _route
        ..clear()
        ..addAll(route);
      _fast = fast;
      _spin = 0;
      _glow = null;
      _hinted = true;
      final to = world.lookout(route.first).at;
      _turnTo = MiradorWorld.bearing(_pos, to) * pi / 180;
    });
    _wake();
  }

  /// Gira (sin moverse) para mirar hacia [p].
  void face(Offset p) => setState(() {
    _spin = 0;
    _turnTo = null;
    _yaw = MiradorWorld.bearing(_pos, p) * pi / 180;
  });

  /// Va hasta el lugar [place] (en la Clásica solo gira hacia él) y, si
  /// [enter], entra.
  void goTo(String place, {bool enter = true, bool fast = false}) {
    final o = world.place(place);
    if (o == null) {
      if (enter) widget.onPlace(Place.values.byName(place));
      return;
    }
    _goal = place;
    _goalEnter = enter;
    _fast = fast;
    final route = widget.multi ? world.route(_at, world.lookoutOf(place).id) : const <String>[];
    if (route.isNotEmpty) return _walk(route, fast: fast);
    setState(() {
      _spin = 0;
      _turnTo = MiradorWorld.bearing(_pos, o.at) * pi / 180;
    });
    _wake();
  }

  /// Lo que hay para dibujar y tocar ahora.
  PanoView _view() {
    final p = _p;
    final now = widget.now;
    final bob = _route.isEmpty ? 0.0 : sin(_walked / 0.9 * pi * 2) * 3;
    return PanoView(
      world: world,
      pos: _pos,
      yaw: _yaw,
      fov: _fov,
      zoom: _zoom,
      bob: bob,
      daylight: p.dayCycle.daylight(now),
      places: {
        for (final o in world.objects)
          if (o.place case final id?)
            if (id != 'model') id: _look(Place.values.byName(id)) else if (p.decorUnlocked) id: _modelLook(),
      },
      decor: [
        for (final (i, d) in p.decor.indexed)
          if (d.side != null && d.cell != null)
            if (p.decorRules.byId(d.id) case final item?)
              PanoThing(
                pos: world.slot(d.side!, d.cell!),
                width: item.size * world.decorScale,
                aspect: item.aspect,
                decor: d.id,
                flip: d.flip,
                index: i,
              ),
      ],
      markers: _markers(),
      exits: [
        if (widget.multi && _route.isEmpty)
          for (final to in world.exits(_at))
            if (world.lookout(to).at - _pos case final d)
              PanoExit(
                pos: _pos + d / d.distance * 1.7,
                to: to,
                label: tr('mirador.$to'),
                bearing: MiradorWorld.bearing(_pos, world.lookout(to).at),
              ),
      ],
      glow: _glow,
    );
  }

  PlaceLook _modelLook() => PlaceLook(open: true, name: tr('model.title'));

  PlaceLook _look(Place place) {
    final p = _p;
    final note = placeLockNote(place);
    final rest = place != Place.board && place != Place.meditation && p.restLeft(place.name) > Duration.zero;
    return PlaceLook(
      open: note == null,
      name: placeName(place),
      note: note ?? (rest ? tr('sendero.resting') : null),
      dot: place == Place.stack && p.towerPending() > 0,
    );
  }

  static const _giftIcons = {
    'dew': Icons.water_drop_rounded,
    'firefly': Icons.flare_rounded,
    'rainjar': Icons.water_rounded,
    'snowflake': Icons.ac_unit_rounded,
    'rainbow': Icons.looks_rounded,
    'seed': Icons.spa_rounded,
    'lastray': Icons.wb_twilight_rounded,
  };

  static const _careIcons = {
    CareKind.weed: Icons.grass_rounded,
    CareKind.leaves: Icons.eco_rounded,
    CareKind.sand: Icons.waves_rounded,
    CareKind.stone: Icons.landscape_rounded,
    CareKind.jar: Icons.water_drop_outlined,
    CareKind.decor: Icons.cleaning_services_rounded,
  };

  /// Un punto libre del patio cerca de un mirador (de [sector] si se pide),
  /// siempre el mismo para la misma semilla.
  Offset _spot(int seed, {int? sector}) {
    final rng = Random(seed);
    final near = [
      for (final l in world.walkable)
        if (sector == null || l.sector == sector) l,
    ];
    for (var i = 0; i < 12; i++) {
      final l = near[rng.nextInt(near.length)];
      final a = rng.nextDouble() * 2 * pi;
      final p = l.at + Offset(sin(a), cos(a)) * (1.8 + rng.nextDouble() * 1.6);
      if (!world.wall.deflate(1).contains(p) || world.inPond(p)) continue;
      if (world.objects.any((o) => o.kind != PanoKind.prop && (o.at - p).distance < o.width / 2 + 0.5)) continue;
      return p;
    }
    return near.first.at + const Offset(1.5, 1.5);
  }

  Offset _by(String place, Offset d) => (world.place(place)?.at ?? world.entrance.at) + d;

  List<PanoMarker> _markers() {
    final p = _p;
    final now = widget.now;
    final out = <PanoMarker>[];
    // Los regalos del día, repartidos por el patio.
    final after = rainbowTime(now);
    for (final g in p.dayCycle.giftsAt(now, widget.weather, afterRain: after)) {
      final left = p.giftsLeft(g, weather: widget.weather, afterRain: after, now: now);
      final shown = [
        for (var i = 0; i < g.daily; i++)
          if (!_gone.contains('${g.id}$i')) i,
      ].take(left);
      for (final i in shown) {
        out.add(
          PanoMarker(
            pos: g.id == 'rainjar'
                ? _by('rain', Offset(-0.6 + i * 0.6, -1.2))
                : _spot(g.id.hashCode * 31 + i + p.playDay * 7),
            width: 0.45,
            art: 'spr_gift_${g.id}',
            icon: _giftIcons[g.id] ?? Icons.redeem_rounded,
            target: PanoTarget(PanoHit.gift, id: g.id, index: i),
          ),
        );
      }
    }
    // Lo que hay que cuidar, en su sector.
    for (var side = 0; side < 3; side++) {
      for (final t in p.careOn(side)) {
        out.add(
          PanoMarker(
            pos: _spot(t.id * 13 + 5, sector: side),
            width: 0.5,
            art: switch (t.kind) {
              CareKind.weed => 'obj_care_weeds',
              CareKind.leaves => 'obj_care_leaves',
              _ => null,
            },
            icon: _careIcons[t.kind],
            color: Palette.moss,
            target: PanoTarget(PanoHit.care, index: t.id, zone: side),
          ),
        );
      }
    }
    // El visitante: cada día espera en otro lugar del patio.
    if (p.visitorState != VisitorState.none) {
      final who = p.visitorWho ?? 'monk';
      final waiting = p.visitorState == VisitorState.waiting;
      out.add(
        PanoMarker(
          pos: _spot(9000 + p.playDay),
          width: waiting ? 0.5 : 0.7,
          aspect: 1.5,
          art: waiting ? null : 'char_visitor_$who',
          icon: waiting ? Icons.sticky_note_2_rounded : Icons.person_rounded,
          color: Palette.clay,
          target: const PanoTarget(PanoHit.visitor),
        ),
      );
    }
    // La visita del té deja su ofrenda en la casa de té.
    if (p.teaState(now: now) == TeaState.visit) {
      out.add(
        PanoMarker(
          pos: _by('matcha', const Offset(-1.6, -1.6)),
          width: 0.5,
          art: 'obj_tea_gift',
          icon: Icons.redeem_rounded,
          target: const PanoTarget(PanoHit.tea),
        ),
      );
    }
    // Las Piedritas que juntó la torre.
    if (p.towerPending(now: now) > 0) {
      out.add(
        PanoMarker(
          pos: _by('stack', const Offset(0.4, -0.9)),
          width: 0.45,
          icon: Icons.circle,
          color: Palette.stone,
          target: const PanoTarget(PanoHit.tower),
        ),
      );
    }
    // Los huecos para decorar.
    if (widget.slots) {
      final m = p.modelRules;
      for (var side = 0; side < 3; side++) {
        for (var cell = 0; cell < m.cells; cell++) {
          if (p.decorAt(side, cell) != null) continue;
          final open = p.parcelOpen(side, cell);
          out.add(
            PanoMarker(
              pos: world.slot(side, cell),
              width: 1.0,
              flat: true,
              art: open ? 'spr_path_slot' : 'spr_path_slot_locked',
              icon: open ? Icons.add_rounded : Icons.lock_rounded,
              color: open ? Palette.lantern : Palette.stoneDark,
              target: PanoTarget(PanoHit.slot, zone: side, index: cell),
            ),
          );
        }
      }
    }
    return out;
  }

  // ---- Toques ----

  void _tap(TapUpDetails d) {
    if (d.localPosition.dy < widget.top) return;
    final scene = PanoScene(_size, _view());
    final hit = scene.hit(d.localPosition);
    if (hit == null) return;
    final from = d.globalPosition;
    if (walking) return;
    switch (hit.kind) {
      case PanoHit.place:
        final place = hit.id!;
        final far = widget.multi && world.lookoutOf(place).id != _at;
        if (far && placeOpen(_p, place)) return goTo(place);
        setState(() => _glow = hit);
        widget.onPlace(Place.values.byName(place));
      case PanoHit.model:
        SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
        widget.onModel?.call();
      case PanoHit.exit:
        _walk([hit.id!]);
      case PanoHit.gate:
        widget.onGate(hit.id!);
      case PanoHit.decor:
        widget.onDecor?.call(hit.index!);
      case PanoHit.slot:
        widget.onSlot?.call(hit.zone!, hit.index!);
      case PanoHit.gift:
        _takeGift(hit.id!, hit.index!, from);
      case PanoHit.care:
        _fixCare(hit.index!, from);
      case PanoHit.visitor:
        SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
        showVisitorSheet(context);
      case PanoHit.tea:
        _takeTea(from);
      case PanoHit.tower:
        final gain = _p.collectTower();
        SoundBoard.instance.play(Sfx.stackPlace, volume: 0.6);
        Haptics.medium();
        if (gain > 0) RewardFlight.fly(context, from: from, currency: 'pebbles', amount: gain);
        setState(() {});
    }
  }

  void _takeGift(String id, int index, Offset from) {
    final g = _p.dayCycle.gifts.where((g) => g.id == id).firstOrNull;
    if (g == null) return;
    if (!_p.takeGift(g, weather: widget.weather, afterRain: rainbowTime(widget.now), now: widget.now)) return;
    SoundBoard.instance.play(Sfx.good, volume: 0.4);
    Haptics.light();
    for (final e in g.give.entries) {
      RewardFlight.fly(context, from: from, currency: e.key, amount: e.value);
    }
    setState(() => _gone.add('$id$index'));
  }

  void _fixCare(int id, Offset from) {
    final t = _p.care.where((c) => c.id == id).firstOrNull;
    if (t == null) return;
    final gain = _p.fixCare(id, now: widget.now);
    SoundBoard.instance.play(switch (t.kind) {
      CareKind.weed => Sfx.pluck,
      CareKind.leaves || CareKind.sand => Sfx.sweep,
      CareKind.jar => Sfx.waterDrop,
      CareKind.stone || CareKind.decor => Sfx.stoneSand,
    }, volume: 0.55);
    Haptics.medium();
    if (gain > 0) RewardFlight.fly(context, from: from, currency: 'pebbles', amount: gain);
    if (_p.care.isEmpty) {
      Future.delayed(const Duration(milliseconds: 250), () => SoundBoard.instance.play(Sfx.great, volume: 0.45));
    }
    setState(() {});
  }

  void _takeTea(Offset from) {
    final who = _p.teaVisitor(now: widget.now);
    final gift = _p.takeVisit(now: widget.now);
    if (gift == null) return;
    SoundBoard.instance.play(Sfx.great, volume: 0.45);
    Haptics.medium();
    var wait = 250;
    for (final e in gift.entries) {
      Timer(Duration(milliseconds: wait), () {
        if (mounted) RewardFlight.fly(context, from: from, currency: e.key, amount: e.value);
      });
      wait += 180;
    }
    showWashiToast(context, tr('tea.visit.${who.id}'));
    setState(() {});
  }

  // ---- Girar y acercar ----

  void _scaleStart(ScaleStartDetails d) {
    _zoomStart = _zoom;
    if (_spin != 0) setState(() => _spin = 0);
  }

  void _scaleUpdate(ScaleUpdateDetails d) {
    if (walking) return;
    setState(() {
      _turnTo = null;
      if (d.pointerCount > 1) {
        _zoom = (_zoomStart * d.scale).clamp(1.0, world.zoomMax);
      } else {
        _yaw = PanoCamera.wrap(_yaw - d.focalPointDelta.dx / _f);
        if (d.focalPointDelta.dx.abs() > 2) _hinted = true;
      }
    });
  }

  void _scaleEnd(ScaleEndDetails d) {
    if (walking || d.pointerCount > 0) return;
    final v = d.velocity.pixelsPerSecond.dx;
    if (v.abs() < 120) return;
    setState(() => _spin = (-v / _f).clamp(-6.0, 6.0));
    _wake();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, box) {
        _size = box.biggest;
        final v = _view();
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                key: const ValueKey('mirador'),
                behavior: HitTestBehavior.opaque,
                onTapUp: _tap,
                onScaleStart: _scaleStart,
                onScaleUpdate: _scaleUpdate,
                onScaleEnd: _scaleEnd,
                child: CustomPaint(painter: PanoPainter(v)),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: widget.bottom + 8,
              child: IgnorePointer(
                child: AnimatedSwitcher(
                  duration: Calm.appear,
                  child: _arrived != null
                      ? _Caption(key: ValueKey('arrived$_arrived'), text: _arrived!, style: text, strong: true)
                      : _showHint
                      ? _Caption(key: const ValueKey('hint'), text: tr('mirador.hint'), style: text)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Caption extends StatelessWidget {
  final String text;
  final TextTheme style;
  final bool strong;
  const _Caption({super.key, required this.text, required this.style, this.strong = false});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: Palette.ink.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(14)),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: (strong ? style.titleMedium : style.bodyMedium)?.copyWith(
          color: Palette.paper,
          fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
  );
}
