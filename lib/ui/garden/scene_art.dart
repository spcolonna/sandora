import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Arte pintado que se dibuja dentro de los `CustomPainter` (jardín y
/// minijuegos). Se carga una vez al abrir la app, así ya está al pintar.
class SceneArt {
  SceneArt._();
  static final instance = SceneArt._();

  static const _names = [
    'obj_callig_hall',
    'obj_temple_belltower',
    'obj_temple_bell',
    'obj_temple_log',
    'bg_enso_paper',
  ];

  final _images = <String, ui.Image>{};

  Future<void> load() async {
    for (final name in _names) {
      try {
        final data = await rootBundle.load('assets/images/temple/$name.webp');
        final frame = await (await ui.instantiateImageCodec(data.buffer.asUint8List())).getNextFrame();
        _images[name] = frame.image;
      } catch (_) {
        // Sin la imagen no se dibuja esa pieza; el resto sigue igual.
      }
    }
  }

  ui.Image? operator [](String name) => _images[name];
}

/// Dibuja [img] estirado a [dst].
void drawArt(ui.Canvas canvas, ui.Image img, ui.Rect dst, {ui.Paint? paint}) {
  canvas.drawImageRect(
    img,
    ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
    dst,
    (paint ?? ui.Paint())..filterQuality = ui.FilterQuality.medium,
  );
}

/// Dibuja [img] lo más grande posible dentro de [r], sin deformarlo y apoyado
/// en su borde de abajo. Devuelve dónde quedó (o null si no hay imagen).
ui.Rect? drawArtIn(ui.Canvas canvas, ui.Image? img, ui.Rect r) {
  if (img == null) return null;
  final k = (r.width / img.width) < (r.height / img.height) ? r.width / img.width : r.height / img.height;
  final w = img.width * k, h = img.height * k;
  final dst = ui.Rect.fromLTWH(r.center.dx - w / 2, r.bottom - h, w, h);
  drawArt(canvas, img, dst);
  return dst;
}

/// Dibuja [img] cubriendo todo [r] sin deformarlo; lo que sobra a los costados
/// (o arriba y abajo) queda afuera.
void drawArtCover(ui.Canvas canvas, ui.Image img, ui.Rect r) {
  final k = (r.width / img.width) > (r.height / img.height) ? r.width / img.width : r.height / img.height;
  final w = r.width / k, h = r.height / k;
  canvas.drawImageRect(
    img,
    ui.Rect.fromLTWH((img.width - w) / 2, (img.height - h) / 2, w, h),
    r,
    ui.Paint()..filterQuality = ui.FilterQuality.medium,
  );
}
