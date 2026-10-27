import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../../balance/balance.dart';
import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../../ui/fx/sfx.dart';
import '../../ui/theme/palette.dart';
import '../common/grade.dart';
import '../common/minigame_screen.dart';
import 'stack_rules.dart';

/// Estado que muestra la capa de Flutter encima del juego.
class StackHud {
  final int height;
  final bool windWarning, windBlowing, over;
  const StackHud({this.height = 0, this.windWarning = false, this.windBlowing = false, this.over = false});
}

/// Apilado de piedras: una piedra se balancea arriba y se toca para soltarla.
/// La torre queda en el jardín y junta Piedritas por hora según su altura.
/// A veces llega una ráfaga (avisada 3 s antes con hojas): mantener el dedo
/// apretado sostiene la torre.
class StackGame extends Forge2DGame with TapCallbacks {
  final void Function(RunOutcome) finish;
  final BalanceSection b = Balance.instance.stack;
  final hud = ValueNotifier(const StackHud());

  StackGame(this.finish) : super(gravity: Vector2(0, Balance.instance.stack.d('gravity')));

  final _rng = Random();
  final _placed = <_Stone>[];
  _Stone? _falling;
  double _settle = 0;
  double _prevVy = 0;
  late StoneShape _next;
  double _t = 0;
  double _camY = 0;
  int _perfects = 0;
  int _peak = 0;
  bool _over = false;
  bool _holding = false;

  // Viento: aviso -> ráfaga -> calma.
  double? _windAt;
  double _windDir = 1;
  final _leaves = <_Leaf>[];

