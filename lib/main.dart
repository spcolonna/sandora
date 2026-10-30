import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'balance/balance.dart';
import 'garden/lotus_store.dart';
import 'garden/progress.dart';
import 'garden/reminders.dart';
import 'garden/weather_service.dart';
import 'i18n/i18n.dart';
import 'minigames/catalog.dart';
import 'settings.dart';
import 'ui/meditation/meditation_screen.dart';
import 'ui/brand_intro.dart';
import 'ui/fx/sfx.dart';
import 'ui/garden/garden_gate.dart';
import 'ui/garden/scene_art.dart';
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
  await WeatherService.instance.load(Balance.instance);
  await Reminders.instance.load(Balance.instance);
  await SceneArt.instance.load();
  // La venta de lotos (si está prendida) carga en segundo plano.
  LotusStore.instance.load(Balance.instance);
  // El clima real (si el jugador lo eligió) llega cuando llega.
  WeatherService.instance.refresh();
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
        home: _gameOverride.isNotEmpty
            ? const _DebugGame()
            : const BrandIntro(
                next: TitleIntro(next: GardenGate(child: GardenScreen())),
              ),
      ),
    );
  }
}

/// Para probar un minijuego directo: `flutter run --dart-define=SANDORA_GAME=moss`
/// (o `meditation`).
/// Abre el jardín y encima el juego (al salir se vuelve al jardín).
const _gameOverride = String.fromEnvironment('SANDORA_GAME');

class _DebugGame extends StatefulWidget {
  const _DebugGame();

  @override
  State<_DebugGame> createState() => _DebugGameState();
}

class _DebugGameState extends State<_DebugGame> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // `meditation` abre la meditación, que no es un minijuego del catálogo.
      final screen = _gameOverride == 'meditation'
          ? const MeditationScreen()
          : minigames.firstWhere((m) => m.id == _gameOverride).screen();
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    });
  }

  @override
  Widget build(BuildContext context) => const GardenScreen();
}
