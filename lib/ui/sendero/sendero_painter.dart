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

/// Qué se tocó en el Sendero.
enum SenderoHit { station, gate, board, decor, slot, gift, care, visitor, tea, tower }

class SenderoTarget {
  final SenderoHit kind;

  /// El lugar (estación) o el id del regalo.
  final String? id;

  /// Zona (portón, hueco, cuidado) e índice (decoración, hueco, cuidado).
  final int? zone, index;

  const SenderoTarget(this.kind, {this.id, this.zone, this.index});

  @override
  bool operator ==(Object other) =>
      other is SenderoTarget && other.kind == kind && other.id == id && other.zone == zone && other.index == index;

  @override
  int get hashCode => Object.hash(kind, id, zone, index);
}

/// Algo parado al costado del Sendero: una decoración del jugador o una pieza
/// del paisaje.
class SenderoThing {
  final Offset pos;

  /// Ancho en el mundo y alto sobre ancho.
  final double width, aspect;
  final bool flip;

  /// Id de la decoración (se pinta como en el jardín) o arte del paisaje.
  final String? decor, art;

  /// Nombre (solo las decoraciones del jugador).
  final String? name;

  /// Índice en `Progress.decor`.
  final int? index;

  const SenderoThing({
    required this.pos,
    required this.width,
    required this.aspect,
    this.flip = false,
    this.decor,
    this.art,
    this.name,
    this.index,
  });
}

/// Algo vivo en el camino que se toca: un regalo, un cuidado, un visitante, un
/// hueco para decorar. Sin arte, se dibuja como una burbuja con su ícono.
class SenderoMarker {
  final Offset pos;
  final double width, aspect;
  final String? art;
  final IconData? icon;
  final Color color;
  final SenderoTarget target;

  /// Apoyado en el suelo (un hueco) en vez de parado.
  final bool flat;

  const SenderoMarker({
    required this.pos,
    required this.target,
    this.width = 0.6,
    this.aspect = 1,
    this.art,
    this.icon,
    this.color = Palette.lantern,
    this.flat = false,
  });
}

/// Cómo se ve cada lugar en el camino.
class StationLook {
  final bool open;

  /// Nombre y, si está cerrado o descansa, una nota.
  final String name;
  final String? note;

  /// Tiene algo nuevo o para retirar (un punto que brilla).
  final bool dot;

  const StationLook({required this.open, required this.name, this.note, this.dot = false});
}

/// El arte de cada lugar en el camino (el del Sendero si ya está pintado, si
/// no el de su vista) y su ancho en el mundo.
const stationArt = <String, (List<String>, double)>{
  'board': (['obj_court_board'], 1.5),
  'meditation': (['obj_station_meditation', 'obj_court_deck'], 2.2),
  'sand': (['obj_station_sand'], 2.0),
  'stack': (['obj_stack_pedestal'], 1.4),
  'rain': (['obj_court_jars'], 2.0),
  'pond': (['obj_station_pond'], 2.4),
  'shishi': (['obj_shishi_basin'], 1.6),
  'leaves': (['obj_station_leaves', 'obj_decor_maple'], 2.2),
  'moss': (['obj_moss_rock'], 1.8),
  'bonsai': (['obj_bonsai_table'], 1.8),
  'enso': (['obj_callig_hall'], 3.4),
  'bell': (['obj_temple_belltower'], 2.6),
  'matcha': (['obj_tea_house'], 4.4),
  'flute': (['obj_bamboo_flute'], 1.4),
  'lanterns': (['obj_river_lantern'], 1.2),
};

/// Lo que hay en el Sendero: las decoraciones, cada una en el hueco de su
/// parcela, y el paisaje fijo (que no pisa caminos ni lugares).
List<SenderoThing> senderoThings(Progress p, SenderoWorld w) => [
  for (final (i, d) in p.decor.indexed)
    if (d.side != null && d.cell != null)
      if (p.decorRules.byId(d.id) case final item?)
        SenderoThing(
          pos: w.slot(d.side!, d.cell!),
          width: item.size * w.rules.decorScale,
          aspect: item.aspect,
          flip: d.flip,
          decor: d.id,
          name: tr('decor.${d.id}'),
          index: i,
        ),
  ...senderoScenery(w),
];

final _sceneryCache = Expando<List<SenderoThing>>();

/// El paisaje: siempre el mismo para el mismo trazado.
List<SenderoThing> senderoScenery(SenderoWorld w) => _sceneryCache[w] ??= _buildScenery(w);

