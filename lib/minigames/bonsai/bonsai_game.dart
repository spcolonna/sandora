import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/game.dart';

import '../../balance/balance.dart';
import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../../ui/fx/sfx.dart';
import '../../ui/theme/palette.dart';
import '../common/grade.dart';
import '../common/minigame_screen.dart';

/// Si los segmentos [a1]-[a2] y [b1]-[b2] se cruzan.
bool segmentsCross(Offset a1, Offset a2, Offset b1, Offset b2) {
  double cross(Offset o, Offset p, Offset q) => (p.dx - o.dx) * (q.dy - o.dy) - (p.dy - o.dy) * (q.dx - o.dx);
  final d1 = cross(b1, b2, a1), d2 = cross(b1, b2, a2);
  final d3 = cross(a1, a2, b1), d4 = cross(a1, a2, b2);
  return ((d1 > 0) != (d2 > 0)) && ((d3 > 0) != (d4 > 0));
}

class _Branch {
  final Offset base;
  final Offset dir;
  final double target, speed, bend;

  /// Si al crecer se va a salir de la silueta.
  final bool wild;
  double length = 0;
  double fall = -1; // >= 0 mientras cae cortada
  int get seed => (target * 997).round();
  _Branch(this.base, this.dir, this.target, this.speed, this.bend, {required this.wild});

  Offset at(double l) {
    // Un poco curvada: las ramas no crecen derechas.
    final n = Offset(-dir.dy, dir.dx);
    final k = l / max(1, target);
    return base + dir * l + n * (bend * k * k * target);
  }

  Offset get tip => at(length);
}

/// Poda del bonsái: el árbol echa ramas sin parar; las que se salen de la
/// silueta se cortan deslizando el dedo sobre ellas (el corte va al nodo).
/// Cortar una rama que crecía bien resta. Cada rama crece a su ritmo y no se
/// sabe del todo hasta dónde va a llegar.
class BonsaiGame extends FlameGame with DragCallbacks {
  final void Function(RunOutcome) finish;
  final BalanceSection b = Balance.instance.section('bonsai');
  BonsaiGame(this.finish);

  final _rng = Random();
  final _branches = <_Branch>[];
  late double _left = b.d('seconds');
  double _spawn = 0.6;
  int _wildCut = 0, _goodCut = 0;
  bool _over = false;
  Offset? _last;
  final _trail = <(Offset, double)>[];

  Offset get _center => Offset(size.x / 2, size.y * 0.4);

  /// La silueta: tres nubes (óvalos) como un bonsái podado.
  List<Rect> get _pads => [
    Rect.fromCenter(
      center: _center + Offset(-size.x * 0.2, size.y * 0.05),
      width: size.x * 0.42,
      height: size.y * 0.15,
    ),
    Rect.fromCenter(center: _center + Offset(size.x * 0.2, size.y * 0.02), width: size.x * 0.44, height: size.y * 0.16),
    Rect.fromCenter(center: _center + Offset(0, -size.y * 0.1), width: size.x * 0.48, height: size.y * 0.17),
  ];

  bool _inside(Offset p) => _pads.any((r) {
    final d = Offset((p.dx - r.center.dx) / (r.width / 2), (p.dy - r.center.dy) / (r.height / 2));
    return d.distance <= 1;
  });

  Offset get _pot => Offset(size.x / 2, size.y * 0.7);

  /// Nodos de las ramas madre, de donde salen las ramas nuevas: cerca de las
  /// copas, así algunas quedan adentro y otras se escapan (hay que elegir).
  List<Offset> get _nodes => [
    for (final r in _pads)
      for (final f in [0.6, 0.85, 1.0]) Offset.lerp(_pot - Offset(0, size.y * 0.12), r.center, f)!,
  ];

  @override
  void update(double dt) {
    super.update(dt);
    for (var i = 0; i < _trail.length; i++) {
      _trail[i] = (_trail[i].$1, _trail[i].$2 - dt);
    }
    _trail.removeWhere((e) => e.$2 <= 0);
    for (final br in _branches) {
      if (br.fall >= 0) {
        br.fall += dt;
      } else {
        br.length = min(br.target, br.length + br.speed * dt);
      }
    }
    _branches.removeWhere((br) => br.fall > 1.2);
    if (_over) return;
    _left -= dt;
    _spawn -= dt;
    if (_spawn <= 0) {
      _spawn = b.d('spawnEvery') * (0.6 + 0.8 * _rng.nextDouble());
      _newBranch();
    }
    if (_left <= 0) _end();
  }

