import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../garden/care.dart';
import '../../garden/decor.dart';
import '../../garden/progress.dart';
import '../../garden/sendero.dart';
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
import 'sendero_painter.dart';

/// Si la zona [zone] del Sendero está abierta: el patio siempre; las demás,
/// cuando alguno de sus lugares ya se puede usar.
bool senderoZoneOpen(Progress p, SenderoWorld w, int zone) {
  if (zone <= 0) return true;
  return w.stations.any((s) => s.zone == zone && placeOpen(p, s.place));
}

/// Si el lugar [place] ya se puede usar.
bool placeOpen(Progress p, String place) => switch (place) {
  'board' => true,
  'meditation' => p.meditationUnlocked,
  _ => p.gameUnlocked(place),
};

/// Lo que el jardín le pide al Sendero desde afuera (el acceso rápido, la
/// vista aérea): ir a un lugar o pararse frente a algo.
class SenderoController extends ChangeNotifier {
  String? _goTo;
  Offset? _standAt;
  bool _enter = false;

  /// Va caminando rápido hasta el lugar [place] y, si [enter], entra.
  void goTo(String place, {bool enter = true}) {
    _goTo = place;
    _enter = enter;
    notifyListeners();
  }

  /// Aparece parado mirando hacia [p] (una decoración, un hueco).
  void standAt(Offset p) {
    _standAt = p;
    notifyListeners();
  }

  bool _stroll = false;

  /// Empieza a caminar solo.
  void stroll() {
    _stroll = true;
    notifyListeners();
  }
}

/// El jardín recorrido en primera persona. Tocar camina o se detiene (o toca
/// lo que se tenga delante); deslizar hacia arriba avanza y hacia abajo
/// retrocede. En las bifurcaciones se elige hacia dónde seguir.
class SenderoWalk extends StatefulWidget {
  final DateTime now;
  final Weather weather;

  /// Lo de arriba y abajo que tapa el HUD.
  final double top, bottom;

  final Future<void> Function(Place place) onPlace;

  /// Un portón cerrado.
  final void Function(int zone) onGate;

  /// Un hueco para decorar (zona y parcela) o una decoración puesta.
  final void Function(int side, int cell)? onSlot;
  final void Function(int index)? onDecor;

  /// Los huecos se muestran (al tener la decoración abierta).
  final bool slots;

  final SenderoController? controller;

  const SenderoWalk({
    super.key,
    required this.now,
    required this.weather,
    required this.onPlace,
    required this.onGate,
    this.onSlot,
    this.onDecor,
    this.slots = false,
    this.top = 0,
    this.bottom = 0,
    this.controller,
  });

  @override
  State<SenderoWalk> createState() => SenderoWalkState();
}

class SenderoWalkState extends State<SenderoWalk> with SingleTickerProviderStateMixin {
  final Progress _p = Progress.instance;
  late final SenderoWorld world = SenderoWorld(
    SenderoRules.from(_p.economy.balance),
    cols: _p.modelRules.cols,
    rows: _p.modelRules.rows,
  );
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  SenderoWalker _w = const SenderoWalker(0, 0.4, 1);
  late double _heading = world.heading(_w);
  bool _auto = false;
  SenderoStop _stop = SenderoStop.none;

  /// A dónde se va caminando solo (un lugar) y si se entra al llegar.
  String? _goal;
  bool _goalEnter = false;

  double _stride = 0;
  double _lastStep = 0;
  static const _stepGap = 0.95;

  /// Regalos ya juntados hoy en esta visita (se van enseguida).
  final _gone = <String>{};