List<SenderoThing> _buildScenery(SenderoWorld w) {
  final r = w.rules;
  final rng = Random(7);
  final out = <SenderoThing>[];
  double aspectOf(String art, double fallback) {
    final img = SceneArt.instance[art];
    return img == null ? fallback : img.height / img.width;
  }

  final pond = pondShape(w);
  final slots = [
    for (var side = 0; side < ModelRules.sides; side++)
      for (var cell = 0; cell < w.cols * w.rows; cell++) w.slot(side, cell),
  ];
  bool free(Offset p, double room) {
    for (final t in w.tracks) {
      if (t.nearest(p).$2 < room) return false;
    }
    for (final s in w.stations) {
      if ((s.pos - p).distance < room + 1.6) return false;
    }
    for (final b in w.branches) {
      if ((b.sign - p).distance < room) return false;
    }
    if ((w.board - p).distance < room + 0.6) return false;
    if (insidePolygon(pond, p)) return false;
    for (final s in slots) {
      if ((s - p).distance < 1.1) return false;
    }
    return true;
  }

  void add(String art, Offset p, double width, double fallback, double room) {
    if (!free(p, room)) return;
    out.add(SenderoThing(pos: p, width: width, aspect: aspectOf(art, fallback), flip: rng.nextBool(), art: art));
  }

  final trunk = w.trunk;
  for (var s = 1.0; s < trunk.length + 20; s += 1.6 + rng.nextDouble() * 1.2) {
    final zone = r.zoneAt(s);
    final p = trunk.pointAt(s), n = trunk.normalAt(s);
    for (final side in [-1.0, 1.0]) {
      if (rng.nextDouble() < 0.35) continue;
      final d = 3.6 + rng.nextDouble() * 2.4;
      final q = p + n * side * d;
      switch (zone) {
        case 0:
          rng.nextDouble() < 0.5
              ? add('obj_court_lantern_small', q, 0.8, 1.6, 2.0)
              : add('obj_court_rock', q, 1.1, 0.6, 2.0);
        case 1:
          rng.nextDouble() < 0.6 ? add('obj_court_rock', q, 0.9, 0.6, 2.0) : add('obj_moss_rock', q, 1.2, 0.7, 2.0);
        default:
          add('obj_bamboo_grove', p + n * side * (d + 1), 2.6, 1.3, 2.6);
      }
    }
  }
  // Los ramales también tienen sus costados.
  for (final b in w.branches) {
    final t = w.tracks[b.track];
    for (var s = 1.5; s < t.length; s += 1.8 + rng.nextDouble()) {
      for (final side in [-1.0, 1.0]) {
        if (rng.nextDouble() < 0.5) continue;
        final q = t.pointAt(s) + t.normalAt(s) * side * (2.4 + rng.nextDouble() * 1.6);
        b.spec.zone == 2
            ? add('obj_bamboo_grove', q, 2.2, 1.3, 2.2)
            : add(b.spec.zone == 0 ? 'obj_court_rock' : 'obj_moss_rock', q, 0.9, 0.6, 1.8);
      }
    }
  }
  return out;
}

/// El estanque: al costado derecho del tronco, al comienzo de la segunda zona.
List<Offset> pondShape(SenderoWorld w) {
  final s = w.rules.zoneStart(1) + w.rules.segment * 0.3;
  final t = w.trunk.tangentAt(s), n = w.trunk.normalAt(s);
  final c = w.trunk.pointAt(s) + n * 6.4;
  return [
    for (var i = 0; i < 40; i++)
      c + n * (2.6 * cos(i / 40 * pi * 2) * (1 + 0.1 * sin(i / 40 * pi * 6))) + t * (w.rules.segment * 0.2 * sin(i / 40 * pi * 2)),
  ];
}

bool insidePolygon(List<Offset> poly, Offset p) {
  var inside = false;
  for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    final a = poly[i], b = poly[j];
    if ((a.dy > p.dy) != (b.dy > p.dy) && p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx) {
      inside = !inside;
    }
  }
  return inside;
}

/// La cámara: parada en [pos], mirando hacia [heading] (0 es +y, positivo
/// hacia la derecha).
class SenderoCamera {
  final Size size;
  final Offset pos;
  final double heading;
  final double bob;

  late final double f = size.width * 0.85;
  static const eye = 1.1;
  static const near = 0.35;
  static const far = 34.0;
  late final double horizon = size.height * 0.4 + bob;
  late final double _s = sin(heading), _c = cos(heading);

  SenderoCamera(this.size, this.pos, this.heading, {this.bob = 0});

  /// Hacia adelante.
  Offset get forward => Offset(_s, _c);

  /// Del mundo a la cámara: (a la derecha, hacia adelante).
  Offset toCam(Offset w) {
    final d = w - pos;
    return Offset(d.dx * _c - d.dy * _s, d.dx * _s + d.dy * _c);
  }

  /// De la cámara a la pantalla, a altura [y].
  Offset screen(Offset c, [double y = 0]) =>
      Offset(size.width / 2 + c.dx * f / c.dy, horizon + (eye - y) * f / c.dy);

  /// Dónde cae en la pantalla el punto del mundo [w] a altura [y]; null si
  /// queda detrás de la cámara.
  Offset? project(Offset w, [double y = 0]) {
    final c = toCam(w);
    if (c.dy < near - 1e-6) return null;
    return screen(Offset(c.dx, max(near, c.dy)), y);
  }