  void _newBranch() {
    final nodes = _nodes;
    final base = nodes[_rng.nextInt(nodes.length)];
    final out = base - _center;
    final a = atan2(out.dy, out.dx) + (_rng.nextDouble() - 0.5) * 1.6;
    final dir = Offset(cos(a), sin(a) * 0.8 - 0.2);
    final unit = dir / dir.distance;
    final target = size.x * (b.d('minLength') + _rng.nextDouble() * (b.d('maxLength') - b.d('minLength')));
    final bend = (_rng.nextDouble() - 0.5) * 0.4;
    final speed = size.x * b.d('growSpeed') * (0.6 + 0.8 * _rng.nextDouble());
    final draft = _Branch(base, unit, target, speed, bend, wild: false);
    final wild = !_inside(draft.at(target));
    _branches.add(_Branch(base, unit, target, speed, bend, wild: wild));
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _last = Offset(event.localPosition.x, event.localPosition.y);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final from = _last;
    if (from == null || _over) return;
    final to = Offset(event.localEndPosition.x, event.localEndPosition.y);
    _last = to;
    _trail.add((to, 0.3));
    for (final br in _branches) {
      if (br.fall >= 0 || br.length < 6) continue;
      if (!_crosses(from, to, br)) continue;
      br.fall = 0;
      SoundBoard.instance.play(Sfx.uiTap, volume: 0.5);
      if (br.wild) {
        _wildCut++;
        // Cortar a tiempo (antes de que se salga) vale más.
        final early = _inside(br.tip);
        celebrate(world, Vector2(br.tip.dx, br.tip.dy), early ? Grade.great : Grade.good, sound: false);
      } else {
        _goodCut++;
        Haptics.medium();
      }
    }
  }

  /// Si el trazo cruza la rama tal como se dibuja (curvada, no recta).
  bool _crosses(Offset from, Offset to, _Branch br) {
    var a = br.base;
    for (var s = 1; s <= 8; s++) {
      final p = br.at(br.length * s / 8);
      if (segmentsCross(from, to, a, p)) return true;
      a = p;
    }
    return false;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _last = null;
  }

  void _end() {
    _over = true;
    // Las salvajes que quedaron afuera cuentan en contra.
    final leftOut = _branches.where((br) => br.fall < 0 && br.wild).length;
    final harmony = ((_wildCut - b.d('goodCutPenalty') * _goodCut) / max(1, _wildCut + leftOut)).clamp(0.0, 1.0);
    final pct = (harmony * 100).round();
    final record = pct > Progress.instance.best('bonsai');
    Progress.instance.setBest('bonsai', pct);
    final stars = starsFor(harmony, b.list('stars'));
    if (stars > 0) celebrate(world, Vector2(_center.dx, _center.dy), Grade.values[stars - 1]);
    Future.delayed(const Duration(milliseconds: 700), () {
      finish(RunOutcome(score: pct, stars: stars, headline: tr('bonsai.result', {'n': pct}), record: record));
    });
  }

