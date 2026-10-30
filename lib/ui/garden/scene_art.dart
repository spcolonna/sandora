import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Arte pintado que se dibuja dentro de los `CustomPainter` (jardín y
/// minijuegos). Se carga una vez al abrir la app, así ya está al pintar.
class SceneArt {
  SceneArt._();
  static final instance = SceneArt._();

  /// Carpeta de `assets/images/` de cada imagen.
  static const _names = {
    'obj_callig_hall': 'temple',
    'obj_temple_belltower': 'temple',
    'obj_temple_bell': 'temple',
    'obj_temple_log': 'temple',
    'bg_enso_paper': 'temple',
    'bg_base_sky': 'bg',
    'bg_base_far': 'bg',
    'bg_base_ground': 'bg',
    'bg_base_foliage': 'bg',
    // Patio pintado: por ahora un solo cuadro; después, en capas.
    'bg_court_ref': 'court',
    'bg_rain_roof': 'rain',
    'obj_rain_vessel_01': 'rain',
    'obj_rain_vessel_02': 'rain',
    'obj_rain_vessel_03': 'rain',
    'obj_rain_vessel_04': 'rain',
    'obj_rain_vessel_05': 'rain',
    'fx_rain_drop': 'rain',
    'fx_rain_splash': 'rain',
    'obj_stack_stone_01': 'stack',
    'obj_stack_stone_02': 'stack',
    'obj_stack_stone_03': 'stack',
    'obj_stack_stone_04': 'stack',
    'obj_stack_stone_05': 'stack',
    'obj_stack_stone_06': 'stack',
    'spr_sand_rake_01': 'sand',
    'tex_sand_base': 'sand',
    // Decoraciones (`garden_decor.dart`): mientras falte alguna, se pinta con código.
    'obj_decor_step': 'decor',
    'obj_decor_rocks': 'decor',
    'obj_decor_moss': 'decor',
    'obj_decor_boulder': 'decor',
    'obj_decor_azalea': 'decor',
    'obj_decor_peak': 'decor',
    'obj_decor_bamboo': 'decor',
    'obj_decor_lantern': 'decor',
    'obj_decor_basin': 'decor',
    'obj_decor_bench': 'decor',
    'obj_decor_jizo': 'decor',
    'obj_decor_pine': 'decor',
    'obj_decor_bridge': 'decor',
    'obj_decor_pagoda': 'decor',
    'obj_decor_maple': 'decor',
    'obj_decor_sakura': 'decor',
  };

  final _images = <String, ui.Image>{};

  Future<void> load() async {
    for (final MapEntry(key: name, value: folder) in _names.entries) {
      try {
        final data = await rootBundle.load('assets/images/$folder/$name.webp');
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
void drawArtCover(ui.Canvas canvas, ui.Image img, ui.Rect r, {ui.Paint? paint}) {
  final k = (r.width / img.width) > (r.height / img.height) ? r.width / img.width : r.height / img.height;
  final w = r.width / k, h = r.height / k;
  canvas.drawImageRect(
    img,
    ui.Rect.fromLTWH((img.width - w) / 2, (img.height - h) / 2, w, h),
    r,
    (paint ?? ui.Paint())..filterQuality = ui.FilterQuality.medium,
  );
}
