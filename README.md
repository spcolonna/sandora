# Sandora

Juego casual para móvil: minijuegos de 30 a 90 s que dan tokens para cuidar un jardín zen propio. El diseño completo
está en [Sandora_GDD.md](Sandora_GDD.md); este README documenta el código y cómo se trabaja.

## Estado: fase 1 (prototipo)

Tres minijuegos con placeholders (sin arte final) para validar la sensación al tacto. **Prueba para pasar a la fase
2: 10 personas lo juegan sin explicación y piden otra partida.**

| Minijuego | Qué está | Qué falta |
| --- | --- | --- |
| Apilado de piedras | Física Forge2D, imán al centro, amortiguación en las primeras 5, grados por centrado, viento con aviso de 3 s y "mantener para sostener", torre que queda en el jardín y junta Piedritas por hora | Gato de la vecina, arte de piedras |
| Arenero | 5 figuras guía, trazo suavizado, puntaje (precisión, cobertura, continuidad y suavidad), rastrillo que pasa por el trazo del jugador, dibujo guardado en el jardín | Shader de relieve, modo libre (desde las 10 figuras) |
| Lluvia en vasijas | Paneo del meditador al alero, partitura generada, 3 a 5 vasijas en pentatónica, ventanas de ±40/80/120 ms, anillo visual para jugar sin sonido, "profundidad de meditación" | Calibración de latencia de audio en Android, tormentas |

| Nivel del jardín | Calma por partida y por meditación, curva configurable, nivel y barra en el jardín, celebración al subir | Celebración visual grande (hoy es un cartel con campana) |
| Ampliaciones | Hoja "Ampliar el jardín": cada ampliación pide nivel y se paga con tokens. Patio I y II agrandan el terreno dibujado | Las zonas (Estanque en adelante) figuran como "Próximamente" hasta tener sus minijuegos |
| Modo meditación | Desde el nivel 5: duraciones, sonido, campana de intervalo, círculo de respiración, reloj real (se retoma o se cobra al reabrir), techo diario, pago por minuto si se corta, racha | Notificación local de la campana final, objetos de racha cada 7 días |

También están: economía (Piedritas y esencias, menos rendimiento al repetir en el día, sin energía), Serenidad que
baja 5 % por día con piso del 40 %, celebración en 3 niveles (partículas, sonido y vibración), 5 idiomas y ajustes.

## Correr

```bash
flutter run                          # simulador o dispositivo
flutter test                         # lógica pura: economía, partituras, puntaje del arenero, i18n
python3 tool/gen_i18n.py             # regenera lib/i18n/*.dart desde tool/i18n_strings.json
python3 tool/gen_prompts.py          # regenera docs/prompts.md (prompts de arte para ChatGPT)
python3 tool/gen_placeholder_audio.py  # regenera los sonidos placeholder (necesita numpy y ffmpeg)
```

## Estructura

| Carpeta | Qué hay |
| --- | --- |
| `lib/balance/` | Lee `assets/balance/game_balance.json`: todos los costos, recompensas, tiempos y tolerancias. Se ajusta sin recompilar la lógica. |
| `lib/garden/` | Reglas puras: `Economy`, `LevelRules` (Calma, nivel, ampliaciones) y `MeditationRules` (recompensa, techo, racha). `Progress` es el singleton sobre SharedPreferences: monedas, serenidad, Calma, ampliaciones, meditación en curso, torre y dibujo. Todo se guarda al momento. |
| `lib/minigames/common/` | `MinigameScreen` (pausa, resultado y pago) y `Grade` + `celebrate()` (bien, genial y perfecto). |
| `lib/minigames/<juego>/` | Cada minijuego es un `FlameGame`. La lógica que se puede probar va aparte, en Dart puro: `rain_chart.dart`, `sand_shapes.dart`, `stack_rules.dart`. |
| `lib/ui/` | Jardín, hoja de ampliaciones, `meditation/` (Modo meditación), ajustes, `fx/sfx.dart` (SoundBoard, loops de ambiente, Haptics) y tema. |
| `lib/i18n/` | `tr('clave', {...})` y `trN(clave, n)`. Generado: no editar `es/en/pt/ja/zh.dart` a mano. |
| `tool/` | Generadores (i18n, prompts, audio). |
| `docs/` | `prompts.md` (generado) y `pendientes.md`. |

Las mismas convenciones que Hexiege: estado en singletons `ChangeNotifier`, `Navigator` directo, i18n desde JSON,
assets en `.webp`, originales de arte en `store/` (no se commitea), `page_width: 120`.

## Decisiones tomadas en el prototipo

- **Riverpod y go_router del GDD no se usan todavía:** con 3 pantallas, el patrón de Hexiege (singletons +
  `Navigator`) alcanza. Se revisa en la fase 2 con Firebase.
- **El juego rítmico se juzga contra el reloj del juego**, con `audioOffsetMs` en el balance para calibrar.
- **Una piedra que queda de costado junto a la torre no cuenta** y se desvanece. Si la torre se cae, queda en el
  jardín lo que siga en pie y el récord se guarda igual.
- **Al repetir el mismo minijuego**, desde la 4.ª partida del día rinde la mitad (`repeats` en el balance).
- **Vasijas:** 3 al empezar, 4 con récord ≥ 300 y 5 con récord ≥ 600.
- **Esencias:** Apilado y Arenero dan Arena; Lluvia da Agua; la meditación da Luz.
- **El nivel habilita, los tokens pagan:** llegar al nivel de una ampliación no la abre sola.
- **Meditación con reloj real:** la sesión se guarda al empezar; si la app se cierra y el tiempo ya se cumplió, se cobra al abrir; si no, el jardín la retoma.

## Idiomas

Español (rioplatense), inglés, portugués (Brasil), japonés y chino simplificado. Para sumar textos:
`python3 tool/gen_i18n.py --add lote.json`, con `{clave: {es, en, pt, ja, zh}}`. Un test controla que todos los
idiomas tengan las mismas claves y marcadores, y que exista cada `tr('…')` del código.