  /// Follaje como una nube de círculos: sombra abajo, cuerpo y brillo arriba.
  /// [light] es el verde claro de lo que crece fuera de la silueta.
  void _foliage(Canvas canvas, Rect r, double alpha, int seed, {bool light = false}) {
    // Semilla fija: la nube crece sin cambiar de forma.
    final rng = Random(seed);
    final blobs = [
      for (var k = 0; k < 7; k++)
        (
          r.center + Offset((rng.nextDouble() - 0.5) * r.width * 0.6, (rng.nextDouble() - 0.5) * r.height * 0.45),
          r.height * (0.32 + 0.12 * rng.nextDouble()),
        ),
    ];
    final shade = Paint()..color = (light ? const Color(0xFF7E9A55) : Palette.mossDark).withValues(alpha: alpha);
    final body = Paint()..color = (light ? const Color(0xFF9BB36B) : Palette.moss).withValues(alpha: alpha);
    final shine = Paint()
      ..color = (light ? const Color(0xFFC2D58F) : const Color(0xFF8DB06A)).withValues(alpha: 0.8 * alpha);
    for (final (c, rad) in blobs) {
      canvas.drawCircle(c + Offset(0, rad * 0.25), rad, shade);
    }
    for (final (c, rad) in blobs) {
      canvas.drawCircle(c, rad * 0.92, body);
    }
    for (final (c, rad) in blobs.take(4)) {
      canvas.drawCircle(c - Offset(rad * 0.25, rad * 0.3), rad * 0.4, shine);
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Offset.zero & Size(size.x, size.y),
      Paint()..shader = Gradient.linear(Offset.zero, Offset(0, size.y), [const Color(0xFFE6EBDD), Palette.paper]),
    );
    // Silueta guía, punteada.
    final guide = Paint()
      ..color = Palette.moss.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    for (final r in _pads) {
      canvas.drawOval(r, guide);
    }
    final dash = Paint()
      ..color = Palette.mossDark.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    for (final r in _pads) {
      for (var k = 0; k < 40; k += 2) {
        final a1 = 2 * pi * k / 40, a2 = 2 * pi * (k + 1) / 40;
        canvas.drawLine(
          r.center + Offset(cos(a1) * r.width / 2, sin(a1) * r.height / 2),
          r.center + Offset(cos(a2) * r.width / 2, sin(a2) * r.height / 2),
          dash,
        );
      }
    }
    // Maceta y tronco.
    final pot = Rect.fromCenter(center: _pot + const Offset(0, 24), width: size.x * 0.42, height: 46);
    canvas.drawRRect(RRect.fromRectAndRadius(pot, const Radius.circular(8)), Paint()..color = const Color(0xFF7A4E3A));
    final trunk = Paint()
      ..color = const Color(0xFF6B4A35)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fork = _pot - Offset(0, size.y * 0.12);
    canvas.drawPath(
      Path()
        ..moveTo(_pot.dx, _pot.dy)
        ..quadraticBezierTo(_pot.dx - size.x * 0.12, _pot.dy - size.y * 0.06, fork.dx, fork.dy),
      trunk..strokeWidth = 16,
    );
    for (final r in _pads) {
      canvas.drawLine(fork, r.center, trunk..strokeWidth = 8);
    }
    // Copas base (lo que ya está bien): nubes de follaje con sombra y luz.
    final pads = _pads;
    for (var i = 0; i < pads.length; i++) {
      final r = pads[i];
      _foliage(canvas, Rect.fromCenter(center: r.center, width: r.width * 0.6, height: r.height * 0.55), 1, i);
    }
    // Ramas nuevas con su mechón de hojas en la punta.
    for (final br in _branches) {
      final fall = br.fall;
      canvas.save();
      if (fall >= 0) {
        canvas.translate(0, fall * fall * 400);
        canvas.translate(br.base.dx, br.base.dy);
        canvas.rotate(fall * 1.5 * (br.dir.dx >= 0 ? 1 : -1));
        canvas.translate(-br.base.dx, -br.base.dy);
      }
      final alpha = fall >= 0 ? (1 - fall / 1.2).clamp(0.0, 1.0) : 1.0;
      final outside = !_inside(br.tip);
      final path = Path()..moveTo(br.base.dx, br.base.dy);
      for (var s = 1; s <= 8; s++) {
        final p = br.at(br.length * s / 8);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF6B4A35).withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );
      final tuft = 6 + 10 * (br.length / br.target);
      final bloom = Rect.fromCenter(center: br.tip, width: tuft * 2.4, height: tuft * 1.8);
      _foliage(canvas, bloom, alpha, br.seed, light: outside);
      canvas.restore();
    }
    // El corte de la tijera: una línea fina que se apaga.
    for (var i = 1; i < _trail.length; i++) {
      final (a, _) = _trail[i - 1];
      final (b, life) = _trail[i];
      if ((b - a).distance > size.x * 0.3) continue;
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9 * life / 0.3)
          ..strokeWidth = 1 + 3 * life / 0.3
          ..strokeCap = StrokeCap.round,
      );
    }
    // Tiempo.
    final k = (_left / b.d('seconds')).clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(24, size.y * 0.1, (size.x - 110) * k, 6), const Radius.circular(3)),
      Paint()..color = Palette.moss,
    );
    super.render(canvas);
  }
}