  double get _visibleH => size.y / camera.viewfinder.zoom;
  double get _topY => _placed.isEmpty ? 0 : _placed.map((s) => s.body.position.y - s.shape.height / 2).reduce(min);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    world.add(_Ground());
    world.add(_Pedestal());
    _next = randomStone(_rng, 0);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x > 0) camera.viewfinder.zoom = size.x / b.d('worldWidth');
  }

  bool get _windy => _windAt != null;
  bool get _canDrop => !_over && _falling == null && !_windy;

  Vector2 get _hoverPos {
    final speed = b.d('swingSpeed') + b.d('swingSpeedPerStone') * _placed.length;
    return Vector2(b.d('swingAmplitude') * sin(_t * speed), _topY - 3.2);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _holding = true;
    if (!_canDrop) return;
    final stone = _Stone(_next, _hoverPos, damped: _placed.length < b.i('dampedStones'));
    _falling = stone;
    _settle = 0;
    _prevVy = 0;
    world.add(stone);
    _next = randomStone(_rng, _placed.length + 1);
  }

  @override
  void onTapUp(TapUpEvent event) => _holding = false;

  @override
  void onTapCancel(TapCancelEvent event) => _holding = false;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (!_over) {
      _updateFalling(dt);
      _updateWind(dt);
      _checkCollapse();
    }
    // La cámara sigue la punta de la torre, suave.
    final target = min(-0.28 * _visibleH, _topY + 0.08 * _visibleH);
    _camY += (target - _camY) * min(1, dt * 3);
    camera.viewfinder.position = Vector2(0, _camY);
    for (final l in _leaves) {
      l.x += l.vx * dt;
      l.y += sin(_t * 3 + l.phase) * 30 * dt;
      l.spin += dt * 2;
    }
    _leaves.removeWhere((l) => l.x < -60 || l.x > size.x + 60);
  }

  void _updateFalling(double dt) {
    final s = _falling;
    if (s == null || !s.isMounted) return;
    final body = s.body;
    final below = _placed.isEmpty ? null : _placed.last;
    final targetX = below?.body.position.x ?? 0;
    final top = _topY;
    // Imán sutil hacia el centro de la de abajo mientras cae (asistencia invisible).
    if (body.position.y < top - 0.2) {
      body.applyForce(Vector2(b.d('magnet') * (targetX - body.position.x) * body.mass, 0));
    }
    final vy = body.linearVelocity.y;
    if (_prevVy > 2.5 && vy < _prevVy * 0.4) {
      SoundBoard.instance.play(Sfx.stackPlace, volume: min(0.8, _prevVy / 10));
      Haptics.light();
    }
    _prevVy = vy;
    if (body.position.y > 0.6) {
      // No cayó en la torre: rueda al suelo y se va, sin castigo.
      _falling = null;
      s.fadeOut();
      return;
    }
    final still = body.linearVelocity.length < 0.15 && body.angularVelocity.abs() < 0.2;
    _settle = still ? _settle + dt : 0;
    if (_settle > 0.35) {
      _falling = null;
      // Quedó de costado junto a la torre, no arriba: no cuenta y se va.
      final onTop = below == null
          ? body.position.x.abs() < _Pedestal.width / 2
          : body.position.y < below.body.position.y - 0.15;
      if (!onTop) {
        s.fadeOut();
        return;
      }
      final belowW = below?.shape.width ?? _Pedestal.width;
      final grade = stoneGrade(body.position.x - targetX, belowW, b);
      if (grade == Grade.perfect) _perfects++;
      _placed.add(s);
      s.calm();
      _peak = max(_peak, _placed.length);
      celebrate(camera.viewport, worldToScreen(body.position - Vector2(0, s.shape.height)), grade);
      _publish();
      _maybeWind();
    }
  }

  void _maybeWind() {
    if (_placed.length < b.i('windFromStone')) return;
    if (_rng.nextDouble() > b.d('windChancePerStone')) return;
    _windAt = _t;
    _windDir = _rng.nextBool() ? 1 : -1;
    _publish();
  }

  void _updateWind(double dt) {
    final at = _windAt;
    if (at == null) return;
    final e = _t - at;
    final warn = b.d('windWarning');
    if (_rng.nextDouble() < dt * (e < warn ? 8 : 20)) {
      _leaves.add(
        _Leaf(
          _windDir > 0 ? -30 : size.x + 30,
          size.y * (0.15 + _rng.nextDouble() * 0.6),
          _windDir * (140 + _rng.nextDouble() * 120) * (e < warn ? 1 : 1.5),
          _rng.nextDouble() * 6,
        ),
      );
    }
    if (e >= warn && e < warn + b.d('windDuration')) {
      if (!hud.value.windBlowing) {
        SoundBoard.instance.loop(Ambience.wind, volume: 0.42, fade: const Duration(milliseconds: 700));
        _publish(blowing: true);
      }
      final f = b.d('windForce') * (_holding ? b.d('windHoldFactor') : 1) * _windDir;
      for (final s in _placed) {
        // Empuja más arriba: la punta de la torre es la que sufre.
        final h = (-s.body.position.y).clamp(0, 30) / 10;
        s.body.applyForce(Vector2(f * s.body.mass * h, 0));
      }
    } else if (e >= warn + b.d('windDuration')) {
      _windAt = null;
      SoundBoard.instance.stopLoop(Ambience.wind);
      _publish();
    }
  }

  void _checkCollapse() {
    final fallen = _placed.any((s) => s.body.position.y > 0.3);
    if (!fallen) return;
    _over = true;
    _windAt = null;
    SoundBoard.instance.stopLoop(Ambience.wind);
    // Una caída se cuenta con calma: un "toc" grave y un golpe suave (pilar 8).
    SoundBoard.instance.play(Sfx.stackFall, volume: 0.55);
    Haptics.medium();
    _publish();
    Future.delayed(const Duration(milliseconds: 1600), () => _end(collapsed: true));
  }

  /// Termina la partida: lo que sigue en pie queda en el jardín.
  void endRun() {
    if (_over) return;
    _over = true;
    _publish();
    _end(collapsed: false);
  }

  void _end({required bool collapsed}) {
    // De abajo hacia arriba, como quedaron (no como se soltaron).
    final up = _placed.where((s) => s.body.position.y < 0).toList()
      ..sort((a, b) => b.body.position.y.compareTo(a.body.position.y));
    final standing = [for (final s in up) (x: s.body.position.x, w: s.shape.width, h: s.shape.height)];
    final record = _peak > Progress.instance.bestTower;
    Progress.instance.setTower(standing);
    final stars = starsFor(_peak.toDouble(), b.list('starHeights'));
    final head = trN('stack.height', _peak);
    finish(
      RunOutcome(
        score: _peak + _perfects * b.i('perfectBonus'),
        stars: stars,
        headline: collapsed ? '${tr('stack.fell')}\n$head' : head,
        record: record,
      ),
    );
  }

  void _publish({bool? blowing}) {
    final e = _windAt == null ? -1 : _t - _windAt!;
    hud.value = StackHud(
      height: _placed.length,
      windWarning: e >= 0 && e < b.d('windWarning'),
      windBlowing: blowing ?? (e >= b.d('windWarning')),
      over: _over,
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Offset.zero & Size(size.x, size.y),
      Paint()..shader = Gradient.linear(Offset.zero, Offset(0, size.y), [Palette.skyTop, Palette.skyBottom]),
    );
    super.render(canvas);
    if (_canDrop) {
      final p = worldToScreen(_hoverPos);
      final zoom = camera.viewfinder.zoom;
      // Hilo y piedra que se balancea (no es un cuerpo físico hasta soltarla).
      canvas.drawLine(Offset(p.x, 0), Offset(p.x, p.y), Paint()..color = Palette.ink.withValues(alpha: 0.15));
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.scale(zoom);
      paintStone(canvas, _next);
      canvas.restore();
    }
    final leaf = Paint()..color = Palette.moss;
    for (final l in _leaves) {
      canvas.save();
      canvas.translate(l.x, l.y);
      canvas.rotate(l.spin);
      canvas.drawOval(const Rect.fromLTWH(-7, -3, 14, 6), leaf);
      canvas.restore();
    }
  }
}

