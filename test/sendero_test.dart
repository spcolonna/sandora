import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/decor.dart';
import 'package:sandora/garden/progress.dart';
import 'package:sandora/garden/sendero.dart';
import 'package:sandora/i18n/i18n.dart';
import 'package:sandora/settings.dart';
import 'package:sandora/ui/sendero/sendero_painter.dart';
import 'package:sandora/ui/sendero_screen.dart';
import 'package:sandora/ui/theme/palette.dart';

import 'helpers.dart';

void main() {
  final balance = loadBalance();

  test('cada parcela de la maqueta es un lugar al costado del camino, dentro de su zona', () {
    final m = ModelRules(balance);
    final r = SenderoRules.from(balance);
    for (var s = 0; s < ModelRules.sides; s++) {
      for (var c = 0; c < m.cells; c++) {
        final (:x, :z) = r.slot(m, s, c);
        expect(r.zoneAt(z), s, reason: 'parcela $s.$c');
        expect(x.abs(), greaterThan(r.halfWidth + 0.5), reason: 'no queda sobre el camino');
        expect(x < 0, m.col(c) < m.cols / 2, reason: 'las columnas de la izquierda, a la izquierda');
        if (m.row(c) > 0) {
          expect(z, lessThan(r.slot(m, s, c - m.cols).z), reason: 'la fila del fondo queda más adelante');
        }
      }
    }
    expect(r.length, greaterThan(r.zoneStart(2) + r.segment));
  });

  test('la cámara ve adelante y no lo que quedó atrás', () {
    final cam = SenderoCamera(const Size(400, 800), 5);
    final ahead = cam.project(senderoCenter(8), 8)!;
    expect(ahead.dy, greaterThan(cam.horizon));
    expect(ahead.dx, closeTo(200, 120));
    expect(cam.project(0, 4), isNull);
    expect(cam.project(senderoCenter(12), 12)!.dy, lessThan(ahead.dy), reason: 'lo lejano, más cerca del horizonte');
  });

  testWidgets('el Sendero muestra la decoración puesta y se camina tocando', (tester) async {
    tester.view.physicalSize = const Size(1320, 2868);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load(const ['es']);
    final p = Progress.instance;
    await p.load(balance);
    p.calm = p.levels.calmToReach(10);
    p.pebbles = 100000;
    for (final e in p.essences.keys) {
      p.essences[e] = 10000;
    }
    final item = p.decorRules.items.first;
    expect(p.buyDecor(item), isTrue);
    final i = p.placeDecor(item.id, 1, p.modelRules.start.first)!;
    final things = senderoThings(p, SenderoRules.from(balance));
    expect(things.where((t) => t.index == i).single.decor, item.id);

    await tester.pumpWidget(MaterialApp(theme: Palette.theme(), home: SenderoScreen(at: i)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(tr('decor.${item.id}')), findsOneWidget, reason: 'parado frente a ella, con su nombre');
    // Tocar camina: al rato ya la pasó.
    await tester.tap(find.byKey(const ValueKey('sendero')));
    for (var k = 0; k < 100; k++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text(tr('decor.${item.id}')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
