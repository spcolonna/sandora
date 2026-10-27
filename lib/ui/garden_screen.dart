import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../garden/economy.dart';
import '../garden/progress.dart';
import '../i18n/i18n.dart';
import '../minigames/catalog.dart';
import '../minigames/sand/sand_painter.dart';
import '../minigames/sand/sand_shapes.dart';
import 'expansions_sheet.dart';
import 'fx/calm.dart';
import 'widgets/garden_sign.dart';
import 'fx/sfx.dart';
import 'meditation/meditation_screen.dart';
import 'settings_sheet.dart';
import 'theme/palette.dart';
import 'widgets/currency.dart';

/// Pantalla principal: el jardín, lo que juntó la torre y los minijuegos.
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
    // La torre junta Piedritas en tiempo real: se refresca cada tanto.
    _tick = Timer.periodic(const Duration(seconds: 20), (_) => setState(() {}));
    SoundBoard.instance.loop(Ambience.wind, volume: 0.18);
    // Una meditación que quedó a medias al cerrar la app se retoma.
    if (Progress.instance.meditationStartedAt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _meditate());
    } else if (!Progress.instance.gardenNameOffered) {
      // La primera vez, después de mirar el jardín un momento, se ofrece
      // ponerle nombre.
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted && !Progress.instance.gardenNameOffered) showGardenNameSheet(context);
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
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
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _GardenPainter(p.tower, p.sandDrawing, DateTime.now().hour, p.patioSize),
                          ),
                        ),
                        Positioned(left: 12, bottom: 12, child: _TowerBadge()),
                        const Positioned(left: 12, top: 4, child: GardenSign()),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Badge(
                            isLabelVisible: p.expansionAvailable,
                            smallSize: 12,
                            child: FilledButton.tonalIcon(
                              onPressed: () => showExpansionsSheet(context),
                              icon: const Icon(Icons.open_in_full_rounded, size: 18),
                              label: Text(tr('exp.button')),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final m in minigames) _MinigameTile(m, onTap: () => _open(m)),
              _MeditationTile(onTap: _meditate),
              const SizedBox(height: 12),
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
                  children: [for (final e in Essence.values) CurrencyChip.essence(e, p.essences[e]!)],
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: Palette.moss, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    tr('level.short', {'n': p.level}),
                    style: const TextStyle(color: Palette.paper, fontWeight: FontWeight.w700),
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

class _TowerBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final pending = p.towerPending();
    final label = p.tower.isEmpty ? tr('garden.tower.empty') : trN('garden.tower.stones', p.tower.length);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Palette.paper.withValues(alpha: 0.88), borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (pending > 0) ...[
            const SizedBox(width: 10),
            FilledButton.tonal(
              onPressed: () {
                p.collectTower();
                SoundBoard.instance.play(Sfx.stackPlace, volume: 0.6);
                Haptics.medium();
              },
              child: Text(tr('garden.tower.collect', {'n': pending})),
            ),
          ],
        ],
      ),
    );
  }
}

class _MinigameTile extends StatelessWidget {
  final MinigameInfo m;
  final VoidCallback onTap;
  const _MinigameTile(this.m, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: CurrencyChip.essenceColor(m.essence).withValues(alpha: 0.25),
                  child: Icon(m.icon, color: Palette.ink),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.name, style: Theme.of(context).textTheme.titleMedium),
                      Text(m.description, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.play_arrow_rounded, size: 30, color: Palette.moss),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El meditador: se destraba en el nivel del Modo meditación.
class _MeditationTile extends StatelessWidget {
  final VoidCallback onTap;
  const _MeditationTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final open = p.meditationUnlocked;
    final text = Theme.of(context).textTheme;
    final sub = !open
        ? tr('meditation.locked', {'n': p.levels.meditationLevel})
        : p.meditationStreak > 0
        ? trN('meditation.streak', p.meditationStreak)
        : tr('meditation.desc');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Opacity(
        opacity: open ? 1 : 0.55,
        child: Material(
          color: Palette.dusk.withValues(alpha: open ? 0.14 : 0.06),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: open ? onTap : () => showExpansionsSheet(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Palette.lantern.withValues(alpha: 0.25),
                    child: Icon(open ? Icons.self_improvement_rounded : Icons.lock_rounded, color: Palette.ink),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('meditation.title'), style: text.titleMedium),
                        Text(sub, style: text.bodySmall),
                      ],
                    ),
                  ),
                  if (open) const Icon(Icons.play_arrow_rounded, size: 30, color: Palette.moss),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El jardín dibujado con código hasta tener los fondos y objetos del Lote 1:
/// cielo según la hora real, arena con el último dibujo y la torre guardada.
class _GardenPainter extends CustomPainter {
  final List<TowerStone> tower;
  final List<double> drawing;
  final int hour;

