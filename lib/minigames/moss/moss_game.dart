import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle, FontWeight, TextDirection;

import '../../balance/balance.dart';
import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../../ui/fx/sfx.dart';
import '../../ui/garden/scene_art.dart';
import '../../ui/theme/palette.dart';
import '../common/grade.dart';
import '../common/minigame_screen.dart';

/// Grilla del musgo: qué celdas son piedra y cuáles tienen musgo. En Dart
/// puro para poder probarla.
class MossField {
  final int cols, rows;
  final Uint8List rock; // 1 piedra, 0 arena
  final Float32List moss; // 0..1
  MossField(this.cols, this.rows) : rock = Uint8List(cols * rows), moss = Float32List(cols * rows);

  int get rockCells => rock.where((r) => r == 1).length;

  /// Pinta con un pincel de radio [r] (en celdas) en ([x], [y]). Si el centro
  /// está sobre piedra, el pincel se ajusta al borde y no mancha la arena
  /// (asistencia invisible); si está sobre arena, mancha.
  void paint(double x, double y, double r, double amount) {
    final cx = x.floor(), cy = y.floor();
    final onRock = _in(cx, cy) && rock[cy * cols + cx] == 1;
    for (var j = (y - r).floor(); j <= (y + r).ceil(); j++) {
      for (var i = (x - r).floor(); i <= (x + r).ceil(); i++) {
        if (!_in(i, j)) continue;
        final d = sqrt(pow(i + 0.5 - x, 2) + pow(j + 0.5 - y, 2));
        if (d > r) continue;
        final k = j * cols + i;
        if (onRock && rock[k] == 0) continue;
        moss[k] = min(1, moss[k] + amount * (1 - d / r * 0.5));
      }
    }
  }

  bool _in(int i, int j) => i >= 0 && j >= 0 && i < cols && j < rows;

  /// El musgo crece solo hacia las vecinas de piedra, con azar.
  void grow(Random rng, double chance) {
    for (var k = 0; k < moss.length; k++) {
      if (moss[k] < 0.6 || rng.nextDouble() > chance) continue;
      final i = k % cols, j = k ~/ cols;
      final (di, dj) = [(1, 0), (-1, 0), (0, 1), (0, -1)][rng.nextInt(4)];
      final n = (j + dj) * cols + (i + di);
      if (_in(i + di, j + dj) && rock[n] == 1) moss[n] = min(1, moss[n] + 0.5);
    }
  }

  /// Fracción de piedra cubierta.
  double get covered {
    var s = 0.0;
    for (var k = 0; k < moss.length; k++) {
      if (rock[k] == 1) s += moss[k] >= 0.5 ? 1 : 0;
    }
    return s / max(1, rockCells);
  }

  /// Arena manchada, como fracción de la piedra (para que pese igual).
  double get stained {
    var s = 0.0;
    for (var k = 0; k < moss.length; k++) {
      if (rock[k] == 0 && moss[k] >= 0.3) s++;
    }
    return s / max(1, rockCells);
  }
}

/// Musgo: se pinta musgo sobre las piedras con el dedo sin manchar la arena.
/// El musgo además crece solo, a su manera. Puntaje: lo cubierto menos lo
/// manchado. Lo pintado queda en las piedras del jardín.
class MossGame extends FlameGame with DragCallbacks {
  final void Function(RunOutcome) finish;
  final BalanceSection b = Balance.instance.section('moss');
  MossGame(this.finish);

  final _rng = Random();
  late final MossField _field;
  late double _left = b.d('seconds');
  bool _over = false;
  Offset? _last;
  final _rocks = <Rect>[];
  final _rockPaths = <Path>[];
  double _growT = 0;

  /// Lo que se ve de cada celda: se acerca al musgo real, así crece de a poco.
  late Float32List _shown;

  /// Para no recalcular la cobertura en cada cuadro.
  double _covered = 0;
  late final _milestones = StarMilestones(b.list('stars'));
  bool _onSand = false;

