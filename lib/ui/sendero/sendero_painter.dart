import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../garden/decor.dart';
import '../../garden/progress.dart';
import '../../garden/sendero.dart';
import '../../i18n/i18n.dart';
import '../garden/garden_decor.dart';
import '../garden/scene_art.dart';
import '../theme/palette.dart';

/// Algo parado al costado del Sendero: una decoración del jugador o una pieza
/// del paisaje. [x] es la distancia al centro del camino en [z].
class SenderoThing {
  final double x, z;

  /// Ancho en el mundo y alto sobre ancho.
  final double width, aspect;
  final bool flip;

  /// Id de la decoración (se pinta como en el jardín) o arte del paisaje.
  final String? decor, art;

  /// Nombre para el cartel (solo las decoraciones del jugador).
  final String? name;

  /// Índice en `Progress.decor`.
  final int? index;

  const SenderoThing({
    required this.x,
    required this.z,
    required this.width,
    required this.aspect,
    this.flip = false,
    this.decor,
    this.art,
    this.name,
    this.index,
  });
}

/// Lo que hay en el Sendero: las decoraciones puestas en la Maqueta, cada una
/// en el lugar de su parcela, y el paisaje fijo de cada zona.
List<SenderoThing> senderoThings(Progress p, SenderoRules r) {
  final m = p.modelRules;
  final out = <SenderoThing>[
    for (final (i, d) in p.decor.indexed)
      if (d.side != null && d.cell != null)
        if (p.decorRules.byId(d.id) case final item?)
          if (r.slot(m, d.side!, d.cell!) case (:final x, :final z))
            SenderoThing(
              x: x,
              z: z,
              width: item.size * r.decorScale,
              aspect: item.aspect,
              flip: d.flip,
              decor: d.id,
              name: tr('decor.${d.id}'),
              index: i,
            ),
  ];
  // El paisaje: siempre el mismo, más afuera que las parcelas.
  final rng = Random(7);
  double aspectOf(String art, double fallback) {
    final img = SceneArt.instance[art];
    return img == null ? fallback : img.height / img.width;
  }

  void scenery(String art, double x, double z, double w, double fallback) =>
      out.add(SenderoThing(x: x, z: z, width: w, aspect: aspectOf(art, fallback), flip: rng.nextBool(), art: art));

  final len = r.length + 30;
  for (var z = 1.0; z < len; z += 2.2 + rng.nextDouble() * 1.4) {
    final zone = r.zoneAt(z);
    final side = rng.nextBool() ? 1.0 : -1.0;
    switch (zone) {
      case 0:
        scenery('obj_court_lantern_small', side * (3.6 + rng.nextDouble()), z, 0.8, 1.6);
        if (rng.nextDouble() < 0.5) scenery('obj_court_rock', -side * (3.8 + rng.nextDouble() * 1.5), z + 0.8, 1.1, 0.6);
      case 1:
        // A la derecha está el agua: el paisaje va del otro lado.
        if (rng.nextDouble() < 0.6) scenery('obj_court_rock', -(3.6 + rng.nextDouble() * 1.5), z, 0.8, 0.6);
        if (rng.nextDouble() < 0.4) scenery('obj_court_lantern_small', -(3.4 + rng.nextDouble()), z + 1, 0.75, 1.6);
      default:
        for (final s in [-1.0, 1.0]) {
          scenery('obj_bamboo_grove', s * (4.2 + rng.nextDouble() * 1.6), z + rng.nextDouble(), 2.6, 1.3);
        }
    }
  }
  return out;
}

/// La cámara del Sendero: parada sobre el camino en [z], mirando hacia donde
/// va el camino.
class SenderoCamera {
  final Size size;
  final double z;
  final double bob;

  /// Distancia focal en píxeles y altura de los ojos.
  late final double f = size.width * 0.85;
  static const eye = 1.1;
  static const near = 0.35;
  static const far = 34.0;
  late final double horizon = size.height * 0.4 + bob;
  late final double x0 = senderoCenter(z);
  late final double slope = senderoSlope(z);

  SenderoCamera(this.size, this.z, {this.bob = 0});

  /// Dónde cae en la pantalla el punto del mundo (x, y, z); null si queda
  /// detrás de la cámara.
  Offset? project(double x, double wz, [double y = 0]) {
    final raw = wz - z;
    if (raw < near - 1e-6) return null;
    final dz = max(near, raw);
    return Offset(size.width / 2 + (x - x0 - slope * dz) * f / dz, horizon + (eye - y) * f / dz);
  }

