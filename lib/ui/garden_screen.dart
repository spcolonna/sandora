import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../garden/cloud_save.dart';
import '../garden/care.dart';
import '../garden/day_cycle.dart';
import '../garden/economy.dart';
import '../garden/progress.dart';
import '../garden/reminders.dart';
import '../garden/weather.dart';
import '../garden/weather_service.dart';
import '../i18n/i18n.dart';
import '../minigames/catalog.dart';
import 'board_sheet.dart';
import 'expansions_sheet.dart';
import 'fx/calm.dart';
import 'fx/reward_flight.dart';
import 'fx/sfx.dart';
import 'garden/garden_scene.dart';
import 'garden/garden_view.dart';
import 'market_screen.dart';
import 'model_screen.dart';
import 'mirador/mirador_view.dart';
import 'mirador/pano_painter.dart';
import 'rest_sheet.dart';
import 'widgets/daily_goals.dart';
import 'widgets/garden_sign.dart';
import 'meditation/meditation_screen.dart';
import 'achievements_sheet.dart';
import 'album_sheet.dart';
import 'settings_sheet.dart';
import '../settings.dart';
import 'theme/palette.dart';
import 'widgets/currency.dart';
import 'widgets/glass.dart';
import 'widgets/milestone_card.dart';
import 'widgets/next_goal.dart';
import 'widgets/washi.dart';

/// Pantalla principal: el jardín a pantalla completa, que también es el menú
/// (se toca cada lugar para entrar). Arriba flota lo justo: el nivel, la
/// billetera (se despliega con todas las monedas), el Mercado y el menú.
class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> with WidgetsBindingObserver {
  /// El panel desplegado arriba (billetera o nivel) y, al volver de una
  /// partida, cuándo se cierra solo la billetera que se abrió para mostrar lo ganado.
  _Panel _panel = _Panel.none;
  Timer? _walletAuto;

