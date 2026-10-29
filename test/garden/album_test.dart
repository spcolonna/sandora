import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/progress.dart';
import 'package:sandora/garden/weather.dart';
import 'package:sandora/minigames/sand/sand_shapes.dart';

import '../helpers.dart';

void main() {
  final balance = loadBalance();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('figuras, regalos y visitas entran al álbum una vez y se guardan', () async {
    final p = Progress.instance;
    final dawn = DateTime(2026, 10, 27, 6, 30);
    await p.load(balance, now: dawn);
    expect(p.albumCount, 0);
    expect(p.albumNew, isFalse);

    p.setSandDrawing([0.5, 0.5], shape: SandShape.wave);
    p.setSandDrawing([0.5, 0.5], shape: SandShape.wave);
    expect(p.found, {'shape.wave'});
    expect(p.albumNew, isTrue);
    p.markAlbumSeen();
    expect(p.albumNew, isFalse);

    final dew = p.dayCycle.gifts.firstWhere((g) => g.id == 'dew');
    expect(p.takeGift(dew, weather: Weather.clear, now: dawn), isTrue);
    expect(p.found, contains('gift.dew'));

    final noon = DateTime(2026, 10, 27, 12);
    p.finishRun('matcha', 1, now: noon);
    p.takeVisit(now: noon.add(p.teaVisits.arrive));
    expect(p.found, contains('visitor.${p.teaVisitor(now: noon).id}'));
    expect(p.albumNew, isTrue);

    await p.load(balance, now: noon);
    expect(p.albumCount, 3);
    expect(p.albumNew, isTrue);
  });

  test('quien ya jugaba antes del álbum no empieza de cero', () async {
    SharedPreferences.setMockInitialValues({'sandFigures': 4, 'sandLastShape': SandShape.leaf.index});
    final p = Progress.instance;
    await p.load(balance, now: DateTime(2026, 10, 27, 12));
    expect(p.found, containsAll(['shape.circle', 'shape.leaf']));
  });
}