  /// Qué tan lejos queda [w] hacia adelante.
  double depth(Offset w) => toCam(w).dy;

  /// Píxeles por unidad del mundo a la profundidad [dz].
  double scaleAt(double dz) => f / max(near, dz);

  /// Un polígono del suelo recortado delante de la cámara, en la pantalla.
  List<Offset>? ground(List<Offset> world) {
    final cam = [for (final p in world) toCam(p)];
    final out = <Offset>[];
    for (var i = 0; i < cam.length; i++) {
      final a = cam[i], b = cam[(i + 1) % cam.length];
      final ain = a.dy >= near, bin = b.dy >= near;
      if (ain) out.add(a);
      if (ain != bin) {
        final t = (near - a.dy) / (b.dy - a.dy);
        out.add(Offset(a.dx + (b.dx - a.dx) * t, near));
      }
    }
    if (out.length < 3) return null;
    return [for (final c in out) screen(c)];
  }

  /// Cuánto se pierde en la bruma a esa distancia (0 nada, 1 todo).
  static double fog(double dz) => ((dz - 7) / 26).clamp(0.0, 0.85);
}

/// Lo que se ve y se toca del Sendero en un momento.
class SenderoView {
  final SenderoWorld world;
  final Offset pos;
  final double heading, bob;
  final List<SenderoThing> things;
  final Map<String, StationLook> stations;

  /// Qué zonas están abiertas (sus portones).
  final List<bool> open;
  final List<SenderoMarker> markers;

  /// Qué tan de día es (1 pleno día, 0 noche).
  final double daylight;

  /// Lo que está elegido (se marca).
  final SenderoTarget? selected;

  const SenderoView({
    required this.world,
    required this.pos,
    required this.heading,
    this.bob = 0,
    this.things = const [],
    this.stations = const {},
    this.open = const [true, true, true],
    this.markers = const [],
    this.daylight = 1,
    this.selected,
  });
}

/// Algo ya ubicado en la pantalla: dónde está, a qué profundidad y qué es.
class _Drawn {
  final double dz;
  final Rect rect;
  final SenderoTarget? target;
  final void Function() paint;
  const _Drawn(this.dz, this.rect, this.target, this.paint);
}

/// Arma la escena para un tamaño: la usan el dibujo y el toque, así coinciden.
class SenderoScene {
  final SenderoView v;
  final SenderoCamera cam;
  final Canvas? _canvas;
  final List<_Drawn> _items = [];

  SenderoScene(Size size, this.v, [this._canvas]) : cam = SenderoCamera(size, v.pos, v.heading, bob: v.bob) {
    _collect();
  }

  SenderoWorld get w => v.world;

  /// Lo que hay bajo [p], lo más cercano primero.
  SenderoTarget? hit(Offset p) {
    final byNear = [..._items.where((d) => d.target != null)]..sort((a, b) => a.dz.compareTo(b.dz));
    for (final d in byNear) {
      if (d.rect.inflate(8).contains(p)) return d.target;
    }
    return null;
  }

  /// Dónde está en la pantalla [t], si se ve.
  Rect? rectOf(SenderoTarget t) => _items.where((d) => d.target == t).firstOrNull?.rect;

  static const _mist = Color(0xFFE9E4D6);
  static const _path = Color(0xFFDCCFAF);
  static const _pathEdge = Color(0xFFB9A982);
  static const _zones = [Color(0xFFE2D5B8), Color(0xFFC9CDAA), Color(0xFF98A87A)];

  Canvas get _c => _canvas!;

  void paint() {
    _c.clipRect(Offset.zero & cam.size);
    _sky();
    _ground();
    _water();
    _paths();
    _items.sort((a, b) => b.dz.compareTo(a.dz));
    for (final d in _items) {
      d.paint();
    }
    _haze();
    _night();
  }

  // ---- Ubicar lo que está parado ----

  void _collect() {
    for (final t in v.things) {
      _thing(t);
    }
    for (final st in w.stations) {
      _station(st.place, st.pos);
    }
    _station('board', w.board);
    for (var z = 1; z < ModelRules.sides; z++) {
      _gate(z);
    }
    _gate(0);
    for (final b in w.branches) {
      _sign(b);
    }
    for (final m in v.markers) {
      _marker(m);
    }
  }

  /// El rectángulo de algo de [width] × [width·aspect] parado en [p].
  (Rect, double)? _stand(Offset p, double width, double aspect) {
    final c = cam.toCam(p);
    final dz = c.dy;
    if (dz < SenderoCamera.near + 0.15 || dz > SenderoCamera.far) return null;
    final base = cam.screen(c);
    final sc = cam.scaleAt(dz);
    final wpx = width * sc, h = wpx * aspect;
    final r = Rect.fromLTWH(base.dx - wpx / 2, base.dy - h, wpx, h);
    if (r.right < -40 || r.left > cam.size.width + 40 || r.top > cam.size.height) return null;
    return (r, dz);
  }