  SenderoWalker get walker => _w;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    widget.controller?.addListener(_ask);
    _lastStep = _w.s;
  }

  @override
  void didUpdateWidget(SenderoWalk oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_ask);
      widget.controller?.addListener(_ask);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_ask);
    _ticker.dispose();
    super.dispose();
  }

  void _ask() {
    final c = widget.controller!;
    if (c._stroll) {
      c._stroll = false;
      setState(() {
        _goal = null;
        _auto = true;
        _stop = SenderoStop.none;
      });
      _wake();
    }
    if (c._goTo case final place?) {
      c._goTo = null;
      _go(place, enter: c._enter, fast: true);
    }
    if (c._standAt case final p?) {
      c._standAt = null;
      setState(() {
        _w = world.viewOf(p);
        _heading = world.heading(_w);
        _auto = false;
        _goal = null;
        _stop = SenderoStop.none;
      });
    }
  }

  bool _open(int zone) => senderoZoneOpen(_p, world, zone);

  void _wake() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration now) {
    final dt = _last == Duration.zero ? 1 / 60 : ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    var w = _w;
    var stop = _stop;
    if (_goal != null) {
      (w, stop) = _towardGoal(w, dt);
    } else if (_auto) {
      final (next, s) = world.advance(w, world.rules.speed * dt, _open);
      w = next;
      if (s != SenderoStop.none) {
        _auto = false;
        stop = s;
      } else {
        stop = SenderoStop.none;
      }
    }
    // El rumbo gira suave hacia donde va el camino.
    final target = world.heading(w);
    var diff = target - _heading;
    while (diff > pi) {
      diff -= 2 * pi;
    }
    while (diff < -pi) {
      diff += 2 * pi;
    }
    final heading = _heading + diff * min(1, dt * 5);
    final moved = (world.position(w) - world.position(_w)).distance;
    final stride = _stride + ((moved > 1e-4 ? 1.0 : 0.0) - _stride) * min(1, dt * 6);
    if ((world.position(w) - world.position(SenderoWalker(w.track, _lastStep, 1))).distance >= _stepGap ||
        w.track != _w.track) {
      _lastStep = w.s;
      if (moved > 1e-4) SoundBoard.instance.play(Sfx.stoneSand, volume: 0.08);
    }
    // Al llegar al final de un ramal, sus lugares quedan encontrados.
    if (stop == SenderoStop.end && w.track > 0 && _stop != SenderoStop.end) {
      for (final place in world.branches[w.track - 1].spec.places) {
        if (placeOpen(_p, place)) _p.seePlace(place);
      }
    }
    final idle = !_auto && _goal == null && diff.abs() < 1e-3 && stride < 1e-3;
    setState(() {
      _w = w;
      _stop = stop;
      _heading = idle ? target : heading;
      _stride = idle ? 0 : stride;
    });
    if (idle) _ticker.stop();
  }

  /// Un paso hacia el lugar [_goal] por el camino más corto.
  (SenderoWalker, SenderoStop) _towardGoal(SenderoWalker w, double dt) {
    final st = world.station(_goal!);
    if (st == null) {
      _goal = null;
      return (w, SenderoStop.none);
    }
    final b = world.branches[st.branch];
    var step = world.rules.speed * dt * (_goalFast ? 7 : 2.5);
    while (step > 1e-6) {
      if (w.track == b.track) {
        final end = world.tracks[b.track].length;
        final d = min(step, end - w.s);
        w = SenderoWalker(w.track, w.s + d, 1);
        step -= d;
        if (w.s >= end - 1e-6) {
          final place = _goal!;
          final enter = _goalEnter;
          _goal = null;
          if (enter) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) widget.onPlace(Place.values.byName(place));
            });
          }
          return (w, SenderoStop.end);
        }
      } else if (w.track > 0) {
        final d = min(step, w.s);
        w = SenderoWalker(w.track, w.s - d, -1);
        step -= d;
        if (w.s <= 1e-6) w = SenderoWalker(0, world.branches[w.track - 1].at, 1);
      } else {
        final dir = b.at >= w.s ? 1 : -1;
        final d = min(step, (b.at - w.s).abs());
        w = SenderoWalker(0, w.s + d * dir, dir);
        step -= d;
        if ((w.s - b.at).abs() < 1e-6) w = SenderoWalker(b.track, 0, 1);
      }
    }
    return (w, SenderoStop.none);
  }

  bool _goalFast = false;

  void _go(String place, {bool enter = true, bool fast = false}) {
    final st = world.station(place);
    if (st == null) {
      if (enter) widget.onPlace(Place.values.byName(place));
      return;
    }
    // No se puede pasar por un portón cerrado.
    if (!_open(st.zone)) {
      widget.onGate(st.zone);
      return;
    }
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.35);
    setState(() {
      _goal = place;
      _goalEnter = enter;
      _goalFast = fast;
      _auto = false;
      _stop = SenderoStop.none;
    });
    _wake();
  }

  /// Lo que hay para dibujar y tocar ahora.
  SenderoView _view() {
    final p = _p;
    final now = widget.now;
    return SenderoView(
      world: world,
      pos: world.position(_w),
      heading: _heading,
      bob: sin(_w.s / _stepGap * pi * 2) * 3 * _stride,
      things: senderoThings(p, world),
      stations: {
        for (final s in [...world.stations.map((s) => s.place), 'board'])
          s: _look(Place.values.byName(s)),
      },
      open: [for (var z = 0; z < ModelRules.sides; z++) _open(z)],
      markers: _markers(),
      daylight: p.dayCycle.daylight(now),
    );
  }

  StationLook _look(Place place) {
    final p = _p;
    final note = placeLockNote(place);
    final rest = place != Place.board && place != Place.meditation && p.restLeft(place.name) > Duration.zero;
    return StationLook(
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

  /// Un punto del camino al costado, siempre el mismo para la misma semilla.
  Offset _spot(int seed, {int? zone, double minSide = 1.3}) {
    final rng = Random(seed);
    final t = world.trunk;
    final open = [for (var z = 0; z < ModelRules.sides; z++) if (_open(z)) z];
    final z = zone ?? open[rng.nextInt(open.length)];
    final s = world.rules.zoneStart(z) + 1.5 + rng.nextDouble() * (world.rules.segment - 3);
    final side = rng.nextBool() ? 1.0 : -1.0;
    return t.pointAt(s) + t.normalAt(s) * side * (minSide + rng.nextDouble() * 0.9);
  }

  List<SenderoMarker> _markers() {
    final p = _p;
    final now = widget.now;
    final out = <SenderoMarker>[];
    // Los regalos del día, repartidos por el camino.
    final after = rainbowTime(now);
    for (final g in p.dayCycle.giftsAt(now, widget.weather, afterRain: after)) {
      final left = p.giftsLeft(g, weather: widget.weather, afterRain: after, now: now);
      final shown = [for (var i = 0; i < g.daily; i++) if (!_gone.contains('${g.id}$i')) i].take(left);
      for (final i in shown) {
        final at = g.id == 'rainjar'
            ? (world.station('rain')?.pos ?? _spot(i)) + Offset(-0.6 + i * 0.6, -0.8)
            : _spot(g.id.hashCode * 31 + i + p.playDay * 7);
        out.add(
          SenderoMarker(
            pos: at,
            width: 0.5,
            art: 'spr_gift_${g.id}',
            icon: _giftIcons[g.id] ?? Icons.redeem_rounded,
            target: SenderoTarget(SenderoHit.gift, id: g.id, index: i),
          ),
        );
      }
    }
    // Lo que hay que cuidar, en su zona.
    for (var side = 0; side < ModelRules.sides; side++) {
      if (!_open(side)) continue;
      for (final t in p.careOn(side)) {
        out.add(
          SenderoMarker(
            pos: _spot(t.id * 13 + 5, zone: side, minSide: 1.1),
            width: 0.55,
            art: switch (t.kind) {
              CareKind.weed => 'obj_care_weeds',
              CareKind.leaves => 'obj_care_leaves',
              _ => null,
            },
            icon: _careIcons[t.kind],
            color: Palette.moss,
            target: SenderoTarget(SenderoHit.care, index: t.id, zone: side),
          ),
        );
      }
    }
    // El visitante: cada día espera en otro punto del camino.
    if (p.visitorState != VisitorState.none) {
      final who = p.visitorWho ?? 'monk';
      out.add(
        SenderoMarker(
          pos: _spot(9000 + p.playDay, minSide: 1.25),
          width: p.visitorState == VisitorState.waiting ? 0.5 : 0.75,
          aspect: 1.5,
          art: p.visitorState == VisitorState.waiting ? null : 'char_visitor_$who',
          icon: p.visitorState == VisitorState.waiting ? Icons.sticky_note_2_rounded : Icons.person_rounded,
          color: Palette.clay,
          target: const SenderoTarget(SenderoHit.visitor),
        ),
      );
    }
    // La visita del té deja su ofrenda en la casa de té.
    if (p.teaState(now: now) == TeaState.visit) {
      if (world.station('matcha') case final st?) {
        out.add(
          SenderoMarker(
            pos: st.pos + const Offset(1.4, -1.2),
            width: 0.55,
            art: 'obj_tea_gift',
            icon: Icons.redeem_rounded,
            target: const SenderoTarget(SenderoHit.tea),
          ),
        );
      }
    }
    // Las Piedritas que juntó la torre.
    if (p.towerPending(now: now) > 0) {
      if (world.station('stack') case final st?) {
        out.add(
          SenderoMarker(
            pos: st.pos + const Offset(0, -1.1),
            width: 0.5,
            icon: Icons.circle,
            color: Palette.stone,
            target: const SenderoTarget(SenderoHit.tower),
          ),
        );
      }
    }
    // Los huecos para decorar, al costado del camino.
    if (widget.slots) {
      final m = p.modelRules;
      for (var side = 0; side < ModelRules.sides; side++) {
        if (!_open(side)) continue;
        for (var cell = 0; cell < m.cells; cell++) {
          if (p.decorAt(side, cell) != null) continue;
          final open = p.parcelOpen(side, cell);
          out.add(
            SenderoMarker(
              pos: world.slot(side, cell),
              width: 1.1,
              flat: true,
              art: open ? 'spr_path_slot' : 'spr_path_slot_locked',
              icon: open ? Icons.add_rounded : Icons.lock_rounded,
              color: open ? Palette.lantern : Palette.stoneDark,
              target: SenderoTarget(SenderoHit.slot, zone: side, index: cell),
            ),
          );
        }
      }
    }
    return out;
  }

  // ---- Toques ----

  void _tap(TapUpDetails d) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final scene = SenderoScene(box.size, _view());
    final hit = d.localPosition.dy < widget.top ? null : scene.hit(d.localPosition);
    if (hit == null) return _toggle();
    final from = d.globalPosition;
    switch (hit.kind) {
      case SenderoHit.station || SenderoHit.board:
        final place = hit.id!;
        final st = world.station(place);
        final far = st != null && (scene.cam.depth(st.pos) > 6.5 || !_atEndOf(st.branch));
        if (far && placeOpen(_p, place)) return _go(place);
        widget.onPlace(Place.values.byName(place));
      case SenderoHit.gate:
        widget.onGate(hit.zone!);
      case SenderoHit.decor:
        widget.onDecor?.call(hit.index!);
      case SenderoHit.slot:
        widget.onSlot?.call(hit.zone!, hit.index!);
      case SenderoHit.gift:
        _takeGift(hit.id!, hit.index!, from);
      case SenderoHit.care:
        _fixCare(hit.index!, from);
      case SenderoHit.visitor:
        SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
        showVisitorSheet(context);
      case SenderoHit.tea:
        _takeTea(from);
      case SenderoHit.tower:
        final gain = _p.collectTower();
        SoundBoard.instance.play(Sfx.stackPlace, volume: 0.6);
        Haptics.medium();
        if (gain > 0) RewardFlight.fly(context, from: from, currency: 'pebbles', amount: gain);
        setState(() {});
    }
  }

  bool _atEndOf(int branch) {
    final b = world.branches[branch];
    return _w.track == b.track && _w.s > world.tracks[b.track].length - 2.5;
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

  void _toggle() {
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.25);
    setState(() {
      _goal = null;
      if (_auto) {
        _auto = false;
        return;
      }
      // Al final de un tramo, tocar da media vuelta.
      if (_stop == SenderoStop.end || _stop == SenderoStop.gate) _w = SenderoWalker(_w.track, _w.s, -_w.dir);
      _stop = SenderoStop.none;
      _auto = true;
    });
    _wake();
  }

  void _turnBack() {
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.3);
    setState(() {
      _goal = null;
      _w = SenderoWalker(_w.track, _w.s, -_w.dir);
      _stop = SenderoStop.none;
      _auto = true;
    });
    _wake();
  }

  void _take(SenderoWay way) {
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.35);
    setState(() {
      _w = world.take(_w, way);
      _stop = SenderoStop.none;
      _auto = true;
      _goal = null;
    });
    _wake();
  }

  void _drag(DragUpdateDetails d) {
    final (next, stop) = world.advance(_w, -d.delta.dy * 0.03, _open);
    setState(() {
      _auto = false;
      _goal = null;
      _w = next;
      _stop = stop;
    });
    _wake();
  }

  /// Deslizar hacia un costado en una bifurcación toma ese camino.
  void _swipe(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v.abs() < 300 || _stop != SenderoStop.fork) return;
    final side = v < 0 ? 1 : -1;
    for (final way in world.ways(_w)) {
      if (world.sideOf(_w, way, _heading) == side) return _take(way);
    }
  }

  String _wayName(SenderoWay way) {
    if (way.places.isNotEmpty) {
      return way.places.map((p) => placeName(Place.values.byName(p))).join(' · ');
    }
    if (way.zone < 0) return tr('sendero.entrance');
    if (way.zone >= ModelRules.sides) return tr('sendero.onward');
    return tr(const ['garden.patio', 'garden.pond', 'garden.forest'][way.zone]);
  }

  /// La decoración que se tiene delante, si hay una cerca.
  SenderoThing? _near(SenderoView v, SenderoCamera cam) {
    SenderoThing? best;
    var bestDz = 0.0;
    for (final t in v.things) {
      if (t.name == null) continue;
      final c = cam.toCam(t.pos);
      if (c.dy < 1.2 || c.dy > 4.8 || c.dx.abs() > c.dy * 0.7) continue;
      if (best == null || c.dy < bestDz) {
        best = t;
        bestDz = c.dy;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final v = _view();
    final text = Theme.of(context).textTheme;
    final ways = _stop == SenderoStop.fork && !_auto && _goal == null ? world.ways(_w) : const <SenderoWay>[];
    final atEnd = (_stop == SenderoStop.end || _stop == SenderoStop.gate) && !_auto && _goal == null;
    return LayoutBuilder(
      builder: (context, box) {
        final cam = SenderoCamera(box.biggest, v.pos, v.heading, bob: v.bob);
        final near = _near(v, cam);
        final sorted = [...ways]..sort((a, b) => world.sideOf(_w, a, _heading).compareTo(world.sideOf(_w, b, _heading)));
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                key: const ValueKey('sendero'),
                behavior: HitTestBehavior.opaque,
                onTapUp: _tap,
                onVerticalDragUpdate: _drag,
                onHorizontalDragEnd: _swipe,
                child: CustomPaint(painter: SenderoPainter(v)),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: widget.bottom + 8,
              child: AnimatedSwitcher(
                duration: Calm.appear,
                child: ways.isNotEmpty
                    ? Row(
                        key: ValueKey('ways${_w.track}${_w.s}'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final way in sorted)
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: _WayButton(
                                  key: ValueKey('way${way.track}.${way.dir}'),
                                  side: world.sideOf(_w, way, _heading),
                                  label: _wayName(way),
                                  onTap: () => _take(way),
                                ),
                              ),
                            ),
                        ],
                      )
                    : atEnd
                    ? Column(
                        key: const ValueKey('end'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_stop == SenderoStop.gate)
                            _Caption(text: tr('sendero.gateClosed'), style: text),
                          if (_stop == SenderoStop.end && _w.track > 0)
                            _Caption(text: tr('sendero.tapPlace'), style: text),
                          const SizedBox(height: 6),
                          _WayButton(
                            key: const ValueKey('turnBack'),
                            side: 2,
                            label: tr('sendero.back'),
                            onTap: _turnBack,
                          ),
                        ],
                      )
                    : near != null
                    ? _Caption(key: ValueKey('near${near.index}'), text: near.name!, style: text, strong: true)
                    : const SizedBox.shrink(),
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
      decoration: BoxDecoration(
        color: Palette.ink.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
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

/// Un camino para elegir: una flecha hacia su lado y adónde lleva.
class _WayButton extends StatelessWidget {
  /// -1 izquierda, 0 derecho, 1 derecha, 2 dar la vuelta.
  final int side;
  final String label;
  final VoidCallback onTap;
  const _WayButton({super.key, required this.side, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final icon = switch (side) {
      -1 => Icons.turn_left_rounded,
      1 => Icons.turn_right_rounded,
      2 => Icons.u_turn_left_rounded,
      _ => Icons.straight_rounded,
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Palette.paper.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Palette.wood.withValues(alpha: 0.5)),
          boxShadow: [BoxShadow(color: Palette.ink.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Palette.wood),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Palette.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
