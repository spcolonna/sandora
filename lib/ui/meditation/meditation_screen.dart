import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../garden/economy.dart';
import '../../garden/meditation_rules.dart';
import '../../garden/progress.dart';
import '../../garden/reminders.dart';
import '../../i18n/i18n.dart';
import '../fx/sfx.dart';
import '../theme/palette.dart';
import '../widgets/currency.dart';
import '../widgets/level_up.dart';
import '../widgets/washi.dart';
import 'meditation_backdrop.dart';

enum _Phase { setup, session, result }

/// Modo meditación (GDD): elegir duración y sonido, contador con ensō de
/// respiración y recompensa por tiempo real, con techo diario. Todo pasa en el
/// patio pintado: de tarde al elegir, de noche al meditar y al amanecer al
/// terminar. Si hay una sesión en curso (la app se cerró en el medio), la retoma.
class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> with SingleTickerProviderStateMixin {
  final p = Progress.instance;
  late _Phase _phase = p.meditationStartedAt == null ? _Phase.setup : _Phase.session;
  late int _minutes = p.meditationStartedAt == null ? 5 : p.meditationChosen;
  Ambience? _ambience = Ambience.wind;
  bool _intervalBell = false;
  Timer? _tick;
  int _bellsRung = 0;
  ({MeditationReward reward, int? newLevel, int lotus, String? object})? _result;

  /// Reloj de cuadro a cuadro: el patio y el ensō respiran suave, no a saltos.
  final _clock = ValueNotifier(0.0);
  late final Ticker _ticker = createTicker((d) => _clock.value = d.inMicroseconds / 1e6);

