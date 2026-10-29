import 'dart:async';

import 'package:flutter/material.dart';

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
import 'shop_sheet.dart';
import 'widgets/daily_goals.dart';
import 'widgets/garden_sign.dart';
import 'meditation/meditation_screen.dart';
import 'settings_sheet.dart';
import 'theme/palette.dart';
import 'widgets/currency.dart';
import 'widgets/next_goal.dart';

/// Pantalla principal: el jardín, que también es el menú (se toca cada lugar
/// para entrar), con las monedas y el nivel arriba.
class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> with WidgetsBindingObserver {
  final _pages = PageController();
  int _page = 0;

  Timer? _tick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    _pages.dispose();
    super.dispose();
  }

  Future<void> _enter(Place place) async {
    switch (place) {
      case Place.market:
        SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
        Progress.instance.advanceGuide(2);
        showShopSheet(context);
      case Place.board:
        SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
        showBoardSheet(context);
      case Place.meditation:
        Progress.instance.meditationUnlocked ? _meditate() : showExpansionsSheet(context);
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
    // Lo ganado en las partidas vuela a sus contadores al volver.
    final from = MediaQuery.sizeOf(context).center(const Offset(0, 60));
    var wait = 380;
    for (final k in keys) {
      final gain = p.walletOf(k) - before[k]!;
      if (gain <= 0) continue;
      Future.delayed(Duration(milliseconds: wait), () {
        if (mounted) RewardFlight.fly(context, from: from, currency: k, amount: gain);
      });
      wait += 200;
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
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([p, WeatherService.instance]),
          builder: (context, _) => Column(
            children: [
              _Header(onSettings: () => showSettingsSheet(context)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          // El patio y, deslizando, el estanque y el bosque.
                          child: PageView(
                            controller: _pages,
                            physics: const _QuickPagePhysics(),
                            onPageChanged: (i) => setState(() => _page = i),
                            children: [
                              for (final side in [0, 1, 2])
                                GardenView(
                                  side: side,
                                  now: gardenNow(),
                                  weather: WeatherService.instance.at(gardenNow()),
                                  onPlace: _enter,
                                ),
                            ],
                          ),
                        ),
                      ),
                      _SideDots(
                        page: _page,
                        onTap: (i) => _pages.animateToPage(i, duration: _pageTurn, curve: Calm.curve),
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
  }
}

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

class _Header extends StatelessWidget {
  final VoidCallback onSettings;
  const _Header({required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final serenity = p.serenity / p.economy.balance.serenity.i('max');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      child: Column(
        children: [
          Row(
            children: [
              RewardTarget(currency: 'pebbles', child: CurrencyChip.pebbles(p.pebbles)),
              const SizedBox(width: 14),
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    for (final e in Essence.values)
                      RewardTarget(currency: e.name, child: CurrencyChip.essence(e, p.essences[e]!)),
                    RewardTarget(currency: 'lotus', child: CurrencyChip.lotus(p.lotus)),
                  ],
                ),
              ),
              IconButton(onPressed: onSettings, icon: const Icon(Icons.settings_rounded)),
            ],
          ),
          const SizedBox(height: 6),
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
                    decoration: BoxDecoration(color: Palette.moss, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      tr('level.short', {'n': p.level}),
                      style: const TextStyle(color: Palette.paper, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: CalmBar(p.levels.progress(p.calm), Palette.lantern)),
                const SizedBox(width: 12),
              ],
            ),
          ),
          const NextGoal(),
          const DailyGoalsLine(),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(tr('garden.serenity'), style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(width: 10),
              Expanded(child: CalmBar(serenity, Palette.moss)),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lo próximo para conseguir, siempre a la vista debajo del nivel: qué se
/// puede abrir ya, qué falta juntar o cuánta Calma falta para el próximo
/// nivel con algo nuevo. Se toca para ver las ampliaciones.
/// Puntos debajo del jardín: el patio, el estanque y el bosque.
class _SideDots extends StatelessWidget {
  final int page;
  final void Function(int) onTap;
  const _SideDots({required this.page, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final (i, key) in [(0, 'garden.patio'), (1, 'garden.pond'), (2, 'garden.forest')])
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: page == i ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: page == i ? Palette.moss : Palette.ink.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tr(key),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: page == i ? FontWeight.w700 : FontWeight.w400,
                        color: Palette.ink.withValues(alpha: page == i ? 0.85 : 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
