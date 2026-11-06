# NOTAS — traspaso entre chats

Archivo para retomar el trabajo en un chat nuevo sin el historial. Última actualización: 2026-11-06.
Complementa (no reemplaza) a `README.md` (código y estructura), `Sandora_GDD.md` (diseño) y `docs/pendientes.md`
(lista larga de pendientes con historia).

## Reglas del usuario (obligatorias)

- **Git:** commitear siempre como `spcolonna <spcolonna@gmail.com>` y pushear a `origin main`
  (`https://github.com/spcolonna/sandora`). **Nunca** con el usuario ni a repos de Ironhide.
  ```bash
  git -c user.name=spcolonna -c user.email=spcolonna@gmail.com commit -m "Mensaje en español

  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
  git push origin main
  ```
- Respuestas en **español**, concisas. Para investigar código, usar subagentes (Explore/Plan).
- Norte de producto: que todo sea **"recontra satisfactorio" y fácil**. Pilar 8 del GDD: **nada es brusco**
  (fundidos, hápticos livianos, sonidos con ataque suave, textos de fallo amables).
- **Capturas:** solo si hay que verificar algo visual. Achicarlas antes (`sips -Z 600` o `scale: 0.5`) y mirar solo la
  zona que importa (zoom). Para texto o estructura: read_page, get_page_text, logs o tests.
- **Nada de capturas, videos, cuadros ni datos de simulación en el repo:** van al scratchpad y se borran al terminar.
- Simuladores o emuladores creados para una prueba se borran al terminar.
- Los resultados importantes (números, conclusiones, decisiones) van en este archivo, no en imágenes.
- Commits y textos en español; números de balance en `assets/balance/game_balance.json`; textos de UI en 5 idiomas
  con `python3 tool/gen_i18n.py --add archivo.json` (placeholders `{n}`).

## Qué es

Sandora (carpeta `ZenGarden`, bundle `com.oraki.sandora`, paquete Dart `sandora`, equipo Apple `RZGQPAGH53`):
juego móvil Flutter + Flame de Oraki Games. Minijuegos cortos (Apilado, Arenero, Lluvia/Gotas, Shishi, Hojas,
Estanque, Flauta, Ensō, etc.) que dan monedas para cuidar y decorar un jardín zen "patio pintado" (acuarela en capas,
cámara navegable).

## Qué se hizo en esta sesión (más reciente primero)

| Commit | Qué |
| --- | --- |
| (este) | **16 imágenes integradas** (fondos de 7 minijuegos, suelos del estanque y del bosque, río, copa y mesa del bonsái, maleza, hojas, regalo del té, toldo del Mercado). IPA 1.0.0+2 generado. |
| `14f9413` | Build vuelta a **1.0.0+2**: en App Store Connect solo está la 1; la próxima subida es la +2. |
| `911b15e` | **Avisos de Apple 90068/90683:** pods a iOS 15 y texto de ubicación "Always". |
| `faf8572` | **Sonido arreglado** (ver Audio: el juego sonaba mudo en el iPhone), sonidos nuevos (tijera, batidor, pájaros, grillo, pincel del musgo) y arte de los premios de la racha (zafu, cuenco, farol de papel). IPA 1.0.0+3. |
| `3448141` | **Sonido procedural nuevo** (ver sección Audio) y música del jardín. |
| `9c99a40` | iOS: `ITSAppUsesNonExemptEncryption = false` en `ios/Runner/Info.plist`. (Por un staging previo, también borra `tool/gen_placeholder_audio.py`, renombrado a `tool/gen_audio.py`.) |
| `7f7e8ad` | **Metas del día:** cofre del jardín cada 7 días completos (no hace falta que sean seguidos; 3 lotos, 150 piedritas, 3 madera, aviso grande `milestone.chest`), punto en el orbe de nivel + línea "Metas nuevas" que brilla hasta abrir la hoja, y la meta de variedad solo sale con suficientes juegos abiertos. |
| `454ad66` | Premios de la racha de meditación en el patio (zafu, cuenco, farol). |
| `7f07202` | Prompts de arte (premios de meditación, bosque, fondos de minijuegos). |
| `a6c827c` | Logros: 19, con aviso grande, y envío a Game Center en iOS. |
| `4b71e3c` | Guardado en la nube por iCloud (key-value). |
| `c67ac6f` | Interfaz pintada (paneles, resultado, botones, barra de Calma). |
| `874d19b` | Clima que se funde de a poco, tutorial jugable por niveles, avisos grandes (`milestone_card.dart`). |

Estado de calidad al cierre: `flutter analyze` sin avisos, **163 tests en verde**.

## Metas del día y cofre (mecánica exacta)

