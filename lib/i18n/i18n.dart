import 'en.dart';
import 'es.dart';
import 'ja.dart';
import 'pt.dart';
import 'zh.dart';

/// Idiomas del juego: español (rioplatense), inglés, portugués (Brasil),
/// japonés y chino simplificado. Los textos salen de `tool/i18n_strings.json`
/// (`python3 tool/gen_i18n.py`).
const supportedLanguages = ['es', 'en', 'pt', 'ja', 'zh'];

const Map<String, Map<String, String>> catalogs = {'es': es, 'en': en, 'pt': pt, 'ja': ja, 'zh': zh};

String _language = 'es';

/// Idioma activo (uno de [supportedLanguages]).
String get currentLanguage => _language;

void setLanguage(String code) => _language = supportedLanguages.contains(code) ? code : 'en';

/// El primero de los idiomas preferidos del sistema que esté soportado; si
/// ninguno lo está, inglés.
String systemLanguage(Iterable<String> codes) => codes.firstWhere(supportedLanguages.contains, orElse: () => 'en');

/// Texto de [key] en el idioma activo, reemplazando `{nombre}` por [args].
/// Si falta en el idioma activo cae al inglés y, si tampoco está, a la clave.
String tr(String key, [Map<String, Object> args = const {}]) {
  var s = catalogs[_language]![key] ?? en[key] ?? key;
  for (final e in args.entries) {
    s = s.replaceAll('{${e.key}}', '${e.value}');
  }
  return s;
}

/// Singular/plural: usa `key.one` si [n] es 1 y `key.other` si no (con `{n}`).
String trN(String key, int n, [Map<String, Object> args = const {}]) =>
    tr(n == 1 ? '$key.one' : '$key.other', {'n': n, ...args});
