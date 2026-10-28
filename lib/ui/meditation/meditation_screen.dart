import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../garden/economy.dart';
import '../../garden/meditation_rules.dart';
import '../../garden/progress.dart';
import '../../garden/reminders.dart';
import '../../i18n/i18n.dart';
import '../fx/sfx.dart';
import '../theme/palette.dart';
import '../widgets/currency.dart';
import '../widgets/level_up.dart';

enum _Phase { setup, session, result }

/// Modo meditación (GDD): elegir duración y sonido, contador con círculo de
/// respiración y recompensa por tiempo real, con techo diario. Si hay una
/// sesión en curso (la app se cerró en el medio), la retoma.
class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  final p = Progress.instance;
  late _Phase _phase = p.meditationStartedAt == null ? _Phase.setup : _Phase.session;
  late int _minutes = p.meditationStartedAt == null ? 5 : p.meditationChosen;
  Ambience? _ambience = Ambience.wind;
  bool _intervalBell = false;
  Timer? _tick;
  int _bellsRung = 0;
  ({MeditationReward reward, int? newLevel, int lotus})? _result;

  @override
  void initState() {
    super.initState();
    if (_phase == _Phase.session) _runTimer();
  }

  @override
  void dispose() {
    _tick?.cancel();
    SoundBoard.instance.stopAllLoops();
    super.dispose();
  }

  void _start() {
    p.startMeditation(_minutes);
    Reminders.instance.meditationStarted(p.meditationStartedAt!, _minutes);
    _bellsRung = 0;
    SoundBoard.instance.play(Sfx.bell, volume: 0.7);
    if (_ambience != null) SoundBoard.instance.loop(_ambience!, volume: 0.3);
    setState(() => _phase = _Phase.session);
    _runTimer();
  }

  void _runTimer() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final elapsed = p.meditationElapsed();
      if (elapsed.inMinutes >= p.meditationChosen) {
        _finish();
        return;
      }
      final every = p.economy.balance.meditation.i('intervalBellMinutes');
      final bells = elapsed.inMinutes ~/ every;
      if (_intervalBell && bells > _bellsRung) SoundBoard.instance.play(Sfx.bell, volume: 0.4);
      _bellsRung = bells;
      setState(() {});
    });
  }

  void _finish() {
    _tick?.cancel();
    // Se sale de meditar despacio: el ambiente se apaga en 3 s y suena la campana.
    SoundBoard.instance.stopAllLoops(fade: const Duration(seconds: 3));
    SoundBoard.instance.play(Sfx.bell, volume: 0.7);
    Haptics.light();
    setState(() {
      _result = p.finishMeditation();
      Reminders.instance.meditationEnded();
      _phase = _Phase.result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _phase != _Phase.session,
      // Entre fases el fondo se oscurece o aclara despacio y el contenido
      // cambia con un fundido largo, como bajar la luz.
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 1400),
        curve: Curves.easeInOut,
        color: _phase == _Phase.setup ? Palette.paper : const Color(0xFF22282B),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1100),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: KeyedSubtree(
                key: ValueKey(_phase),
                child: switch (_phase) {
                  _Phase.setup => _setup(context),
                  _Phase.session => _session(context),
                  _Phase.result => _resultView(context),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _setup(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final left = p.meditationMinutesLeft();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
        ),
        const Icon(Icons.self_improvement_rounded, size: 64, color: Palette.moss),
        Text(tr('meditation.title'), style: text.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(tr('meditation.desc'), style: text.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Text(tr('meditation.duration'), style: text.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final m in p.meditationRules.durations)
              ChoiceChip(
                label: Text(tr('meditation.minutes', {'n': m})),
                selected: _minutes == m,
                onSelected: (_) => setState(() => _minutes = m),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(tr('meditation.sound'), style: text.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(tr('meditation.silence')),
              selected: _ambience == null,
              onSelected: (_) => setState(() => _ambience = null),
            ),
            for (final a in Ambience.forMeditation)
              ChoiceChip(
                label: Text(tr('meditation.ambience.${a.name}')),
                selected: _ambience == a,
                onSelected: (_) => setState(() => _ambience = a),
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(tr('meditation.intervalBell', {'n': p.economy.balance.meditation.i('intervalBellMinutes')})),
          value: _intervalBell,
          onChanged: (v) => setState(() => _intervalBell = v),
        ),
        const SizedBox(height: 8),
        Text(
          left > 0 ? tr('meditation.left', {'n': left}) : tr('meditation.capReached'),
          style: text.bodySmall,
          textAlign: TextAlign.center,
        ),
        if (p.meditationStreak > 0)
          Text(trN('meditation.streak', p.meditationStreak), style: text.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _start,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(tr('meditation.start')),
        ),
      ],
    );
  }

  Widget _session(BuildContext context) {
    final elapsed = p.meditationElapsed();
    final left = Duration(minutes: p.meditationChosen) - elapsed;
    final m = p.economy.balance.meditation;
    final inhale = m.d('breathIn'), cycle = inhale + m.d('breathOut');
    final t = (elapsed.inMilliseconds / 1000) % cycle;
    final breathingIn = t < inhale;
    // Inhalar agranda, exhalar achica, con curva suave.
    final open = breathingIn ? _ease(t / inhale) : 1 - _ease((t - inhale) / m.d('breathOut'));
    final light = Palette.paper.withValues(alpha: 0.9);
    final mm = left.inMinutes.toString().padLeft(2, '0');
    final ss = (left.inSeconds % 60).toString().padLeft(2, '0');
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _DimGardenPainter()),
        Column(
          children: [
            const Spacer(),
            Text(
              '$mm:$ss',
              style: TextStyle(fontSize: 64, fontWeight: FontWeight.w300, color: light, letterSpacing: 2),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 240,
              height: 240,
              child: Center(
                child: Container(
                  width: 110 + 120 * open,
                  height: 110 + 120 * open,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Palette.moss.withValues(alpha: 0.25 + 0.2 * open),
                    border: Border.all(color: light.withValues(alpha: 0.35 + 0.15 * open), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Palette.moss.withValues(alpha: 0.18 + 0.2 * open),
                        blurRadius: 30 + 30 * open,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr(breathingIn ? 'meditation.inhale' : 'meditation.exhale'),
              style: TextStyle(fontSize: 20, color: light.withValues(alpha: 0.75)),
            ),
            const Spacer(),
            TextButton(
              onPressed: _finish,
              child: Text(tr('meditation.end'), style: TextStyle(color: light.withValues(alpha: 0.7))),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ],
    );
  }

  static double _ease(double x) => 0.5 - cos(x.clamp(0.0, 1.0) * pi) / 2;

  Widget _resultView(BuildContext context) {
    final r = _result!.reward;
    final light = Palette.paper.withValues(alpha: 0.95);
    final text = Theme.of(context).textTheme.apply(bodyColor: light, displayColor: light);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wb_sunny_rounded, size: 56, color: Palette.lantern),
            const SizedBox(height: 12),
            Text(trN('meditation.done', r.minutes), style: text.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (r.pebbles + r.light + r.calm + _result!.lotus > 0)
              DefaultTextStyle.merge(
                style: TextStyle(color: light),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    CurrencyChip.pebbles(r.pebbles, prefix: '+'),
                    if (r.light > 0) CurrencyChip.essence(Essence.light, r.light, prefix: '+'),
                    if (_result!.lotus > 0) CurrencyChip.lotus(_result!.lotus, prefix: '+'),
                    CalmChip(r.calm),
                  ],
                ),
              ),
            if (r.capped) ...[
              const SizedBox(height: 10),
              Text(tr('meditation.capped'), style: text.bodySmall, textAlign: TextAlign.center),
            ],
            if (p.meditationStreak > 0) ...[
              const SizedBox(height: 10),
              Text(trN('meditation.streak', p.meditationStreak), style: text.bodyMedium),
            ],
            if (_result!.newLevel != null) ...[
              const SizedBox(height: 16),
              DefaultTextStyle.merge(
                style: TextStyle(color: light),
                child: LevelUpBanner(_result!.newLevel!),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton(onPressed: () => Navigator.pop(context), child: Text(tr('result.garden'))),
          ],
        ),
      ),
    );
  }
}

/// El jardín en penumbra, dibujado con código hasta tener `bg_meditation`.
class _DimGardenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1C2226), Color(0xFF2E3A36), Color(0xFF3A3A33)],
        ).createShader(rect),
    );
    final hill = Path()..moveTo(0, size.height * 0.78);
    for (var x = 0.0; x <= size.width; x += 8) {
      hill.lineTo(x, size.height * (0.76 + 0.02 * sin(x / 41)));
    }
    hill
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill, Paint()..color = const Color(0xFF283330));
  }

  @override
  bool shouldRepaint(_DimGardenPainter old) => false;
}
