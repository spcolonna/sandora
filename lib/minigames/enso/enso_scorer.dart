import 'dart:math';
import 'dart:ui';

import '../../balance/balance.dart';

/// Un punto del trazo: dónde y en qué segundo.
typedef InkPoint = ({Offset at, double t});

/// Cómo salió un ensō: redondez, cierre y fluidez (0 a 1) y el total.
class EnsoResult {
  final double roundness, closure, fluency, total;

  /// Cuánto del círculo recorrió el trazo (1 = una vuelta).
  final double sweep;
  final bool tooSmall;
  const EnsoResult({
    required this.roundness,
    required this.closure,
    required this.fluency,
    required this.total,
    required this.sweep,
    this.tooSmall = false,
  });

  static const none = EnsoResult(roundness: 0, closure: 0, fluency: 0, total: 0, sweep: 0, tooSmall: true);
}

/// Puntúa un ensō hecho de un solo trazo. [width] es el ancho de la pantalla:
/// el radio mínimo es una fracción de él.
///
/// - Redondez: cuánto se aparta del radio medio.
/// - Cierre: una vuelta casi completa es lo mejor; un ensō real deja una
///   pequeña abertura, así que cerrarlo justo o pasarse un poco no resta,
///   pero quedarse corto o dar vuelta y media sí.
/// - Fluidez: un trazo de velocidad pareja, sin frenadas ni tirones.
EnsoResult scoreEnso(List<InkPoint> stroke, double width, BalanceSection b) {
  if (stroke.length < 8) return EnsoResult.none;
  final pts = [for (final p in stroke) p.at];
  final c = _fitCenter(pts);
  final radii = [for (final p in pts) (p - c).distance];
  final r = radii.reduce((a, v) => a + v) / radii.length;
  if (r < width * b.d('minRadius')) return EnsoResult.none;

  final sd = sqrt(radii.map((v) => (v - r) * (v - r)).reduce((a, v) => a + v) / radii.length);
  final roundness = (1 - (sd / r) / b.d('roundTolerance')).clamp(0.0, 1.0);

  // Vuelta recorrida, sumando los giros alrededor del centro.
  var turn = 0.0;
  for (var i = 1; i < pts.length; i++) {
    final a0 = atan2(pts[i - 1].dy - c.dy, pts[i - 1].dx - c.dx);
    var d = atan2(pts[i].dy - c.dy, pts[i].dx - c.dx) - a0;
    if (d > pi) d -= 2 * pi;
    if (d < -pi) d += 2 * pi;
    turn += d;
  }
  final sweep = turn.abs() / (2 * pi);
  final lo = b.d('sweepLow'), hi = b.d('sweepHigh');
  final closure = sweep < lo
      ? ((sweep - 0.5) / (lo - 0.5)).clamp(0.0, 1.0)
      : (sweep <= hi ? 1.0 : (1 - (sweep - hi) / 0.35).clamp(0.0, 1.0));

  // Velocidad por tramo (ignorando tramos sin tiempo).
  final speeds = <double>[];
  for (var i = 1; i < stroke.length; i++) {
    final dt = stroke[i].t - stroke[i - 1].t;
    if (dt > 0.004) speeds.add((stroke[i].at - stroke[i - 1].at).distance / dt);
  }
  var fluency = 1.0;
  if (speeds.length > 3) {
    final mean = speeds.reduce((a, v) => a + v) / speeds.length;
    final cv = sqrt(speeds.map((v) => (v - mean) * (v - mean)).reduce((a, v) => a + v) / speeds.length) / mean;
    fluency = (1 - (cv - b.d('fluencyEasy')) / 0.9).clamp(0.0, 1.0);
  }

  final w = b.nums('weights');
  final total =
      (roundness * w['roundness']! + closure * w['closure']! + fluency * w['fluency']!) /
      (w['roundness']! + w['closure']! + w['fluency']!);
  return EnsoResult(roundness: roundness, closure: closure, fluency: fluency, total: total, sweep: sweep);
}

/// Centro del círculo que mejor ajusta los puntos (mínimos cuadrados). El
/// promedio de los puntos no sirve: la abertura del ensō lo corre hacia el
/// lado cerrado.
Offset _fitCenter(List<Offset> pts) {
  // x² + y² + a·x + b·y + c = 0, en ecuaciones normales 3×3.
  var sxx = 0.0, sxy = 0.0, syy = 0.0, sx = 0.0, sy = 0.0, sxz = 0.0, syz = 0.0, sz = 0.0;
  final n = pts.length.toDouble();
  for (final p in pts) {
    final z = p.dx * p.dx + p.dy * p.dy;
    sxx += p.dx * p.dx;
    sxy += p.dx * p.dy;
    syy += p.dy * p.dy;
    sx += p.dx;
    sy += p.dy;
    sxz += p.dx * z;
    syz += p.dy * z;
    sz += z;
  }
  final m = [
    [sxx, sxy, sx, -sxz],
    [sxy, syy, sy, -syz],
    [sx, sy, n, -sz],
  ];
  // Eliminación de Gauss con pivoteo.
  for (var i = 0; i < 3; i++) {
    var piv = i;
    for (var k = i + 1; k < 3; k++) {
      if (m[k][i].abs() > m[piv][i].abs()) piv = k;
    }
    final tmp = m[i];
    m[i] = m[piv];
    m[piv] = tmp;
    if (m[i][i].abs() < 1e-9) return pts.reduce((a, p) => a + p) / n;
    for (var k = 0; k < 3; k++) {
      if (k == i) continue;
      final f = m[k][i] / m[i][i];
      for (var j = i; j < 4; j++) {
        m[k][j] -= f * m[i][j];
      }
    }
  }
  final a = m[0][3] / m[0][0], b = m[1][3] / m[1][1];
  return Offset(-a / 2, -b / 2);
}
