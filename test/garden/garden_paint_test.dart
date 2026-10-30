import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sandora/ui/garden/garden_scene.dart';
import 'package:sandora/ui/garden/scene_art.dart';

void main() {
  testWidgets('cada vista se dibuja entera (cielo y tierra), en cualquier tamaño de patio', (t) async {
    await t.runAsync(() => SceneArt.instance.load());
    for (final size in [const Size(440, 846), const Size(375, 560)]) {
      for (final side in [0, 1, 2]) {
        for (final patio in [0, 1, 2]) {
          final layout = GardenLayout(size, patio, side: side, bottom: 80);
          for (final layer in GardenLayer.values) {
            final painter = GardenPainter(
              layer: layer,
              layout: layout,
              tower: const [],
              drawing: const [],
              meditationOpen: true,
              daylight: 0.3,
              warmth: 0.2,
              arc: 0.5,
              morning: false,
              rainbow: 0.5,
              wet: 0.5,
              drift: 1.4,
              skyTop: -120,
            );
            painter.paint(Canvas(ui.PictureRecorder()), size);
          }
          for (final r in layout.places.values) {
            expect(r.bottom, lessThanOrEqualTo(size.height - 80), reason: 'lado $side: nada bajo la barra de abajo');
          }
        }
      }
    }
  });

  test('el patio pintado tiene sus cinco lugares adentro y sin pisarse', () {
    const size = Size(440, 440 / GardenLayout.courtAspect);
    final layout = GardenLayout.court(size);
    final rects = layout.places.values.toList();
    expect(rects, hasLength(5));
    for (final (i, r) in rects.indexed) {
      expect((Offset.zero & size).intersect(r), r);
      for (final o in rects.skip(i + 1)) {
        expect(r.intersect(o).isEmpty || r.intersect(o).width <= 0 || r.intersect(o).height <= 0, isTrue);
      }
    }
  });
}
