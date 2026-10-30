import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../../balance/balance.dart';
import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../../ui/fx/sfx.dart';
import '../../ui/garden/scene_art.dart';
import '../../ui/theme/palette.dart';
import '../common/grade.dart';
import '../common/minigame_screen.dart';
import 'stack_rules.dart';
import 'stone_painter.dart';

/// Estado que muestra la capa de Flutter encima del juego.
class StackHud {
  final int height, bag;
  final bool windWarning, windBlowing, over;

  /// Piedras que se cayeron en el último derrumbe y su número (para el aviso).
  final int lost, lostAt;
  const StackHud({
    this.height = 0,
    this.bag = 0,
    this.windWarning = false,
    this.windBlowing = false,
    this.over = false,
    this.lost = 0,
    this.lostAt = 0,
  });
}

/// Una piedra apoyada en la torre. [y] es su centro (negativo hacia arriba;
/// el pedestal está en 0) y [tilt], cuánto quedó inclinada.
class _Placed {
  final StoneShape shape;
  final double x, y, tilt;
  _Placed(this.shape, this.x, this.y, this.tilt);

  double get top => y - shape.height / 2;
}

/// Piedra en el aire: la que se soltó o una que se cae de la torre.
class _Loose {
  final StoneShape shape;
  double x, y, vx, vy, angle, spin;
  double fade = 1;
  _Loose(this.shape, this.x, this.y, {this.vx = 0, this.vy = 0, this.angle = 0, this.spin = 0});
}

const _debugTower = int.fromEnvironment('SANDORA_TOWER');

/// Apilado de piedras. Cada partida trae una bolsa de piedras de formas y
/// tamaños distintos que se suman a la torre guardada, así crece día a día.
/// Al apoyarse, la torre se balancea según qué tan centrada cayó la piedra y
/// la altura. Si queda muy corrida puede ceder: se cae un tramo de arriba que
/// depende de lo mal que quedó y de la altura, con algo de azar
/// ([StackRules]). A veces llega una ráfaga: mantener apretado la sostiene.
class StackGame extends FlameGame with TapCallbacks {
  final void Function(RunOutcome) finish;
  final BalanceSection b = Balance.instance.stack;
  late final rules = StackRules(b);
  final hud = ValueNotifier(const StackHud());

  StackGame(this.finish);

  static const _pedestalWidth = 3.4;

  final _rng = Random();
  final _streak = Streak();
  final _tower = <_Placed>[];
  final _bag = <StoneShape>[];
  final _debris = <_Loose>[];
  StoneShape? _hanging;
  _Loose? _drop;

  double _t = 0;
  double _swing = 0;
  double _camY = 0;
  bool _camReady = false;

  /// Fondo pintado: el patio desenfocado detrás de la torre.
  Image? _far;

  /// Balanceo de la torre (0 quieta; 1 o más, se cae) y su fase.
  double _wobble = 0;
  double _phase = 0;

  int _startHeight = 0, _peak = 0, _placedRun = 0, _lostRun = 0, _perfects = 0, _collapses = 0;
  bool _over = false;
  bool _holding = false;
  double _quiet = 0;
  double _pause = 0;

  // Viento: aviso -> ráfaga -> calma.
  double? _windAt;
  double _windDir = 1;
  final _leaves = <_Leaf>[];

  double get _ppm => size.x / b.d('viewWidth');
  double get _visibleH => size.y / _ppm;
  int get _height => _tower.length;

  /// Cámara con la torre vacía: el piso queda al 82% de la pantalla.
  double get _restCam => 1 - 0.32 * _visibleH;
  double get _topY => _tower.isEmpty ? 0 : _tower.last.top;

