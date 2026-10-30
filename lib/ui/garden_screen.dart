import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../garden/day_cycle.dart';
import '../garden/economy.dart';
import '../garden/progress.dart';
import '../garden/reminders.dart';
import '../garden/weather.dart';
import '../garden/weather_service.dart';
import '../i18n/i18n.dart';
import '../minigames/catalog.dart';
import 'board_sheet.dart';
import 'decor_tray.dart';
import 'expansions_sheet.dart';
import 'fx/calm.dart';
import 'fx/reward_flight.dart';
import 'fx/sfx.dart';
import 'garden/garden_scene.dart';
import 'garden/garden_view.dart';
import 'market_screen.dart';
import 'widgets/daily_goals.dart';
import 'widgets/garden_sign.dart';
import 'meditation/meditation_screen.dart';
import 'album_sheet.dart';
import 'settings_sheet.dart';
import 'theme/palette.dart';
import 'widgets/currency.dart';
import 'widgets/glass.dart';
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

  void _market() {
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
    Progress.instance.advanceGuide(2);
    setState(() => _panel = _Panel.none);
    openMarket(context);
  }

  /// Modo Decorar, y la decoración recién puesta desde la bandeja.
  bool _decorating = false;

  /// El patio pintado está acercado: deslizar mueve la cámara, no la vista.
  bool _zoomed = false;
  int? _fresh;

  void _setDecorating(bool on) {
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
    setState(() {
      _decorating = on;
      _fresh = null;
      _panel = _Panel.none;
    });
  }

  Timer? _tick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pages.addListener(() => _drift.value = _pages.page ?? 0);
    // Las metas del día cumplidas fuera de una partida se anuncian enseguida
    // (también la de una meditación que terminó con la app cerrada).
    Progress.instance.addListener(_announceGoals);
    WidgetsBinding.instance.addPostFrameCallback((_) => _announceGoals());
    // Hoy ya se entró: los recordatorios arrancan mañana.
    Reminders.instance.reschedule();
    // La torre junta Piedritas y la luz del día y el clima cambian en tiempo
    // real: se refresca cada tanto.
    _tick = Timer.periodic(const Duration(seconds: 20), (_) {
      WeatherService.instance.refresh();
      Progress.instance.countDay(DateTime.now());
      setState(() {});
      _gardenSound();
      _announceUnlocks();
    });
    _gardenSound();
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
    if (state == AppLifecycleState.resumed) Reminders.instance.reschedule();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Progress.instance.removeListener(_announceGoals);
    _tick?.cancel();
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
        if (p.gameUnlocked(m.id)) return _open(m);
        if (p.unlockZone(m.id) != null) {
          await showExpansionsSheet(context);
          if (mounted) _announceUnlocks();
          return;
        }
        SoundBoard.instance.play(Sfx.uiTap, volume: 0.3);
        _toast(trN('garden.opensIn', p.unlockDay(m.id) - p.playDay));
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text, textAlign: TextAlign.center),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2400),
        ),
      );
  }

  /// Anuncia una vez los minijuegos que se abrieron (por día o por zona).
  void _announceUnlocks() {
    // Si hay un minijuego (u otra pantalla) encima, se avisa al volver.
    if (ModalRoute.of(context)?.isCurrent == false) return;
    final p = Progress.instance;
    final fresh = p.newUnlocks(minigames.map((m) => m.id));
    if (fresh.isEmpty) return;
    p.markUnlocksSeen(fresh);
    SoundBoard.instance.play(Sfx.good, volume: 0.4);
    _toast(tr('level.unlocked', {'list': fresh.map((id) => tr('mg.$id.name')).join(', ')}));
  }

  /// Viento de fondo y, si llueve, la lluvia.
  void _gardenSound() {
    final sound = SoundBoard.instance;
    sound.loop(Ambience.wind, volume: 0.18);
    switch (WeatherService.instance.at(gardenNow())) {
      case Weather.rain:
        sound.loop(Ambience.rain, volume: 0.22);
      case Weather.storm:
        sound.loop(Ambience.rain, volume: 0.32);
      default:
        sound.stopLoop(Ambience.rain);
    }
  }

  void _quiet() {
    SoundBoard.instance.stopLoop(Ambience.wind);
    SoundBoard.instance.stopLoop(Ambience.rain);
  }

  Future<void> _open(MinigameInfo m) async {
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
    _quiet();
    final p = Progress.instance;
    final keys = ['pebbles', for (final e in Essence.values) e.name, 'lotus'];
    final before = {for (final k in keys) k: p.walletOf(k)};
    await Navigator.of(context).push(calmRoute<void>(m.screen()));
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
    // Después de la primera partida (no al abrir la app) se ofrecen los avisos.
    if (Progress.instance.guideStep >= 1) Reminders.instance.askOnce();
  }

  Future<void> _meditate() async {
    _quiet();
    await Navigator.of(context).push(calmRoute<void>(const MeditationScreen()));
    if (mounted) _gardenSound();
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
                          // Decorando, se arrastran las decoraciones: las vistas se cambian con los puntos.
                          physics: _decorating || _zoomed
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
                                decorating: _decorating,
                                fresh: side == _page ? _fresh : null,
                                top: top,
                                bottom: _decorating ? 8 : bottom,
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
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _decorating
                                ? _DecorBar(onDone: () => _setDecorating(false))
                                : _Hud(
                                    now: now,
                                    weather: weather,
                                    panel: _panel,
                                    onPanel: _toggle,
                                    onMarket: _market,
                                    onDecor: () => _setDecorating(true),
                                  ),
                          ),
                        ),
                      ),
                      if (!_decorating)
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
                              _Panel.none when p.guideStep == 1 => _MarketHint(onTap: () => p.advanceGuide(2)),
                              _Panel.none => const SizedBox.shrink(),
                            },
                          ),
                        ),
                      if (!_decorating)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: pad.bottom + 10,
                          child: Center(
                            child: _SideDots(
                              page: _page,
                              onTap: (i) => _pages.animateToPage(i, duration: _pageTurn, curve: Calm.curve),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Decorando, la bandeja empuja el jardín hacia arriba.
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Calm.curve,
                  child: _decorating
                      ? ColoredBox(
                          color: Palette.paper,
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                              child: Column(
                                children: [
                                  _SideDots(
                                    page: _page,
                                    onTap: (i) => _pages.animateToPage(i, duration: _pageTurn, curve: Calm.curve),
                                    flat: true,
                                  ),
                                  DecorTray(side: _page, onPlaced: (i) => setState(() => _fresh = i)),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
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

/// Alto de la fila de arriba y a qué tamaño va el cartel del jardín.
const _hudRow = 56.0, _signScale = 0.78;

/// Mientras la página se mueve, el PageView no deja tocar los lugares (el
/// primer toque solo la frena): se asienta rápido para que eso casi no pase.
const _pageTurn = Duration(milliseconds: 300);

class _QuickPagePhysics extends PageScrollPhysics {
  const _QuickPagePhysics({super.parent});

  @override
  _QuickPagePhysics applyTo(ScrollPhysics? ancestor) => _QuickPagePhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(mass: 0.5, stiffness: 420, ratio: 1.1);
}

/// Arriba, mientras se decora: qué se puede hacer y el botón para terminar.
class _DecorBar extends StatelessWidget {
  final VoidCallback onDone;
  const _DecorBar({required this.onDone});

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Glass(
        opacity: 0.8,
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('decor.title'), style: text.titleMedium),
                  Text(tr('decor.hint'), style: text.bodySmall?.copyWith(color: Palette.ink.withValues(alpha: 0.65))),
                  const SizedBox(height: 6),
                  // Lo que se tiene, para saber qué alcanza.
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      CurrencyChip.pebbles(p.pebbles),
                      for (final e in Essence.values) CurrencyChip.essence(e, p.essences[e]!),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkButton.small(label: tr('decor.done'), onPressed: onDone),
          ],
        ),
      ),
    );
  }
}

