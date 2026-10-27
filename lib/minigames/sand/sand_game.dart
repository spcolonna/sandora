import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight, TextPainter, TextSpan, TextAlign;

import '../../balance/balance.dart';
import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../../ui/fx/sfx.dart';
import '../../ui/theme/palette.dart';
import '../common/grade.dart';
import '../common/minigame_screen.dart';
import 'sand_painter.dart';
import 'sand_shapes.dart';

enum _Phase { draw, rake, done }

/// Arenero: se recorre una figura guía sin levantar el dedo; después un
/// rastrillo pasa por el trazo del jugador (no por la guía) y deja surcos.
/// El dibujo queda en el jardín hasta el próximo.
class SandGame extends FlameGame with DragCallbacks {
  final void Function(RunOutcome) finish;
  final BalanceSection b = Balance.instance.sand;

  SandGame(this.finish);

  late final SandShape shape;
  late final List<P> guide;
  late final SandScorer scorer;

  final strokes = <List<P>>[];
  P? _smoothed;
  _Phase _phase = _Phase.draw;
  double _t = 0;
  double _rakeT = 0;
  double _guideAlpha = 1;
  SandScore? _score;
  Picture? _sandTexture;
  Vector2? _textureSize;

  @override
  Color backgroundColor() => Palette.sand;

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    final done = Progress.instance.sandFigures;
    shape = SandShape.values[done % SandShape.values.length];
    guide = shapePoints(shape);
    final tol = done < b.i('hardAfterFigures') ? b.d('toleranceEasy') : b.d('toleranceHard');
    scorer = SandScorer(b, guide, tol);
  }

  /// Cuadro de dibujo en pantalla.
  Rect get box {
    final side = min(size.x * 0.9, size.y * 0.62);
    return Rect.fromCenter(center: Offset(size.x / 2, size.y * 0.48), width: side, height: side);
  }

  P _toBox(Vector2 v) => (x: (v.x - box.left) / box.width, y: (v.y - box.top) / box.height);

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_phase != _Phase.draw) return;
    final p = _toBox(event.canvasPosition);
    _smoothed = p;
    strokes.add([p]);
    SoundBoard.instance.loop(Ambience.rake, volume: 0.4, fade: const Duration(milliseconds: 150));
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_phase != _Phase.draw || _smoothed == null) return;
    final raw = _toBox(event.canvasEndPosition);
    // Suavizado en tiempo real (asistencia invisible).
    final k = b.d('smoothing');
    final s = (x: _smoothed!.x * k + raw.x * (1 - k), y: _smoothed!.y * k + raw.y * (1 - k));
    _smoothed = s;
    strokes.last.add(s);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    SoundBoard.instance.stopLoop(Ambience.rake, fade: const Duration(milliseconds: 300));
    _smoothed = null;
    if (_phase == _Phase.draw && scorer.coverage(strokes) >= b.d('finishCoverage')) _startRake();
  }

  void _startRake() {
    _phase = _Phase.rake;
    _score = scorer.score(strokes);
    // El rastrillo pasa por una versión más suave del trazo: el jugador ve su
    // dibujo, pero más prolijo (asistencia invisible).
    for (var i = 0; i < strokes.length; i++) {
      strokes[i] = chaikin(resample(strokes[i], 0.015), iterations: 3);
    }
    SoundBoard.instance.loop(Ambience.rake, volume: 0.3, fade: const Duration(milliseconds: 400));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_phase == _Phase.draw && _t > b.d('timeLimit') && _smoothed == null) {
      if (strokes.isEmpty) strokes.add([]);
      _startRake();
    }
    if (_phase == _Phase.rake) {
      _guideAlpha = max(0, _guideAlpha - dt * 2);
      _rakeT += dt / b.d('rakeSeconds');
      if (_rakeT >= 1) {
        _rakeT = 1;
        _phase = _Phase.done;
        SoundBoard.instance.stopLoop(Ambience.rake);
        _end();
      }
    }
  }

  void _end() {
    final s = _score!;
    if (s.stars > 0) {
      celebrate(world, Vector2(size.x / 2, box.top - 10), Grade.values[s.stars - 1]);
    }
    final flat = [
      for (final st in strokes)
        for (final p in resample(st, 0.012)) ...[p.x, p.y],
    ];
    Progress.instance.setSandDrawing(flat);
    Future.delayed(const Duration(milliseconds: 1300), () {
      finish(RunOutcome(score: (s.total * 1000).round(), stars: s.stars, headline: tr('sand.shape.${shape.name}')));
    });
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    if (_sandTexture == null || _textureSize != size) {
      _textureSize = size.clone();
      _sandTexture = sandTexture(rect.size);
    }
    canvas.drawPicture(_sandTexture!);
    final r = box;
    // Guía tenue.
    if (_guideAlpha > 0) {
      final path = pathOf(guide, r);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r.width * scorer.tolerance * 0.9
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = Palette.sandLight.withValues(alpha: 0.55 * _guideAlpha),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Palette.ink.withValues(alpha: 0.25 * _guideAlpha),
      );
      if (strokes.isEmpty) {
        final s = guide.first;
        final pulse = 10 + 4 * sin(_t * 5);
        canvas.drawCircle(
          Offset(r.left + s.x * r.width, r.top + s.y * r.height),
          pulse,
          Paint()..color = Palette.moss.withValues(alpha: 0.8 * _guideAlpha),
        );
      }
    }
    if (_phase == _Phase.draw) {
      for (final st in strokes) {
        canvas.drawPath(
          pathOf(st, r),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = Palette.sandShadow.withValues(alpha: 0.6),
        );
      }
      _hint(canvas, tr('sand.hint'));
    } else {
      final head = drawGrooves(canvas, strokes, r, _rakeT);
      if (head != null && _phase == _Phase.rake) drawRake(canvas, head.$1, head.$2);
    }
    super.render(canvas);
  }

  void _hint(Canvas canvas, String s) {
    final tp = TextPainter(
      text: TextSpan(
        text: '${tr('sand.shape.${shape.name}')}\n$s',
        style: const TextStyle(color: Palette.ink, fontSize: 17, fontWeight: FontWeight.w500, height: 1.4),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.x - 48);
    tp.paint(canvas, Offset((size.x - tp.width) / 2, box.bottom + 24));
  }
}
