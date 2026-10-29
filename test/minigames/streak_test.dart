import 'package:flutter_test/flutter_test.dart';
import 'package:sandora/minigames/common/grade.dart';

void main() {
  test('la racha: muy bien y perfecto suman, bien la sostiene, un fallo la corta', () {
    final s = Streak();
    expect(s.hit(Grade.great), 1);
    expect(s.hit(Grade.perfect), 2);
    expect(s.hit(Grade.good), 2);
    expect(s.hit(Grade.perfect), 3);
    expect(s.hit(null), 0);
    expect(s.best, 3);
    s.hit(Grade.great);
    s.miss();
    expect(s.count, 0);
  });
}
