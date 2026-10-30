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
    // Patio pintado: capas del mismo lienzo y objetos apoyados en el suelo.
    'bg_court_sky': 'court',
    'bg_court_far': 'court',
    'bg_court_wall': 'court',
    'bg_court_ground': 'court',
    'bg_court_side_left': 'court',
    'bg_court_side_right': 'court',
    'obj_court_tower_base': 'court',
    'obj_court_board': 'court',
    'obj_court_deck': 'court',
    'obj_court_jars': 'court',
    'obj_court_lantern_tall': 'court',
    'obj_court_lantern_small': 'court',
    'obj_court_rock': 'court',
    'obj_court_rake': 'court',
    'fg_court_doorway': 'court',
    'bg_rain_roof': 'rain',
    'obj_rain_vessel_01': 'rain',
    'obj_rain_vessel_02': 'rain',
    'obj_rain_vessel_03': 'rain',
    'obj_rain_vessel_04': 'rain',
    'obj_rain_vessel_05': 'rain',
    'fx_rain_drop': 'rain',
    'fx_rain_splash': 'rain',
    'char_meditator': 'rain',
    'obj_stack_stone_01': 'stack',
    'obj_stack_stone_02': 'stack',
    'obj_stack_stone_03': 'stack',
    'obj_stack_stone_04': 'stack',
    'obj_stack_stone_05': 'stack',
    'obj_stack_stone_06': 'stack',
    'bg_stack_far': 'stack',
    'obj_stack_pedestal': 'stack',
    'fg_stack_leaves': 'stack',
    // Minijuegos de la vista del estanque.
    'obj_shishi_bamboo': 'east',
    'obj_shishi_basin': 'east',
    'spr_leaf_01': 'east',
    'spr_leaf_02': 'east',
    'spr_leaf_03': 'east',
    'spr_leaf_04': 'east',
    'tex_moss': 'east',
    'obj_moss_rock': 'east',
    'obj_bonsai_pot': 'east',
    'obj_bonsai_trunk': 'east',
    // Estanque de lotos (3 en línea).
    'bg_pond_water': 'pond',
    'spr_pond_tile_lotus': 'pond',
    'spr_pond_tile_pad': 'pond',
    'spr_pond_tile_stone': 'pond',
    'spr_pond_tile_koi': 'pond',
    'spr_pond_tile_drop': 'pond',
    'spr_pond_power_wave': 'pond',
    'spr_pond_power_bloom': 'pond',
    'spr_pond_power_moon': 'pond',
    // Vista del bosque.
    'obj_tea_house': 'forest',
    'obj_bamboo_grove': 'forest',
    'obj_tea_bowl': 'forest',
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
  final dst = artRectIn(img, r);
  drawArt(canvas, img, dst);
  return dst;
}

/// Dónde queda [img] al dibujarlo con [drawArtIn] en [r].
ui.Rect artRectIn(ui.Image img, ui.Rect r) {
  final k = (r.width / img.width) < (r.height / img.height) ? r.width / img.width : r.height / img.height;
  final w = img.width * k, h = img.height * k;
  return ui.Rect.fromLTWH(r.center.dx - w / 2, r.bottom - h, w, h);
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