  void _add(double dz, Rect r, SenderoTarget? target, void Function(Canvas c) draw) {
    _items.add(_Drawn(dz, r, target, () => _veiled(r, dz, () => draw(_c))));
  }

  void _thing(SenderoThing t) {
    final placed = _stand(t.pos, t.width, t.aspect);
    if (placed == null) return;
    final (r, dz) = placed;
    final target = t.index == null ? null : SenderoTarget(SenderoHit.decor, index: t.index);
    _add(dz, r, target, (c) {
      if (t.decor case final id?) {
        paintDecor(c, id, r, flip: t.flip);
        if (target != null && target == v.selected) _ring(c, r);
        return;
      }
      _shadow(c, r);
      final img = SceneArt.instance[t.art ?? ''];
      if (img == null) {
        c.drawRRect(
          RRect.fromRectAndRadius(r.deflate(r.width * 0.2), Radius.circular(r.width * 0.1)),
          Paint()..color = (t.art ?? '').contains('bamboo') ? Palette.moss : Palette.stone,
        );
        return;
      }
      _art(c, img, r, flip: t.flip);
    });
  }

  void _station(String place, Offset pos) {
    final (arts, width) = stationArt[place] ?? (const <String>[], 1.6);
    final look = v.stations[place];
    final open = look?.open ?? true;
    final img = [for (final a in arts) SceneArt.instance[a]].nonNulls.firstOrNull;
    final aspect = !open ? 0.5 : (img == null ? 0.7 : img.height / img.width);
    final placed = _stand(pos, open ? width : max(2.8, width), aspect);
    if (placed == null) return;
    final (r, dz) = placed;
    final target = SenderoTarget(place == 'board' ? SenderoHit.board : SenderoHit.station, id: place);
    _add(dz, r, target, (c) {
      _shadow(c, r);
      if (!open) {
        _fence(c, r);
      } else if (img != null) {
        _art(c, img, r);
      } else {
        _stationSketch(c, place, r);
      }
    });
    // El nombre flota encima mientras se está cerca.
    if (look != null && dz < 11) {
      final label = Rect.fromCenter(center: r.topCenter - const Offset(0, 26), width: max(90, r.width), height: 36);
      _items.add(_Drawn(dz - 0.01, label, target, () => _label(look, r.topCenter, dz)));
    }
  }

  void _gate(int zone) {
    final s = w.gateAt(zone);
    final p = w.trunk.pointAt(s), n = w.trunk.normalAt(s);
    final l = cam.toCam(p - n * 1.3), rr = cam.toCam(p + n * 1.3);
    final dz = (l.dy + rr.dy) / 2;
    if (min(l.dy, rr.dy) < SenderoCamera.near + 0.15 || dz > SenderoCamera.far) return;
    final a = cam.screen(l), b = cam.screen(rr);
    final sc = cam.scaleAt(dz);
    final hgt = 2.5 * sc;
    final top = min(a.dy, b.dy) - hgt;
    final bounds = Rect.fromLTRB(min(a.dx, b.dx) - 0.6 * sc, top - 0.3 * sc, max(a.dx, b.dx) + 0.6 * sc, max(a.dy, b.dy));
    if (bounds.right < 0 || bounds.left > cam.size.width) return;
    final open = zone == 0 || v.open[zone];
    final target = open ? null : SenderoTarget(SenderoHit.gate, zone: zone);
    _add(dz, bounds, target, (c) => _torii(c, a, b, sc, hgt, open));
  }

  void _sign(SenderoBranch b) {
    final placed = _stand(b.sign, 1.2, 1.4);
    if (placed == null) return;
    final (r, dz) = placed;
    _add(dz, r, null, (c) => _signpost(c, r, b, dz));
  }

  void _marker(SenderoMarker m) {
    final img = m.art == null ? null : SceneArt.instance[m.art!];
    final aspect = img == null ? m.aspect : img.height / img.width;
    if (m.flat) {
      final c = cam.toCam(m.pos);
      if (c.dy < SenderoCamera.near + 0.2 || c.dy > 16) return;
      final ctr = cam.screen(c);
      final sc = cam.scaleAt(c.dy);
      final wpx = m.width * sc, hpx = wpx * SenderoCamera.eye / c.dy;
      final r = Rect.fromCenter(center: ctr, width: wpx, height: max(3, hpx));
      _items.add(_Drawn(c.dy + 0.6, r.inflate(10), m.target, () => _veiled(r, c.dy, () => _flat(m, r))));
      return;
    }
    final placed = _stand(m.pos, m.width, aspect);
    if (placed == null) return;
    final (r, dz) = placed;
    _add(dz, r, m.target, (c) {
      if (img != null) {
        _shadow(c, r);
        _art(c, img, r);
      } else {
        _bubble(c, m, r);
      }
      if (m.target == v.selected) _ring(c, r);
    });
  }

  // ---- Fondo ----

