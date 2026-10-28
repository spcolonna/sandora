import 'dart:async';

import 'package:flutter/material.dart';

import '../garden/day_cycle.dart';
import '../garden/economy.dart';
import '../garden/progress.dart';
import '../i18n/i18n.dart';
import '../minigames/catalog.dart';
import 'board_sheet.dart';
import 'expansions_sheet.dart';
import 'fx/calm.dart';
import 'fx/sfx.dart';
import 'garden/garden_scene.dart';
import 'garden/garden_view.dart';
import 'shop_sheet.dart';
import 'widgets/garden_sign.dart';
import 'meditation/meditation_screen.dart';
import 'settings_sheet.dart';
import 'theme/palette.dart';
import 'widgets/currency.dart';

/// Pantalla principal: el jardín, que también es el menú (se toca cada lugar
/// para entrar), con las monedas y el nivel arriba.
class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // La torre junta Piedritas y la luz del día cambia en tiempo real: se
    // refresca cada tanto.
    _tick = Timer.periodic(const Duration(seconds: 20), (_) => setState(() {}));
    SoundBoard.instance.loop(Ambience.wind, volume: 0.18);
    // Una meditación que quedó a medias al cerrar la app se retoma.
    if (Progress.instance.meditationStartedAt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _meditate());
    } else if (!Progress.instance.gardenNameOffered) {
      // La primera vez, después de mirar el jardín un momento, se ofrece
      // ponerle nombre (después de que se abren las puertas).
      Future.delayed(const Duration(milliseconds: 3400), () {
        if (mounted && !Progress.instance.gardenNameOffered) showGardenNameSheet(context);
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _enter(Place place) {
    switch (place) {
      case Place.market:
        SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
        showShopSheet(context);
      case Place.board:
        SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
        showBoardSheet(context);
      case Place.meditation:
        Progress.instance.meditationUnlocked ? _meditate() : showExpansionsSheet(context);
      case Place.sand || Place.stack || Place.rain:
        _open(minigames.firstWhere((m) => m.id == place.name));
    }
  }

  Future<void> _open(MinigameInfo m) async {
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
    SoundBoard.instance.stopLoop(Ambience.wind);
    await Navigator.of(context).push(calmRoute<void>(m.screen()));
    if (mounted) SoundBoard.instance.loop(Ambience.wind, volume: 0.18);
  }

  Future<void> _meditate() async {
    SoundBoard.instance.stopLoop(Ambience.wind);
    await Navigator.of(context).push(calmRoute<void>(const MeditationScreen()));
    if (mounted) SoundBoard.instance.loop(Ambience.wind, volume: 0.18);
  }

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: p,
          builder: (context, _) => Column(
            children: [
              _Header(onSettings: () => showSettingsSheet(context)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: GardenView(now: gardenNow(), onPlace: _enter),
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
              CurrencyChip.pebbles(p.pebbles),
              const SizedBox(width: 14),
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    for (final e in Essence.values) CurrencyChip.essence(e, p.essences[e]!),
                    CurrencyChip.lotus(p.lotus),
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
                Expanded(child: _Bar(p.levels.progress(p.calm), Palette.lantern)),
                const SizedBox(width: 12),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(tr('garden.serenity'), style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(width: 10),
              Expanded(child: _Bar(serenity, Palette.moss)),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double value;
  final Color color;
  const _Bar(this.value, this.color);

  @override
  Widget build(BuildContext context) {
    // Se llena despacio hasta el valor nuevo (Calma ganada, Serenidad).
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeInOutCubic,
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: v,
          minHeight: 10,
          color: color,
          backgroundColor: Palette.sandShadow.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
