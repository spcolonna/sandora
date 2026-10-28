import 'dart:math';
import 'dart:typed_data';
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
  double _growT = 0;

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
      final cx = _cols * (0.25 + 0.5 * _rng.nextDouble());
      final cy = _rows * (k + 0.5) / n;
      _rocks.add(Rect.fromCenter(center: Offset(cx, cy), width: w, height: h));
    }
    for (var j = 0; j < _rows; j++) {
      for (var i = 0; i < _cols; i++) {
        final p = Offset(i + 0.5, j + 0.5);
        for (final r in _rocks) {
          final d = Offset((p.dx - r.center.dx) / (r.width / 2), (p.dy - r.center.dy) / (r.height / 2));
          // Óvalo con relieve: no son elipses perfectas.
          final wobble = 1 + 0.08 * sin(atan2(d.dy, d.dx) * 3 + r.left);
          if (d.distance < wobble) _field.rock[j * _cols + i] = 1;
        }
      }
    }
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
    if (_over) return;
    _left -= dt;
    _growT += dt;
    if (_growT > 0.25) {
      _growT = 0;
      _field.grow(_rng, b.d('growChance'));
    }
    if (_left <= 0 || _field.covered >= 0.98) _end();
  }

  void _end() {
    _over = true;
    final score = (_field.covered - _field.stained * b.d('stainWeight')).clamp(0.0, 1.0);
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

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Offset.zero & Size(size.x, size.y), Paint()..color = Palette.sand);
    final c = _cell;
    final rock = Paint()..color = Palette.stone;
    final rockDark = Paint()..color = Palette.stoneDark;
    for (final r in _rocks) {
      final rect = Rect.fromLTWH(r.left * c, _top + r.top * c, r.width * c, r.height * c);
      canvas.drawOval(rect.shift(const Offset(0, 6)), Paint()..color = Palette.ink.withValues(alpha: 0.12));
      canvas.drawOval(rect.inflate(2), rockDark);
      canvas.drawOval(rect, rock);
      // Motas para que se lea como piedra.
      final rng = Random(r.left.round());
      final speck = Paint()..color = Palette.stoneDark.withValues(alpha: 0.35);
      for (var k = 0; k < 30; k++) {
        final a = rng.nextDouble() * 2 * pi, d = sqrt(rng.nextDouble()) * 0.9;
        canvas.drawCircle(
          rect.center + Offset(cos(a) * d * rect.width / 2, sin(a) * d * rect.height / 2),
          1.5 + rng.nextDouble() * 2,
          speck,
        );
      }
    }
    // Musgo y manchas, celda por celda (como puntitos superpuestos).
    final moss = Paint();
    for (var j = 0; j < _rows; j++) {
      for (var i = 0; i < _cols; i++) {
        final k = j * _cols + i;
        final m = _field.moss[k];
        if (m < 0.05) continue;
        final onRock = _field.rock[k] == 1;
        moss.color = (onRock ? const Color(0xFF7FA35A) : const Color(0xFF9C8B63)).withValues(
          alpha: min(1, m) * (onRock ? 1 : 0.7),
        );
        final jitter = sin(k * 12.9898) * 0.25;
        canvas.drawCircle(Offset((i + 0.5 + jitter) * c, _top + (j + 0.5 - jitter) * c), c * (0.55 + 0.25 * m), moss);
      }
    }
    // Tiempo: una barra fina arriba.
    final k = (_left / b.d('seconds')).clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(24, size.y * 0.1, (size.x - 48) * k, 6), const Radius.circular(3)),
      Paint()..color = Palette.moss,
    );
    super.render(canvas);
  }
}
