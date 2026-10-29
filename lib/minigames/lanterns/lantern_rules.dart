import 'dart:math';
import 'dart:ui';

import '../../balance/balance.dart';

/// Cómo terminó una linterna: llegó al muelle, pasó de largo o se apagó
/// contra una piedra.
enum LanternEnd { docked, missed, out }

/// Una linterna por soltar: de dónde sale, la fase de la corriente y dónde
/// está su muelle (todo en fracciones del ancho del río).
typedef LanternSetup = ({double startX, double phase, double dockX});

/// Recorrido de una linterna y cómo terminó.
typedef LanternRun = ({List<Offset> path, LanternEnd end});

/// Reglas de las Linternas flotantes, en Dart puro para poder probarlas.
///
/// El río baja de arriba (y = 0) hacia abajo (y = 1) y serpentea: la corriente
/// empuja de costado según la altura. Las piedras desvían la linterna de
/// costado con un empujón suave que se apaga con la distancia; si la linterna
/// llega de frente, choca y se apaga. Todo es determinista: la misma jugada da el mismo viaje.
class LanternRules {
  final BalanceSection b;
  LanternRules(this.b);

  static const step = 1 / 60;

  int get lanterns => b.i('lanterns');
  int get maxStones => b.i('maxStones');
  double get dockHalf => b.d('dockWidth') / 2;
  double get stoneRadius => b.d('stoneRadius');

  /// Una linterna cuyo muelle queda lejos de donde la llevaría el río solo.
  LanternSetup setup(Random rng) {
    while (true) {
      final startX = 0.3 + rng.nextDouble() * 0.4, phase = rng.nextDouble() * 2 * pi;
      final natural = simulate((startX: startX, phase: phase, dockX: 0), const []).path.last.dx;
      final shift =
          (b.d('shiftMin') + rng.nextDouble() * (b.d('shiftMax') - b.d('shiftMin'))) * (rng.nextBool() ? 1 : -1);
      final dockX = natural + shift;
      if (dockX >= 0.15 && dockX <= 0.85) return (startX: startX, phase: phase, dockX: dockX);
    }
  }

  /// Corriente de costado a la altura [y].
  double drift(double y, double phase) => b.d('meander') * sin(2 * pi * y * b.d('bends') + phase);

  /// Dónde se puede poner una piedra: dentro del río, lejos de la salida y
  /// del muelle.
  bool canPlace(Offset p) => p.dx > 0.04 && p.dx < 0.96 && p.dy > 0.16 && p.dy < 0.9;

  LanternRun simulate(LanternSetup l, List<Offset> stones) {
    var p = Offset(l.startX, 0);
    final path = [p];
    final speed = b.d('speed'), push = b.d('push'), reach = b.d('reach'), bank = 0.03;
    while (p.dy < 1) {
      var vx = drift(p.dy, l.phase);
      for (final s in stones) {
        final d = p - s, r = d.distance;
        if (r < stoneRadius) return (path: path, end: LanternEnd.out);
        if (r < reach) {
          // El agua rodea la piedra: empuja de costado, más fuerte a media
          // distancia. De frente casi no desvía, y la linterna choca.
          final k = r / reach;
          vx += d.dx / r * push * 4 * k * (1 - k);
        }
      }
      p = Offset((p.dx + vx * step).clamp(bank, 1 - bank), p.dy + speed * step);
      path.add(p);
      if (path.length > 2000) break;
    }
    final docked = (p.dx - l.dockX).abs() <= dockHalf;
    return (path: path, end: docked ? LanternEnd.docked : LanternEnd.missed);
  }

  /// Lo que vale una linterna que llegó con [stones] piedras: las primeras
  /// [b.freeStones] no restan.
  double value(int stones) => (1 - b.d('stonePenalty') * max(0, stones - b.i('freeStones'))).clamp(0.0, 1.0);
}
