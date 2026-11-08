import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/decor.dart';
import 'package:sandora/garden/progress.dart';
import 'package:sandora/garden/sendero.dart';
import 'package:sandora/garden/weather.dart';
import 'package:sandora/garden/weather_service.dart';
import 'package:sandora/i18n/i18n.dart';
import 'package:sandora/minigames/catalog.dart';
import 'package:sandora/settings.dart';
import 'package:sandora/ui/garden/garden_scene.dart';
import 'package:sandora/ui/sendero/sendero_painter.dart';
import 'package:sandora/ui/sendero/sendero_walk.dart';
import 'package:sandora/ui/theme/palette.dart';

import 'helpers.dart';

void main() {
  final balance = loadBalance();
  final m = ModelRules(balance);
  final world = SenderoWorld(SenderoRules.from(balance), cols: m.cols, rows: m.rows);
  bool allOpen(int _) => true;

  test('cada juego y la meditación tienen su lugar al final de un ramal de su zona', () {
    final places = {for (final s in world.stations) s.place: s};
    for (final id in [...minigames.map((g) => g.id), 'meditation']) {
      final st = places[id];
      expect(st, isNotNull, reason: '$id en el Sendero');
      expect(st!.zone, Place.values.byName(id).side, reason: '$id en su zona');
    }
    for (final b in world.branches) {
      expect(world.rules.zoneAt(b.at), b.spec.zone, reason: 'el ramal sale dentro de su zona');
      expect(world.tracks[b.track].points.first, offsetMoreOrLessEquals(world.trunk.pointAt(b.at), epsilon: 1e-6));
    }
  });

  test('cada parcela es un hueco al costado del tronco, en su zona y sin pisar caminos', () {
    for (var side = 0; side < ModelRules.sides; side++) {
      for (var c = 0; c < m.cells; c++) {
        final p = world.slot(side, c);
        expect(world.zoneOf(p), side, reason: 'parcela $side.$c');
        for (final t in world.tracks) {
          expect(t.nearest(p).$2, greaterThan(world.rules.halfWidth + 0.5), reason: 'parcela $side.$c fuera del camino');
        }
        // Las columnas de la izquierda quedan a la izquierda del tronco.
        final (s, _) = world.trunk.nearest(p);
        final right = (p - world.trunk.pointAt(s)).dx * world.trunk.normalAt(s).dx +
            (p - world.trunk.pointAt(s)).dy * world.trunk.normalAt(s).dy;
        expect(right < 0, m.col(c) < m.cols / 2, reason: 'parcela $side.$c del lado de su columna');
      }
    }
  });

  test('caminando se frena en la bifurcación, se elige el ramal y se llega al final', () {
    var w = const SenderoWalker(0, 0.4, 1);
    final first = world.branches.first;
    var (next, stop) = world.advance(w, 100, allOpen);
    expect(stop, SenderoStop.fork);
    expect(next.s, closeTo(first.at, 1e-9));
    final ways = world.ways(next);
    expect(ways.length, 2, reason: 'seguir o tomar el ramal');
    final branch = ways.firstWhere((way) => way.track == first.track);
    expect(branch.places, first.spec.places);
    expect(world.sideOf(next, branch, world.heading(next)), first.spec.side);
    w = world.take(next, branch);
    (next, stop) = world.advance(w, 100, allOpen);
    expect(stop, SenderoStop.end);
    expect(next.s, closeTo(world.tracks[first.track].length, 1e-9));
    // De vuelta, al llegar al tronco se puede ir hacia la entrada o seguir.
    (next, stop) = world.advance(SenderoWalker(next.track, next.s, -1), 100, allOpen);
    expect(stop, SenderoStop.fork);
    expect({for (final way in world.ways(next)) way.dir}, {1, -1});
  });

  test('un portón cerrado frena antes de la zona; hacia atrás no frenan las bifurcaciones', () {
    var w = SenderoWalker(0, world.branches.where((b) => b.spec.zone == 0).last.at, 1);
    final (next, stop) = world.advance(w, 100, (z) => z == 0);
    expect(stop, SenderoStop.gate);
    expect(next.s, closeTo(world.gateAt(1) - 1, 1e-9));
    w = SenderoWalker(0, 20, 1);
    final (back, s2) = world.advance(w, -19.6, allOpen);
    expect(s2, SenderoStop.none);
    expect(back.s, closeTo(0.4, 1e-9));
  });

  test('la cámara proyecta lo de adelante abajo del horizonte y gira con el rumbo', () {
    final cam = SenderoCamera(const Size(400, 800), Offset.zero, 0);
    final ahead = cam.project(const Offset(0, 5))!;
    expect(ahead.dx, closeTo(200, 1e-6));
    expect(ahead.dy, greaterThan(cam.horizon));
    expect(cam.project(const Offset(0, -2)), isNull, reason: 'lo de atrás no se ve');
    expect(cam.project(const Offset(1, 5))!.dx, greaterThan(200));
    // Mirando hacia la derecha, lo que está a la derecha queda adelante.
    final turned = SenderoCamera(const Size(400, 800), Offset.zero, pi / 2);
    expect(turned.project(const Offset(5, 0))!.dx, closeTo(200, 1e-6));
  });

  testWidgets('el lugar del final de un ramal se toca y se ve su nombre', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load(const ['es']);
    await Progress.instance.load(balance);
    final st = world.station('sand')!;
    final w = world.walkerAt('sand')!;
    final view = SenderoView(
      world: world,
      pos: world.position(w),
      heading: world.heading(w),
      stations: {'sand': const StationLook(open: true, name: 'Arenero')},
    );
    final scene = SenderoScene(const Size(430, 930), view);
    final cam = scene.cam;
    expect(cam.depth(st.pos), inInclusiveRange(1.5, 4));
    final r = scene.rectOf(const SenderoTarget(SenderoHit.station, id: 'sand'))!;
    expect(scene.hit(r.center), const SenderoTarget(SenderoHit.station, id: 'sand'));
  });

  Future<void> pumpWalk(WidgetTester tester, SenderoController c, {Place? Function()? entered, List<int>? gates}) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: Palette.theme(),
        home: Scaffold(
          body: SenderoWalk(
            now: DateTime(2026, 11, 8, 11),
            weather: Weather.clear,
            controller: c,
            onPlace: (place) async => entered?.call(),
            onGate: (z) => gates?.add(z),
          ),
        ),
      ),
    );
  }

  Future<void> setUp() async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load(const ['es']);
    await WeatherService.instance.load(balance);
    await Progress.instance.load(balance);
  }

  testWidgets('el acceso rápido camina hasta el Arenero, entra y lo deja encontrado', (tester) async {
    await setUp();
    final c = SenderoController();
    Place? got;
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: Palette.theme(),
        home: Scaffold(
          body: SenderoWalk(
            now: DateTime(2026, 11, 8, 11),
            weather: Weather.clear,
            controller: c,
            onPlace: (place) async => got = place,
            onGate: (_) {},
          ),
        ),
      ),
    );
    expect(Progress.instance.discovered('sand'), isFalse);
    c.goTo('sand');
    for (var i = 0; i < 80 && got == null; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(got, Place.sand);
    expect(Progress.instance.discovered('sand'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('con el estanque cerrado, ir a uno de sus juegos avisa del portón', (tester) async {
    await setUp();
    expect(senderoZoneOpen(Progress.instance, world, 1), isFalse, reason: 'el primer día');
    final c = SenderoController();
    final gates = <int>[];
    await pumpWalk(tester, c, gates: gates);
    c.goTo('shishi');
    await tester.pump();
    expect(gates, [1]);
  });

  testWidgets('tocar camina; en la bifurcación aparecen los caminos y se elige', (tester) async {
    await setUp();
    final c = SenderoController();
    await pumpWalk(tester, c);
    await tester.tapAt(const Offset(215, 600));
    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(ValueKey('way${world.branches.first.track}.1')).evaluate().isNotEmpty) break;
    }
    final way = find.byKey(ValueKey('way${world.branches.first.track}.1'));
    expect(way, findsOneWidget);
    expect(find.textContaining(tr('mg.sand.name')), findsOneWidget);
    await tester.tap(way);
    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('turnBack')).evaluate().isNotEmpty) break;
    }
    expect(find.byKey(const ValueKey('turnBack')), findsOneWidget);
    expect(find.text(tr('sendero.tapPlace')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