- Cada día salen 3 metas (`lib/garden/daily_goals.dart`, `DailyGoals.forDay`), elegidas con el día como semilla.
  Solo salen las cumplibles (`DailyGoals.doable`): la de meditar pide poder meditar y la de variedad pide tener
  abiertos al menos tantos juegos como su meta (`Progress.openGames`).
- Al cumplir las 3 paga el bonus `all` y, en ese momento (`Progress._goalEvent`), se suma **1 sello**
  (`goalSeals`, guardado en prefs `goals.seals`).
- Con `chest.target` = 7 sellos (no hace falta que sean días seguidos) el cofre se abre: paga `chest.give`, los
  sellos **vuelven a 0**, el cofre entra en `done` y se encola el aviso grande `queueMilestone('chest')`.
- Valor exacto en `assets/balance/game_balance.json`:
  `"chest": { "days": 7, "give": { "lotus": 3, "pebbles": 150, "wood": 3 } }` (dentro de `dailyGoals`).
- Aviso de metas nuevas: `goalsUnseen()` (el día visto, en prefs `goals.seen`, no es hoy y no hay metas hechas).
  Muestra un punto en el orbe de nivel y la línea "Metas nuevas" con brillo. `markGoalsSeen()` se llama al abrir la
  hoja.
- Para depurar: `--dart-define=SANDORA_SEALS=6`. Lo cubre `test/garden/daily_goals_test.dart`. La apertura del
  cofre en pantalla no se vio en el simulador; solo la cubre el test.

## Audio (decisiones y estado)

- **Decisión:** todo el audio es procedural, generado por `tool/gen_audio.py` (numpy + scipy + ffmpeg). Sin
  grabaciones ni servicios de IA: es todo propio y sin licencias que cuidar. El usuario descartó apps de IA gratuitas
  porque sus planes gratis no permiten uso comercial (Suno, Udio, ElevenLabs). Si algún día se quiere IA local con
  licencia comercial: ACE-Step (Apache 2.0, música) y Stable Audio Open (licencia comunitaria, efectos); hay que
  verificar las licencias antes de usarlas.
- **Todo en pentatónica de Do** (Do Re Mi Sol La): música, gotas, celebraciones y flauta nunca chocan.
- **Técnicas:** kalimba (notas, UI, celebraciones), koto Karplus-Strong (música, error), shakuhachi con soplido
  (flauta, música), cuenco con parciales que baten (meditación), modales para piedras y bambú, burbuja para gotas,
  texturas granulares (hojas, escoba, pincel, rastrillo, tierra), lluvia con miles de gotitas y viento con silbidos,
  maullido con formantes, reverbs sintéticas (`GARDEN`, `HALL`, `TEMPLE`).
- **Loops** (`sfx_base_wind` 8 s, `sfx_rain_ambient` 8 s, `sfx_sand_rake` 2 s) son circulares: empalman sin costura.
- **Música:** `music_garden_01` (koto, ~114 s) y `music_garden_02` (flauta, ~131 s). Terminan en silencio y se
  alternan con 8 a 18 s de pausa. API en `lib/ui/fx/sfx.dart`: `SoundBoard.music({volume: 0.28})`, `stopMusic()`;
  `stopAllLoops()` también corta la música. El jardín la arranca en `_gardenSound()` y la corta al entrar a un
  minijuego o a meditar. Se apaga con el interruptor "Música" de Ajustes.
- **Bandera `_away`** (`lib/ui/garden_screen.dart`): vale `true` mientras hay un minijuego o una meditación encima
  del jardín (`_open` / `_meditate`), y `_gardenSound()` no hace nada si está prendida. Existe porque el reloj
  periódico del jardín (`_tick`, cada 20 s) llama a `_gardenSound()` aunque el jardín esté tapado. Antes de la
  bandera, eso **volvía a prender el viento en medio de un minijuego**, y con la música habría pasado lo mismo.
- **Por qué el juego "no tenía sonido" (2026-11-06), arreglado:** (1) la categoría `ambient` de iOS respeta el
  interruptor de silencio, así que con el iPhone en silencio quedaba mudo. Ahora es `playback` + `mixWithOthers`
  (suena siempre, se mezcla con la música del usuario y se apaga desde Ajustes). (2) El jardín pedía música y viento
  antes de que cargara el audio y se perdía hasta el próximo tic (20 s); ahora espera `SoundBoard.whenReady`.
  (3) Si fallaba un archivo, no sonaba nada; ahora cada sonido carga por su cuenta y en paralelo. En el simulador el
  log dice `Audio listo: 37 efectos, 4 ambientes`.
