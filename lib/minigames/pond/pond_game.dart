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
import 'pond_rules.dart';

/// Estado que muestra la capa de Flutter encima del juego.
class PondHud {
  final int moves, score, lotus;
  final bool current;
  const PondHud({this.moves = 0, this.score = 0, this.lotus = 0, this.current = false});
}

/// Pieza que se va: se achica y se apaga donde estaba.
class _Vanish {
  final Piece piece;
  final Offset at;
  double t = 0;
  _Vanish(this.piece, this.at);
}

/// Estanque de lotos: un 3 en línea sobre el agua. Se cambian dos vecinas
/// para alinear tres iguales; florecen y caen nuevas. Las cadenas valen más y
/// las líneas largas dejan especiales (ondas, flores, lunas). No hay reloj:
/// hay [moves] jugadas. Cada tanto la corriente corre una fila (avisada una
/// jugada antes): puede armar líneas sola o desarmar un plan.
class PondGame extends FlameGame with DragCallbacks, TapCallbacks {
  final void Function(RunOutcome) finish;
  final BalanceSection b = Balance.instance.section('pond');
  final hud = ValueNotifier(const PondHud());

  PondGame(this.finish);

  final _rng = Random();
  late final PondBoard _board = PondBoard(b.i('cols'), b.i('rows'), _rng);
  late int _moves = b.i('moves');
  int _made = 0, _score = 0, _lotus = 0, _cascade = 1;
  Set<int> _moved = {};

  /// Posición dibujada de cada pieza (en celdas): se acerca sola a la real.
  final _pos = <int, Offset>{};
  final _vanish = <_Vanish>[];

  /// Cambio que no armó nada: va y vuelve.
  (int, int)? _bounce;
  double _bounceT = 0;

  bool _resolving = false;
  double _wait = 0;
  int? _currentRow;
  int _currentDir = 1;
  bool _over = false;
  double _t = 0;

  int? _dragFrom;
  Vector2? _dragStart;
  int? _selected;

  double get _cell => min((size.x - 48) / _board.cols, (size.y * 0.62) / _board.rows);
  Offset get _origin => Offset((size.x - _cell * _board.cols) / 2, size.y * 0.56 - _cell * _board.rows / 2);

  Offset _screen(Offset cell) => _origin + Offset((cell.dx + 0.5) * _cell, (cell.dy + 0.5) * _cell);

  int? _cellAt(Vector2 p) {
    final local = Offset(p.x, p.y) - _origin;
    final c = (local.dx / _cell).floor(), r = (local.dy / _cell).floor();
    if (c < 0 || r < 0 || c >= _board.cols || r >= _board.rows) return null;
    return r * _board.cols + c;
  }

