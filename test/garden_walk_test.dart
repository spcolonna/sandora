import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/progress.dart';
import 'package:sandora/garden/weather.dart';
import 'package:sandora/garden/weather_service.dart';
import 'package:sandora/i18n/i18n.dart';
import 'package:sandora/settings.dart';
import 'package:sandora/ui/garden/garden_scene.dart';
import 'package:sandora/ui/garden/garden_view.dart';
import 'package:sandora/ui/theme/palette.dart';

import 'helpers.dart';

void main() {
  testWidgets('el paseo recorre la vista de adelante hacia el fondo, pasando por la decoración', (tester) async {
    tester.view.physicalSize = const Size(1320, 2868);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load(const ['es']);
    // El paseo por las vistas es para cuando la decoración se ve en ellas.
    final balance = loadBalanceWith((b) => (b['model'] as Map)['inViews'] = true);
    await WeatherService.instance.load(balance);
    final p = Progress.instance;
    await p.load(balance);
    p.calm = p.levels.calmToReach(10);
    p.pebbles = 100000;
    for (final e in p.essences.keys) {
      p.essences[e] = 10000;
    }
    final item = p.decorRules.items.first;
    expect(p.buyDecor(item), isTrue);
    expect(p.placeDecor(item.id, 1, p.modelRules.start.first), isNotNull);

    final stops = <String>[];
    var done = false;
    Widget view(int? walk) => MaterialApp(
      theme: Palette.theme(),
      home: Scaffold(
        body: GardenView(
          side: 1,
          now: DateTime(2026, 11, 7, 11),
          weather: Weather.clear,
          onPlace: (_) async {},
          walk: walk,
          onWalkStop: (name, kind) => stops.add(name),
          onWalkDone: () => done = true,
        ),
      ),
    );
    await tester.pumpWidget(view(null));
    await tester.pump();
    await tester.pumpWidget(view(1));
    for (var i = 0; i < 400 && !done; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(done, isTrue);
    expect(stops, contains(tr('decor.${item.id}')));
    expect(stops.length, greaterThanOrEqualTo(Place.values.where((pl) => pl.side == 1).length));
    expect(
      stops.indexOf(tr('mg.moss.name')),
      lessThan(stops.indexOf(tr('mg.bell.name'))),
      reason: 'de adelante (el musgo) al fondo (la campana)',
    );

    // Cortado a la mitad: no sigue ni avisa que terminó.
    stops.clear();
    done = false;
    await tester.pumpWidget(view(2));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpWidget(view(null));
    final seen = stops.length;
    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(stops.length, seen);
    expect(done, isFalse);
    expect(tester.takeException(), isNull);
  });
}
