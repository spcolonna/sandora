import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'balance/balance.dart';
import 'garden/progress.dart';
import 'i18n/i18n.dart';
import 'settings.dart';
import 'ui/brand_intro.dart';
import 'ui/fx/sfx.dart';
import 'ui/garden/garden_gate.dart';
import 'ui/garden_screen.dart';
import 'ui/title_intro.dart';
import 'ui/theme/palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  Balance.instance = Balance.parse(await rootBundle.loadString('assets/balance/game_balance.json'));
  final locales = WidgetsBinding.instance.platformDispatcher.locales.map((l) => l.languageCode);
  await AppSettings.instance.load(locales);
  await Progress.instance.load(Balance.instance);
  // El audio carga en segundo plano: la app abre sin esperarlo.
  SoundBoard.instance.init();
  runApp(const SandoraApp());
}

class SandoraApp extends StatelessWidget {
  const SandoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) => MaterialApp(
        title: tr('app.title'),
        debugShowCheckedModeBanner: false,
        theme: Palette.theme(),
        locale: Locale(currentLanguage),
        supportedLocales: [for (final l in supportedLanguages) Locale(l)],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        // Estudio (continúa la pantalla de carga nativa) → título → puertas
        // que se abren al jardín.
        home: const BrandIntro(next: TitleIntro(next: GardenGate(child: GardenScreen()))),
      ),
    );
  }
}
