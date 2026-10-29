import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../../balance/balance.dart';
import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../../ui/fx/sfx.dart';
import '../../ui/theme/palette.dart';
import '../common/grade.dart';
import '../common/minigame_screen.dart';

/// Estado que muestra la capa de Flutter encima del juego.
class LeavesHud {
  final double seconds;
  final int inPile, total;
  final bool windWarning;
  const LeavesHud({this.seconds = 0, this.inPile = 0, this.total = 0, this.windWarning = false});
}

class Leaf {
  Offset p;
  Offset v = Offset.zero;
  double angle, spin = 0;

  /// Las livianas vuelan más con el escobazo y con el viento.
  final double weight;
  final int color;
  Leaf(this.p, this.angle, this.weight, this.color);
}

/// Empuje de un escobazo sobre una hoja: depende de qué tan cerca pasó la
/// escoba y de lo liviana que es.
Offset sweepPush(Offset leaf, Offset from, Offset to, double reach, double weight) {
  final seg = to - from;
  final len2 = seg.distanceSquared;
  if (len2 == 0) return Offset.zero;
  final t = (((leaf - from).dx * seg.dx + (leaf - from).dy * seg.dy) / len2).clamp(0.0, 1.0);
  final closest = from + seg * t;
  final d = (leaf - closest).distance;
  if (d > reach) return Offset.zero;
  return seg * ((1 - d / reach) / weight);
}

/// Hojas al viento: se barren las hojas del camino hasta el montón,
/// deslizando el dedo. Cada tanto llega una ráfaga (avisada) que desparrama
/// las que están sueltas; las del montón aguantan, pero no todas. Cuentan las
/// hojas que terminan en el montón y barrer con pocos gestos.
class LeavesGame extends FlameGame with DragCallbacks {
  final void Function(RunOutcome) finish;
  final BalanceSection b = Balance.instance.section('leaves');
  final hud = ValueNotifier(const LeavesHud());
  LeavesGame(this.finish);

  final _rng = Random();
  final _leaves = <Leaf>[];
  late double _left = b.d('seconds');
  int _strokes = 0;
  late final _milestones = StarMilestones(b.list('stars'));
  int _heard = 0;
  double _heardAt = 0;
  bool _over = false;
  Offset? _last;
  final _trail = <(Offset, double)>[];

  double? _windAt;
  double _windNext = 0;
  Offset _windDir = Offset.zero;
  double _t = 0;

