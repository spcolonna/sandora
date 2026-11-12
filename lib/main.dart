import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'balance/balance.dart';
import 'boot.dart';
import 'i18n/i18n.dart';
import 'minigames/catalog.dart';
import 'settings.dart';
import 'ui/meditation/meditation_screen.dart';
import 'ui/brand_intro.dart';
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
  _catchErrors();
  // Imágenes ya decodificadas que Flutter guarda por si vuelven: con 60 MB
  // alcanza (el arte del jardín vive aparte, en SceneArt).
  PaintingBinding.instance.imageCache.maximumSizeBytes = 60 << 20;
  _redrawOnLanguage();
  // La pantalla nativa se queda hasta que la intro tenga el logo decodificado
  // (BrandIntro suelta el primer cuadro); en modo prueba de juego, no.
  if (_gameOverride.isEmpty) WidgetsBinding.instance.deferFirstFrame();
  runApp(const SandoraApp());
  // La carga pesada, mientras se ven las intros.
  Boot.instance.run();
}

/// Los errores de Dart no cierran la app, pero que queden en el registro del
/// aparato (Consola de macOS / Xcode) para poder rastrearlos.
void _catchErrors() {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    debugPrint('Error de Flutter: ${details.exceptionAsString()}\n${details.stack}');
    previous?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Error sin atrapar: $error\n$stack');
    return true;
  };
}

/// Al cambiar el idioma, todo se redibuja: los widgets const que usan `tr`
/// no dependen de nada que cambie y se quedarían con el idioma anterior.
void _redrawOnLanguage() {
  var lang = currentLanguage;
  AppSettings.instance.addListener(() {
    if (lang == currentLanguage) return;
    lang = currentLanguage;
    void dirty(Element e) {
      e.markNeedsBuild();
      e.visitChildren(dirty);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(dirty);
  });
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
    Boot.instance.ready.then((_) {
      if (!mounted) return;
      // `meditation` abre la meditación, que no es un minijuego del catálogo.
      final screen = _gameOverride == 'meditation'
          ? const MeditationScreen()
          : minigames.firstWhere((m) => m.id == _gameOverride).screen();
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: Boot.instance.ready,
    builder: (context, snap) => snap.connectionState == ConnectionState.done ? const GardenScreen() : const SizedBox(),
  );
}
