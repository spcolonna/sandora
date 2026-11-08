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
import 'sendero_screen.dart';
import 'rest_sheet.dart';
import 'widgets/daily_goals.dart';
import 'widgets/garden_sign.dart';
import 'meditation/meditation_screen.dart';
import 'achievements_sheet.dart';
import 'album_sheet.dart';
import 'settings_sheet.dart';
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
  final _pages = PageController();
  int _page = 0;

  /// Dónde va el deslizamiento entre vistas, para el fondo que se corre lento.
  final _drift = ValueNotifier<double>(0);

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

  /// El patio pintado está acercado: deslizar mueve la cámara, no la vista.
  bool _zoomed = false;

  /// La decoración que se pidió ver desde la Maqueta (índice, pedido).
  (int, int)? _focus;
  var _focusAsks = 0;

  /// Abre la Maqueta; al volver, si se pidió ver una decoración, va a su vista.
  Future<void> _model() async {
    final p = Progress.instance;
    if (p.guideStep == Guide.decor) p.advanceGuide(Guide.done);
    setState(() => _panel = _Panel.none);
    final focus = await openModel(context, side: _page);
    if (!mounted) return;
    // Al poner la primera decoración, a subir de nivel; el aviso de lo que
    // cambió se ve ya en el jardín.
    if (p.guideStep == Guide.place && p.decor.any((d) => d.placed)) p.advanceGuide(Guide.level2);
    _celebrate();
    if (focus == null) return;
    final index = focus.index;
    if (index == null) return _walk(focus.side);
    if (focus.side != _page) {
      await _pages.animateToPage(focus.side, duration: _pageTurn, curve: Calm.curve);
      if (!mounted) return;
    }
    setState(() => _focus = (index, ++_focusAsks));
  }

  /// El paseo en primera persona: la vista en que camina la cámara y su
  /// pedido (null, sin paseo), y en qué se paró.
  int _walkSide = 0;
  int? _walkAsk;
  var _walkAsks = 0;
  (String, String)? _walkStop;
  Completer<void>? _walkSideDone;

  bool get _walking => _walkAsk != null;

  /// Pasea desde la vista [from] hasta el bosque; se termina tocando.
  Future<void> _walk(int from) async {
    setState(() => _panel = _Panel.none);
    for (var side = from; side < 3; side++) {
      if (side != _page) {
        setState(() => _walkStop = null);
        await _pages.animateToPage(side, duration: const Duration(milliseconds: 900), curve: Curves.easeInOutSine);
        if (!mounted || (side != from && !_walking)) return;
      }
      final done = _walkSideDone = Completer<void>();
      setState(() {
        _walkSide = side;
        _walkAsk = ++_walkAsks;
      });
      await done.future;
      if (!mounted || !_walking) return;
    }
    _endWalk();
  }

  void _endWalk() {
    if (!_walking) return;
    if (_walkSideDone case final d? when !d.isCompleted) d.complete();
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.3);
    setState(() {
      _walkAsk = null;
      _walkStop = null;
    });
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
    _pages.addListener(() => _drift.value = _pages.page ?? 0);
    // Las metas del día cumplidas fuera de una partida se anuncian enseguida
    // (también la de una meditación que terminó con la app cerrada).
    Progress.instance.addListener(_announceGoals);
    CloudSave.instance.restored.addListener(_celebrate);
    WidgetsBinding.instance.addPostFrameCallback((_) => _announceGoals());
    // Para ver el paseo sin tocar nada: `--dart-define=SANDORA_WALK=true`.
    if (_autoWalk && kDebugMode) {
      Future<void>.delayed(const Duration(seconds: 4), () {
        if (mounted) _walk(0);
      });
    }
    // Para ver el Sendero sin tocar nada: `--dart-define=SANDORA_PATH=true`.
    if (_autoPath && kDebugMode) {
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) openSendero(context);
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
    _pages.dispose();
    _drift.dispose();
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

  void _quiet() {
    SoundBoard.instance.stopLoop(Ambience.wind);
    SoundBoard.instance.stopLoop(Ambience.rain);
    SoundBoard.instance.stopMusic();
  }

  Future<void> _open(MinigameInfo m) async {
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
    _quiet();
    final p = Progress.instance;
    final keys = ['pebbles', for (final e in Essence.values) e.name, 'lotus'];
    final before = {for (final k in keys) k: p.walletOf(k)};
    _away = true;
    await Navigator.of(context).push(calmRoute<void>(m.screen()));
    _away = false;
    if (!mounted) return;
    _gardenSound();
    // Lo ganado en las partidas vuela a sus contadores al volver: la
    // billetera se abre un momento para verlo llegar y se vuelve a cerrar.
    final from = MediaQuery.sizeOf(context).center(const Offset(0, 60));
    var wait = 380;
    final gains = {for (final k in keys) k: p.walletOf(k) - before[k]!}..removeWhere((_, g) => g <= 0);
    if (gains.keys.any((k) => k != 'pebbles') && _panel == _Panel.none) {
      setState(() => _panel = _Panel.wallet);
    }
    for (final MapEntry(key: k, value: gain) in gains.entries) {
      Future.delayed(Duration(milliseconds: wait), () {
        if (mounted) RewardFlight.fly(context, from: from, currency: k, amount: gain);
      });
      wait += 200;
    }
    if (_panel == _Panel.wallet) {
      _walletAuto?.cancel();
      _walletAuto = Timer(Duration(milliseconds: wait + 1800), () {
        if (mounted && _panel == _Panel.wallet) setState(() => _panel = _Panel.none);
      });
    }
    // Después de ver llegar lo ganado, el aviso grande (si subió de nivel).
    Future.delayed(Duration(milliseconds: wait + 500), _celebrate);
    // Después de la primera partida (no al abrir la app) se ofrecen los avisos.
    if (Progress.instance.guideStep >= 1) Reminders.instance.askOnce();
  }

  Future<void> _meditate() async {
    _quiet();
    _away = true;
    await Navigator.of(context).push(calmRoute<void>(const MeditationScreen()));
    _away = false;
    if (mounted) _gardenSound();
    Future.delayed(const Duration(milliseconds: 600), _celebrate);
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
        listenable: Listenable.merge([p, WeatherService.instance]),
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
                        child: RepaintBoundary(
                          child: GardenBackdrop(now: now, weather: weather, page: _drift, top: top),
                        ),
                      ),
                      // El patio y, deslizando, el estanque y el bosque.
                      Positioned.fill(
                        child: PageView(
                          controller: _pages,
                          physics: _zoomed || _walking
                              ? const NeverScrollableScrollPhysics()
                              : const _QuickPagePhysics(),
                          onPageChanged: (i) => setState(() => _page = i),
                          children: [
                            for (final side in [0, 1, 2])
                              GardenView(
                                side: side,
                                now: now,
                                weather: weather,
                                onPlace: _enter,
                                onZoom: side == 0 ? (z) => setState(() => _zoomed = z) : null,
                                onModel: side == 0 ? _model : null,
                                focus: side == _page ? _focus : null,
                                walk: side == _walkSide ? _walkAsk : null,
                                onWalkStop: (name, kind) => setState(() => _walkStop = (name, kind)),
                                onWalkDone: () => _walkSideDone?.complete(),
                                top: top,
                                bottom: bottom,
                              ),
                          ],
                        ),
                      ),
                      Positioned.fill(
                        child: GardenSkyLife(now: now, weather: weather),
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
                            hidden: _walking,
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
                            _ when _walking => const SizedBox.shrink(),
                            _Panel.wallet => _WalletPanel(onMarket: _market),
                            _Panel.level => const _LevelPanel(),
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
                            // La guía de decorar marca la mesa, en el patio; desde otra vista, lo dice acá.
                            _Panel.none
                                when (p.guideStep == Guide.place || p.guideStep == Guide.decor) &&
                                    p.decorUnlocked &&
                                    _page != 0 =>
                              _GuideHint(
                                text: tr('guide.modelBack'),
                                right: 0,
                                onTap: () => _pages.animateToPage(0, duration: _pageTurn, curve: Calm.curve),
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
                          child: _Hidden(
                            hidden: _walking,
                            child: _SideDots(
                              page: _page,
                              onTap: (i) => _pages.animateToPage(i, duration: _pageTurn, curve: Calm.curve),
                            ),
                          ),
                        ),
                      ),
                      // Paseando: franjas de cine, lo que se está mirando y,
                      // tocando en cualquier lado, se termina.
                      if (_walking)
                        Positioned.fill(
                          child: GestureDetector(
                            key: const ValueKey('walkEnd'),
                            behavior: HitTestBehavior.opaque,
                            onTap: _endWalk,
                          ),
                        ),
                      _WalkFrame(on: _walking, stop: _walkStop),
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