  static const _cols = 48;
  double get _cell => size.x / _cols;
  int get _rows => (size.y * 0.7 / _cell).floor();
  double get _top => size.y * 0.18;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _field = MossField(_cols, _rows);
    // Dos o tres piedras con formas distintas cada vez.
    final n = 2 + _rng.nextInt(2);
    for (var k = 0; k < n; k++) {
      final w = _cols * (0.3 + _rng.nextDouble() * 0.25);
      final h = _rows * (0.18 + _rng.nextDouble() * 0.14);
      final cx = w * 0.54 + 1 + (_cols - w * 1.08 - 2) * _rng.nextDouble();
      final cy = _rows * (k + 0.5) / n;
      _rocks.add(Rect.fromCenter(center: Offset(cx, cy), width: w, height: h));
    }
    for (var j = 0; j < _rows; j++) {
      for (var i = 0; i < _cols; i++) {
        final p = Offset(i + 0.5, j + 0.5);
        for (final r in _rocks) {
          final d = Offset((p.dx - r.center.dx) / (r.width / 2), (p.dy - r.center.dy) / (r.height / 2));
          if (d.distance < _wobble(r, atan2(d.dy, d.dx))) _field.rock[j * _cols + i] = 1;
        }
      }
    }
    _shown = Float32List(_field.moss.length);
  }

  /// Borde de la piedra: un óvalo con relieve, no una elipse perfecta. El
  /// dibujo y la grilla usan el mismo, así lo que se ve es lo que cuenta.
  static double _wobble(Rect r, double a) => 1 + 0.08 * sin(a * 3 + r.left);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _rockPaths.clear();
  }

  Path _rockPath(Rect r) {
    final c = _cell;
    final center = Offset(r.center.dx * c, _top + r.center.dy * c);
    final path = Path();
    for (var k = 0; k <= 64; k++) {
      final a = 2 * pi * k / 64;
      final w = _wobble(r, a);
      final p = center + Offset(cos(a) * r.width / 2 * c * w, sin(a) * r.height / 2 * c * w);
      k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  Offset _toField(Vector2 p) => Offset(p.x / _cell, (p.y - _top) / _cell);

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_over) return;
    _last = _toField(event.localPosition);
    _brush(_last!);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final from = _last;
    if (from == null || _over) return;
    final to = _toField(event.localEndPosition);
    final steps = max(1, ((to - from).distance / 0.6).ceil());
    for (var s = 1; s <= steps; s++) {
      _brush(Offset.lerp(from, to, s / steps)!);
    }
    _last = to;
  }

  void _brush(Offset p) {
    // El pincel varía un poco: el musgo no se pinta parejo.
    final r = b.d('brush') * (0.85 + 0.3 * _rng.nextDouble());
    // Se siente cuando el pincel sale de la piedra.
    final i = p.dx.floor(), j = p.dy.floor();
    final onSand = i >= 0 && j >= 0 && i < _cols && j < _rows && _field.rock[j * _cols + i] == 0;
    if (onSand && !_onSand) Haptics.light();
    _onSand = onSand;
    _field.paint(p.dx, p.dy, r, b.d('amount') * (0.7 + 0.6 * _rng.nextDouble()));
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _last = null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final k = min(1.0, dt * 7);
    for (var i = 0; i < _shown.length; i++) {
      _shown[i] += (_field.moss[i] - _shown[i]) * k;
    }
    if (_over) return;
    _left -= dt;
    _growT += dt;
    if (_growT > 0.25) {
      _growT = 0;
      _field.grow(_rng, b.d('growChance'));
      _covered = _field.covered;
      // Cada estrella se festeja cuando se gana, no recién al final.
      _milestones.update(_score, world, Vector2(size.x / 2, size.y * 0.3));
    }
    if (_left <= 0 || _covered >= 0.98) _end();
  }

  double get _score => (_field.covered - _field.stained * b.d('stainWeight')).clamp(0.0, 1.0);

  void _end() {
    _over = true;
    final score = _score;
    final pct = (score * 100).round();
    final record = pct > Progress.instance.best('moss');
    Progress.instance.setBest('moss', pct);
    final stars = starsFor(score, b.list('stars'));
    if (stars > 0) celebrate(world, Vector2(size.x / 2, size.y * 0.4), Grade.values[stars - 1]);
    SoundBoard.instance.play(Sfx.good, volume: 0.4);
    Future.delayed(const Duration(milliseconds: 700), () {
      finish(
        RunOutcome(
          score: pct,
          stars: stars,
          headline: tr('moss.result', {'n': (_field.covered * 100).round(), 'stain': (_field.stained * 100).round()}),
          record: record,
        ),
      );
    });
  }

  static const _levels = 6, _tones = 3;
  static const _mossLight = [Color(0xFFA6C474), Color(0xFF9DBF6E), Color(0xFFB4C97A)];
  static const _mossDark = [Color(0xFF5E8A3E), Color(0xFF4F7A36), Color(0xFF6E9446)];

  /// Un número fijo entre 0 y 1 por celda.
  static double _hash(int k) {
    final x = sin(k * 12.9898) * 43758.5453;
    return x - x.floorToDouble();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Offset.zero & Size(size.x, size.y), Paint()..color = Palette.sand);
    final c = _cell;
    if (_rockPaths.isEmpty) _rockPaths.addAll(_rocks.map(_rockPath));
    for (var n = 0; n < _rocks.length; n++) {
      final r = _rocks[n], path = _rockPaths[n];
      final rect = Rect.fromLTWH(r.left * c, _top + r.top * c, r.width * c, r.height * c);
      canvas.drawPath(path.shift(const Offset(0, 6)), Paint()..color = Palette.ink.withValues(alpha: 0.12));
      canvas.drawPath(
        path,
        Paint()
          ..color = Palette.stoneDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      final art = SceneArt.instance['obj_moss_rock'];
      if (art != null) {
        // La piedra pintada, recortada a la forma de la grilla: se toma el
        // centro del arte (los bordes son transparentes).
        canvas.save();
        canvas.clipPath(path);
        final iw = art.width.toDouble(), ih = art.height.toDouble();
        canvas.drawImageRect(
          art,
          Rect.fromLTRB(iw * 0.1, ih * 0.14, iw * 0.9, ih * 0.86),
          rect.inflate(c),
          Paint()..filterQuality = FilterQuality.medium,
        );
        canvas.restore();
        continue;
      }
      canvas.drawPath(
        path,
        Paint()
          ..shader = Gradient.radial(rect.center - Offset(rect.width * 0.15, rect.height * 0.2), rect.width * 0.7, [
            const Color(0xFFA9A397),
            Palette.stone,
          ]),
      );
      // Motas para que se lea como piedra.
      final rng = Random(r.left.round());
      final speck = Paint()..color = Palette.stoneDark.withValues(alpha: 0.35);
      for (var k = 0; k < 30; k++) {
        final a = rng.nextDouble() * 2 * pi, d = sqrt(rng.nextDouble()) * 0.85;
        canvas.drawCircle(
          rect.center + Offset(cos(a) * d * rect.width / 2, sin(a) * d * rect.height / 2),
          1.5 + rng.nextDouble() * 2,
          speck,
        );
      }
    }
    // Musgo y manchas como puntitos superpuestos, agrupados por intensidad y
    // tono (pocas llamadas de dibujo aunque haya miles de celdas). Cada celda
    // tiene su tono y su corrimiento fijos, así el musgo se ve moteado.
    final buckets = [for (var i = 0; i < _levels * (_tones + 1); i++) <double>[]];
    for (var j = 0; j < _rows; j++) {
      for (var i = 0; i < _cols; i++) {
        final k = j * _cols + i;
        final m = _shown[k];
        if (m < 0.05) continue;
        final level = min(_levels - 1, (m * _levels).floor());
        final h1 = _hash(k), h2 = _hash(k + 7919);
        final group = _field.rock[k] == 1 ? (h1 * _tones).floor() % _tones : _tones;
        buckets[group * _levels + level]
          ..add((i + 0.5 + (h2 - 0.5) * 0.9) * c)
          ..add(_top + (j + 0.5 + (h1 - 0.5) * 0.9) * c);
      }
    }
    // Con la textura, el musgo sobre piedra toma su color de ella.
    final tex = SceneArt.instance['tex_moss'];
    final texShader = tex == null
        ? null
        : ImageShader(
            tex,
            TileMode.repeated,
            TileMode.repeated,
            Float64List.fromList([0.5, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
          );
    for (var n = 0; n < buckets.length; n++) {
      if (buckets[n].isEmpty) continue;
      final group = n ~/ _levels;
      final m = (n % _levels + 1) / _levels;
      final onRock = group < _tones;
      final color = onRock
          ? Color.lerp(_mossLight[group], _mossDark[group], m)!.withValues(alpha: min(1, 0.35 + m))
          : const Color(0xFF9C8B63).withValues(alpha: 0.35 * m);
      canvas.drawRawPoints(
        PointMode.points,
        Float32List.fromList(buckets[n]),
        Paint()
          ..color = onRock && texShader != null ? const Color(0xFFFFFFFF).withValues(alpha: min(1, 0.45 + m)) : color
          ..shader = onRock ? texShader : null
          ..strokeWidth = c * (onRock ? 1.1 + 0.5 * m : 1.0)
          ..strokeCap = StrokeCap.round,
      );
    }
    // Tiempo: una barra fina arriba, y cuánto va cubierto.
    final k = (_left / b.d('seconds')).clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(24, size.y * 0.1, (size.x - 110) * k, 6), const Radius.circular(3)),
      Paint()..color = Palette.moss,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: tr('moss.covered', {'n': (_covered * 100).round()}),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Palette.mossDark),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.x - tp.width) / 2, size.y * 0.1 + 14));
    super.render(canvas);
  }
}