- **Sonidos nuevos:** `sfx_snip_01/02` (tijera del bonsái, antes era un toque de interfaz), `sfx_whisk` (loop del
  batidor de matcha, antes usaba el rastrillo), `sfx_bird_01..03` (ruiseñor, mosquitero, ojiblanco) y
  `sfx_night_cricket` (grillo campana): el jardín los toca de lejos de vez en cuando (`_wildlife`, de día pájaros y
  de noche grillo, callados con lluvia). El musgo suena con el pincel mientras se pinta y las piedras de los faroles
  suenan al sacarlas. El rastrillo y el batidor siguen al interruptor de **sonido**, no al de música.
- **Verificado:** afinación del koto (< 1 cent), picos sin recorte, loops sin costura.
- **No verificado:** cómo suena en el iPhone. **Está pendiente que el usuario pruebe la build 3** y pida ajustes (volumen de la música,
  reverb, brillo del koto, etc.).
- **Regenerar:** `python3 tool/gen_audio.py [prefijos]` tarda **unos 12 s** con todo. El script antes se llamaba
  `tool/gen_placeholder_audio.py` y se renombró en esta sesión.
- Idea no hecha: silenciar nuestra música cuando el usuario ya está escuchando la suya (hoy se mezclan:
  `AVAudioSessionCategory.ambient` + `mixWithOthers`).

## Estado actual / en curso

**Qué sigue ahora (al 2026-11-06):** no hay tarea de código en curso. El último pedido (NOTAS.md + borrar el
simulador) está terminado. Quedan dos cosas esperando al usuario:
- **No entró todavía a Xcode** con su cuenta, así que el build de TestFlight sigue frenado (detalle abajo). Cuando
  avise, el próximo paso es correr `flutter build ipa --release` y subirlo.
- **No escuchó todavía** el sonido nuevo ni la música: el simulador se apagó antes y después se borró. Para
  escucharlo hay que crear un simulador, hacer `flutter run` y ajustar según lo que diga.

- **Build de iOS para TestFlight (2026-11-06): ya se generó.** El usuario cargó su cuenta en Xcode y
  `flutter build ipa --release` produjo `build/ios/ipa/Sandora.ipa` (1.0.0+1, 43 MB; ya subido). Está firmado con Apple
  Distribution RZGQPAGH53 y tiene los entitlements de Game Center, iCloud KV y `beta-reports-active`. Falta que el
  usuario cree la app en App Store Connect (nombre principal en inglés "Sandora: Zen Garden", más es, pt-BR, ja y
  zh-Hans) y suba el IPA con Transporter. **Para cada subida nueva hay que subir el número de build en
  `pubspec.yaml` (`+2`, `+3`…).**
- **Deployment target iOS 15.0** (Podfile y project.pbxproj): Apple lo exige desde abril de 2027 (aviso 90068 en
  la build 1). La build 1.0.0+2 ya sale con 15.0.
  El aviso 90068 siguió en la build 3 porque los pods compilaban con 13.0. Ahora el `post_install` del Podfile los
  fuerza a 15.0. Siguen en 13.0 `App.framework`, `Flutter.framework` y `objective_c.framework`: los arma Flutter
  3.41 y no se pueden cambiar desde el proyecto. Es solo un aviso hasta abril de 2027; actualizar Flutter antes.
- **Aviso 90683:** `geolocator` referencia la API de ubicación "siempre", así que Apple pide
  `NSLocationAlwaysAndWhenInUseUsageDescription` aunque el juego solo pide "mientras se usa". Ya está en Info.plist.
- **IPA 1.0.0+2 generado (2026-11-06)** en `build/ios/ipa/Sandora.ipa`: sonido, arte de la racha, las 16 imágenes
  nuevas y los avisos de Apple. Falta que el usuario lo suba con Transporter. Las builds +3 y +4 se generaron pero
  **no se subieron**. Solo subir el número cuando el usuario suba de verdad una build (la siguiente sería +3).
- **16 imágenes integradas** (originales en `store/art/minigames/`, `store/art/bg/` y `store/art/garden/`). Todas
  vuelven al dibujo de código si falta el archivo:
  - Fondos de minijuegos con `drawArtCover`: `bg_leaves`, `bg_shishi`, `bg_moss` (east), `bg_bell` (temple),
    `bg_matcha`, `bg_flute` (forest). `bg_bonsai` va en dos tajadas (`_paintRoom`) para que la maceta apoye en la
    mesa pintada (al 87,5 % de la imagen).
  - `bg_east_ground` / `bg_forest_ground`: se usa la mitad de abajo del lienzo cubriendo desde el 43 % de la
    pantalla (`_groundArt` en `garden_scene.dart`), en lugar del verde liso con matas.
  - `bg_forest_river` cubre el rect del río (`paintRiver`); las linternas siguen en código en `_paintedLanterns`.
  - `obj_bonsai_foliage`: copas del minijuego (el verde claro de lo que sale de la silueta es un tinte) y del
    bonsái del jardín. `obj_bonsai_table`: la maceta apoya al 22 % de su alto.
  - `obj_care_weeds` / `obj_care_leaves` (`garden_care.dart`), `obj_tea_gift` (`tea_visit.dart`, sin verificar en
    pantalla: hace falta una visita al té) y `ui_market_awning` (`market_screen.dart`).
  - En `docs/prompts.md` solo quedan `style_stones` y `style_plants` (guía de estilo, opcionales).