  void _sky() {
    final s = cam.size, h = cam.horizon;
    _c.drawRect(
      Rect.fromLTWH(0, 0, s.width, h + 2),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, h), [Palette.skyTop, Palette.skyBottom, _mist], [0, 0.7, 1]),
    );
    // Montes lejanos: se corren al girar y apenas al avanzar.
    void hills(String art, Color c, double amp, double freq, double par, double seed, double lift) {
      final shift = v.heading / (pi * 2) * s.width * 4 * par + v.pos.dy * par * 4;
      final img = SceneArt.instance[art];
      if (img != null) {
        final ww = s.width * 1.2;
        final hh = ww * img.height / img.width;
        var x = -(shift % ww);
        if (x > 0) x -= ww;
        for (; x < s.width; x += ww) {
          drawArt(_c, img, Rect.fromLTWH(x, h + 2 - hh, ww + 1, hh));
        }
        return;
      }
      final path = Path()..moveTo(0, h + 2);
      for (var x = 0.0; x <= s.width + 8; x += 8) {
        final u = (x + shift) / s.width;
        final y = h - lift - amp * (0.5 + 0.3 * sin(u * freq + seed) + 0.2 * sin(u * freq * 2.7 + seed * 2));
        path.lineTo(x, y);
      }
      path
        ..lineTo(s.width, h + 2)
        ..close();
      _c.drawPath(path, Paint()..color = c);
    }

    hills('bg_path_hills_far', Color.lerp(Palette.dusk, _mist, 0.78)!, s.height * 0.07, 5, 0.15, 1, s.height * 0.01);
    hills('bg_path_hills_near', Color.lerp(Palette.mossDark, _mist, 0.62)!, s.height * 0.045, 8, 0.3, 4, 0);
  }

  Color _groundAt(Offset p) {
    final t = p.dy / w.rules.segment;
    final i = t.floor().clamp(0, _zones.length - 1);
    final next = (i + 1).clamp(0, _zones.length - 1);
    final blend = ((t - i - 0.85) / 0.15).clamp(0.0, 1.0);
    return Color.lerp(_zones[i], _zones[next], blend)!;
  }

  void _ground() {
    final s = cam.size;
    var da = SenderoCamera.far;
    while (da > SenderoCamera.near) {
      final db = max(SenderoCamera.near, da - max(0.2, da * 0.07));
      final ya = cam.horizon + SenderoCamera.eye * cam.f / da;
      final yb = cam.horizon + SenderoCamera.eye * cam.f / db;
      final at = cam.pos + cam.forward * da;
      _c.drawRect(
        Rect.fromLTRB(0, ya - 0.5, s.width, min(s.height, yb) + 0.5),
        Paint()..color = Color.lerp(_groundAt(at), _mist, SenderoCamera.fog(da))!,
      );
      da = db;
      if (ya > s.height) break;
    }
  }

  void _water() {
    final shape = pondShape(w);
    final poly = cam.ground(shape);
    if (poly == null) return;
    final fog = SenderoCamera.fog(max(0, cam.depth(shape[0])));
    final path = Path()..addPolygon(poly, true);
    _c.drawPath(path, Paint()..color = Color.lerp(Palette.water, _mist, fog * 0.8)!);
    _c.drawPath(
      path,
      Paint()
        ..color = Color.lerp(Palette.mossDark, _mist, fog)!.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  /// Los caminos (tronco y ramales) con sus piedras pisaderas.
  void _paths() {
    final hw = w.rules.halfWidth;
    final quads = <(double, List<Offset>)>[];
    final stones = <(double, Offset, int)>[];
    for (final (ti, t) in w.tracks.indexed) {
      const step = 0.35;
      for (var s = 0.0; s < t.length; s += step) {
        final s2 = min(t.length, s + step + 0.05);
        final a = t.pointAt(s), b = t.pointAt(s2);
        final dz = cam.depth(Offset.lerp(a, b, 0.5)!);
        if (dz > SenderoCamera.far || dz < -hw * 3) continue;
        final na = t.normalAt(s) * hw, nb = t.normalAt(s2) * hw;
        // Los ramales se abren un poco al salir, para que el cruce se lea.
        double flare(double at) => ti > 0 && at < 1.5 ? 1 + (1.5 - at) * 0.5 : 1.0;
        quads.add((dz, [a - na * flare(s), a + na * flare(s), b + nb * flare(s2), b - nb * flare(s2)]));
      }
      for (var k = 0; k * 0.95 + 0.3 < t.length; k++) {
        final s = k * 0.95 + 0.3;
        if (ti > 0 && s < 0.9) continue;
        final p = t.pointAt(s) + t.normalAt(s) * (0.22 * sin(k * 1.9 + ti));
        stones.add((cam.depth(p), p, k + ti * 31));
      }
    }
    quads.sort((a, b) => b.$1.compareTo(a.$1));
    for (final (dz, q) in quads) {
      final poly = cam.ground(q);
      if (poly == null) continue;
      final fog = SenderoCamera.fog(dz);
      _c.drawPath(Path()..addPolygon(poly, true), Paint()..color = Color.lerp(_path, _mist, fog)!);
      if (poly.length == 4) {
        final edge = Paint()
          ..color = Color.lerp(_pathEdge, _mist, fog)!
          ..strokeWidth = max(1, 0.05 * cam.scaleAt(dz));
        _c
          ..drawLine(poly[0], poly[3], edge)
          ..drawLine(poly[1], poly[2], edge);
      }
    }
    stones.sort((a, b) => b.$1.compareTo(a.$1));
    for (final (dz, p, k) in stones) {
      if (dz < SenderoCamera.near + 0.1 || dz > SenderoCamera.far) continue;
      final ctr = cam.project(p)!;
      final sc = cam.scaleAt(dz);
      final wpx = (0.6 + 0.08 * sin(k * 2.3)) * sc;
      final d = 0.38 * sc * (SenderoCamera.eye / dz);
      final r = Rect.fromCenter(center: ctr, width: wpx, height: max(1.5, d));
      final fog = SenderoCamera.fog(dz);
      final img = SceneArt.instance[k.isEven ? 'obj_path_stone_01' : 'obj_path_stone_02'];
      if (img != null) {
        drawArt(_c, img, r, paint: Paint()..colorFilter = ColorFilter.mode(_mist.withValues(alpha: fog), BlendMode.srcATop));
        continue;
      }
      _c.drawOval(r.shift(Offset(0, d * 0.12)), Paint()..color = Color.lerp(Palette.stoneDark, _mist, fog)!.withValues(alpha: 0.35));
      _c.drawOval(r, Paint()..color = Color.lerp(Palette.stoneLight, _mist, fog)!);
      _c.drawOval(
        Rect.fromLTWH(r.left + r.width * 0.18, r.top + r.height * 0.1, r.width * 0.5, r.height * 0.42),
        Paint()..color = Color.lerp(Palette.sandLight, _mist, fog)!.withValues(alpha: 0.55),
      );
    }
  }

  void _haze() {
    final s = cam.size, h = cam.horizon;
    _c.drawRect(
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

  /// De noche, un velo azul.
  void _night() {
    final dark = (1 - v.daylight).clamp(0.0, 1.0) * 0.5;
    if (dark < 0.01) return;
    _c.drawRect(Offset.zero & cam.size, Paint()..color = Palette.dusk.withValues(alpha: dark));
  }

  // ---- Piezas ----

  /// Envuelve el dibujo de algo a [dz] con su bruma y, si está casi encima,
  /// lo desvanece (para que no tape todo al pasar al lado).
  void _veiled(Rect bounds, double dz, void Function() draw) {
    final fog = SenderoCamera.fog(dz);
    final alpha = ((dz - SenderoCamera.near) / 0.9).clamp(0.0, 1.0);
    if (fog < 0.01 && alpha > 0.99) return draw();
    _c.saveLayer(
      bounds.inflate(40),
      Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..colorFilter = ColorFilter.mode(_mist.withValues(alpha: fog), BlendMode.srcATop),
    );
    draw();
    _c.restore();
  }

  void _shadow(Canvas c, Rect r) => c.drawOval(
    Rect.fromCenter(center: r.bottomCenter, width: r.width * 0.8, height: r.width * 0.14),
    Paint()..color = Palette.ink.withValues(alpha: 0.14),
  );

  void _art(Canvas c, ui.Image img, Rect r, {bool flip = false}) {
    if (!flip) return drawArt(c, img, r);
    c.save();
    c.translate(r.center.dx * 2, 0);
    c.scale(-1, 1);
    drawArt(c, img, r);
    c.restore();
  }

  void _ring(Canvas c, Rect r) => c.drawRRect(
    RRect.fromRectAndRadius(r.inflate(6), const Radius.circular(10)),
    Paint()
      ..color = Palette.lantern
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5,
  );

  /// Un lugar sin arte propio: un esbozo que se entiende.
  void _stationSketch(Canvas c, String place, Rect r) {
    switch (place) {
      case 'pond':
        final water = Rect.fromLTRB(r.left, r.top + r.height * 0.45, r.right, r.bottom);
        c.drawOval(water, Paint()..color = Palette.water);
        c.drawOval(water.deflate(water.height * 0.15), Paint()..color = Palette.mossDark.withValues(alpha: 0.25));
        for (final (dx, col) in [(0.35, Palette.lantern), (0.62, Palette.paper)]) {
          c.drawOval(
            Rect.fromCenter(center: Offset(r.left + r.width * dx, water.center.dy), width: r.width * 0.12, height: r.width * 0.05),
            Paint()..color = col,
          );
        }
      case 'sand':
        final box = Rect.fromLTRB(r.left, r.top + r.height * 0.5, r.right, r.bottom);
        c.drawRect(box, Paint()..color = Palette.wood);
        c.drawRect(box.deflate(r.width * 0.04), Paint()..color = Palette.sandLight);
        final line = Paint()
          ..color = Palette.stone.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1, r.width * 0.01);
        for (var i = 1; i < 4; i++) {
          final y = box.top + box.height * i / 4;
          c.drawLine(Offset(box.left + 4, y), Offset(box.right - 4, y), line);
        }
        final rake = SceneArt.instance['obj_court_rake'];
        if (rake != null) drawArtIn(c, rake, Rect.fromLTRB(r.right - r.width * 0.35, r.top, r.right, r.bottom));
      default:
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTRB(r.left, r.top + r.height * 0.3, r.right, r.bottom), Radius.circular(r.width * 0.08)),
          Paint()..color = Palette.wood,
        );
    }
  }

  /// Un ramal cerrado: una cerca de bambú con su noren.
  void _fence(Canvas c, Rect r) {
    final img = SceneArt.instance['obj_path_fence_closed'];
    if (img != null) return drawArt(c, img, r);
    final bamboo = Paint()..color = const Color(0xFF9DA86A);
    final knot = Paint()..color = Palette.ink.withValues(alpha: 0.6);
    const n = 9;
    for (var i = 0; i < n; i++) {
      final x = r.left + r.width * (i + 0.5) / n;
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(x - r.width * 0.035, r.top + r.height * 0.1, x + r.width * 0.035, r.bottom), const Radius.circular(3)),
        bamboo,
      );
    }
    for (final y in [0.3, 0.7]) {
      c.drawRect(Rect.fromLTWH(r.left, r.top + r.height * y, r.width, r.height * 0.05), knot);
    }
    final noren = Rect.fromLTWH(r.center.dx - r.width * 0.16, r.top + r.height * 0.12, r.width * 0.32, r.height * 0.5);
    c.drawRect(noren, Paint()..color = const Color(0xFF3E4C6E));
    c.drawLine(noren.topCenter, noren.bottomCenter, Paint()..color = Palette.paper.withValues(alpha: 0.4));
  }

  void _torii(Canvas c, Offset l, Offset rr, double sc, double hgt, bool open) {
    final img = SceneArt.instance[open ? 'obj_path_gate' : 'obj_path_gate_closed'];
    final top = min(l.dy, rr.dy) - hgt;
    if (img != null) {
      final wpx = (rr.dx - l.dx).abs() + 1.2 * sc;
      final hpx = wpx * img.height / img.width;
      return drawArt(c, img, Rect.fromLTWH(min(l.dx, rr.dx) - 0.6 * sc, max(l.dy, rr.dy) - hpx, wpx, hpx));
    }
    final post = 0.16 * sc;
    final wood = Paint()..color = Palette.clay;
    final dark = Paint()..color = Palette.ink.withValues(alpha: 0.85);
    for (final p in [l, rr]) {
      c.drawRect(Rect.fromLTRB(p.dx - post / 2, top, p.dx + post / 2, p.dy), wood);
      c.drawRect(Rect.fromLTRB(p.dx - post * 0.7, p.dy - post * 0.9, p.dx + post * 0.7, p.dy), dark);
    }
    final beam = Path()
      ..moveTo(l.dx - 0.55 * sc, top - 0.12 * sc)
      ..quadraticBezierTo((l.dx + rr.dx) / 2, top + 0.05 * sc, rr.dx + 0.55 * sc, top - 0.12 * sc)
      ..lineTo(rr.dx + 0.5 * sc, top + 0.12 * sc)
      ..quadraticBezierTo((l.dx + rr.dx) / 2, top + 0.24 * sc, l.dx - 0.5 * sc, top + 0.12 * sc)
      ..close();
    c.drawPath(beam, dark);
    c.drawRect(Rect.fromLTRB(l.dx - 0.3 * sc, top + 0.42 * sc, rr.dx + 0.3 * sc, top + 0.56 * sc), wood);
    if (open) return;
    // Cerrado: la cuerda de paja de lado a lado y un sello con candado.
    final ropeY = (l.dy + rr.dy) / 2 - hgt * 0.55;
    final rope = Path()
      ..moveTo(l.dx, ropeY)
      ..quadraticBezierTo((l.dx + rr.dx) / 2, ropeY + 0.35 * sc, rr.dx, ropeY);
    c.drawPath(
      rope,
      Paint()
        ..color = const Color(0xFFC9A964)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(2, 0.12 * sc),
    );
    final seal = Offset((l.dx + rr.dx) / 2, ropeY + 0.32 * sc);
    c.drawCircle(seal, 0.28 * sc, Paint()..color = Palette.wood);
    _glyph(c, Icons.lock_rounded, seal, 0.3 * sc, Palette.paper);
  }

  void _signpost(Canvas c, Rect r, SenderoBranch b, double dz) {
    final img = SceneArt.instance['obj_path_signpost'];
    if (img != null) {
      drawArt(c, img, r);
    } else {
      c.drawRect(Rect.fromLTWH(r.center.dx - r.width * 0.05, r.top, r.width * 0.1, r.height), Paint()..color = Palette.wood);
    }
    // Las tablas: hacia el ramal, sus lugares; del otro lado, la zona que sigue.
    final names = [for (final p in b.spec.places) v.stations[p]?.name ?? p].join(' · ');
    final next = w.towards(b.at, 1);
    final ahead = next >= ModelRules.sides
        ? tr('sendero.onward')
        : tr(const ['garden.patio', 'garden.pond', 'garden.forest'][next]);
    for (final (i, text, side) in [(0, names, b.spec.side), (1, ahead, -b.spec.side)]) {
      final y = r.top + r.height * (0.12 + i * 0.28);
      final wpx = r.width * 1.3;
      final plank = side > 0
          ? Rect.fromLTWH(r.center.dx - r.width * 0.05, y, wpx, r.height * 0.18)
          : Rect.fromLTWH(r.center.dx + r.width * 0.05 - wpx, y, wpx, r.height * 0.18);
      if (img == null) {
        final tip = side > 0 ? plank.right + plank.height * 0.4 : plank.left - plank.height * 0.4;
        final near = side > 0 ? plank.left : plank.right, farX = side > 0 ? plank.right : plank.left;
        final path = Path()
          ..moveTo(near, plank.top)
          ..lineTo(farX, plank.top)
          ..lineTo(tip, plank.center.dy)
          ..lineTo(farX, plank.bottom)
          ..lineTo(near, plank.bottom)
          ..close();
        c.drawPath(path, Paint()..color = const Color(0xFFC79A66));
        c.drawPath(
          path,
          Paint()
            ..color = Palette.wood
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(1, r.width * 0.02),
        );
      }
      if (dz < 14) _text(c, text, plank.deflate(plank.height * 0.12), Palette.ink);
    }
  }

  /// El nombre de un lugar flotando arriba, con su nota.
  void _label(StationLook look, Offset top, double dz) {
    final alpha = (1 - (dz - 7) / 4).clamp(0.0, 1.0);
    if (alpha <= 0) return;
    final name = TextPainter(
      text: TextSpan(
        text: look.name,
        style: TextStyle(color: Palette.ink.withValues(alpha: alpha), fontSize: 15, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 220);
    final note = look.note == null
        ? null
        : (TextPainter(
            text: TextSpan(
              text: look.note,
              style: TextStyle(color: Palette.ink.withValues(alpha: 0.7 * alpha), fontSize: 12),
            ),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: 220));
    final lock = look.open ? 0.0 : 16.0;
    final wpx = max(name.width + lock, note?.width ?? 0) + 22;
    final hpx = name.height + (note?.height ?? 0) + 10;
    final box = Rect.fromLTWH(top.dx - wpx / 2, top.dy - hpx - 10, wpx, hpx);
    _c.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(10)),
      Paint()..color = Palette.paper.withValues(alpha: 0.86 * alpha),
    );
    if (look.dot) _c.drawCircle(box.topRight + const Offset(-4, 4), 5, Paint()..color = Palette.lantern.withValues(alpha: alpha));
    final x = box.center.dx - (name.width + lock) / 2;
    if (!look.open) {
      _glyph(_c, Icons.lock_rounded, Offset(x + 6, box.top + 5 + name.height / 2), 13, Palette.ink.withValues(alpha: 0.7 * alpha));
    }
    name.paint(_c, Offset(x + lock, box.top + 5));
    note?.paint(_c, Offset(box.center.dx - note.width / 2, box.top + 5 + name.height));
  }

  void _text(Canvas c, String text, Rect box, Color color) {
    if (box.height < 4) return;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: box.height * 0.8, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: box.width);
    tp.paint(c, Offset(box.center.dx - tp.width / 2, box.center.dy - tp.height / 2));
  }

  void _glyph(Canvas c, IconData icon, Offset center, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: size, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _bubble(Canvas c, SenderoMarker m, Rect r) {
    final d = min(r.width, r.height);
    final ctr = Offset(r.center.dx, r.bottom - d / 2);
    c.drawCircle(ctr, d * 0.55, Paint()..color = m.color.withValues(alpha: 0.25));
    c.drawCircle(ctr, d * 0.42, Paint()..color = Palette.paper.withValues(alpha: 0.92));
    if (m.icon != null) _glyph(c, m.icon!, ctr, d * 0.5, m.color);
  }

  void _flat(SenderoMarker m, Rect r) {
    final img = m.art == null ? null : SceneArt.instance[m.art!];
    if (img != null) return drawArt(_c, img, r);
    _c.drawOval(r, Paint()..color = m.color.withValues(alpha: 0.18));
    _c.drawOval(
      r.deflate(r.height * 0.1),
      Paint()
        ..color = m.color.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.5, r.height * 0.06),
    );
    if (m.icon != null) _glyph(_c, m.icon!, r.center, min(r.height, r.width) * 0.6, m.color);
  }
}

/// Dibuja el Sendero.
class SenderoPainter extends CustomPainter {
  final SenderoView view;
  SenderoPainter(this.view);

  @override
  void paint(Canvas canvas, Size size) => SenderoScene(size, view, canvas).paint();

  @override
  bool shouldRepaint(SenderoPainter old) => old.view != view;
}