  Offset get _pile => Offset(size.x / 2, size.y * 0.5);
  double get _pileR => size.x * 0.17;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final n = b.i('leaves');
    for (var i = 0; i < n; i++) {
      Offset p;
      do {
        p = Offset(30 + _rng.nextDouble() * (size.x - 60), size.y * 0.2 + _rng.nextDouble() * size.y * 0.66);
      } while ((p - _pile).distance < _pileR * 1.4);
      _leaves.add(Leaf(p, _rng.nextDouble() * pi, 0.6 + _rng.nextDouble() * 0.9, _rng.nextInt(4)));
    }
    _windNext = b.d('windFirst') + _rng.nextDouble() * 3;
    _publish();
  }

  /// El camino de grava (el resto es pasto).
  Rect get _path => Rect.fromLTRB(0, size.y * 0.15, size.x, size.y * 0.92);

  bool _inPile(Leaf l) => (l.p - _pile).distance < _pileR;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_over) return;
    _last = Offset(event.localPosition.x, event.localPosition.y);
    _strokes++;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final from = _last;
    if (from == null || _over) return;
    final to = Offset(event.localEndPosition.x, event.localEndPosition.y);
    _last = to;
    _trail.add((to, 0.35));
    final reach = size.x * b.d('broomReach');
    var touched = false;
    for (final l in _leaves) {
      final push = sweepPush(l.p, from, to, reach, l.weight);
      if (push == Offset.zero) continue;
      touched = true;
      // Un poco de azar en cada hoja: ninguna sale igual.
      final jitter = Offset(_rng.nextDouble() - 0.5, _rng.nextDouble() - 0.5) * push.distance * 0.5;
      l.v += (push + jitter) * b.d('sweepForce');
      l.spin += (_rng.nextDouble() - 0.5) * 8;
    }
    if (touched && _rng.nextDouble() < 0.15) SoundBoard.instance.play(Sfx.uiTap, volume: 0.15);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _last = null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    for (var i = 0; i < _trail.length; i++) {
      _trail[i] = (_trail[i].$1, _trail[i].$2 - dt);
    }
    _trail.removeWhere((e) => e.$2 <= 0);
    if (!_over) {
      _left -= dt;
      _updateWind(dt);
      if (_left <= 0) _end();
    }
    final friction = exp(-dt * b.d('friction'));
    for (final l in _leaves) {
      l.p += l.v * dt;
      l.v *= friction;
      l.angle += l.spin * dt;
      l.spin *= friction;
      // Bordes del camino: la hoja rebota apenas contra el pasto y frena.
      final r = _path.deflate(10);
      if (l.p.dx < r.left || l.p.dx > r.right) l.v = Offset(-l.v.dx * 0.3, l.v.dy * 0.6);
      if (l.p.dy < r.top || l.p.dy > r.bottom) l.v = Offset(l.v.dx * 0.6, -l.v.dy * 0.3);
      l.p = Offset(l.p.dx.clamp(r.left, r.right), l.p.dy.clamp(r.top, r.bottom));
    }
    _publish();
  }

  void _updateWind(double dt) {
    final at = _windAt;
    if (at == null) {
      _windNext -= dt;
      if (_windNext <= 0) {
        _windAt = _t;
        final a = _rng.nextDouble() * 2 * pi;
        _windDir = Offset(cos(a), sin(a) * 0.5);
        SoundBoard.instance.loop(Ambience.wind, volume: 0.3, fade: const Duration(milliseconds: 600));
      }
      return;
    }
    final e = _t - at;
    final warn = b.d('windWarning');
    if (e < warn) return;
    if (e < warn + b.d('windDuration')) {
      for (final l in _leaves) {
        // En el montón aguantan más; sueltas, vuelan según su peso.
        final hold = _inPile(l) ? b.d('pileHold') : 1.0;
        final gust = b.d('windForce') * (0.6 + 0.8 * _rng.nextDouble()) * hold / l.weight;
        l.v += _windDir * gust * dt;
        l.spin += (_rng.nextDouble() - 0.5) * dt * 6;
      }
    } else {
      _windAt = null;
      _windNext = b.d('windEvery') * (0.7 + 0.6 * _rng.nextDouble());
      SoundBoard.instance.stopLoop(Ambience.wind);
    }
  }

  double get _score {
    final share = _leaves.where(_inPile).length / _leaves.length;
    // Pocos gestos suman un poco (barrer con calma).
    final calm = (1 - (_strokes - b.i('calmStrokes')) / 40).clamp(0.0, 1.0);
    return share * 0.85 + calm * 0.15 * share;
  }

  void _end() {
    _over = true;
    _windAt = null;
    SoundBoard.instance.stopLoop(Ambience.wind);
    final score = _score;
    final points = (score * 1000).round();
    final record = points > Progress.instance.best('leaves');
    Progress.instance.setBest('leaves', points);
    final stars = starsFor(score, b.list('stars'));
    if (stars > 0) celebrate(world, Vector2(_pile.dx, _pile.dy - _pileR), Grade.values[stars - 1]);
    Future.delayed(const Duration(milliseconds: 700), () {
      finish(
        RunOutcome(
          score: points,
          stars: stars,
          headline: tr('leaves.result', {'n': _leaves.where(_inPile).length, 'total': _leaves.length}),
          record: record,
        ),
      );
    });
  }

  void _publish() {
    final e = _windAt == null ? -1 : _t - _windAt!;
    final inPile = _leaves.where(_inPile).length;
    if (!_over) {
      // Cada hoja que entra al montón suena, más aguda cuanto más lleno.
      if (inPile > _heard && _t - _heardAt > 0.12) {
        _heardAt = _t;
        SoundBoard.instance.play(Sfx.rainNote, variant: (inPile * 5 / _leaves.length).ceil().clamp(1, 5), volume: 0.16);
      }
      _heard = inPile;
      _milestones.update(_score, world, Vector2(_pile.dx, _pile.dy - _pileR - 20));
    }
    hud.value = LeavesHud(
      seconds: max(0, _left),
      inPile: inPile,
      total: _leaves.length,
      windWarning: e >= 0 && e < b.d('windWarning') + b.d('windDuration'),
    );
  }

  static const _colors = [Color(0xFFD9822B), Color(0xFFC0552F), Color(0xFFE3B23C), Color(0xFF9C6B3A)];

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Offset.zero & Size(size.x, size.y), Paint()..color = Palette.moss);
    // Camino de grava con un borde de piedritas contra el pasto.
    final path = _path;
    canvas.drawRect(path, Paint()..color = Palette.sand);
    final rng = Random(2);
    final grit = Paint()..color = Palette.sandShadow.withValues(alpha: 0.6);
    for (var i = 0; i < 220; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.x, path.top + rng.nextDouble() * path.height),
        0.8 + rng.nextDouble() * 1.4,
        grit,
      );
    }
    final edge = Paint()..color = Palette.stone;
    final edgeDark = Paint()..color = Palette.stoneDark.withValues(alpha: 0.5);
    for (final y in [path.top, path.bottom]) {
      for (var x = 4.0; x < size.x; x += 13 + rng.nextDouble() * 6) {
        final r = 5 + rng.nextDouble() * 2.5;
        final c = Offset(x, y + rng.nextDouble() * 4 - 2);
        canvas.drawCircle(c + const Offset(0, 1.5), r, edgeDark);
        canvas.drawCircle(c, r, edge);
      }
    }
    // El montón: un círculo de barrido en la grava.
    canvas.drawCircle(_pile, _pileR, Paint()..color = Palette.sandShadow.withValues(alpha: 0.35));
    canvas.drawCircle(
      _pile,
      _pileR,
      Paint()
        ..color = Palette.wood.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (final (p, life) in _trail) {
      canvas.drawCircle(
        p,
        size.x * b.d('broomReach') * 0.6,
        Paint()..color = const Color(0x22FFFFFF).withValues(alpha: 0.12 * life / 0.35),
      );
    }
    // Las hojas: con sombra; las que vuelan rápido se levantan (sombra más
    // lejos y un poco más grandes).
    final shadow = Paint()..color = Palette.ink.withValues(alpha: 0.14);
    for (final l in _leaves) {
      final lift = min(1.0, l.v.distance / 420);
      final s = (10 + 5 * l.weight) * (1 + 0.18 * lift);
      final leaf = Path()
        ..moveTo(-s, 0)
        ..quadraticBezierTo(0, -s * 0.6, s, 0)
        ..quadraticBezierTo(0, s * 0.6, -s, 0);
      canvas.save();
      canvas.translate(l.p.dx + 2 + 6 * lift, l.p.dy + 3 + 10 * lift);
      canvas.rotate(l.angle);
      canvas.drawPath(leaf, shadow);
      canvas.restore();
      canvas.save();
      canvas.translate(l.p.dx, l.p.dy);
      canvas.rotate(l.angle);
      canvas.drawPath(leaf, Paint()..color = _colors[l.color]);
      canvas.drawLine(Offset(-s, 0), Offset(s, 0), Paint()..color = const Color(0x55000000));
      canvas.restore();
    }
    if (_windAt != null) {
      final e = _t - _windAt!;
      final a = (e < b.d('windWarning') ? 0.12 : 0.25) * (0.6 + 0.4 * sin(_t * 6));
      final line = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: a)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var k = 0; k < 8; k++) {
        final r = Random(k);
        final base = Offset(r.nextDouble() * size.x, size.y * (0.15 + 0.7 * r.nextDouble()));
        final shift = _windDir * ((_t * 160 + k * 90) % (size.x + 200) - 100);
        canvas.drawLine(base + shift, base + shift + _windDir * 40, line);
      }
    }
    super.render(canvas);
  }
}