  Offset _home(int i) => Offset(_board.col(i).toDouble(), _board.row(i).toDouble());

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (var i = 0; i < _board.cells.length; i++) {
      // Entran cayendo desde arriba, escalonadas.
      _pos[_board.cells[i]!.id] = _home(i) - Offset(0, _board.rows + _board.col(i) * 0.3);
    }
    _publish();
  }

  bool get _settled =>
      _vanish.isEmpty &&
      _bounce == null &&
      [
        for (var i = 0; i < _board.cells.length; i++) i,
      ].every((i) => (_pos[_board.cells[i]!.id]! - _home(i)).distance < 0.02);

  bool get _canPlay => !_over && !_resolving && _settled && _moves > 0;

  // --- Entrada: arrastrar hacia una vecina, o tocar dos vecinas. ---

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!_canPlay) return;
    _dragFrom = _cellAt(event.localPosition);
    _dragStart = event.localPosition.clone();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final from = _dragFrom, start = _dragStart;
    if (from == null || start == null) return;
    final d = event.localEndPosition - start;
    if (d.length < _cell * 0.35) return;
    _dragFrom = null;
    final horizontal = d.x.abs() > d.y.abs();
    final c = _board.col(from) + (horizontal ? d.x.sign.toInt() : 0);
    final r = _board.row(from) + (horizontal ? 0 : d.y.sign.toInt());
    if (c < 0 || r < 0 || c >= _board.cols || r >= _board.rows) return;
    _selected = null;
    _try(from, r * _board.cols + c);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _dragFrom = null;
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!_canPlay) return;
    final i = _cellAt(event.localPosition);
    if (i == null) return;
    final sel = _selected;
    if (sel != null && _board.adjacent(sel, i)) {
      _selected = null;
      _try(sel, i);
    } else {
      _selected = sel == i ? null : i;
      SoundBoard.instance.play(Sfx.uiTap, volume: 0.3);
    }
  }

  void _try(int a, int c) {
    if (!_canPlay) return;
    if (_board.trySwap(a, c)) {
      _moved = {a, c};
      _cascade = 1;
      _resolving = true;
      _wait = 0.05;
    } else {
      _bounce = (a, c);
      _bounceT = 0;
      Haptics.light();
    }
  }

  // --- Resolución paso a paso, esperando que se vea cada caída. ---

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _animate(dt);
    if (!_resolving || !_settled) return;
    _wait -= dt;
    if (_wait > 0) return;
    final step = _board.step(moved: _moved, cascade: _cascade);
    _moved = {};
    if (step == null) {
      _endMove();
      return;
    }
    _show(step);
    _cascade++;
    _wait = 0.08;
  }

  void _show(PondStep step) {
    _score += step.points;
    _lotus += step.lotus;
    // Lo que se fue, donde estaba.
    for (final i in step.cleared) {
      final id = _pos.keys.firstWhere((id) => _pieceWas(id, i, step), orElse: () => -1);
      if (id >= 0) _vanish.add(_Vanish(_ghosts[id]!, _pos.remove(id)!));
    }
    for (final e in step.spawned.entries) {
      _pos[_board.cells[e.key]!.id] = _home(e.key) - Offset(0, e.value.toDouble());
    }
    for (final e in step.created.entries) {
      _pos[e.value.id] = _home(e.key);
    }
    // Una nota del agua por paso; más aguda cuanto más larga la cadena.
    SoundBoard.instance.play(Sfx.rainNote, volume: 0.45, variant: min(5, _cascade));
    final center = step.cleared.map(_home).reduce((a, b) => a + b) / step.cleared.length.toDouble();
    final at = _screen(center);
    if (_cascade >= 3 || step.created.values.any((p) => p.power == Power.moon)) {
      celebrate(world, Vector2(at.dx, at.dy), Grade.perfect);
    } else if (_cascade == 2 || step.created.isNotEmpty) {
      celebrate(world, Vector2(at.dx, at.dy), Grade.great);
    } else {
      Haptics.light();
    }
    _publish();
  }

  /// Copia de las piezas como estaban antes del paso (para dibujar las que
  /// se van). Se arma al principio de cada frame.
  final _ghosts = <int, Piece>{};
  final _ghostAt = <int, int>{};

  bool _pieceWas(int id, int cell, PondStep step) => _ghostAt[id] == cell;

  void _endMove() {
    _resolving = false;
    _moves--;
    _made++;
    final every = b.i('currentEvery');
    final row = _currentRow;
    if (row != null) {
      // La corriente: corre la fila y lo que arme se resuelve solo.
      _currentRow = null;
      _board.drift(row, _currentDir);
      for (var c = 0; c < _board.cols; c++) {
        final i = row * _board.cols + c;
        final id = _board.cells[i]!.id;
        final wrapped = _currentDir > 0 ? c == 0 : c == _board.cols - 1;
        // La que da la vuelta entra desde afuera, no cruza el estanque.
        if (wrapped) _pos[id] = _home(i) - Offset(_currentDir.toDouble(), 0);
      }
      SoundBoard.instance.play(Sfx.rainNote, volume: 0.3, variant: 1);
      if (_board.groups().isNotEmpty) {
        _cascade = 1;
        _resolving = true;
        _wait = 0.25;
        _moves++;
        _made--;
        return;
      }
    } else if (_moves > 1 && _made % every == every - 1) {
      _currentRow = _rng.nextInt(_board.rows);
      _currentDir = _rng.nextBool() ? 1 : -1;
    }
    if (!_board.hasMove()) {
      _board.shuffle();
      for (var i = 0; i < _board.cells.length; i++) {
        _pos[_board.cells[i]!.id] = _home(i) + Offset(0, -0.4);
      }
    }
    _publish();
    if (_moves <= 0) _end();
  }

  void _end() {
    if (_over) return;
    _over = true;
    final record = _score > Progress.instance.best('pond');
    Progress.instance.setBest('pond', _score);
    final stars = starsFor(_score.toDouble(), b.list('stars'));
    Future.delayed(const Duration(milliseconds: 900), () {
      finish(
        RunOutcome(
          score: _score,
          stars: stars,
          headline: '${trN('pond.bloomed', _lotus)}\n${tr('pond.points', {'n': _score})}',
          record: record,
        ),
      );
    });
  }

  void _publish() => hud.value = PondHud(moves: _moves, score: _score, lotus: _lotus, current: _currentRow != null);

  void _animate(double dt) {
    // Recordar dónde estaba cada pieza antes de resolver el próximo paso.
    _ghosts.clear();
    _ghostAt.clear();
    for (var i = 0; i < _board.cells.length; i++) {
      final p = _board.cells[i];
      if (p == null) continue;
      _ghosts[p.id] = p;
      _ghostAt[p.id] = i;
    }
    for (var i = 0; i < _board.cells.length; i++) {
      final id = _board.cells[i]!.id;
      final home = _home(i);
      final p = _pos[id] ?? home;
      final d = home - p;
      // Rápido de lejos y suave al llegar: las piezas se asientan.
      final step = (6 + 10 * d.distance) * dt;
      _pos[id] = d.distance <= step ? home : p + d / d.distance * step;
    }
    for (final v in _vanish) {
      v.t += dt / 0.28;
    }
    _vanish.removeWhere((v) => v.t >= 1);
    if (_bounce != null) {
      _bounceT += dt / 0.3;
      if (_bounceT >= 1) _bounce = null;
    }
  }

  // --- Dibujo ---

  @override
  void render(Canvas canvas) {
    final cell = _cell, o = _origin;
    final board = Rect.fromLTWH(o.dx, o.dy, cell * _board.cols, cell * _board.rows);
    _paintWater(canvas, board);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(board.inflate(4), Radius.circular(cell * 0.4)));
    final row = _currentRow;
    if (row != null) {
      // Aviso de la corriente: la fila se ondula hacia donde va a correr.
      final y = o.dy + (row + 0.5) * cell;
      final a = 0.25 + 0.15 * sin(_t * 4);
      final p = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (var k = 0; k < 5; k++) {
        final x = o.dx + ((k / 5 + _t * 0.25 * _currentDir) % 1) * board.width;
        canvas.drawPath(
          Path()
            ..moveTo(x - cell * 0.2 * _currentDir, y - cell * 0.3)
            ..lineTo(x, y)
            ..lineTo(x - cell * 0.2 * _currentDir, y + cell * 0.3),
          p,
        );
      }
    }
    for (var i = 0; i < _board.cells.length; i++) {
      final piece = _board.cells[i]!;
      var at = _pos[piece.id] ?? _home(i);
      final bounce = _bounce;
      if (bounce != null && (bounce.$1 == i || bounce.$2 == i)) {
        final other = bounce.$1 == i ? bounce.$2 : bounce.$1;
        at += (_home(other) - _home(i)) * (0.35 * sin(pi * _bounceT));
      }
      final s = _screen(at);
      if (s.dy < o.dy - cell) continue;
      final bob = sin(_t * 1.4 + i) * cell * 0.015;
      _paintPiece(canvas, piece, s + Offset(0, bob), cell * 0.42, selected: _selected == i);
    }
    for (final v in _vanish) {
      final s = _screen(v.at);
      final k = 1 - v.t;
      // Florece al irse: crece un poco y se apaga.
      _paintPiece(canvas, v.piece, s, cell * 0.42 * (1 + 0.35 * v.t), opacity: k * k);
    }
    canvas.restore();
    super.render(canvas);
  }

  void _paintWater(Canvas canvas, Rect board) {
    final pond = RRect.fromRectAndRadius(board.inflate(10), Radius.circular(_cell * 0.5));
    final water = SceneArt.instance['bg_pond_water'];
    if (water != null) {
      // El estanque pintado ocupa todo; el tablero apenas se oscurece.
      drawArtCover(canvas, water, Offset.zero & Size(size.x, size.y));
      canvas.drawRRect(pond, Paint()..color = const Color(0xFF0E2A30).withValues(alpha: 0.22));
    } else {
      canvas.drawRect(
        Offset.zero & Size(size.x, size.y),
        Paint()
          ..shader = Gradient.linear(Offset.zero, Offset(0, size.y), [
            const Color(0xFFCFE3DF),
            const Color(0xFFE8EEDC),
          ]),
      );
      canvas.drawRRect(pond.shift(const Offset(0, 6)), Paint()..color = Palette.ink.withValues(alpha: 0.08));
      canvas.drawRRect(
        pond,
        Paint()
          ..shader = Gradient.linear(board.topCenter, board.bottomCenter, [
            const Color(0xFF6FA9B0),
            const Color(0xFF3F7F8C),
          ]),
      );
    }
    // Ondas lentas sobre el agua.
    final ring = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var k = 0; k < 4; k++) {
      final r = Random(k);
      final c = Offset(board.left + r.nextDouble() * board.width, board.top + r.nextDouble() * board.height);
      final grow = (_t * 0.12 + k / 4) % 1;
      canvas.drawCircle(c, _cell * (0.4 + 1.6 * grow), ring..color = ring.color.withValues(alpha: 0.12 * (1 - grow)));
    }
  }

  void _paintPiece(Canvas canvas, Piece p, Offset c, double r, {double opacity = 1, bool selected = false}) {
    final a = opacity.clamp(0.0, 1.0);
    if (selected) {
      canvas.drawCircle(c, r * 1.15, Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.35));
    }
    if (p.power == Power.bloom || p.power == Power.moon) {
      canvas.drawCircle(
        c,
        r * 1.2,
        Paint()
          ..color = const Color(0xFFFFF3C4).withValues(alpha: 0.45 * a * (0.8 + 0.2 * sin(_t * 3)))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.3),
      );
    }
    canvas.save();
    canvas.translate(c.dx, c.dy);
    if (_paintPieceArt(canvas, p, r, a)) {
      canvas.restore();
      return;
    }
    switch (p.tile) {
      case Tile.lotus:
        _lotusFlower(canvas, r, a, open: p.power == Power.bloom);
      case Tile.pad:
        _pad(canvas, r, a);
      case Tile.stone:
        _stone(canvas, r, a);
      case Tile.koi:
        _koi(canvas, r, a);
      case Tile.drop:
        _drop(canvas, r, a);
      case null:
        _moon(canvas, r, a);
    }
    if (p.power == Power.rowWave || p.power == Power.colWave) {
      final w = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.8 * a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.09
        ..strokeCap = StrokeCap.round;
      if (p.power == Power.colWave) canvas.rotate(pi / 2);
      for (final dy in [-0.28, 0.28]) {
        canvas.drawPath(
          Path()
            ..moveTo(-r * 0.75, r * dy)
            ..quadraticBezierTo(-r * 0.37, r * (dy - 0.18), 0, r * dy)
            ..quadraticBezierTo(r * 0.37, r * (dy + 0.18), r * 0.75, r * dy),
          w,
        );
      }
    }
    canvas.restore();
  }

  /// Pieza pintada: el poder va detrás, como un halo, y la ficha encima un poco
  /// más chica para que se siga viendo de qué tipo es. Devuelve false si falta
  /// alguna imagen.
  bool _paintPieceArt(Canvas canvas, Piece p, double r, double a) {
    final art = SceneArt.instance;
    final tile = p.tile == null ? art['spr_pond_power_moon'] : art['spr_pond_tile_${p.tile!.name}'];
    if (tile == null) return false;
    final paint = Paint()..color = Color.fromRGBO(0, 0, 0, a);
    void fit(Image img, double side) {
      final k = side / max(img.width, img.height);
      final w = img.width * k, h = img.height * k;
      drawArt(
        canvas,
        img,
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        paint: paint,
      );
    }

    final halo = switch (p.power) {
      Power.rowWave || Power.colWave => art['spr_pond_power_wave'],
      Power.bloom => art['spr_pond_power_bloom'],
      _ => null,
    };
    if (halo != null) {
      canvas.save();
      if (p.power == Power.colWave) canvas.rotate(pi / 2);
      fit(halo, r * 2.4);
      canvas.restore();
    }
    fit(tile, r * (halo == null ? 2.2 : 1.6));
    return true;
  }

  void _lotusFlower(Canvas canvas, double r, double a, {bool open = false}) {
    final petal = Paint()..color = Palette.lotus.withValues(alpha: a);
    final inner = Paint()..color = const Color(0xFFF2C9D2).withValues(alpha: a);
    final n = open ? 8 : 6;
    for (var k = 0; k < n; k++) {
      canvas.save();
      canvas.rotate(2 * pi * k / n);
      canvas.drawOval(Rect.fromCenter(center: Offset(0, -r * 0.45), width: r * 0.5, height: r * 0.9), petal);
      canvas.restore();
    }
    for (var k = 0; k < 5; k++) {
      canvas.save();
      canvas.rotate(2 * pi * k / 5 + 0.3);
      canvas.drawOval(Rect.fromCenter(center: Offset(0, -r * 0.25), width: r * 0.32, height: r * 0.55), inner);
      canvas.restore();
    }
    canvas.drawCircle(Offset.zero, r * 0.18, Paint()..color = const Color(0xFFE9C46A).withValues(alpha: a));
  }

  void _pad(Canvas canvas, double r, double a) {
    final pad = Path()
      ..moveTo(0, 0)
      ..arcTo(Rect.fromCircle(center: Offset.zero, radius: r * 0.9), -pi / 2 + 0.35, 2 * pi - 0.7, false)
      ..close();
    canvas.drawPath(pad, Paint()..color = Palette.moss.withValues(alpha: a));
    final vein = Paint()
      ..color = Palette.mossDark.withValues(alpha: 0.6 * a)
      ..strokeWidth = r * 0.05;
    for (var k = 0; k < 5; k++) {
      final ang = -pi / 2 + 0.9 + k * 1.1;
      canvas.drawLine(Offset.zero, Offset(cos(ang), sin(ang)) * r * 0.75, vein);
    }
  }

  void _stone(Canvas canvas, double r, double a) {
    final rect = Rect.fromCenter(center: Offset.zero, width: r * 1.6, height: r * 1.15);
    canvas.drawOval(rect, Paint()..color = Palette.stone.withValues(alpha: a));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-r * 0.2, -r * 0.2), width: r * 0.9, height: r * 0.45),
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.25 * a),
    );
    canvas.drawOval(
      rect,
      Paint()
        ..color = Palette.stoneDark.withValues(alpha: 0.6 * a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.06,
    );
  }

  void _koi(Canvas canvas, double r, double a) {
    canvas.rotate(-0.5);
    final body = Paint()..color = const Color(0xFFF2F0EA).withValues(alpha: a);
    final orange = Paint()..color = const Color(0xFFE07A3F).withValues(alpha: a);
    canvas.drawPath(
      Path()
        ..moveTo(r * 0.55, 0)
        ..lineTo(r * 0.95, -r * 0.35)
        ..lineTo(r * 0.95, r * 0.35)
        ..close(),
      orange,
    );
    canvas.drawOval(Rect.fromCenter(center: Offset(-r * 0.1, 0), width: r * 1.4, height: r * 0.7), body);
    canvas.drawOval(Rect.fromCenter(center: Offset(-r * 0.35, -r * 0.05), width: r * 0.55, height: r * 0.45), orange);
    canvas.drawCircle(Offset(r * 0.2, r * 0.08), r * 0.16, orange);
    canvas.drawCircle(Offset(-r * 0.6, -r * 0.1), r * 0.05, Paint()..color = Palette.ink.withValues(alpha: a));
  }

  void _drop(Canvas canvas, double r, double a) {
    final path = Path()
      ..moveTo(0, -r * 0.85)
      ..cubicTo(r * 0.75, -r * 0.05, r * 0.6, r * 0.75, 0, r * 0.75)
      ..cubicTo(-r * 0.6, r * 0.75, -r * 0.75, -r * 0.05, 0, -r * 0.85);
    canvas.drawPath(path, Paint()..color = const Color(0xFF8FC9E8).withValues(alpha: a));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-r * 0.2, r * 0.15), width: r * 0.22, height: r * 0.4),
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.6 * a),
    );
  }

  void _moon(Canvas canvas, double r, double a) {
    canvas.drawCircle(Offset.zero, r * 0.8, Paint()..color = const Color(0xFFFFF6DC).withValues(alpha: a));
    canvas.drawCircle(
      Offset(r * 0.2, -r * 0.15),
      r * 0.14,
      Paint()..color = const Color(0xFFE9DFC0).withValues(alpha: a),
    );
    canvas.drawCircle(
      Offset(-r * 0.25, r * 0.25),
      r * 0.1,
      Paint()..color = const Color(0xFFE9DFC0).withValues(alpha: a),
    );
  }
}
