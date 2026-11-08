import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/progress.dart';
import 'package:sandora/garden/sendero.dart';
import 'package:sandora/i18n/i18n.dart';
import 'package:sandora/settings.dart';
import 'package:sandora/ui/model_screen.dart';
import 'package:sandora/ui/theme/palette.dart';

import 'helpers.dart';

void main() {
  testWidgets('la maqueta: se elige del cajón, se pone en una parcela, se guarda y se pide verla', (tester) async {
    tester.view.physicalSize = const Size(1320, 2868);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load(const ['es']);
    final p = Progress.instance;
    await p.load(loadBalance());
    p.calm = p.levels.calmToReach(10);
    p.pebbles = 100000;
    for (final e in p.essences.keys) {
      p.essences[e] = 10000;
    }
    ModelFocus? focus;
    await tester.pumpWidget(
      MaterialApp(
        theme: Palette.theme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(onPressed: () async => focus = await openModel(context), child: const Text('x')),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('x'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(tr('model.title')), findsOneWidget);

    // Compra la primera del cajón y queda elegida; se pone en una parcela libre.
    final item = p.decorRules.items.first;
    await tester.tap(find.text(tr('decor.${item.id}')).last);
    await tester.pump();
    expect(p.decorStored(item.id), 1);
    final cell = p.modelRules.start.first;
    await tester.tap(find.byKey(ValueKey('cell0.$cell')));
    await tester.pump();
    expect(p.decorAt(0, cell), isNotNull);

    // Elegida en la maqueta: se guarda y vuelve a la caja.
    await tester.tap(find.byKey(ValueKey('cell0.$cell')));
    await tester.pumpAndSettle();
    // Se da vuelta.
    await tester.tap(find.byKey(const ValueKey('flip')));
    await tester.pump();
    expect(p.decor[p.decorAt(0, cell)!].flip, isTrue);
    await tester.tap(find.text(tr('decor.store')));
    await tester.pumpAndSettle();
    expect(p.decorAt(0, cell), isNull);
    expect(p.decorStored(item.id), 1);

    // Otra zona: se pone y se pide verla en el jardín.
    await tester.tap(find.text(tr('garden.pond')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tr('decor.${item.id}')).last);
    await tester.pump();
    await tester.tap(find.byKey(ValueKey('cell1.$cell')));
    await tester.pump();
    await tester.tap(find.byKey(ValueKey('cell1.$cell')));
    await tester.pumpAndSettle();
    // Verla cierra la maqueta y pide esa decoración.
    await tester.tap(find.text(tr('model.see')));
    await tester.pumpAndSettle();
    expect(find.text(tr('model.title')), findsNothing);
    expect(focus, (side: 1, index: p.decorAt(1, cell)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Recorrer cierra la maqueta y pide pasear desde esa zona', (tester) async {
    tester.view.physicalSize = const Size(1320, 2868);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load(const ['es']);
    final p = Progress.instance;
    await p.load(loadBalance());
    p.calm = p.levels.calmToReach(10);
    ModelFocus? focus;
    await tester.pumpWidget(
      MaterialApp(
        theme: Palette.theme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(onPressed: () async => focus = await openModel(context), child: const Text('x')),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('x'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tr('garden.forest')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tr('model.walk')));
    await tester.pumpAndSettle();
    expect(focus, (side: 2, index: null));
    expect(tester.takeException(), isNull);
  });

  testWidgets('la vista aérea pone la pieza en su hueco del Sendero', (tester) async {
    tester.view.physicalSize = const Size(1320, 2868);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load(const ['es']);
    final p = Progress.instance;
    await p.load(loadBalance());
    p.calm = p.levels.calmToReach(10);
    p.pebbles = 100000;
    for (final e in p.essences.keys) {
      p.essences[e] = 10000;
    }
    final world = SenderoWorld(SenderoRules.from(p.economy.balance), cols: p.modelRules.cols, rows: p.modelRules.rows);
    await tester.pumpWidget(
      MaterialApp(
        theme: Palette.theme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(onPressed: () => openModel(context, world: world), child: const Text('x')),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('x'));
    await tester.pumpAndSettle();
    expect(find.text(tr('aerial.title')), findsOneWidget);
    final item = p.decorRules.items.first;
    await tester.tap(find.text(tr('decor.${item.id}')).last);
    await tester.pump();
    final cell = p.modelRules.start.last;
    await tester.tap(find.byKey(ValueKey('cell0.$cell')));
    await tester.pump();
    expect(p.decorAt(0, cell), isNotNull);
    expect(tester.takeException(), isNull);
  });
}