  Offset _toScreen(double x, double y) => Offset(size.x / 2 + x * _ppm, size.y / 2 + (y - _camY) * _ppm);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // La torre guardada, de abajo hacia arriba.
    for (final s in Progress.instance.tower) {
      final kind = StoneKind.values[s.kind.clamp(0, StoneKind.values.length - 1)];
      _stack(StoneShape(kind, s.w, s.h, s.tone, s.seed), s.x);
    }
    // Para probar torres altas: flutter run --dart-define=SANDORA_TOWER=500
    if (_tower.isEmpty) {
      for (var i = 0; i < _debugTower; i++) {
        _stack(randomStone(_rng), (_rng.nextDouble() - 0.5) * 0.3);
      }
    }
    _startHeight = _peak = _height;
    for (var i = 0; i < b.i('bagSize'); i++) {
      _bag.add(randomStone(_rng));
    }
    _hanging = _bag.removeLast();
    _publish();
    final far = SceneArt.instance['bg_stack_far'];
    if (far != null) {
      final w = far.width.toDouble(), h = far.height.toDouble();
      _far = await _bake([far], Rect.fromLTWH(0, 0, w, h), fadeTop: 0.15);
    } else {
      // Sin fondo propio: las capas del patio, de las montañas al ripio, desenfocadas.
      final layers = [
        for (final n in ['bg_court_sky', 'bg_court_far', 'bg_court_wall', 'bg_court_ground']) ?SceneArt.instance[n],
      ];
      if (layers.isNotEmpty) {
        final w = layers.first.width.toDouble(), h = layers.first.height.toDouble();
        _far = await _bake(layers, Rect.fromLTRB(0, h * 0.2, w, h * 0.8), blur: 4, fadeTop: 0.22);
      }
    }
  }

  /// Recorta [crop] de las capas [src] (una sobre otra) a una imagen nueva, desenfocada y con el borde de
  /// arriba desvanecido si se pide. Se hace una vez: pintarlo por cuadro cuesta.
  Future<Image> _bake(List<Image> src, Rect crop, {double blur = 0, double fadeTop = 0}) async {
    final w = crop.width.round(), h = crop.height.round();
    final dst = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
    final rec = PictureRecorder();
    final c = Canvas(rec)..saveLayer(dst, Paint());
    c.saveLayer(
      dst,
      Paint()..imageFilter = blur > 0 ? ImageFilter.blur(sigmaX: blur, sigmaY: blur, tileMode: TileMode.clamp) : null,
    );
    for (final img in src) {
      c.drawImageRect(img, crop, dst, Paint()..filterQuality = FilterQuality.medium);
    }
    c.restore();
    if (fadeTop > 0) {
      c.drawRect(
        dst,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = Gradient.linear(Offset.zero, Offset(0, h * fadeTop), [
            const Color(0x00FFFFFF),
            const Color(0xFFFFFFFF),
          ]),
      );
    }
    c.restore();
    return rec.endRecording().toImage(w, h);
  }

  /// Apoya [shape] arriba de todo con su centro en [x].
  void _stack(StoneShape shape, double x) {
    final below = _tower.isEmpty ? null : _tower.last;
    // Las piedras son redondeadas: la de arriba se hunde un poco en la curva.
    final sink = below == null ? 0.0 : 0.12 * min(below.shape.height, shape.height);
    final bottom = (below?.top ?? 0) + sink;
    final belowW = below?.shape.width ?? _pedestalWidth;
    final tilt = ((x - (below?.x ?? 0)) / belowW * 0.35).clamp(-0.2, 0.2);
    _tower.add(_Placed(shape, x, bottom - shape.height / 2, tilt));
  }

  bool get _windy => _windAt != null;
  bool get _canDrop => !_over && _drop == null && _hanging != null && !_windy && _pause <= 0;

  double get _swingSpeed =>
      b.d('swingSpeed') +
      b.d('swingSpeedPerStone') * _placedRun +
      b.d('swingSpeedPerHeight') * rules.heightFactor(_height);

  double get _hoverX => b.d('swingAmplitude') * sin(_swing);
  double get _hoverY => _topY - b.d('hoverGap') + 0.06 * sin(_t * 1.7);

  /// Corrimiento de la piedra [i] por el balanceo: la punta es la que más se
  /// mueve; la base, nada.
  double _sway(int i) {
    if (_tower.isEmpty) return 0;
    final top = -_topY;
    final h = -_tower[i].y;
    return _swayTop * pow(h / top, 2);
  }

  double get _swayTop => _wobble * b.d('swayMeters') * (1 + rules.heightFactor(_height)) * sin(_phase) + _windLean;
  double _windLean = 0;

  @override
  void onTapDown(TapDownEvent event) {
    _holding = true;
    if (!_canDrop) return;
    // Al soltarla conserva parte del impulso del balanceo: no da lo mismo cuándo.
    final vx = b.d('swingAmplitude') * _swingSpeed * cos(_swing) * b.d('releaseCarry');
    _drop = _Loose(_hanging!, _hoverX, _hoverY, vx: vx);
    _hanging = null;
  }

  @override
  void onTapUp(TapUpEvent event) => _holding = false;

  @override
  void onTapCancel(TapCancelEvent event) => _holding = false;

  @override
  void update(double dt) {
    super.update(dt);
    if (size.x == 0) return;
    _t += dt;
    _pause = max(0, _pause - dt);
    _swing += dt * _swingSpeed;
    _phase += dt * 2 * pi / (1.1 + 1.2 * rules.heightFactor(_height));
    _wobble = rules.wobbleDecay(_wobble, dt, _height);
    _windLean *= exp(-dt * 1.5);
    if (!_over) {
      _updateDrop(dt);
      _updateWind(dt);
      _maybeFinish(dt);
    }
    _updateDebris(dt);
    // La cámara sube con cada piedra: primero más despacio que la torre (así
    // se sigue viendo el piso) y, cuando la punta llega a media pantalla, a la par.
    final target = min(_restCam + 0.6 * _topY, _topY - 0.05 * _visibleH);
    _camY = _camReady ? _camY + (target - _camY) * min(1, dt * 2.5) : target;
    _camReady = true;
    for (final l in _leaves) {
      l.x += l.vx * dt;
      l.y += sin(_t * 3 + l.phase) * 30 * dt;
      l.spin += dt * 2;
    }
    _leaves.removeWhere((l) => l.x < -60 || l.x > size.x + 60);
  }

  void _updateDrop(double dt) {
    final d = _drop;
    if (d == null) return;
    d.vy += b.d('gravity') * dt;
    d.x += d.vx * dt;
    d.y += d.vy * dt;
    final below = _tower.isEmpty ? null : _tower.last;
    final belowX = below == null ? 0.0 : below.x + _sway(_height - 1);
    final belowW = below?.shape.width ?? _pedestalWidth;
    // Si ni la roza, sigue de largo: se pierde esa piedra y nada más.
    if ((d.x - belowX).abs() > belowW / 2 + d.shape.width * 0.45) {
      if (d.y > _topY + 1.5) {
        _debris.add(d..spin = d.vx.sign * 1.5);
        _drop = null;
        _next();
      }
      return;
    }
    if (d.y + d.shape.height / 2 < _topY) return;
    _drop = null;
    _land(d, below, belowX, belowW);
  }

  void _land(_Loose d, _Placed? below, double belowX, double belowW) {
    var dx = d.x - belowX;
    // Asistencia invisible en una torre recién empezada.
    if (_height < b.i('assistStones')) dx *= 1 - b.d('assistPull');
    final ratio = StackRules.offRatio(dx, belowW);
    final safe = rules.safeRatio(d.shape.kind, below?.shape.kind.stability ?? b.d('pedestalStability'), _height);
    final sev = rules.severity(ratio, safe, wobble: _wobble, lean: _lean(dx));
    final impact = d.vx.abs() + d.vy * 0.05;
    SoundBoard.instance.play(Sfx.stackPlace, volume: min(0.8, 0.3 + d.vy / 20));
    if (_rng.nextDouble() < rules.fallChance(sev)) {
      _collapse(rules.collapseLoss(_height + 1, sev, _rng), dx.sign == 0 ? 1 : dx.sign, extra: d);
      _next();
      return;
    }
    _stack(d.shape, (below?.x ?? 0) + dx);
    _placedRun++;
    _peak = max(_peak, _height);
    _wobble += rules.wobbleAdd(ratio, impact, _height);
    _phase = dx >= 0 ? 0 : pi;
    final grade = stoneGrade(dx, belowW, b);
    if (grade == Grade.perfect) _perfects++;
    final p = _toScreen(_tower.last.x, _tower.last.top);
    celebrate(world, Vector2(p.dx, p.dy), grade, streak: _streak.hit(grade));
    _maybeWind();
    _next();
  }

  /// Si las últimas piedras ya cargan hacia el lado de [dx], 0 a 1.
  double _lean(double dx) {
    if (_tower.length < 2) return 0;
    var sum = 0.0;
    final n = min(4, _tower.length - 1);
    for (var i = _tower.length - n; i < _tower.length; i++) {
      sum += (_tower[i].x - _tower[i - 1].x) / (_tower[i - 1].shape.width / 2);
    }
    return max(0, sum / n * dx.sign);
  }

  void _next() {
    _hanging = _bag.isEmpty ? null : _bag.removeLast();
    _publish();
  }

  /// Se caen [count] piedras de arriba (contando [extra], la que se soltó).
  void _collapse(int count, double dir, {_Loose? extra}) {
    _streak.miss();
    var fromTower = count - (extra == null ? 0 : 1);
    fromTower = min(fromTower, _height);
    final fallen = _tower.sublist(_height - fromTower);
    _tower.removeRange(_height - fromTower, _height);
    _lostRun += fromTower;
    // Solo se animan las de arriba (las que se ven); el resto se va sin ruido.
    final shown = fallen.reversed.take(30).toList();
    for (var i = 0; i < shown.length; i++) {
      final s = shown[i];
      final k = 1 - i / max(1, shown.length);
      _debris.add(
        _Loose(
          s.shape,
          s.x,
          s.y,
          vx: dir * (0.6 + 2.4 * k + _rng.nextDouble()),
          vy: -_rng.nextDouble() * 2,
          angle: s.tilt,
          spin: dir * (0.8 + _rng.nextDouble() * 3),
        ),
      );
    }
    if (extra != null) {
      _debris.add(extra..spin = dir * 3);
      extra.vx = dir * 2.5;
    }
    _wobble = 0.25;
    _windAt = null;
    SoundBoard.instance.stopLoop(Ambience.wind);
    // Una caída se cuenta con calma: un "toc" grave y un golpe suave (pilar 8).
    SoundBoard.instance.play(Sfx.stackFall, volume: 0.55);
    Haptics.medium();
    _pause = 1.2;
    hud.value = _hudNow(lost: count, lostAt: ++_collapses);
  }

  void _updateDebris(double dt) {
    final ground = 1.0;
    for (final d in _debris) {
      d.vy += b.d('gravity') * dt;
      d.x += d.vx * dt;
      d.y += d.vy * dt;
      d.angle += d.spin * dt;
      if (d.y + d.shape.height / 2 > ground) {
        d.y = ground - d.shape.height / 2;
        d.vy *= -0.2;
        d.vx *= 0.6;
        d.spin *= 0.5;
        d.fade -= dt * 1.2;
      }
      // Muy abajo de la cámara: ya no se ve.
      if (d.y > _camY + _visibleH) d.fade = 0;
    }
    _debris.removeWhere((d) => d.fade <= 0);
  }

  void _maybeWind() {
    if (_height < b.i('windFromHeight')) return;
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
      // La ráfaga empuja la punta; apretado, apenas.
      final push = b.d('windForce') * (_holding ? b.d('windHoldFactor') : 1) * (1 + rules.heightFactor(_height));
      _wobble += push * dt;
      _windLean += _windDir * push * dt * 0.4;
      if (_wobble >= 1) {
        final sev = 0.4 + (_wobble - 1);
        _collapse(rules.collapseLoss(_height, sev, _rng), _windDir);
      }
    } else if (e >= warn + b.d('windDuration')) {
      _windAt = null;
      SoundBoard.instance.stopLoop(Ambience.wind);
      _publish();
    }
  }

  /// Sin piedras en la bolsa y con la torre quieta, termina sola.
  void _maybeFinish(double dt) {
    final done = _hanging == null && _drop == null && _debris.isEmpty && !_windy && _wobble < 0.12;
    _quiet = done ? _quiet + dt : 0;
    if (_quiet > 0.6) endRun();
  }

  /// Termina la partida: la torre queda en el jardín como quedó.
  void endRun() {
    if (_over) return;
    _over = true;
    // Una piedra que todavía venía cayendo vuelve a la bolsa.
    _drop = null;
    _windAt = null;
    SoundBoard.instance.stopLoop(Ambience.wind);
    _publish();
    final record = _peak > Progress.instance.bestTower;
    Progress.instance.setTower([
      for (final s in _tower)
        (x: s.x, w: s.shape.width, h: s.shape.height, kind: s.shape.kind.index, tone: s.shape.tone, seed: s.shape.seed),
    ]);
    final net = _height - _startHeight;
    final stars = starsFor(max(0, net).toDouble(), b.list('starNet'));
    finish(
      RunOutcome(
        score: max(0, net) + _perfects * b.i('perfectBonus'),
        stars: stars,
        headline: [
          if (_placedRun > 0) trN('stack.added', _placedRun),
          if (_lostRun > 0) trN('stack.lost', _lostRun),
          trN('stack.height', _height),
        ].join('\n'),
        record: record,
      ),
    );
  }

  StackHud _hudNow({bool? blowing, int? lost, int? lostAt}) {
    final e = _windAt == null ? -1 : _t - _windAt!;
    return StackHud(
      height: _height,
      bag: _bag.length + (_hanging == null ? 0 : 1),
      windWarning: e >= 0 && e < b.d('windWarning'),
      windBlowing: blowing ?? (e >= b.d('windWarning')),
      over: _over,
      lost: lost ?? hud.value.lost,
      lostAt: lostAt ?? hud.value.lostAt,
    );
  }

  void _publish({bool? blowing}) => hud.value = _hudNow(blowing: blowing);

  @override
  void render(Canvas canvas) {
    _paintSky(canvas);
    _paintFar(canvas);
    final ppm = _ppm;
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2 - _camY * ppm);
    canvas.scale(ppm);
    _paintGround(canvas);
    // Solo las piedras que entran en pantalla.
    final top = _camY - _visibleH / 2 - 2, bottom = _camY + _visibleH / 2 + 2;
    for (var i = 0; i < _tower.length; i++) {
      final s = _tower[i];
      if (s.y < top || s.y > bottom) continue;
      final sway = _sway(i);
      final lean = _tower.isEmpty ? 0.0 : 2 * sway / max(1, -_tower[i].y);
      // Sombra de contacto sobre la de abajo: le da peso y volumen a la pila.
      _contact(canvas, s.x + sway, s.y + s.shape.height * 0.42, s.shape.width * 0.8, 0.32);
      _paintAt(canvas, s.shape, s.x + sway, s.y, s.tilt + lean);
    }
    for (final d in _debris) {
      _paintAt(canvas, d.shape, d.x, d.y, d.angle, opacity: d.fade);
    }
    final drop = _drop;
    if (drop != null) {
      final near = (1 - (_topY - drop.y) / b.d('hoverGap')).clamp(0.0, 1.0);
      _contact(canvas, drop.x, _topY + 0.04, drop.shape.width * (0.5 + 0.3 * near), 0.12 + 0.2 * near);
      _paintAt(canvas, drop.shape, drop.x, drop.y, 0);
    }
    final hanging = _hanging;
    if (hanging != null && !_over) {
      // Sin hilo: la piedra flota y su sombra sobre la punta ayuda a apuntar.
      final alpha = _canDrop ? 1.0 : 0.5;
      _contact(canvas, _hoverX, _topY + 0.04, hanging.width * 0.5, 0.12 * alpha);
      _paintAt(canvas, hanging, _hoverX, _hoverY, 0, opacity: alpha);
    }
    canvas.restore();
    final leaf = Paint()..color = Palette.moss;
    for (final l in _leaves) {
      canvas.save();
      canvas.translate(l.x, l.y);
      canvas.rotate(l.spin);
      canvas.drawOval(const Rect.fromLTWH(-7, -3, 14, 6), leaf);
      canvas.restore();
    }
    _paintLeaves(canvas);
    _paintVignette(canvas);
    super.render(canvas);
  }

  void _paintAt(Canvas canvas, StoneShape s, double x, double y, double angle, {double opacity = 1}) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);
    paintStone(canvas, s, opacity: opacity);
    canvas.restore();
  }

  /// Sombra suave y achatada centrada en ([x], [y]), en metros.
  void _contact(Canvas canvas, double x, double y, double width, double alpha) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: width, height: width * 0.16),
      Paint()
        ..color = Palette.ink.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.07),
    );
  }

  /// Cuánto subió la cámara desde el piso, en metros.
  double get _rise => max(0, _restCam - _camY);

  /// Cielo pintado; con la altura se va poniendo más azul y pasan nubes.
  void _paintSky(Canvas canvas) {
    final screen = Offset.zero & Size(size.x, size.y);
    final sky = SceneArt.instance['bg_base_sky'];
    if (sky != null) {
      drawArtCover(canvas, sky, screen);
    } else {
      canvas.drawRect(
        screen,
        Paint()..shader = Gradient.linear(Offset.zero, Offset(0, size.y), [Palette.skyTop, Palette.skyBottom]),
      );
    }
    final alt = (_rise / 120).clamp(0.0, 1.0);
    if (alt > 0) {
      canvas.drawRect(
        screen,
        Paint()
          ..shader = Gradient.linear(Offset.zero, Offset(0, size.y), [
            const Color(0xFF6F98B8).withValues(alpha: 0.55 * alt),
            const Color(0xFF9CC0D6).withValues(alpha: 0.3 * alt),
          ]),
      );
    }
    // Nubes desenfocadas que pasan más lento que la torre (paralaje).
    final clouds = (_rise / 8).clamp(0.0, 1.0);
    if (clouds == 0) return;
    final cloud = Paint()
      ..color = const Color(0xFFFFFBF2).withValues(alpha: 0.55 * clouds)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    const spacing = 260.0;
    final scroll = _rise * _ppm * 0.3;
    final first = ((scroll - size.y) / spacing).floor();
    for (var k = first; k < first + size.y / spacing + 3; k++) {
      final r = Random(k);
      final y = size.y - (k * spacing - scroll) - spacing;
      final x = (r.nextDouble() * 1.4 - 0.2) * size.x + sin(_t * 0.05 + k) * 20;
      final w = 110 + r.nextDouble() * 90;
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: w, height: w * 0.3), cloud);
      canvas.drawOval(Rect.fromCenter(center: Offset(x + w * 0.2, y - 12), width: w * 0.6, height: w * 0.3), cloud);
    }
  }

  /// El patio detrás de la torre, desenfocado. Baja más despacio que el piso
  /// al subir la cámara, así se lee la distancia.
  void _paintFar(Canvas canvas) {
    final far = _far;
    if (far == null) return;
    final w = size.x * 1.08, h = w * far.height / far.width;
    // El borde de abajo del recorte queda un poco por debajo de la pantalla
    // con la cámara en el piso; el ripio del cuadro hace de suelo.
    final bottom = size.y * 1.08 + _rise * _ppm * 0.3;
    if (bottom - h > size.y) return;
    drawArt(canvas, far, Rect.fromLTWH((size.x - w) / 2, bottom - h, w, h));
  }

  void _paintGround(Canvas canvas) {
    // Isla de musgo donde se apoya la base, con sombra hacia abajo a la derecha.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0.25, 1.12), width: _pedestalWidth + 2.2, height: 0.8),
      Paint()
        ..color = Palette.ink.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.18),
    );
    final art = SceneArt.instance['obj_stack_pedestal'];
    if (art != null) {
      // El arte trae la laja y el musgo; la cara de arriba está al 45% y la
      // laja ocupa el 70% del ancho.
      final side = _pedestalWidth / 0.7;
      drawArt(canvas, art, Rect.fromLTWH(-side / 2, -0.45 * side, side, side));
      return;
    }
    // Si no, la misma laja del patio: la cara de arriba al 20% del alto y el
    // 74% del ancho.
    final court = SceneArt.instance['obj_court_tower_base'];
    if (court != null) {
      final w = _pedestalWidth / 0.74, h = w * court.height / court.width;
      drawArt(canvas, court, Rect.fromLTWH(-w / 2, -0.2 * h, w, h));
      return;
    }
    canvas.drawPicture(_moss ??= _paintMoss());
    // La base: una laja ancha (el arte de la laja, si está).
    final slab = SceneArt.instance['obj_stack_stone_04'];
    const base = Rect.fromLTWH(-_pedestalWidth / 2, -0.06, _pedestalWidth, 1.06);
    _contact(canvas, 0.1, 0.98, _pedestalWidth * 1.05, 0.45);
    if (slab != null) {
      drawArt(canvas, slab, base);
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(base, const Radius.circular(0.15)), Paint()..color = Palette.stoneDark);
    }
  }

  Picture? _moss;

  /// Musgo pintado a toques: muchas manchas suaves de verdes distintos dentro
  /// de un óvalo, más oscuras abajo. Se graba una vez y se reusa.
  Picture _paintMoss() {
    final rec = PictureRecorder();
    final c = Canvas(rec);
    final rng = Random(7);
    const greens = [Color(0xFF4F6B3A), Color(0xFF6E8B5B), Color(0xFF86A060), Color(0xFF9DB473)];
    const cx = 0.0, cy = 1.0, rx = (_pedestalWidth + 1.8) / 2, ry = 0.36;
    for (var i = 0; i < 420; i++) {
      final a = rng.nextDouble() * 2 * pi, d = sqrt(rng.nextDouble());
      final x = cx + cos(a) * d * rx, y = cy + sin(a) * d * ry;
      // Abajo más oscuro, arriba a la izquierda le da la luz.
      final light = ((cy - y) / ry - (x - cx) / rx * 0.4 + 1) / 2;
      final k = (light * 3 + rng.nextDouble() * 1.2 - 0.4).clamp(0, 3).round();
      final r = 0.05 + rng.nextDouble() * 0.11;
      c.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = greens[k].withValues(alpha: 0.75)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5),
      );
    }
    return rec.endRecording();
  }

  /// Hojas desenfocadas muy cerca de la cámara: pasan más rápido que la torre.
  void _paintLeaves(Canvas canvas) {
    final fg = SceneArt.instance['fg_stack_leaves'];
    if (fg == null) return;
    final h = size.x * fg.height / fg.width;
    final y = (_rise * _ppm * 1.4) % h;
    drawArt(canvas, fg, Rect.fromLTWH(0, y - h, size.x, h));
    drawArt(canvas, fg, Rect.fromLTWH(0, y, size.x, h));
  }

  /// Bordes apenas más oscuros, como un cuadro: centra la mirada en la torre.
  void _paintVignette(Canvas canvas) {
    final c = Offset(size.x / 2, size.y * 0.45);
    canvas.drawRect(
      Offset.zero & Size(size.x, size.y),
      Paint()
        ..shader = Gradient.radial(
          c,
          size.y * 0.75,
          [const Color(0x00000000), Palette.ink.withValues(alpha: 0.22)],
          [0.55, 1],
        ),
    );
  }
}

class _Leaf {
  double x, y, spin = 0;
  final double vx, phase;
  _Leaf(this.x, this.y, this.vx, this.phase);
}
