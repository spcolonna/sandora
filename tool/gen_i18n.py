#!/usr/bin/env python3
"""Genera lib/i18n/{es,en,pt,ja,zh}.dart desde tool/i18n_strings.json.

El JSON es la fuente de verdad: {"clave": {"es": "...", "en": "...", "pt": "...", "ja": "...", "zh": "..."}}.
Uso:
  python3 tool/gen_i18n.py                 # regenera los .dart
  python3 tool/gen_i18n.py --add lote.json # suma/actualiza claves y regenera
"""
import json
import sys
from collections import OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'tool' / 'i18n_strings.json'
LANGS = ['es', 'en', 'pt', 'ja', 'zh']


def load():
    if not SRC.exists():
        return OrderedDict()
    return json.loads(SRC.read_text(), object_pairs_hook=OrderedDict)


def dart_str(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$').replace('\n', '\\n') + "'"


def main():
    data = load()
    if len(sys.argv) > 2 and sys.argv[1] == '--add':
        batch = json.loads(Path(sys.argv[2]).read_text(), object_pairs_hook=OrderedDict)
        for k, v in batch.items():
            missing = [l for l in LANGS if l not in v]
            if missing:
                sys.exit(f'{k}: falta {missing}')
            data[k] = OrderedDict((l, v[l]) for l in LANGS)
        SRC.write_text(json.dumps(data, ensure_ascii=False, indent=1) + '\n')
    for lang in LANGS:
        lines = [
            '// GENERADO por tool/gen_i18n.py desde tool/i18n_strings.json. No editar a mano.',
            '// ignore_for_file: lines_longer_than_80_chars',
            f'const {lang} = <String, String>{{',
        ]
        lines += [f'  {dart_str(k)}: {dart_str(v[lang])},' for k, v in data.items()]
        lines.append('};')
        (ROOT / 'lib' / 'i18n' / f'{lang}.dart').write_text('\n'.join(lines) + '\n')
    print(f'{len(data)} claves')


main()
