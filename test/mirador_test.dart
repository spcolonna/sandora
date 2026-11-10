import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/decor.dart';
import 'package:sandora/garden/mirador.dart';
import 'package:sandora/garden/progress.dart';
import 'package:sandora/garden/weather.dart';
import 'package:sandora/garden/weather_service.dart';
import 'package:sandora/i18n/i18n.dart';
import 'package:sandora/settings.dart';
import 'package:sandora/ui/garden/garden_scene.dart';
import 'package:sandora/ui/garden/garden_view.dart';
import 'package:sandora/ui/mirador/mirador_view.dart';
import 'package:sandora/ui/mirador/pano_painter.dart';
import 'package:sandora/ui/theme/palette.dart';

import 'helpers.dart';

void main() {
  final balance = loadBalance();
  final m = ModelRules(balance);
  final world = MiradorWorld.from(balance, cols: m.cols, rows: m.rows);
  const size = Size(430, 930);

  test('cada lugar está una sola vez en el patio y dentro del muro', () {
    for (final place in Place.values) {
      final objs = world.objects.where((o) => o.place == place.name).toList();
      expect(objs.length, 1, reason: '${place.name} en el patio');
      expect(world.wall.deflate(0.5).contains(objs.single.at), isTrue, reason: '${place.name} dentro del muro');
    }
    expect(world.place('model'), isNotNull, reason: 'la mesa de la Maqueta, en el pabellón');
  });

  test('los miradores forman un solo camino y toda salida tiene vuelta', () {
    final ids = [for (final l in world.walkable) l.id];
    for (final a in ids) {
      for (final b in ids) {
        if (a == b) continue;
        final r = world.route(a, b);
        expect(r, isNotEmpty, reason: '$a → $b');
        expect(r.last, b);
      }
      for (final to in world.exits(a)) {
        expect(world.exits(to), contains(a), reason: '$a ↔ $to');
      }
    }
    expect(world.exits(world.hub.id), isEmpty, reason: 'el central no tiene salidas');
  });

  test('los huecos para decorar no pisan lugares, senderos ni el agua', () {
    for (var sector = 0; sector < ModelRules.sides; sector++) {
      for (var c = 0; c < m.cells; c++) {
        final p = world.slot(sector, c);
        expect(world.wall.contains(p), isTrue);
        expect(world.inPond(p), isFalse);
        for (final o in world.objects) {
          if (o.kind == PanoKind.prop && o.decor != 'pavilion') continue;
          expect((o.at - p).distance, greaterThan(o.width / 2 + 0.3), reason: 'hueco $sector.$c y ${o.id}');
        }
        for (final (s, _) in world.stones) {
          expect((s - p).distance, greaterThan(0.6), reason: 'hueco $sector.$c sobre el sendero');
        }
      }
    }
  });

  test('cada lugar se ve desde su mirador, de cerca y sin tapar el camino', () {
    for (final place in Place.values) {
      final o = world.place(place.name)!;
      final l = world.lookoutOf(place.name);
      final d = (o.at - l.at).distance;
      expect(d, inInclusiveRange(2.0, 7.0), reason: '${place.name} desde ${l.id}');
      for (final (s, _) in world.stones) {
        if (place == Place.pond) continue;
        expect((s - o.at).distance, greaterThan(min(0.8, o.width / 2)), reason: '${place.name} sobre una piedra');
      }
    }
  });

  test('al caminar no se atraviesan el muro, los juegos ni el agua', () {
    expect(world.wall.deflate(0.8).contains(world.resolve(const Offset(-40, 3))), isTrue);
    expect(world.wall.deflate(0.8).contains(world.resolve(const Offset(2, 80))), isTrue);
    for (final o in world.objects.where((o) => o.kind == PanoKind.place && o.place != 'pond')) {
      final p = world.resolve(o.at + const Offset(0.05, -0.05));
      expect((p - o.at).distance, greaterThan(0.4), reason: 'no se mete en ${o.place}');
    }
    expect(world.inPond(world.resolve(world.pondAt)), isFalse);
    // Lo libre queda como está.
    expect(world.resolve(world.hub.at), world.hub.at);
  });

  test('la cámara gira 360°: adelante al centro, a la derecha más a la derecha, atrás afuera', () {
    const cam = PanoCamera(size: size, pos: Offset.zero, yaw: 0, fov: 70 * pi / 180);
    final ahead = cam.project(const Offset(0, 5))!;
    expect(ahead.dx, closeTo(size.width / 2, 1e-6));
    expect(ahead.dy, greaterThan(cam.horizon));
    expect(cam.project(const Offset(1, 5))!.dx, greaterThan(size.width / 2));
    expect(cam.project(const Offset(0, -5)), isNull);
    // Más lejos, más cerca del horizonte.
    expect(cam.project(const Offset(0, 10))!.dy, lessThan(ahead.dy));
    // Girando media vuelta, lo de atrás queda adelante (y da la vuelta entera).
    const back = PanoCamera(size: size, pos: Offset.zero, yaw: pi, fov: 70 * pi / 180);
    expect(back.project(const Offset(0, -5))!.dx, closeTo(size.width / 2, 1e-6));
    expect(PanoCamera.wrap(3 * pi).abs(), closeTo(pi, 1e-9));
  });

  test('el piso de la Clásica: senderos de piedras libres y surcos solo en la arena', () {
    expect(world.hubStones.length, greaterThan(20), reason: 'senderos desde el centro');
    for (final (p, r) in world.hubStones) {
      expect(world.wall.deflate(0.6).contains(p), isTrue);
      expect(world.inPond(p), isFalse);
      for (final o in world.objects) {
        if (o.kind == PanoKind.gate || o.decor == 'pavilion' || o.place == 'pond') continue;
        expect((o.at - p).distance, greaterThan(o.width * 0.42 + r), reason: 'piedra sobre ${o.id}');
      }
    }
    final rake = world.rake(true);
    expect(rake.length, greaterThan(100));
    for (final line in rake) {
      for (final p in line) {
        expect(world.wall.contains(p) && !world.inPond(p), isTrue);
        expect(world.mossAt(p), lessThanOrEqualTo(0.15), reason: 'surcos fuera del musgo');
        for (final (s, r) in world.hubStones) {
          expect((s - p).distance, greaterThanOrEqualTo(r), reason: 'los surcos no pisan las piedras');
        }
      }
    }
    expect(world.fallenLeaves, isNotEmpty, reason: 'hojas bajo el arce');
  });

  test('desde cada mirador, mirando hacia un lugar, se lo toca', () {
    for (final place in Place.values) {
      final o = world.place(place.name)!;
      final l = world.lookoutOf(place.name);
      final view = PanoView(
        world: world,
        pos: l.at,
        yaw: MiradorWorld.bearing(l.at, o.at) * pi / 180,
        fov: world.fov * pi / 180,
        places: {for (final p in Place.values) p.name: PlaceLook(open: true, name: p.name)},
      );
      final scene = PanoScene(size, view);
      final target = PanoTarget(PanoHit.place, id: place.name);
      final r = scene.rectOf(target);
      expect(r, isNotNull, reason: '${place.name} se ve desde ${l.id}');
      expect(scene.hit(r!.center), target, reason: '${place.name} se toca desde ${l.id}');
    }
  });

  test('desde el mirador central de la Clásica se ve y se toca cada lugar', () {
    for (final place in Place.values) {
      final o = world.place(place.name)!;
      final view = PanoView(
        world: world,
        pos: world.hub.at,
        yaw: MiradorWorld.bearing(world.hub.at, o.at) * pi / 180,
        fov: world.hubFov * pi / 180,
        hub: true,
        places: {for (final p in Place.values) p.name: PlaceLook(open: true, name: p.name)},
      );
      final scene = PanoScene(size, view);
      final target = PanoTarget(PanoHit.place, id: place.name);
      final r = scene.rectOf(target);
      expect(r, isNotNull, reason: '${place.name} se ve desde el central');
      // Algo cercano puede tapar la base de un lugar lejano: alcanza con que asome.
      final spots = [r!.center, Offset(r.center.dx, r.top + r.height * 0.25)];
      expect(spots.map(scene.hit), contains(target), reason: '${place.name} se toca desde el central');
    }
  });

  Future<void> setUp() async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load(const ['es']);
    await WeatherService.instance.load(balance);
    await Progress.instance.load(balance);
  }

  Future<void> pump(WidgetTester tester, Widget view) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: Palette.theme(),
        home: Scaffold(body: view),
      ),
    );
  }

  testWidgets('arrastrar gira alrededor y da la vuelta entera', (tester) async {
    await setUp();
    final key = GlobalKey<MiradorViewState>();
    await pump(
      tester,
      MiradorView(
        key: key,
        now: DateTime(2026, 11, 8, 11),
        weather: Weather.clear,
        onPlace: (_) async {},
        onGate: (_) {},
      ),
    );
    final painter = find.byKey(const ValueKey('mirador'));
    double yaw() =>
        (tester.widget<CustomPaint>(find.descendant(of: painter, matching: find.byType(CustomPaint))).painter
                as PanoPainter)
            .view
            .yaw;
    final start = yaw();
    await tester.drag(painter, const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(PanoCamera.wrap(yaw() - start), greaterThan(0.2), reason: 'arrastrar a la izquierda mira a la derecha');
    for (var i = 0; i < 12; i++) {
      await tester.drag(painter, const Offset(-300, 0));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('el acceso rápido camina de mirador en mirador hasta el arenero, entra y lo deja encontrado', (
    tester,
  ) async {
    await setUp();
    final c = MiradorController();
    final key = GlobalKey<MiradorViewState>();
    Place? got;
    await pump(
      tester,
      MiradorView(
        key: key,
        now: DateTime(2026, 11, 8, 11),
        weather: Weather.clear,
        controller: c,
        onPlace: (place) async => got = place,
        onGate: (_) {},
      ),
    );
    expect(key.currentState!.lookout, world.entrance.id);
    c.goTo('rain');
    for (var i = 0; i < 200 && got == null; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(got, Place.rain);
    expect(key.currentState!.lookout, world.lookoutOf('rain').id);
    expect(Progress.instance.discovered('sand'), isTrue, reason: 'el arenero se ve desde el mismo mirador');
    expect(tester.takeException(), isNull);
  });

  PanoView viewOf(WidgetTester tester) =>
      (tester
                  .widget<CustomPaint>(
                    find.descendant(of: find.byKey(const ValueKey('mirador')), matching: find.byType(CustomPaint)),
                  )
                  .painter
              as PanoPainter)
          .view;

  testWidgets('tocar la piedra con luz camina al otro mirador, y se puede volver', (tester) async {
    await setUp();
    final key = GlobalKey<MiradorViewState>();
    final c = MiradorController();
    await pump(
      tester,
      MiradorView(
        key: key,
        now: DateTime(2026, 11, 8, 11),
        weather: Weather.clear,
        controller: c,
        onPlace: (_) async {},
        onGate: (_) {},
      ),
    );
    final box = tester.getSize(find.byKey(const ValueKey('mirador')));
    Future<void> walk(String to) async {
      // Se mira hacia la salida y se toca su piedra.
      key.currentState!.face(world.lookout(to).at);
      await tester.pump();
      final r = PanoScene(box, viewOf(tester)).rectOf(PanoTarget(PanoHit.exit, id: to));
      expect(r, isNotNull, reason: 'se ve la piedra hacia $to');
      await tester.tapAt(r!.center);
      for (var i = 0; i < 300 && key.currentState!.lookout != to; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
      expect(key.currentState!.lookout, to);
    }

    await walk('sand');
    await walk(world.entrance.id);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en la Clásica, tocar un juego de la tira camina hasta él y entra', (tester) async {
    await setUp();
    final c = MiradorController();
    final key = GlobalKey<MiradorViewState>();
    Place? got;
    await pump(
      tester,
      MiradorView(
        key: key,
        now: DateTime(2026, 11, 8, 11),
        weather: Weather.clear,
        multi: false,
        controller: c,
        onPlace: (place) async => got = place,
        onGate: (_) {},
      ),
    );
    expect(key.currentState!.lookout, world.hub.id);
    c.goTo('sand');
    for (var i = 0; i < 100 && got == null; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(got, Place.sand);
    expect(key.currentState!.lookout, world.hub.id);
    final sand = world.place('sand')!;
    expect((key.currentState!.position - sand.at).distance, lessThan(sand.width / 2 + 2.5), reason: 'quedó al lado');
    expect(tester.takeException(), isNull);
  });

  testWidgets('en la Clásica, arrastrar para arriba camina hacia adelante sin salir del patio', (tester) async {
    await setUp();
    final key = GlobalKey<MiradorViewState>();
    await pump(
      tester,
      MiradorView(
        key: key,
        now: DateTime(2026, 11, 8, 11),
        weather: Weather.clear,
        multi: false,
        onPlace: (_) async {},
        onGate: (_) {},
      ),
    );
    final painter = find.byKey(const ValueKey('mirador'));
    final start = key.currentState!.position;
    final yaw = key.currentState!.yaw;
    // Arranca mirando hacia los juegos abiertos, no hacia los cerrados.
    final open = [
      for (final p in Place.values)
        if (placeLockNote(p) == null) world.place(p.name)!.at,
    ];
    expect(open, isNotEmpty);
    expect(
      open.any((at) => PanoCamera.wrap(MiradorWorld.bearing(world.hub.at, at) * pi / 180 - yaw).abs() < 0.5),
      isTrue,
      reason: 'algún juego abierto a la vista al empezar',
    );
    await tester.drag(painter, const Offset(0, -240));
    await tester.pumpAndSettle();
    final moved = key.currentState!.position - start;
    // Avanzar es ir hacia donde se mira.
    final ahead = Offset(sin(yaw), cos(yaw));
    expect(moved.dx * ahead.dx + moved.dy * ahead.dy, greaterThan(2), reason: 'caminó hacia adelante');
    expect((moved.dx * ahead.dy - moved.dy * ahead.dx).abs(), lessThan(1.5));
    for (var i = 0; i < 15; i++) {
      await tester.drag(painter, const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
    expect(world.wall.contains(key.currentState!.position), isTrue, reason: 'el muro frena');
    // Y se puede volver al centro.
    await tester.tap(find.byKey(const ValueKey('mirador-home')));
    await tester.pumpAndSettle();
    expect((key.currentState!.position - world.hub.at).distance, lessThan(0.3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('el portón del fondo avisa que ahí van las zonas que vienen', (tester) async {
    await setUp();
    final gates = <String>[];
    final key = GlobalKey<MiradorViewState>();
    final c = MiradorController();
    await pump(
      tester,
      MiradorView(
        key: key,
        now: DateTime(2026, 11, 8, 11),
        weather: Weather.clear,
        multi: false,
        controller: c,
        onPlace: (_) async {},
        onGate: gates.add,
      ),
    );
    final gate = world.objects.firstWhere((o) => o.id == 'future');
    c.lookAt(gate.at);
    await tester.pump();
    final box = tester.getSize(find.byKey(const ValueKey('mirador')));
    final r = PanoScene(box, viewOf(tester)).rectOf(const PanoTarget(PanoHit.gate, id: 'future'))!;
    await tester.tapAt(r.center);
    await tester.pump();
    expect(gates, ['future']);
  });

  testWidgets('VoiceOver anuncia lo tocable del patio y lo activa; sin cambios no se repinta', (tester) async {
    await setUp();
    final handle = tester.ensureSemantics();
    final gates = <String>[];
    final c = MiradorController();
    await pump(
      tester,
      MiradorView(
        now: DateTime(2026, 11, 8, 11),
        weather: Weather.clear,
        multi: false,
        controller: c,
        onPlace: (_) async {},
        onGate: gates.add,
      ),
    );
    c.lookAt(world.objects.firstWhere((o) => o.id == 'future').at);
    await tester.pump();
    expect(find.semantics.byLabel(tr('mirador.future')), findsOne);
    tester.semantics.tap(find.semantics.byLabel(tr('mirador.future')));
    await tester.pump();
    expect(gates, ['future']);
    final v = viewOf(tester);
    tester.element(find.byType(MiradorView)).markNeedsBuild();
    await tester.pump();
    final again = viewOf(tester);
    expect(identical(again, v), isFalse);
    expect(PanoPainter(again).shouldRepaint(PanoPainter(v)), isFalse);
    handle.dispose();
  });
}