/// Pinta una piedra en coordenadas del mundo (metros).
void paintStone(Canvas canvas, StoneShape shape) {
  final path = Path();
  for (var i = 0; i < shape.vertices.length; i++) {
    final (x, y) = shape.vertices[i];
    i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
  }
  path.close();
  final base = [Palette.stone, Palette.stoneDark, Palette.stoneLight][shape.tone];
  canvas.drawPath(path, Paint()..color = base);
  // Brillo arriba y sombra abajo para que se lea el volumen.
  canvas.save();
  canvas.clipPath(path);
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(-shape.width * 0.1, -shape.height * 0.35),
      width: shape.width * 0.8,
      height: shape.height * 0.5,
    ),
    Paint()..color = const Color(0x33FFFFFF),
  );
  canvas.drawRect(
    Rect.fromLTWH(-shape.width, shape.height * 0.18, shape.width * 2, shape.height),
    Paint()..color = const Color(0x22000000),
  );
  canvas.restore();
}

class _Stone extends BodyComponent {
  final StoneShape shape;
  final Vector2 start;
  final bool damped;
  double _fade = 1;
  bool _fading = false;

  _Stone(this.shape, this.start, {required this.damped}) : super(renderBody: false);

  @override
  Body createBody() {
    final body = world.createBody(
      BodyDef(
        type: BodyType.dynamic,
        position: start,
        // Física amortiguada en las primeras piedras (asistencia invisible).
        linearDamping: damped ? 1.2 : 0.2,
        angularDamping: damped ? 4 : 1.5,
      ),
    );
    body.createFixture(
      FixtureDef(
        PolygonShape()..set([for (final (x, y) in shape.vertices) Vector2(x, y)]),
        density: 1,
        friction: 0.9,
        restitution: 0,
      ),
    );
    return body;
  }

  /// Ya apoyada: un poco más de amortiguación para que la torre no tiemble.
  void calm() {
    body.angularDamping = max(body.angularDamping, 2.5);
  }

  void fadeOut() => _fading = true;

  @override
  void update(double dt) {
    super.update(dt);
    if (_fading) {
      _fade -= dt * 1.5;
      if (_fade <= 0) removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_fade < 1) canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, _fade.clamp(0, 1)));
    paintStone(canvas, shape);
    if (_fade < 1) canvas.restore();
  }
}

class _Pedestal extends BodyComponent {
  static const width = 3.4;
  _Pedestal() : super(renderBody: false);

  @override
  Body createBody() {
    final body = world.createBody(BodyDef(position: Vector2(0, 0.5)));
    body.createFixture(FixtureDef(PolygonShape()..setAsBoxXY(width / 2, 0.5), friction: 1));
    return body;
  }

  @override
  void render(Canvas canvas) {
    final r = RRect.fromRectAndRadius(const Rect.fromLTWH(-width / 2, -0.5, width, 1), const Radius.circular(0.15));
    canvas.drawRRect(r, Paint()..color = Palette.stoneDark);
    canvas.drawRect(const Rect.fromLTWH(-width / 2, -0.5, width, 0.12), Paint()..color = Palette.moss);
  }
}

class _Ground extends BodyComponent {
  _Ground() : super(renderBody: false);

  @override
  Body createBody() {
    final body = world.createBody(BodyDef(position: Vector2(0, 6)));
    body.createFixture(FixtureDef(PolygonShape()..setAsBoxXY(40, 5), friction: 1));
    return body;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(const Rect.fromLTWH(-40, -5, 80, 30), Paint()..color = Palette.sand);
    canvas.drawRect(const Rect.fromLTWH(-40, -5, 80, 0.15), Paint()..color = Palette.sandShadow);
  }
}

class _Leaf {
  double x, y, spin = 0;
  final double vx, phase;
  _Leaf(this.x, this.y, this.vx, this.phase);
}
