import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../garden/progress.dart';
import '../garden/sendero.dart';
import '../i18n/i18n.dart';
import 'fx/calm.dart';
import 'fx/sfx.dart';
import 'sendero/sendero_painter.dart';
import 'theme/palette.dart';

/// Abre el Sendero. Sin [at], se entra caminando desde el comienzo; con [at]
/// (un índice de `Progress.decor`), se aparece parado frente a esa decoración.
Future<void> openSendero(BuildContext context, {int? at}) =>
    Navigator.of(context).push(CupertinoPageRoute<void>(builder: (_) => SenderoScreen(at: at)));

/// El Sendero: el jardín recorrido en primera persona. Tocar camina o se
/// detiene; deslizar hacia arriba avanza y hacia abajo retrocede.
class SenderoScreen extends StatefulWidget {
  final int? at;
  const SenderoScreen({super.key, this.at});

  @override
  State<SenderoScreen> createState() => _SenderoScreenState();
}

class _SenderoScreenState extends State<SenderoScreen> with SingleTickerProviderStateMixin {
  late final SenderoRules _rules = SenderoRules.from(Progress.instance.economy.balance);
  late final List<SenderoThing> _things = senderoThings(Progress.instance, _rules);
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;

  double _z = 0;
  bool _auto = false;

  /// Cuánto se movió hace poco (para el vaivén del paso).
  double _stride = 0;
  double _lastStep = 0;
  static const _stepGap = 0.95;

  @override
  void initState() {
    super.initState();
    final at = widget.at;
    final thing = at == null ? null : _things.where((t) => t.index == at).firstOrNull;
    if (thing != null) {
      _z = _rules.viewFrom(thing.z);
    } else {
      _auto = true;
    }
    _lastStep = _z;
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration now) {
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    var z = _z;
    if (_auto) z += _rules.speed * dt;
    z = z.clamp(0.0, _rules.length);
    if (_auto && z >= _rules.length) _auto = false;
    _move(z, dt);
  }

  void _move(double z, double dt) {
    final moved = (z - _z).abs();
    // El vaivén crece al caminar y se apaga al detenerse.
    final target = moved > 1e-4 ? 1.0 : 0.0;
    final stride = _stride + (target - _stride) * min(1, dt * 6);
    if (moved < 1e-6 && (stride - _stride).abs() < 1e-3) return;
    if ((z - _lastStep).abs() >= _stepGap) {
      _lastStep = z;
      SoundBoard.instance.play(Sfx.stoneSand, volume: 0.08);
    }
    setState(() {
      _z = z;
      _stride = stride;
    });
  }

  void _drag(DragUpdateDetails d) {
    _auto = false;
    _move((_z - d.delta.dy * 0.03).clamp(0.0, _rules.length), 1 / 60);
  }

  void _toggle() {
    setState(() {
      if (_z >= _rules.length - 0.01) {
        _z = 0;
        _lastStep = 0;
      }
      _auto = !_auto;
    });
  }

  /// La decoración que se tiene delante, si hay una cerca.
  SenderoThing? get _near {
    SenderoThing? best;
    for (final t in _things) {
      if (t.name == null) continue;
      final dz = t.z - _z;
      if (dz < 1.2 || dz > 4.8) continue;
      if (best == null || dz < best.z - _z) best = t;
    }
    return best;
  }

  static const _zoneKeys = ['garden.patio', 'garden.pond', 'garden.forest'];

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final text = Theme.of(context).textTheme;
    final near = _near;
    final atEnd = _z >= _rules.length - 0.01;
    final zone = _rules.zoneAt(_z + 1.5);
    const bar = 64.0;
    final light = TextStyle(color: Palette.paper.withValues(alpha: 0.9));
    return Scaffold(
      backgroundColor: Palette.ink,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const ValueKey('sendero'),
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
              onVerticalDragUpdate: _drag,
              child: CustomPaint(
                painter: SenderoPainter(
                  z: _z,
                  rules: _rules,
                  things: _things,
                  bob: sin(_z / _stepGap * pi * 2) * 3 * _stride,
                ),
              ),
            ),
          ),
          // Franjas de cine, arriba y abajo.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: pad.top + bar,
            child: IgnorePointer(child: ColoredBox(color: Palette.ink.withValues(alpha: 0.92))),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: pad.bottom + bar + 20,
            child: IgnorePointer(child: ColoredBox(color: Palette.ink.withValues(alpha: 0.92))),
          ),
          Positioned(
            left: 4,
            top: pad.top + 8,
            child: IconButton(
              key: const ValueKey('senderoClose'),
              icon: Icon(Icons.close_rounded, color: Palette.paper.withValues(alpha: 0.9)),
              tooltip: tr('result.garden'),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Positioned(
            left: 60,
            right: 60,
            top: pad.top + 18,
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: Calm.page,
                child: Text(
                  '${tr('sendero.title')} · ${tr(_zoneKeys[zone])}',
                  key: ValueKey(zone),
                  textAlign: TextAlign.center,
                  style: text.titleMedium?.merge(light).copyWith(letterSpacing: 1.2),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: pad.bottom + 18,
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: Calm.page,
                child: Column(
                  key: ValueKey(atEnd ? 'end' : near?.index ?? -1),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      atEnd ? tr('sendero.end') : near?.name ?? '',
                      textAlign: TextAlign.center,
                      style: text.titleLarge?.merge(light).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      atEnd ? tr('sendero.again') : (near != null ? tr('walk.decor') : tr('sendero.hint')),
                      textAlign: TextAlign.center,
                      style: text.bodySmall?.merge(light).copyWith(color: Palette.paper.withValues(alpha: 0.6)),
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