  /// Píxeles por unidad del mundo a la distancia de [wz].
  double scale(double wz) => f / max(near, wz - z);

  /// Cuánto se pierde en la bruma a esa distancia (0 nada, 1 todo).
  static double fog(double dz) => ((dz - 7) / 26).clamp(0.0, 0.85);
}

/// Dibuja el Sendero visto desde [z].
class SenderoPainter extends CustomPainter {
  final double z, bob;
  final SenderoRules rules;
  final List<SenderoThing> things;

  SenderoPainter({required this.z, required this.rules, required this.things, this.bob = 0});

  static const _mist = Color(0xFFE9E4D6);
  static const _path = Color(0xFFDCCFAF);
  static const _pathEdge = Color(0xFFB9A982);
  static const _zones = [Color(0xFFE2D5B8), Color(0xFFC9CDAA), Color(0xFF98A87A)];

  Color _groundAt(double wz) {
    final t = wz / rules.segment;
    final i = t.floor().clamp(0, _zones.length - 1);
    final next = (i + 1).clamp(0, _zones.length - 1);
    // Cada zona se funde en la siguiente en sus últimos pasos.
    final blend = ((t - i - 0.85) / 0.15).clamp(0.0, 1.0);
    return Color.lerp(_zones[i], _zones[next], blend)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cam = SenderoCamera(size, z, bob: bob);
    canvas.clipRect(Offset.zero & size);
    _sky(canvas, cam);
    _ground(canvas, cam);
    _water(canvas, cam);
    _walk(canvas, cam);
    _standing(canvas, cam);
  }

