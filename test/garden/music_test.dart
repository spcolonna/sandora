import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sandora/minigames/catalog.dart';
import 'package:sandora/ui/fx/sfx.dart';

void main() {
  test('cada minijuego tiene su pieza de música y el archivo existe', () {
    for (final m in minigames) {
      final tracks = SoundBoard.tracksFor(m.id);
      expect(tracks, ['music_game_${m.id}'], reason: '${m.id} sin música propia');
      expect(File('assets/audio/${tracks.single}.m4a').existsSync(), isTrue, reason: tracks.single);
    }
    for (final t in SoundBoard.tracksFor(SoundBoard.garden)) {
      expect(File('assets/audio/$t.m4a').existsSync(), isTrue, reason: t);
    }
  });

  test('un juego sin pieza propia sigue con la música del jardín', () {
    expect(SoundBoard.tracksFor('nada'), SoundBoard.tracksFor(SoundBoard.garden));
  });
}
