import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sandora/i18n/i18n.dart';

void main() {
  test('todos los idiomas tienen las mismas claves y marcadores', () {
    final base = catalogs['es']!;
    final marker = RegExp(r'\{(\w+)\}');
    for (final lang in supportedLanguages) {
      final c = catalogs[lang]!;
      expect(c.keys.toSet(), base.keys.toSet(), reason: lang);
      for (final k in base.keys) {
        final want = marker.allMatches(base[k]!).map((m) => m[1]).toSet();
        final got = marker.allMatches(c[k]!).map((m) => m[1]).toSet();
        expect(got, want, reason: '$lang $k');
      }
    }
  });

  test('cada tr() literal del código existe', () {
    final keys = catalogs['es']!.keys.toSet();
    final call = RegExp(r"""\btr(N?)\('([a-z0-9_.]+)'""");
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      for (final m in call.allMatches(f.readAsStringSync())) {
        final key = m[1] == 'N' ? '${m[2]}.other' : m[2]!;
        expect(keys, contains(key), reason: f.path);
      }
    }
  });

  test('tr reemplaza marcadores y trN elige singular o plural', () {
    setLanguage('es');
    expect(trN('stack.height', 1), '1 piedra');
    expect(trN('stack.height', 4), '4 piedras');
    setLanguage('xx');
    expect(currentLanguage, 'en');
    expect(systemLanguage(['fr', 'pt']), 'pt');
  });
}