  void _sky(Canvas canvas, SenderoCamera cam) {
    final s = cam.size, h = cam.horizon;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s.width, h + 2),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, h), [Palette.skyTop, Palette.skyBottom, _mist], [0, 0.7, 1]),
    );
    // Montes lejanos: se corren poco al girar (están lejos) y nada al avanzar.
    void hills(Color c, double amp, double freq, double par, double seed, double lift) {
      final path = Path()..moveTo(0, h + 2);
      final shift = -cam.slope * s.width * par + cam.z * par * 6;
      for (var x = 0.0; x <= s.width + 8; x += 8) {
        final u = (x + shift) / s.width;
        final y = h - lift - amp * (0.5 + 0.3 * sin(u * freq + seed) + 0.2 * sin(u * freq * 2.7 + seed * 2));
        path.lineTo(x, y);
      }
      path
        ..lineTo(s.width, h + 2)
        ..close();
      canvas.drawPath(path, Paint()..color = c);
    }

    hills(Color.lerp(Palette.dusk, _mist, 0.78)!, s.height * 0.07, 5, 0.15, 1, s.height * 0.01);
    hills(Color.lerp(Palette.mossDark, _mist, 0.62)!, s.height * 0.045, 8, 0.3, 4, 0);
  }

  void _ground(Canvas canvas, SenderoCamera cam) {
    final s = cam.size;
    var za = z + SenderoCamera.far;
    while (za > z + SenderoCamera.near) {
      final dz = za - z;
      final zb = max(z + SenderoCamera.near, za - max(0.2, dz * 0.07));
      final ya = cam.horizon + SenderoCamera.eye * cam.f / dz;
      final yb = cam.horizon + SenderoCamera.eye * cam.f / (zb - z);
      canvas.drawRect(
        Rect.fromLTRB(0, ya - 0.5, s.width, min(s.height, yb) + 0.5),
        Paint()..color = Color.lerp(_groundAt(za), _mist, SenderoCamera.fog(dz))!,
      );
      za = zb;
      if (ya > s.height) break;
    }
  }

  /// El estanque: a la derecha del camino, a lo largo de la segunda zona.
  void _water(Canvas canvas, SenderoCamera cam) {
    final cz = rules.zoneStart(1) + rules.segment * 0.5;
    const rx = 2.6;
    final rz = rules.segment * 0.42;
    if (cz + rz < z || cz - rz > z + SenderoCamera.far) return;
    final path = Path();
    var first = true;
    for (var i = 0; i <= 48; i++) {
      final a = i / 48 * pi * 2;
      final wz = max(z + SenderoCamera.near, cz + rz * sin(a));
      final wx = senderoCenter(wz) + 5.2 + rx * cos(a) * (1 + 0.12 * sin(a * 3));
      final o = cam.project(wx, wz)!;
      first ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      first = false;
    }
    path.close();
    final fog = SenderoCamera.fog(cz - z);
    canvas.drawPath(path, Paint()..color = Color.lerp(Palette.water, _mist, fog * 0.8)!);
    canvas.drawPath(
      path,
      Paint()
        ..color = Color.lerp(Palette.mossDark, _mist, fog)!.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  /// El camino de arena con sus piedras pisaderas.
  void _walk(Canvas canvas, SenderoCamera cam) {
    final hw = rules.halfWidth;
    var za = z + SenderoCamera.far;
    while (za > z + SenderoCamera.near) {
      final dz = za - z;
      final zb = max(z + SenderoCamera.near, za - max(0.15, dz * 0.06));
      final ca = senderoCenter(za), cb = senderoCenter(zb);
      final a1 = cam.project(ca - hw, za)!, a2 = cam.project(ca + hw, za)!;
      final b1 = cam.project(cb - hw, zb)!, b2 = cam.project(cb + hw, zb)!;
      final fog = SenderoCamera.fog(dz);
      canvas.drawPath(
        Path()..addPolygon([a1, a2, b2, b1], true),
        Paint()..color = Color.lerp(_path, _mist, fog)!,
      );
      final edge = Paint()
        ..color = Color.lerp(_pathEdge, _mist, fog)!
        ..strokeWidth = max(1, 0.05 * cam.scale(za));
      canvas
        ..drawLine(a1, b1, edge)
        ..drawLine(a2, b2, edge);
      za = zb;
    }
    // Piedras: de la más lejana a la más cercana.
    const gap = 0.95;
    for (var k = ((z + SenderoCamera.far) / gap).floor(); k >= 0; k--) {
      final wz = k * gap + 0.3;
      final dz = wz - z;
      if (dz < SenderoCamera.near + 0.1) break;
      final wx = senderoCenter(wz) + 0.22 * sin(k * 1.9);
      final c = cam.project(wx, wz)!;
      final sc = cam.scale(wz);
      final w = (0.6 + 0.08 * sin(k * 2.3)) * sc;
      final d = 0.38 * sc * (SenderoCamera.eye / dz);
      final r = Rect.fromCenter(center: c, width: w, height: max(1.5, d));
      final fog = SenderoCamera.fog(dz);
      canvas.drawOval(r.shift(Offset(0, d * 0.12)), Paint()..color = Color.lerp(Palette.stoneDark, _mist, fog)!.withValues(alpha: 0.35));
      canvas.drawOval(r, Paint()..color = Color.lerp(Palette.stoneLight, _mist, fog)!);
      // Un brillo arriba para que se lean como piedras y no como manchas.
      canvas.drawOval(
        Rect.fromLTWH(r.left + r.width * 0.18, r.top + r.height * 0.1, r.width * 0.5, r.height * 0.42),
        Paint()..color = Color.lerp(Palette.sandLight, _mist, fog)!.withValues(alpha: 0.55),
      );
    }
  }

  /// Lo que está parado (decoraciones, paisaje y portales), de lejos a cerca.
  void _standing(Canvas canvas, SenderoCamera cam) {
    final s = cam.size;
    final items = <(double, void Function())>[];
    for (final t in things) {
      final dz = t.z - z;
      if (dz < SenderoCamera.near + 0.15 || dz > SenderoCamera.far) continue;
      items.add((t.z, () => _thing(canvas, cam, t)));
    }
    for (var side = 0; side < ModelRules.sides; side++) {
      final gz = rules.zoneStart(side) + (side == 0 ? 0.8 : 0);
      final dz = gz - z;
      if (dz < SenderoCamera.near + 0.15 || dz > SenderoCamera.far) continue;
      items.add((gz, () => _gate(canvas, cam, gz)));
    }
    items.sort((a, b) => b.$1.compareTo(a.$1));
    for (final (_, draw) in items) {
      draw();
    }
    // Un velo de bruma al pie del horizonte une todo.
    final h = cam.horizon;
    canvas.drawRect(
      Rect.fromLTWH(0, h - s.height * 0.04, s.width, s.height * 0.08),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, h - s.height * 0.04),
          Offset(0, h + s.height * 0.04),
          [_mist.withValues(alpha: 0), _mist.withValues(alpha: 0.55), _mist.withValues(alpha: 0)],
          [0, 0.5, 1],
        ),
    );
  }

  /// Envuelve el dibujo de algo a [dz] con su bruma y, si está casi encima,
  /// lo desvanece (para que no tape todo al pasar al lado).
  void _veiled(Canvas canvas, Rect bounds, double dz, void Function() draw) {
    final fog = SenderoCamera.fog(dz);
    final alpha = ((dz - SenderoCamera.near) / 0.9).clamp(0.0, 1.0);
    if (fog < 0.01 && alpha > 0.99) return draw();
    canvas.saveLayer(
      bounds.inflate(4),
      Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..colorFilter = ColorFilter.mode(_mist.withValues(alpha: fog), BlendMode.srcATop),
    );
    draw();
    canvas.restore();
  }

  void _thing(Canvas canvas, SenderoCamera cam, SenderoThing t) {
    final base = cam.project(senderoCenter(t.z) + t.x, t.z);
    if (base == null) return;
    final sc = cam.scale(t.z);
    final w = t.width * sc, h = w * t.aspect;
    final r = Rect.fromLTWH(base.dx - w / 2, base.dy - h, w, h);
    if (r.right < 0 || r.left > cam.size.width || r.top > cam.size.height) return;
    _veiled(canvas, r, t.z - z, () {
      if (t.decor case final id?) return paintDecor(canvas, id, r, flip: t.flip);
      canvas.drawOval(
        Rect.fromCenter(center: r.bottomCenter, width: r.width * 0.8, height: r.width * 0.14),
        Paint()..color = Palette.ink.withValues(alpha: 0.14),
      );
      final img = SceneArt.instance[t.art ?? ''];
      if (img == null) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(r.deflate(r.width * 0.2), Radius.circular(r.width * 0.1)),
          Paint()..color = (t.art ?? '').contains('bamboo') ? Palette.moss : Palette.stone,
        );
        return;
      }
      if (t.flip) {
        canvas.save();
        canvas.translate(r.center.dx * 2, 0);
        canvas.scale(-1, 1);
      }
      drawArt(canvas, img, r);
      if (t.flip) canvas.restore();
    });
  }

  /// El portal de madera que marca el comienzo de cada zona.
  void _gate(Canvas canvas, SenderoCamera cam, double gz) {
    final cx = senderoCenter(gz);
    final l = cam.project(cx - 1.25, gz), rr = cam.project(cx + 1.25, gz);
    if (l == null || rr == null) return;
    final sc = cam.scale(gz);
    final hgt = 2.5 * sc, post = 0.16 * sc;
    final top = l.dy - hgt;
    final bounds = Rect.fromLTRB(l.dx - 0.6 * sc, top - 0.3 * sc, rr.dx + 0.6 * sc, l.dy);
    if (bounds.right < 0 || bounds.left > cam.size.width) return;
    _veiled(canvas, bounds, gz - z, () {
      final wood = Paint()..color = Palette.clay;
      final dark = Paint()..color = Palette.ink.withValues(alpha: 0.85);
      for (final p in [l, rr]) {
        canvas.drawRect(Rect.fromLTRB(p.dx - post / 2, top, p.dx + post / 2, p.dy), wood);
        canvas.drawRect(Rect.fromLTRB(p.dx - post * 0.7, p.dy - post * 0.9, p.dx + post * 0.7, p.dy), dark);
      }
      final beam = Path()
        ..moveTo(l.dx - 0.55 * sc, top - 0.12 * sc)
        ..quadraticBezierTo((l.dx + rr.dx) / 2, top + 0.05 * sc, rr.dx + 0.55 * sc, top - 0.12 * sc)
        ..lineTo(rr.dx + 0.5 * sc, top + 0.12 * sc)
        ..quadraticBezierTo((l.dx + rr.dx) / 2, top + 0.24 * sc, l.dx - 0.5 * sc, top + 0.12 * sc)
        ..close();
      canvas.drawPath(beam, dark);
      canvas.drawRect(Rect.fromLTRB(l.dx - 0.3 * sc, top + 0.42 * sc, rr.dx + 0.3 * sc, top + 0.56 * sc), wood);
    });
  }

  @override
  bool shouldRepaint(SenderoPainter old) =>
      old.z != z || old.bob != bob || !identical(old.things, things) || old.rules != rules;
}