  /// Ampliaciones de patio compradas: el terreno cuidado crece.
  final int patio;
  _GardenPainter(this.tower, this.drawing, this.hour, this.patio);

  bool get _night => hour < 7 || hour >= 20;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = _night ? [Palette.dusk, const Color(0xFF6B6F86)] : [Palette.skyTop, Palette.skyBottom];
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky,
        ).createShader(Offset.zero & size),
    );
    // Colinas lejanas y follaje.
    final hill = Path()..moveTo(0, size.height * 0.42);
    for (var x = 0.0; x <= size.width; x += 8) {
      hill.lineTo(x, size.height * (0.38 + 0.04 * sin(x / 37) + 0.02 * sin(x / 13)));
    }
    hill
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill, Paint()..color = _night ? const Color(0xFF3D5048) : Palette.mossDark.withValues(alpha: 0.7));
    // Pasto silvestre alrededor; la arena es el terreno ya cuidado.
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.5),
      Paint()..color = _night ? const Color(0xFF34443B) : Palette.moss,
    );
    const inset = [0.17, 0.07, 0.0], top = [0.6, 0.54, 0.5];
    final k = patio.clamp(0, 2);
    final ground = Rect.fromLTRB(size.width * inset[k], size.height * top[k], size.width * (1 - inset[k]), size.height);
    canvas.save();
    canvas.clipRect(ground);
    canvas.translate(ground.left, ground.top);
    canvas.drawPicture(sandTexture(ground.size, seed: 11));
    canvas.restore();
    // Dibujo del arenero sobre la arena.
    if (drawing.length >= 4) {
      final side = min(ground.width * 0.55, ground.height * 0.9);
      final box = Rect.fromLTWH(ground.left + 12, ground.top + (ground.height - side) / 2, side, side);
      final pts = <P>[for (var i = 0; i + 1 < drawing.length; i += 2) (x: drawing[i], y: drawing[i + 1])];
      drawGrooves(canvas, [pts], box, 1, tines: 4);
    } else {
      final tp = TextPainter(
        text: TextSpan(
          text: tr('garden.sand.empty'),
          style: TextStyle(color: Palette.ink.withValues(alpha: 0.45)),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width * 0.5);
      tp.paint(canvas, Offset(16, ground.top + 16));
    }
    _paintFence(canvas, ground, size);
    _paintTower(canvas, Offset(ground.left + ground.width * 0.76, size.height * 0.82), size.width * 0.06);
    if (_night) {
      // Farol encendido.
      canvas.drawCircle(
        Offset(size.width * 0.58, size.height * 0.62),
        26,
        Paint()..color = Palette.lantern.withValues(alpha: 0.25),
      );
      canvas.drawCircle(Offset(size.width * 0.58, size.height * 0.62), 6, Paint()..color = Palette.lantern);
    }
  }

  /// Cerco de bambú en el borde del terreno cuidado (si no ocupa todo).
  void _paintFence(Canvas canvas, Rect ground, Size size) {
    if (ground.left <= 0) return;
    final post = Paint()..color = const Color(0xFFB59A5B);
    final rail = Paint()
      ..color = const Color(0xFF8E7746)
      ..strokeWidth = 3;
    for (final x in [ground.left, ground.right]) {
      for (var y = ground.top; y < size.height; y += 16) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 3, y - 10, 6, 14), const Radius.circular(2)), post);
      }
      canvas.drawLine(Offset(x, ground.top - 6), Offset(x, size.height), rail);
    }
    canvas.drawLine(Offset(ground.left, ground.top - 4), Offset(ground.right, ground.top - 4), rail);
  }

  void _paintTower(Canvas canvas, Offset base, double scale) {
    final ped = Rect.fromCenter(center: base + Offset(0, scale * 0.5), width: scale * 3.4, height: scale);
    canvas.drawRRect(RRect.fromRectAndRadius(ped, Radius.circular(scale * 0.15)), Paint()..color = Palette.stoneDark);
    var y = base.dy;
    final tones = [Palette.stone, Palette.stoneLight, Palette.stoneDark];
    for (var i = 0; i < tower.length; i++) {
      final s = tower[i];
      final r = Rect.fromLTWH(base.dx + (s.x - s.w / 2) * scale, y - s.h * scale, s.w * scale, s.h * scale);
      canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(s.h * scale * 0.45)), Paint()..color = tones[i % 3]);
      y -= s.h * scale;
    }
  }

  @override
  bool shouldRepaint(_GardenPainter old) =>
      old.tower != tower || old.drawing != drawing || old.hour != hour || old.patio != patio;
}
