import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/reminder_plan.dart';
import 'package:sandora/garden/reminders.dart';
import 'package:sandora/garden/progress.dart';
import 'package:sandora/i18n/i18n.dart';
import 'package:sandora/settings.dart';
import 'package:sandora/ui/rest_sheet.dart';
import 'package:sandora/ui/settings_sheet.dart';
import 'package:sandora/ui/theme/palette.dart';

import 'helpers.dart';

void main() {
  testWidgets('la hoja de ajustes se arma sin errores de layout', (tester) async {
    tester.view.physicalSize = const Size(1320, 2868);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load(const ['es']);
    Reminders.instance.rules = ReminderPlan(loadBalance().section('reminders'));
    await tester.pumpWidget(
      MaterialApp(
        theme: Palette.theme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(onPressed: () => showSettingsSheet(context), child: const Text('x')),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('x'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // La vista del jardín: Sendero de entrada, Clásica a un toque (y se guarda).
    expect(AppSettings.instance.classicView, isFalse);
    await tester.tap(find.byKey(const ValueKey('viewClassic')));
    await tester.pump();
    expect(AppSettings.instance.classicView, isTrue);
    await AppSettings.instance.load(const ['es']);
    expect(AppSettings.instance.classicView, isTrue);
    AppSettings.instance.setClassicView(false);
  });

  testWidgets('la hoja de descanso muestra lo que falta y cobra un loto por seguir', (tester) async {
    tester.view.physicalSize = const Size(1320, 2868);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load(const ['es']);
    final p = Progress.instance;
    await p.load(loadBalance());
    p.advanceGuide(Guide.done);
    p.finishRun('sand', 2);
    p.lotus = 2;
    bool? paid;
    await tester.pumpWidget(
      MaterialApp(
        theme: Palette.theme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => paid = await showRestSheet(context, 'sand'),
                child: const Text('x'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('x'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.text(tr('rest.title')), findsOneWidget);
    await tester.tap(find.text(tr('rest.skip')));
    await tester.pumpAndSettle();
    expect(p.lotus, 2 - p.restSkipCost);
    expect(paid, isTrue);
  });
}