/// El marco del paseo: franjas arriba y abajo, como en el cine, y abajo el
/// nombre de lo que se está mirando.
class _WalkFrame extends StatelessWidget {
  final bool on;
  final (String, String)? stop;
  const _WalkFrame({required this.on, required this.stop});

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final text = Theme.of(context).textTheme;
    const dur = Duration(milliseconds: 700);
    final bar = Palette.ink.withValues(alpha: 0.82);
    final topH = pad.top + 36, bottomH = pad.bottom + 92;
    return IgnorePointer(
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: dur,
            curve: Calm.curve,
            left: 0,
            right: 0,
            top: on ? 0 : -topH,
            height: topH,
            child: ColoredBox(color: bar),
          ),
          AnimatedPositioned(
            duration: dur,
            curve: Calm.curve,
            left: 0,
            right: 0,
            bottom: on ? 0 : -bottomH,
            height: bottomH,
            child: Container(
              color: bar,
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Column(
                  key: ValueKey(stop),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stop?.$1 ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(color: Palette.paper, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stop == null ? tr('walk.end') : '${stop!.$2} · ${tr('walk.end')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: Palette.paper.withValues(alpha: 0.65)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Alto de la fila de arriba y a qué tamaño va el cartel del jardín.
const _hudRow = 56.0, _signScale = 0.78;

/// Mientras la página se mueve, el PageView no deja tocar los lugares (el
/// primer toque solo la frena): se asienta rápido para que eso casi no pase.
const _pageTurn = Duration(milliseconds: 300);
const _autoWalk = bool.fromEnvironment('SANDORA_WALK');
const _autoPath = bool.fromEnvironment('SANDORA_PATH');

class _QuickPagePhysics extends PageScrollPhysics {
  const _QuickPagePhysics({super.parent});

  @override
  _QuickPagePhysics applyTo(ScrollPhysics? ancestor) => _QuickPagePhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(mass: 0.5, stiffness: 420, ratio: 1.1);
}

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
    return GestureDetector(
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
    return GestureDetector(
      onTap: onTap,
      child: RewardTarget(
        currency: 'wallet',
        child: Glass(
          opacity: open ? 0.86 : 0.62,
          padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RewardTarget(currency: 'pebbles', child: CurrencyChip.pebbles(p.pebbles)),
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
                    RewardTarget(currency: e.name, child: CurrencyChip.essence(e, p.essences[e]!)),
                  RewardTarget(currency: 'lotus', child: CurrencyChip.lotus(p.lotus)),
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
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
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
                  item(Icons.settings_rounded, tr('settings.title'), false, () => showSettingsSheet(context)),
                ],
              ),
            ),
          );
        },
      );
    }

    return GestureDetector(
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
      child: GestureDetector(
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

/// Las tres vistas (el patio, el estanque y el bosque) en una pastilla de
/// vidrio abajo.
class _SideDots extends StatelessWidget {
  final int page;
  final void Function(int) onTap;
  const _SideDots({required this.page, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dots = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, key) in [(0, 'garden.patio'), (1, 'garden.pond'), (2, 'garden.forest')])
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: page == i ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: page == i ? Palette.wood : Palette.ink.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tr(key),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: page == i ? FontWeight.w700 : FontWeight.w500,
                      color: Palette.ink.withValues(alpha: page == i ? 0.9 : 0.6),
                    ),
                  ),
                  // En el bosque, una visita dejó su ofrenda en la casa de té.
                  if (i == 2 && page != 2 && Progress.instance.teaState() == TeaState.visit) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.redeem_rounded, size: 14, color: Palette.lantern),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
    return Glass(padding: const EdgeInsets.symmetric(horizontal: 6), child: dots);
  }
}
