import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/reminder_plan.dart';
import 'package:sandora/garden/reminders.dart';
import 'package:sandora/settings.dart';
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
  });
}