  void _toggle(_Panel panel) {
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.4);
    _walletAuto?.cancel();
    setState(() => _panel = _panel == panel ? _Panel.none : panel);
  }

  Future<void> _market() async {
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
    Progress.instance.advanceGuide(Guide.buy);
    setState(() => _panel = _Panel.none);
    // Desde el Mercado, "Poner ahora" abre la Maqueta.
    if (await openMarket(context) == true && mounted) await _model();
  }

  /// La vista Sendero (de mirador en mirador) en vez de la Clásica (el
  /// mirador central, desde donde se ve todo).
  bool get _path => !AppSettings.instance.classicView;
  final _mirador = MiradorController();
  final _viewKey = GlobalKey<MiradorViewState>();

  /// El portón del fondo: ahí van a estar las zonas que vienen.
  void _gate(String gate) {
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.3);
    _toast(tr('mirador.future'));
  }

  /// Los juegos del patio, en orden (sin la mesa de la Maqueta).
  List<String> _games() => [
    ...?_viewKey.currentState?.world.objects.map((o) => o.place).nonNulls.where((id) => id != 'model'),
  ];

  /// Un juego ya se puede ir directo: en el Sendero, si ya se encontró.
  bool _known(String place) {
    final p = Progress.instance;
    return placeOpen(p, place) && (!_path || p.discovered(place));
  }

  /// El acceso rápido: los juegos ya encontrados van directo; los demás se
  /// encuentran paseando.
  Future<void> _quick() async {
    final view = _viewKey.currentState;
    if (view == null) return;
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.4);
    final picked = await showWashiSheet<String>(
      context,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tr('sendero.quick'), textAlign: TextAlign.center, style: Theme.of(sheet).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                tr('sendero.quickHint'),
                textAlign: TextAlign.center,
                style: Theme.of(sheet).textTheme.bodySmall?.copyWith(color: Palette.ink.withValues(alpha: 0.65)),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final id in _games())
                        _QuickChip(
                          key: ValueKey('quick$id'),
                          label: _known(id)
                              ? placeName(Place.values.byName(id))
                              : '? · ${tr('mirador.${view.world.lookoutOf(id).id}')}',
                          known: _known(id),
                          onTap: _known(id) ? () => Navigator.pop(sheet, id) : null,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) _mirador.goTo(picked);
  }

  /// Abre la Maqueta; al volver, si se pidió ver una decoración, la mira.
  Future<void> _model() async {
    final p = Progress.instance;
    if (p.guideStep == Guide.decor) p.advanceGuide(Guide.done);
    setState(() => _panel = _Panel.none);
    final view = _viewKey.currentState;
    final focus = await openModel(context, side: view?.sector ?? 0, world: view?.world);
    if (!mounted) return;
    // Al poner la primera decoración, a subir de nivel; el aviso de lo que
    // cambió se ve ya en el jardín.
    if (p.guideStep == Guide.place && p.decor.any((d) => d.placed)) p.advanceGuide(Guide.level2);
    _celebrate();
    if (focus == null || view == null) return;
    final d = focus.index == null ? null : p.decor[focus.index!];
    if (d == null || d.cell == null) {
      // «Recorrer»: al mirador de esa parte del patio.
      final area = view.world.decorAreas[focus.side];
      return _mirador.lookAt(area.center);
    }
    _mirador.lookAt(view.world.slot(d.side!, d.cell!), glow: PanoTarget(PanoHit.decor, index: focus.index));
  }

  Timer? _tick, _fadeTick;

  /// En un minijuego o meditando: el jardín no suena.
  bool _away = false;

  /// Mientras un clima se funde en otro, el jardín se redibuja seguido para
  /// que entre de a poco (y no a saltos de 20 segundos).
  void _followFade() {
    if (_fadeTick != null || !WeatherService.instance.blend(gardenNow()).fading) return;
    _fadeTick = Timer.periodic(const Duration(milliseconds: 500), (t) {
      if (!mounted) return t.cancel();
      setState(() {});
      _gardenSound();
      if (!WeatherService.instance.blend(gardenNow()).fading) {
        t.cancel();
        _fadeTick = null;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Las metas del día cumplidas fuera de una partida se anuncian enseguida
    // (también la de una meditación que terminó con la app cerrada).
    Progress.instance.addListener(_announceGoals);
    CloudSave.instance.restored.addListener(_celebrate);
    WidgetsBinding.instance.addPostFrameCallback((_) => _announceGoals());
    // Para ver el Sendero recorriéndose solo: `--dart-define=SANDORA_PATH=true`.
    if (_autoPath && kDebugMode) {
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted && _path) _mirador.stroll();
      });
    }
    // Hoy ya se entró: los recordatorios arrancan mañana.
    Reminders.instance.reschedule();
    // La torre junta Piedritas y la luz del día y el clima cambian en tiempo
    // real: se refresca cada tanto.
    _tick = Timer.periodic(const Duration(seconds: 20), (_) {
      WeatherService.instance.refresh();
      Progress.instance.countDay(DateTime.now());
      setState(() {});
      _gardenSound();
      _followFade();
      _announceUnlocks();
      _checkCare();
    });
    // Después de que se abre la puerta del jardín.
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) _checkCare();
    });
    // El audio carga en segundo plano: la música y el viento arrancan apenas
    // está listo, no al próximo tic.
    SoundBoard.instance.whenReady.then((_) => _gardenSound());
    _followFade();
    // Una meditación que quedó a medias al cerrar la app se retoma.
    if (Progress.instance.meditationStartedAt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _meditate());
    } else if (Progress.instance.gardenNameOffered) {
      // Después de que se abren las puertas.
      Future.delayed(const Duration(milliseconds: 3600), () {
        if (mounted) _announceUnlocks();
      });
    } else {
      // La primera vez, después de mirar el jardín un momento, se ofrece
      // ponerle nombre (después de que se abren las puertas).
      Future.delayed(const Duration(milliseconds: 3400), () {
        if (mounted && !Progress.instance.gardenNameOffered) showGardenNameSheet(context);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Reminders.instance.reschedule();
      _checkCare();
    }
  }

  /// Lo que pasó en el jardín mientras no se miraba (maleza, hojas, lo que
  /// tiró una tormenta), con un aviso corto si apareció algo.
  void _checkCare() {
    final w = WeatherService.instance;
    final news = Progress.instance.refreshCare(
      DateTime.now(),
      weatherAt: w.at,
      windy: w.rules.windy,
      blockHours: w.rules.blockHours,
    );
    Progress.instance.refreshVisitor(DateTime.now());
    if (!mounted || news == CareNews.none) return;
    showWashiToast(context, tr(news == CareNews.storm ? 'care.storm' : 'care.grew'));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Progress.instance.removeListener(_announceGoals);
    CloudSave.instance.restored.removeListener(_celebrate);
    _tick?.cancel();
    _fadeTick?.cancel();
    _walletAuto?.cancel();
    _mirador.dispose();
    super.dispose();
  }

  Future<void> _enter(Place place) async {
    switch (place) {
      case Place.board:
        SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
        await showBoardSheet(context);
      case Place.meditation:
        await (Progress.instance.meditationUnlocked ? _meditate() : showExpansionsSheet(context));
      default:
        final m = minigames.where((m) => m.id == place.name).firstOrNull;
        if (m == null) return;
        final p = Progress.instance;
        if (p.gameUnlocked(m.id)) {
          // Recién jugado, el lugar descansa: se espera o se sigue con lotos.
          if (p.restLeft(m.id) > Duration.zero) {
            SoundBoard.instance.play(Sfx.uiTap, volume: 0.3);
            if (!await showRestSheet(context, m.id) || !mounted) return;
          }
          return _open(m);
        }
        if (p.unlockZone(m.id) != null) {
          await showExpansionsSheet(context);
          if (mounted) _announceUnlocks();
          return;
        }
        SoundBoard.instance.play(Sfx.uiTap, volume: 0.3);
        if (p.lockedByLevel(m.id)) {
          _toast(tr('garden.opensAtLevel', {'n': p.unlockLevel(m.id)}));
        } else {
          _toast(trN('garden.opensIn', p.unlockDay(m.id) - p.playDay));
        }
    }
  }

  void _announceGoals() {
    final done = Progress.instance.takePendingGoals();
    if (done.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) GoalToast.show(context, done);
    });
  }

  void _toast(String text) {
    showWashiToast(context, text);
  }

  /// Anuncia una vez los minijuegos que se abrieron (por día o por zona).
  void _announceUnlocks() {
    if (!mounted) return;
    // Si hay un minijuego (u otra pantalla) encima, se avisa al volver.
    if (ModalRoute.of(context)?.isCurrent == false) return;
    final p = Progress.instance;
    final fresh = p.newUnlocks(minigames.map((m) => m.id));
    p.markUnlocksSeen(fresh);
    for (final id in fresh) {
      p.queueMilestone('game:$id');
    }
    _celebrate();
  }

  /// Muestra los avisos grandes que esperan (nivel nuevo, lugar nuevo,
  /// mejora), si el jardín está a la vista.
  void _celebrate() {
    if (!mounted || Progress.instance.milestones.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
      showPendingMilestones(context);
    });
  }

  /// Música, viento de fondo y, si llueve, la lluvia. Solo con el jardín a la
  /// vista: el reloj de 20 s no tiene que traerlos de vuelta en un minijuego.
  void _gardenSound() {
    if (!mounted || _away) return;
    final sound = SoundBoard.instance;
    sound.music();
    sound.loop(Ambience.wind, volume: 0.18);
    // Sube y baja con el clima que se funde.
    final now = gardenNow();
    final b = WeatherService.instance.blend(now);
    final rain = 0.22 * b.amount(Weather.rain) + 0.32 * b.amount(Weather.storm);
    if (rain > 0.01) {
      sound.loop(Ambience.rain, volume: rain, fade: const Duration(milliseconds: 500));
    } else {
      sound.stopLoop(Ambience.rain);
    }
    _wildlife(now, rain);
  }

  final _rng = Random();

  /// De vez en cuando, de lejos, un pájaro de día o un grillo de noche: el
  /// jardín está vivo. Con lluvia se callan.
  void _wildlife(DateTime now, double rain) {
    if (rain > 0.05 || _rng.nextDouble() > 0.55) return;
    final h = now.hour;
    final night = h >= 20 || h < 5;
    final day = h >= 6 && h < 19;
    if (!night && !day) return;
    // Entre 1 y 12 s después del tic, para que no caiga siempre igual.
    Future.delayed(Duration(milliseconds: 1000 + _rng.nextInt(11000)), () {
      if (!mounted || _away) return;
      SoundBoard.instance.play(night ? Sfx.cricket : Sfx.bird, volume: night ? 0.22 : 0.2);
    });
  }

  /// Se apagan el viento y la lluvia del jardín; la música sigue y el
  /// minijuego la funde con la suya.
  void _quiet() {
    SoundBoard.instance.stopLoop(Ambience.wind);
    SoundBoard.instance.stopLoop(Ambience.rain);
  }

  Future<void> _open(MinigameInfo m) async {
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
    _quiet();
    final before = _wallet();
    _away = true;
    await Navigator.of(context).push(calmRoute<void>(m.screen()));
    _away = false;
    if (!mounted) return;
    _gardenSound();
    final wait = _flyGains(before);
    // Después de ver llegar lo ganado, el aviso grande (si subió de nivel).
    Future.delayed(Duration(milliseconds: wait + 500), _celebrate);
    // Después de la primera partida (no al abrir la app) se ofrecen los avisos.
    if (Progress.instance.guideStep >= 1) Reminders.instance.askOnce();
  }

  static final _walletKeys = ['pebbles', for (final e in Essence.values) e.name, 'lotus'];

  Map<String, int> _wallet() => {for (final k in _walletKeys) k: Progress.instance.walletOf(k)};

  /// Lo ganado afuera (una partida, una meditación) vuela a sus contadores al
  /// volver: la billetera se abre un momento para verlo llegar y se vuelve a
  /// cerrar. Los contadores no muestran lo ganado hasta que llega. Devuelve
  /// cuánto tarda (ms).
  int _flyGains(Map<String, int> before) {
    final now = _wallet();
    final gains = {for (final k in _walletKeys) k: now[k]! - before[k]!}..removeWhere((_, g) => g <= 0);
    for (final MapEntry(key: k, value: gain) in gains.entries) {
      RewardFlight.hold(k, gain);
    }
    final from = MediaQuery.sizeOf(context).center(const Offset(0, 60));
    var wait = 380;
    if (gains.keys.any((k) => k != 'pebbles') && _panel == _Panel.none) {
      setState(() => _panel = _Panel.wallet);
    }
    for (final MapEntry(key: k, value: gain) in gains.entries) {
      Future.delayed(Duration(milliseconds: wait), () {
        if (mounted) {
          RewardFlight.fly(context, from: from, currency: k, amount: gain, held: true);
        } else {
          RewardFlight.heldOf(k).value = 0;
        }
      });
      wait += 200;
    }
    if (_panel == _Panel.wallet) {
      _walletAuto?.cancel();
      _walletAuto = Timer(Duration(milliseconds: wait + 1800), () {
        if (mounted && _panel == _Panel.wallet) setState(() => _panel = _Panel.none);
      });
    }
    return wait;
  }

  Future<void> _meditate() async {
    _quiet();
    // Para meditar, solo el ambiente que se elija.
    SoundBoard.instance.stopMusic();
    final before = _wallet();
    _away = true;
    await Navigator.of(context).push(calmRoute<void>(const MeditationScreen()));
    _away = false;
    if (!mounted) return;
    _gardenSound();
    final wait = _flyGains(before);
    Future.delayed(Duration(milliseconds: wait + 600), _celebrate);
  }

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final pad = MediaQuery.paddingOf(context);
    // Arriba, la fila de botones (el cartel y el clima flotan sobre el cielo
    // del jardín); abajo, las vistas.
    final top = pad.top + _hudRow;
    final bottom = pad.bottom + 50;
    return Scaffold(
      backgroundColor: Palette.mossDark,
      body: ListenableBuilder(
        listenable: Listenable.merge([p, WeatherService.instance, AppSettings.instance]),
        builder: (context, _) {
          final now = gardenNow();
          final weather = WeatherService.instance.at(now);
          // De noche, la hora y la batería en claro sobre el cielo oscuro.
          final night = p.dayCycle.daylight(now) < 0.4;
          return AnnotatedRegion(
            value: night ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: MiradorView(
                          key: _viewKey,
                          now: now,
                          weather: weather,
                          multi: _path,
                          top: top + 70,
                          bottom: bottom + (_path ? 8 : 60),
                          controller: _mirador,
                          slots: p.decorUnlocked,
                          onPlace: _enter,
                          onGate: _gate,
                          onModel: _model,
                          onSlot: (side, cell) => _model(),
                          onDecor: (i) => _model(),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: GardenSkyLife(now: now, weather: weather),
                        ),
                      ),
                      // Con un panel abierto, tocar el jardín lo cierra.
                      if (_panel != _Panel.none)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _panel = _Panel.none),
                          ),
                        ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: SafeArea(
                          bottom: false,
                          child: _Hidden(
                            hidden: false,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: _Hud(
                                now: now,
                                weather: weather,
                                panel: _panel,
                                onPanel: _toggle,
                                onMarket: _market,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        top: pad.top + _hudRow + 4,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, a) => FadeTransition(
                            opacity: a,
                            child: SlideTransition(
                              position: Tween(begin: const Offset(0, -0.04), end: Offset.zero).animate(a),
                              child: child,
                            ),
                          ),
                          child: switch (_panel) {
                            _Panel.wallet => _WalletPanel(onMarket: _market),
                            _Panel.level => const _LevelPanel(),
                            // En el Sendero, la guía dice adónde caminar (y tocarla lleva).
                            _Panel.none when p.guideStep == Guide.play || p.guideStep == Guide.level2 => _GuideHint(
                              text: tr('guide.pathSand'),
                              right: 0,
                              onTap: () => _mirador.goTo('sand', enter: false),
                            ),
                            _Panel.none when p.guideStep == Guide.tryRain => _GuideHint(
                              text: tr('guide.pathRain'),
                              right: 0,
                              onTap: () => _mirador.goTo('rain', enter: false),
                            ),
                            _Panel.none when p.guideStep == Guide.market => _GuideHint(
                              text: tr('guide.market'),
                              right: 30,
                              onTap: _market,
                            ),
                            _Panel.none when p.guideStep == Guide.buy => _GuideHint(
                              text: tr('guide.buyBack'),
                              right: 30,
                              onTap: _market,
                            ),
                            _Panel.none => const SizedBox.shrink(),
                          },
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: pad.bottom + 10,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // En la Clásica, los juegos a mano.
                              if (!_path)
                                _GameStrip(
                                  games: [
                                    for (final g in _games())
                                      if (_known(g)) g,
                                  ],
                                  onTap: _mirador.goTo,
                                ),
                              _SenderoBar(onQuick: _quick, onDecor: p.decorUnlocked ? _model : null),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum _Panel { none, wallet, level }

/// Algo de la pantalla que se esconde (y no se toca) durante el paseo.
class _Hidden extends StatelessWidget {
  final bool hidden;
  final Widget child;
  const _Hidden({required this.hidden, required this.child});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: hidden,
    child: AnimatedOpacity(opacity: hidden ? 0 : 1, duration: Calm.appear, curve: Calm.curve, child: child),
  );
}

/// Alto de la fila de arriba y a qué tamaño va el cartel del jardín.
const _hudRow = 56.0, _signScale = 0.78;

const _autoPath = bool.fromEnvironment('SANDORA_PATH');

/// Lo de arriba, liviano para no tapar el jardín: el nivel, la billetera, el
/// Mercado y el menú; debajo, el cartel con el nombre y el clima.
class _Hud extends StatelessWidget {
  final DateTime now;
  final Weather weather;
  final _Panel panel;
  final void Function(_Panel) onPanel;
  final VoidCallback onMarket;
  const _Hud({
    required this.now,
    required this.weather,
    required this.panel,
    required this.onPanel,
    required this.onMarket,
  });

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _hudRow,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Row(
              children: [
                _LevelOrb(open: panel == _Panel.level, onTap: () => onPanel(_Panel.level)),
                const SizedBox(width: 8),
                _WalletPill(open: panel == _Panel.wallet, onTap: () => onPanel(_Panel.wallet)),
                const Spacer(),
                _RoundButton(
                  icon: Icons.storefront_rounded,
                  tooltip: tr('shop.title'),
                  dot: p.dealNew,
                  pulse: p.guideStep == Guide.market || p.guideStep == Guide.buy,
                  onTap: onMarket,
                ),
                const SizedBox(width: 8),
                const _MenuButton(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: GardenSign.width * _signScale,
                height: GardenSign.height * _signScale,
                child: const FittedBox(child: GardenSign()),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: MomentChip(now: now, weather: weather),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// El nivel en un círculo chico: el anillo se llena con la Calma. Se toca
/// para ver el detalle (próxima meta, metas del día, Serenidad). Un punto
/// avisa si hay un lugar para comprar o metas nuevas sin mirar.
class _LevelOrb extends StatelessWidget {
  final bool open;
  final VoidCallback onTap;
  const _LevelOrb({required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    return Pressable(
      onTap: onTap,
      child: Badge(
        isLabelVisible: p.expansionAvailable || p.goalsUnseen(),
        smallSize: 10,
        backgroundColor: Palette.lantern,
        offset: const Offset(-2, 2),
        child: Glass(
          radius: BorderRadius.circular(22),
          opacity: open ? 0.86 : 0.62,
          child: SizedBox.square(
            dimension: 44,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: p.levels.progress(p.calm)),
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeInOutCubic,
              builder: (context, v, child) => CustomPaint(painter: _RingPainter(v), child: child),
              child: Center(
                child: Text(
                  '${p.level}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Palette.ink),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  _RingPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final r = (Offset.zero & size).deflate(4.5);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, 2 * pi, false, stroke..color = Palette.ink.withValues(alpha: 0.1));
    canvas.drawArc(r, -pi / 2, 2 * pi * value.clamp(0.0, 1.0), false, stroke..color = Palette.lantern);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

/// La billetera cerrada: las Piedritas (lo que más se usa) y una flecha. Se
/// toca para ver todas las monedas; lo que se gana con ella cerrada vuela acá.
class _WalletPill extends StatelessWidget {
  final bool open;
  final VoidCallback onTap;
  const _WalletPill({required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    return Pressable(
      onTap: onTap,
      child: RewardTarget(
        currency: 'wallet',
        child: Glass(
          opacity: open ? 0.86 : 0.62,
          padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RewardTarget(
                currency: 'pebbles',
                child: HeldAmount(currency: 'pebbles', value: p.pebbles, builder: CurrencyChip.pebbles),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: Icon(Icons.expand_more_rounded, size: 20, color: Palette.ink.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La billetera abierta: cada esencia y los lotos, con el atajo al Mercado.
class _WalletPanel extends StatelessWidget {
  final VoidCallback onMarket;
  const _WalletPanel({required this.onMarket});

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Glass(
          opacity: 0.84,
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 18,
                runSpacing: 12,
                children: [
                  for (final e in Essence.values)
                    RewardTarget(
                      currency: e.name,
                      child: HeldAmount(
                        currency: e.name,
                        value: p.essences[e]!,
                        builder: (n) => CurrencyChip.essence(e, n),
                      ),
                    ),
                  RewardTarget(
                    currency: 'lotus',
                    child: HeldAmount(currency: 'lotus', value: p.lotus, builder: CurrencyChip.lotus),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: InkButton.paper(
                  label: tr('shop.title'),
                  glyph: InkGlyph.market,
                  height: 38,
                  onPressed: onMarket,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El detalle del nivel: la Calma, lo próximo para conseguir, las metas del
/// día y la Serenidad del jardín.
class _LevelPanel extends StatelessWidget {
  const _LevelPanel();

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final serenity = p.serenity / p.economy.balance.serenity.i('max');
    return Glass(
      opacity: 0.86,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showExpansionsSheet(context),
            child: Row(
              children: [
                Badge(
                  isLabelVisible: p.expansionAvailable,
                  smallSize: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: Palette.clay, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      tr('level.short', {'n': p.level}),
                      style: const TextStyle(color: Palette.paper, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: CalmBar(p.levels.progress(p.calm), Palette.lantern)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const NextGoal(),
          const DailyGoalsLine(),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(tr('garden.serenity'), style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(width: 10),
              Expanded(child: CalmBar(serenity, Palette.moss)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Botón redondo de vidrio, con un punto si hay algo nuevo y, en la primera
/// partida guiada, un brillo que late.
class _RoundButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool dot, pulse;
  final VoidCallback onTap;
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.dot = false,
    this.pulse = false,
  });

  @override
  State<_RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<_RoundButton> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_RoundButton old) {
    super.didUpdateWidget(old);
    if (old.pulse != widget.pulse) _sync();
  }

  /// Solo late cuando hay algo que avisar: quieto no gasta cuadros.
  void _sync() {
    if (widget.pulse) {
      _c.repeat(reverse: true);
    } else {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: Pressable(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) => DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                if (widget.pulse)
                  BoxShadow(
                    color: Palette.lantern.withValues(alpha: 0.35 + 0.45 * _c.value),
                    blurRadius: 6 + 10 * _c.value,
                  ),
              ],
            ),
            child: child,
          ),
          child: Badge(
            isLabelVisible: widget.dot,
            smallSize: 10,
            backgroundColor: Palette.lantern,
            offset: const Offset(-2, 2),
            child: Glass(
              radius: BorderRadius.circular(22),
              child: SizedBox.square(dimension: 44, child: Icon(widget.icon, size: 22, color: Palette.ink)),
            ),
          ),
        ),
      ),
    );
  }
}

/// El resto, guardado en un menú: el álbum y los ajustes.
class _MenuButton extends StatelessWidget {
  const _MenuButton();

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    void open() {
      SoundBoard.instance.play(Sfx.uiTap, volume: 0.4);
      showWashiSheet<void>(
        context,
        builder: (sheet) {
          Widget item(IconData icon, String label, bool dot, VoidCallback go) => WashiTile(
            onTap: () {
              Navigator.pop(sheet);
              go();
            },
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Badge(
                  isLabelVisible: dot,
                  backgroundColor: Palette.lantern,
                  child: Icon(icon, color: Palette.wood),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(label, style: Theme.of(sheet).textTheme.titleMedium)),
              ],
            ),
          );
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  item(Icons.collections_bookmark_rounded, tr('album.title'), p.albumNew, () {
                    SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
                    showAlbumSheet(context);
                  }),
                  item(Icons.emoji_events_rounded, tr('ach.title'), p.achievementsNew, () {
                    SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
                    showAchievementsSheet(context);
                  }),
                  item(Icons.settings_rounded, tr('settings.title'), false, () {
                    SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
                    showSettingsSheet(context);
                  }),
                ],
              ),
            ),
          );
        },
      );
    }

    return Pressable(
      onTap: open,
      child: Badge(
        isLabelVisible: p.albumNew || p.achievementsNew,
        smallSize: 10,
        backgroundColor: Palette.lantern,
        offset: const Offset(-2, 2),
        child: Glass(
          radius: BorderRadius.circular(22),
          child: const SizedBox.square(dimension: 44, child: Icon(Icons.menu_rounded, size: 22, color: Palette.ink)),
        ),
      ),
    );
  }
}

/// Guía: una burbuja bajo la fila de arriba que señala un botón (el Mercado
/// después de la primera partida, decorar al llegar a su nivel). [right] es
/// cuánto se corre desde el borde para quedar debajo de ese botón.
class _GuideHint extends StatelessWidget {
  final String text;
  final double right;
  final VoidCallback onTap;
  const _GuideHint({required this.text, required this.right, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Pressable(
        onTap: onTap,
        child: CalmAppear(
          delay: const Duration(milliseconds: 400),
          child: Container(
            margin: EdgeInsets.only(right: right, top: 4),
            constraints: const BoxConstraints(maxWidth: 240),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Palette.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Palette.lantern, width: 1.5),
              boxShadow: [
                BoxShadow(color: Palette.ink.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Palette.ink),
            ),
          ),
        ),
      ),
    );
  }
}

/// En la vista Clásica: los juegos a mano, en una tira que se desliza.
class _GameStrip extends StatelessWidget {
  final List<String> games;
  final void Function(String place) onTap;
  const _GameStrip({required this.games, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          for (final g in games)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _QuickChip(
                key: ValueKey('strip$g'),
                label: placeName(Place.values.byName(g)),
                known: true,
                onTap: () => onTap(g),
              ),
            ),
        ],
      ),
    );
  }
}

/// Abajo, en el Sendero: el acceso rápido a los juegos y la vista aérea para
/// decorar.
class _SenderoBar extends StatelessWidget {
  final VoidCallback onQuick;
  final VoidCallback? onDecor;
  const _SenderoBar({required this.onQuick, required this.onDecor});

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    Widget button(Key key, IconData icon, String label, VoidCallback onTap, {bool pulse = false}) => Pressable(
      key: key,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: pulse ? Palette.lantern : Palette.wood),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Palette.ink),
            ),
          ],
        ),
      ),
    );
    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(const ValueKey('quick'), Icons.signpost_rounded, tr('sendero.quick'), onQuick),
          if (onDecor != null) ...[
            Container(width: 1, height: 22, color: Palette.ink.withValues(alpha: 0.15)),
            button(
              const ValueKey('aerial'),
              Icons.map_rounded,
              tr('aerial.title'),
              onDecor!,
              pulse: p.guideStep == Guide.place || p.guideStep == Guide.decor,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool known;
  final VoidCallback? onTap;
  const _QuickChip({super.key, required this.label, required this.known, required this.onTap});

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: known ? Palette.paper : Palette.paper.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: known ? Palette.wood.withValues(alpha: 0.5) : Palette.ink.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Palette.ink.withValues(alpha: known ? 0.9 : 0.45),
        ),
      ),
    ),
  );
}
