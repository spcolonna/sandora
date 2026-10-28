import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight, TextPainter, TextSpan, TextAlign;

import '../../balance/balance.dart';
import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../../ui/fx/sfx.dart';
import '../../ui/garden/scene_art.dart';
import '../../ui/theme/palette.dart';
import '../common/grade.dart';
import '../common/minigame_screen.dart';
import 'enso_ink.dart';
import 'enso_scorer.dart';

/// Ensō (Sala de caligrafía): un círculo de un solo trazo con el pincel. El
/// ancho de la tinta sigue la velocidad del dedo: despacio carga más tinta,
/// rápido la afina, y al final del trazo el pincel se seca.
class EnsoGame extends FlameGame with DragCallbacks {
  final void Function(RunOutcome) finish;
  final BalanceSection b = Balance.instance.section('enso');
  EnsoGame(this.finish);

  final _stroke = <InkPoint>[];

  /// Ancho del pincel en cada punto del trazo (suavizado).
  final _widths = <double>[];
  double _t = 0;
  bool _drawing = false, _over = false;
  EnsoResult? _result;

  /// Aviso cuando un trazo no alcanzó (muy chico o muy corto).
  double _retryAt = -10;

  @override
  Color backgroundColor() => const Color(0xFFF1E8D4);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_over) return;
    _stroke.clear();
    _widths.clear();
    _drawing = true;
    _add(Offset(event.localPosition.x, event.localPosition.y));
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_drawing) return;
    _add(Offset(event.localEndPosition.x, event.localEndPosition.y));
  }

  void _add(Offset at) {
    final maxW = size.x * 0.055, minW = size.x * 0.012;
    var w = maxW;
    if (_stroke.isNotEmpty) {
      final last = _stroke.last;
      final dt = max(0.008, _t - last.t);
      final speed = (at - last.at).distance / dt / size.x; // anchos por segundo
      final target = maxW - (maxW - minW) * (speed / 2.2).clamp(0.0, 1.0);
      w = _widths.last + (target - _widths.last) * 0.25;
    }
    _stroke.add((at: at, t: _t));
    _widths.add(w);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_drawing) return;
    _drawing = false;
    final r = scoreEnso(_stroke, size.x, b);
    if (r.tooSmall || r.sweep < 0.4) {
      // No cuenta: se borra despacio y se puede volver a intentar.
      _retryAt = _t;
      _stroke.clear();
      _widths.clear();
      SoundBoard.instance.play(Sfx.uiTap, volume: 0.3);
      return;
    }
    _end(r);
  }

  void _end(EnsoResult r) {
    _over = true;
    _result = r;
    final pct = (r.total * 100).round();
    final record = pct > Progress.instance.best('enso');
    if (Progress.instance.setBest('enso', pct)) {
      // El mejor ensō queda colgado en el pabellón del jardín.
      Progress.instance.setEnsoInk(SavedInk.fromStroke([for (final p in _stroke) p.at], _widths).toFlat());
    }
    final stars = starsFor(r.total, b.list('stars'));
    final c = _stroke.map((p) => p.at).reduce((a, p) => a + p) / _stroke.length.toDouble();
    if (stars > 0) celebrate(world, Vector2(c.dx, c.dy), Grade.values[stars - 1]);
    Future.delayed(const Duration(milliseconds: 1600), () {
      finish(RunOutcome(score: pct, stars: stars, headline: tr('enso.result', {'n': pct}), record: record));
    });
  }

  @override
  void render(Canvas canvas) {
    _paper(canvas);
    _ink(canvas);
    super.render(canvas);
    final r = _result;
    if (r != null) {
      _text(
        canvas,
        tr('enso.parts', {
          'round': (r.roundness * 100).round(),
          'close': (r.closure * 100).round(),
          'flow': (r.fluency * 100).round(),
        }),
        Offset(size.x / 2, size.y * 0.86),
        15,
      );
    } else if (_t - _retryAt < 2.5) {
      _text(canvas, tr('enso.retry'), Offset(size.x / 2, size.y * 0.86), 16);
    } else if (_stroke.isEmpty) {
      _text(canvas, tr('enso.hint'), Offset(size.x / 2, size.y * 0.86), 16);
    }
  }

  /// Papel washi y un sello rojo en la esquina.
  void _paper(Canvas canvas) {
    final paper = SceneArt.instance['bg_enso_paper'];
    if (paper != null) drawArtCover(canvas, paper, Rect.fromLTWH(0, 0, size.x, size.y));
    final seal = Rect.fromLTWH(size.x - 62, size.y * 0.7, 30, 30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(seal, const Radius.circular(4)),
      Paint()..color = const Color(0xFFB0413E).withValues(alpha: 0.8),
    );
  }

  void _ink(Canvas canvas) => paintEnsoInk(canvas, [for (final p in _stroke) p.at], _widths);

  void _text(Canvas canvas, String s, Offset center, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(color: Palette.ink.withValues(alpha: 0.8), fontSize: fontSize, fontWeight: FontWeight.w600),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.x - 48);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }
}
