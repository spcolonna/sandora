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
    // Kit de interfaz pintado (nine-slice, en `washi.dart`).
    'ui_panel': 'ui',
    'ui_result': 'ui',
    'ui_button': 'ui',
    'ui_score_frame': 'ui',
    'ui_serenity_bar': 'ui',
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
    // Premios de la racha de meditación, sobre la tarima.
    'obj_court_zafu': 'court',
    'obj_court_singing_bowl': 'court',
    'obj_court_paper_lantern': 'court',
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
    'obj_bonsai_foliage': 'east',
    'obj_bonsai_table': 'east',
    // Fondos pintados de los minijuegos (de borde a borde, el juego dibuja encima).
    'bg_leaves': 'east',
    'bg_bonsai': 'east',
    'bg_shishi': 'east',
    'bg_moss': 'east',
    'bg_bell': 'temple',
    'bg_matcha': 'forest',
    'bg_flute': 'forest',
    // Suelos de las vistas del estanque y del bosque, y el río.
    'bg_east_ground': 'east',
    'bg_forest_ground': 'forest',
    'bg_forest_river': 'forest',
    // Piezas chicas del jardín.
    'obj_care_weeds': 'court',
    'obj_care_leaves': 'court',
    'obj_tea_gift': 'forest',
    'ui_market_awning': 'ui',
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
    'obj_tea_whisk': 'forest',
    'obj_bamboo_flute': 'forest',
    'obj_river_lantern': 'forest',
    'bg_river': 'forest',
    // Visitantes con pedidos y mejoras de lugares.
    'char_visitor_monk': 'court',
    'char_visitor_traveler': 'court',
    'char_visitor_potter': 'court',
    'char_visitor_gardener': 'court',
    'char_visitor_fisher': 'court',
    'obj_upgrade_border': 'court',
    'obj_upgrade_bloom': 'court',
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
    // La Maqueta (`model_screen.dart`, `pano_painter.dart`): sin arte, se pinta con código.
    'obj_model_table': 'court',
    // Los Miradores (Bloque 26 de `docs/prompts.md`): mientras falte, se pinta con código.
    'pano_sky': 'path',
    'pano_far_mountains': 'path',
    'pano_forest': 'path',
    'tex_pano_ground_detail': 'path',
    'obj_path_gate': 'path',
    'obj_gate_future': 'path',
    'spr_path_glow_stone': 'path',
    'obj_pavilion_back': 'path',
    'obj_pavilion_front': 'path',
    'obj_path_bush': 'path',
    'obj_station_sand': 'path',
    'obj_station_leaves': 'path',
    'obj_station_meditation': 'path',
    'spr_path_slot': 'path',
    'spr_path_slot_locked': 'path',
    'bg_path_aerial_paper': 'path',
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

/// Dibuja [img] en nine-slice dentro de [dst]: el centro [slice] (en píxeles
/// de la imagen) se estira y los bordes quedan como se pintaron, achicados
/// [scale] veces.
void drawArtNine(ui.Canvas canvas, ui.Image img, ui.Rect slice, ui.Rect dst, double scale) {
  canvas.save();
  canvas.translate(dst.left, dst.top);
  canvas.scale(1 / scale);
  canvas.drawImageNine(
    img,
    slice,
    ui.Rect.fromLTWH(0, 0, dst.width * scale, dst.height * scale),
    ui.Paint()..filterQuality = ui.FilterQuality.medium,
  );
  canvas.restore();
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