- **Arte de la racha integrado:** `obj_court_zafu`, `obj_court_singing_bowl` y `obj_court_paper_lantern` (520 px,
  `assets/images/court/`, originales en `store/art/court/`). Se dibujan en `_paintCourtStreak`; si falta el arte,
  vuelve el dibujo de código. El farol ya viene encendido y de noche solo suma el halo.
- La restricción "sin pruebas en dispositivo hasta el 2026-10-30" ya venció: el usuario quiere probar en un iPhone
  real.

## Pendientes

Del usuario:
- Entrar con su cuenta en Xcode y crear la app en App Store Connect (desbloquea TestFlight).
- Escuchar el sonido nuevo y la música, y decir qué ajustar.
- Generar las imágenes de `docs/prompts.md` (ChatGPT) y dejarlas en `store/`.
- App Store Connect: activar Game Center y crear los 19 logros `sandora.<id>` (lista en `docs/pendientes.md`).
- Capacidades iCloud y Game Center en el primer build (la firma automática debería sumarlas).
- Búsqueda de marca "Sandora" (USPTO, EUIPO, MIEM; clases 9 y 41).

Opciones de desarrollo que quedaron sobre la mesa:
- Mejoras visibles en el álbum.
- Ranking online (necesita backend).
- Play Games en Android.
- Silenciar la música propia si suena la del usuario.

## Comandos útiles

```bash
flutter run -d <simulador>                              # ver `flutter devices`
flutter test
flutter analyze
dart format -l 120 <archivos>
python3 tool/gen_audio.py [prefijos] [--preview DIR]      # audio procedural → assets/audio/*.m4a
python3 tool/gen_i18n.py --add nuevos.json               # textos en 5 idiomas
python3 tool/gen_prompts.py                              # regenera docs/prompts.md
flutter build ipa --release                              # build para App Store (necesita cuenta en Xcode)
xcrun simctl create "Sandora Test" "iPhone 17 Pro Max"   # crear uno para probar (borrarlo al terminar)
```

Defines de depuración (`--dart-define=NOMBRE=valor`, solo en debug): `SANDORA_SEALS` (sellos del cofre),
`SANDORA_DAY`, `SANDORA_HOUR`, `SANDORA_WEATHER`, `SANDORA_WEATHER_FROM` (para ver un fundido de clima),
`SANDORA_AFTER_RAIN`, `SANDORA_AWAY_H`, `SANDORA_GAME`, `SANDORA_REMINDER_MIN`, `SANDORA_STREAK`, `SANDORA_TOWER`.

Simulador: "Sandora Test" se borró el 2026-11-06; para probar, crear uno y borrarlo al terminar. Las
capturas del simulador llegan con una acción de atraso: sacar otra para ver el estado real.

## Rutas clave

- Balance: `assets/balance/game_balance.json` (secciones `dailyGoals`, `weather`, `unlocks`, `tutorial`, …).
- Progreso y guardado: `lib/garden/progress.dart` (singleton sobre SharedPreferences).
- Metas del día: `lib/garden/daily_goals.dart`, `lib/ui/widgets/daily_goals.dart`.
- Avisos grandes: `lib/ui/widgets/milestone_card.dart` (`Progress.queueMilestone` / `takeMilestone`).
- Jardín: `lib/ui/garden_screen.dart`, `lib/ui/garden/` (escena, cielo, vista).
- Audio: `tool/gen_audio.py`, `lib/ui/fx/sfx.dart`, `assets/audio/`.
- Textos: `tool/i18n_strings.json` → `lib/i18n/*.dart`.
- iOS: `ios/Runner/Info.plist`, `ios/Runner/Runner.entitlements` (Game Center + iCloud KV), `AppDelegate.swift`
  (canales `sandora/cloud` y `sandora/games`).
- Tests: `test/` (`test/garden/daily_goals_test.dart`, `test/sim/economy_sim_test.dart`, …).
- Docs: `docs/pendientes.md`, `docs/release-checklist.md`, `docs/store-listing.md`, `docs/prompts.md`.