/// Lo de arriba, liviano para no tapar el jardín: el nivel, la billetera, el
/// Mercado y el menú; debajo, el cartel con el nombre y el clima.
class _Hud extends StatelessWidget {
  final DateTime now;
  final Weather weather;
  final _Panel panel;
  final void Function(_Panel) onPanel;
  final VoidCallback onMarket, onDecor;
  const _Hud({
    required this.now,
    required this.weather,
    required this.panel,
    required this.onPanel,
    required this.onMarket,
    required this.onDecor,
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
                  pulse: p.guideStep == 1,
                  onTap: onMarket,
                ),
                const SizedBox(width: 8),
                _MenuButton(onDecor: onDecor),
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
/// para ver el detalle (próxima meta, metas del día, Serenidad).
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
        isLabelVisible: p.expansionAvailable,
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
                child: TextButton.icon(
                  onPressed: onMarket,
                  icon: const Icon(Icons.storefront_rounded, size: 18),
                  label: Text(tr('shop.title')),
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
          InkWell(
            onTap: () => showExpansionsSheet(context),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Badge(
                  isLabelVisible: p.expansionAvailable,
                  smallSize: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFA35A33), borderRadius: BorderRadius.circular(10)),
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

/// El resto, guardado en un menú: decorar, el álbum y los ajustes.
class _MenuButton extends StatelessWidget {
  final VoidCallback onDecor;
  const _MenuButton({required this.onDecor});

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    Widget item(IconData icon, String label, bool dot) => Row(
      children: [
        Badge(
          isLabelVisible: dot,
          backgroundColor: Palette.lantern,
          child: Icon(icon, color: Palette.ink),
        ),
        const SizedBox(width: 14),
        Text(label),
      ],
    );
    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, 52),
      color: Palette.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onOpened: () => SoundBoard.instance.play(Sfx.uiTap, volume: 0.4),
      onSelected: (id) {
        switch (id) {
          case 'decor':
            onDecor();
          case 'album':
            SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
            showAlbumSheet(context);
          case 'settings':
            showSettingsSheet(context);
        }
      },
      itemBuilder: (context) => [
        if (p.decorUnlocked)
          PopupMenuItem(value: 'decor', child: item(Icons.local_florist_rounded, tr('decor.title'), p.decorNew)),
        PopupMenuItem(value: 'album', child: item(Icons.collections_bookmark_rounded, tr('album.title'), p.albumNew)),
        PopupMenuItem(value: 'settings', child: item(Icons.settings_rounded, tr('settings.title'), false)),
      ],
      child: Badge(
        isLabelVisible: (p.decorUnlocked && p.decorNew) || p.albumNew,
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

/// Primera partida guiada: después de jugar, la burbuja que señala el Mercado.
class _MarketHint extends StatelessWidget {
  final VoidCallback onTap;
  const _MarketHint({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: GestureDetector(
        onTap: onTap,
        child: CalmAppear(
          delay: const Duration(milliseconds: 400),
          child: Container(
            margin: const EdgeInsets.only(right: 30, top: 4),
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
              tr('guide.market'),
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
/// vidrio abajo; [flat] sin vidrio, sobre la bandeja de decorar.
class _SideDots extends StatelessWidget {
  final int page;
  final void Function(int) onTap;
  final bool flat;
  const _SideDots({required this.page, required this.onTap, this.flat = false});

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
    if (flat) return dots;
    return Glass(padding: const EdgeInsets.symmetric(horizontal: 6), child: dots);
  }
}