  @override
  void initState() {
    super.initState();
    _ticker.start();
    if (_phase == _Phase.session) _runTimer();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
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
      child: Scaffold(
        backgroundColor: const Color(0xFF22282B),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // El patio baja la luz despacio al empezar y amanece al terminar.
            TweenAnimationBuilder<Offset>(
              tween: Tween(
                end: switch (_phase) {
                  _Phase.setup => const Offset(0.15, 0),
                  _Phase.session => const Offset(0.9, 0),
                  _Phase.result => const Offset(0.3, 1),
                },
              ),
              duration: const Duration(milliseconds: 2600),
              curve: Curves.easeInOut,
              builder: (context, v, _) => MeditationBackdrop.available
                  ? CustomPaint(
                      painter: MeditationBackdrop(clock: _clock, night: v.dx, dawn: v.dy, breath: _breath),
                    )
                  : CustomPaint(painter: _DimGardenPainter()),
            ),
            SafeArea(
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
          ],
        ),
      ),
    );
  }

  /// Cuánto aire hay ahora (0 a 1): sube al inhalar y baja al exhalar. Fuera
  /// de la sesión, una respiración lenta y tranquila.
  double _breath() {
    final m = p.economy.balance.meditation;
    final inhale = m.d('breathIn'), exhale = m.d('breathOut'), cycle = inhale + exhale;
    if (_phase != _Phase.session) return 0.5 + 0.5 * sin(_clock.value * 2 * pi / (cycle * 1.4));
    final t = (p.meditationElapsed().inMilliseconds / 1000) % cycle;
    return t < inhale ? _ease(t / inhale) : 1 - _ease((t - inhale) / exhale);
  }

  static const _light = Palette.sandLight;
  static const _shadow = [Shadow(color: Color(0x99000000), blurRadius: 12)];

  Widget _setup(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final left = p.meditationMinutesLeft();
    // Arriba, el título sobre el patio; abajo, las opciones en un papel.
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: InkIconButton(glyph: InkGlyph.close, size: 42, onPressed: () => Navigator.pop(context)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr('meditation.title'),
          style: text.headlineMedium?.copyWith(color: _light, fontWeight: FontWeight.w300, shadows: _shadow),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            tr('meditation.desc'),
            style: text.bodyMedium?.copyWith(color: _light.withValues(alpha: 0.9), shadows: _shadow),
            textAlign: TextAlign.center,
          ),
        ),
        const Spacer(),
        _Paper(child: _options(context, text, left)),
      ],
    );
  }

  Widget _options(BuildContext context, TextTheme text, int left) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr('meditation.duration'), style: text.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in p.meditationRules.durations)
              InkChip(
                label: tr('meditation.minutes', {'n': m}),
                selected: _minutes == m,
                onTap: () => setState(() => _minutes = m),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(tr('meditation.sound'), style: text.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            InkChip(
              label: tr('meditation.silence'),
              selected: _ambience == null,
              onTap: () => setState(() => _ambience = null),
            ),
            for (final a in Ambience.forMeditation)
              InkChip(
                label: tr('meditation.ambience.${a.name}'),
                selected: _ambience == a,
                onTap: () => setState(() => _ambience = a),
              ),
          ],
        ),
        const SizedBox(height: 8),
        InkToggleRow(
          title: tr('meditation.intervalBell', {'n': p.economy.balance.meditation.i('intervalBellMinutes')}),
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
        InkButton(label: tr('meditation.start'), glyph: InkGlyph.play, onPressed: _start),
      ],
    );
  }

  Widget _session(BuildContext context) {
    final left = Duration(minutes: p.meditationChosen) - p.meditationElapsed();
    final mm = left.inMinutes.toString().padLeft(2, '0');
    final ss = (left.inSeconds % 60).toString().padLeft(2, '0');
    return Column(
      children: [
        const SizedBox(height: 24),
        Text(
          '$mm:$ss',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w300,
            color: _light.withValues(alpha: 0.7),
            letterSpacing: 4,
            shadows: _shadow,
          ),
        ),
        const Spacer(),
        // El ensō respira en el centro; la palabra va adentro, sin apuro.
        SizedBox.square(
          dimension: 280,
          child: CustomPaint(
            painter: BreathRing(clock: _clock, breath: _breath),
            child: Center(
              child: ValueListenableBuilder(
                valueListenable: _clock,
                builder: (context, _, _) {
                  final m = p.economy.balance.meditation;
                  final t = (p.meditationElapsed().inMilliseconds / 1000) % (m.d('breathIn') + m.d('breathOut'));
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 900),
                    child: Text(
                      tr(t < m.d('breathIn') ? 'meditation.inhale' : 'meditation.exhale'),
                      key: ValueKey(t < m.d('breathIn')),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.5,
                        color: _light.withValues(alpha: 0.85),
                        shadows: _shadow,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: _finish,
          child: Text(tr('meditation.end'), style: TextStyle(color: _light.withValues(alpha: 0.6))),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  static double _ease(double x) => 0.5 - cos(x.clamp(0.0, 1.0) * pi) / 2;

  Widget _resultView(BuildContext context) {
    final r = _result!.reward;
    final light = Palette.ink;
    final text = Theme.of(context).textTheme;
    // Amanece en el patio: lo ganado, en el mismo papel de las opciones.
    return Column(
      children: [
        const Spacer(),
        _Paper(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wb_twilight_rounded, size: 44, color: Palette.lantern),
              const SizedBox(height: 8),
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
              if (_result!.object != null) ...[
                const SizedBox(height: 14),
                Text(
                  tr('meditation.object.${_result!.object}'),
                  style: text.titleMedium?.copyWith(color: Palette.lantern),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_result!.newLevel != null) ...[
                const SizedBox(height: 16),
                DefaultTextStyle.merge(
                  style: TextStyle(color: light),
                  child: LevelUpBanner(_result!.newLevel!),
                ),
              ],
              const SizedBox(height: 24),
              InkButton(label: tr('result.garden'), onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Papel tibio apoyado abajo, sobre el patio, donde van las opciones.
class _Paper extends StatelessWidget {
  final Widget child;
  const _Paper({required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: WashiCard(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        radius: 28,
        child: child,
      ),
    );
  }
}

/// El jardín en penumbra, por si falta el arte del patio.
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
