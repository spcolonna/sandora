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
| `f47d0c6` | **Prototipo del Sendero** (al usuario no lo convenció la decoración dentro de las vistas: se ve todo lleno y no se entiende). La decoración sale de las vistas (`model.inViews: false`; con `true` vuelve todo lo anterior, incluido el paseo por las vistas) y se ve en **El Sendero** (`sendero_screen.dart`, `sendero/sendero_painter.dart`, `garden/sendero.dart`, balance `sendero`): un camino en primera persona en falso 3D (cada pieza es una imagen plana escalada por distancia, bruma a lo lejos, montes con parallax) que cruza patio → estanque → bosque, con un portal en cada zona. La Maqueta es su plano: fila 0 (fondo) = más adelante en el camino, columnas 0-1 a la izquierda y 2-3 a la derecha. «Recorrer» abre el Sendero caminando; «Ver en el jardín» lo abre parado frente a la pieza. Tocar camina o se detiene, deslizar avanza o retrocede; el cartel muestra la pieza que se tiene delante. Con la decoración fuera de las vistas no se caen piezas en las tormentas. Paisaje con arte existente (faroles y rocas del patio, bambú). Para probar: `--dart-define=SANDORA_PATH=true` (abre el Sendero solo), junto con `SANDORA_DEMO=true`. El usuario lo aprobó: pasa a ser el jardín principal (fila siguiente). |
| `362edc8` | **El Sendero es el jardín principal** (el usuario lo pidió tras ver el prototipo). Ajuste **Vista del jardín: Sendero (por defecto) / Clásica** (`AppSettings.classicView`, hoja de ajustes); en Clásica todo sigue como antes y la decoración vuelve a las vistas (`Progress.decorInViews`). El Sendero vive **dentro de `GardenScreen`** (mismo HUD, `_enter`, celebraciones, sonido): `sendero/sendero_walk.dart` (camina, bifurcaciones, toques, regalos), `sendero/sendero_painter.dart` (cámara con rumbo, escena con hit-test), `garden/sendero.dart` (mundo en grafo: tronco + ramales). Balance `sendero`: `segment 24`, `branches` (zona, `at`, lado, lugares) y `board`. **Bifurcaciones**: al caminar solo se frena y salen botones (izq./derecho/der., con adónde lleva); deslizar al costado también elige. Cada ramal termina en un claro con 1-2 lugares (juegos); tocarlo entra (si está lejos, camina hasta ahí). Carteles en cada bifurcación con los nombres. **Bloqueos**: juego cerrado = cerca de bambú con su nota (nivel/día); **portones** entre zonas se abren cuando algún juego de la zona está disponible (estanque día 2 con shishi; bosque con la casa de té); tocarlo dice qué falta u ofrece las ampliaciones. **Vida**: regalos del día, cuidados, visitante (cada día en otro punto), ofrenda del té y piedritas de la torre como marcadores tocables (arte si existe, si no burbuja con ícono). **Acceso rápido** («Juegos», abajo): los juegos *encontrados* (`Progress.discovered`: se llegó al claro o ya se jugó; pref `sendero.seen`) van caminando rápido y entran; los demás salen «?». **Vista aérea** (abajo, con la decoración abierta): la Maqueta con `world:` muestra la zona desde arriba (`_AerialBoard`, arranca acercada a las parcelas, se pellizca); las parcelas son huecos al costado del tronco. Paseando, los huecos libres muestran un anillo y tocar uno (o una pieza) abre la vista aérea. Guía: en el Sendero dice adónde caminar (tocarla lleva). Se borró `sendero_screen.dart`. `SANDORA_PATH=true` ahora hace caminar solo al abrir. **Arte**: Bloque 26 en `gen_prompts.py` (31 imágenes, primero en `docs/prompts.md`); `scene_art.dart` ya las busca en `assets/images/path/` (hay que agregar esa carpeta al `pubspec` al integrar la primera). Los `model_tray_*` quedan reemplazados. Al usuario no le gustó al probarlo (plano, sin vida, carteles que se atraviesan, sin giro 360, «Volver» sin vuelta, juegos como recortes): lo reemplazan los Miradores (fila siguiente). |
| aaf634d/31d888f | **Miradores 360 pintados** (decisión del usuario: en vez del paseo continuo, un «Street View» pintado). El jardín es un **patio ampliado** visto desde arriba en metros (`garden/mirador.dart`, balance `miradores`): muro alrededor con bosque detrás, estanque, manchas de musgo, senderos de piedras entre **miradores** (`entrance`, `sand`, `water`, `pavilion`, `bamboo`; `links` de ida y vuelta) y un mirador central `hub` = **vista Clásica** (sin salidas, fov más ancho, tira de juegos abajo). En cada mirador se **gira 360°** arrastrando (con inercia) y se pellizca para acercar; tocar la **piedra con luz** camina (de verdad, por el plano) al siguiente mirador; tocar un lugar lejano camina hasta su mirador y entra; al volver de un juego se queda mirándolo (resaltado) y se puede volver a entrar. **Estanque y bosque quedan cerrados** como zonas futuras: todos los juegos se mudaron al patio (mismas reglas de desbloqueo por juego) y al fondo hay un **portón cerrado** (`gates.future`, «ahí van a abrir nuevas zonas»). **Pabellón** (prop `pavilion`, dibujado con código en capas: pared con shoji abiertos, galería elevada, postes y tejado): la **meditación** (zafu) va en la galería y la **mesa de la Maqueta** (`places.model`, toca → Maqueta) adentro. Cámara cilíndrica (`ui/mirador/pano_painter.dart`): suelo como malla de colores (grava/musgo/agua), surcos de rastrillo concéntricos, matitas, muro con tejadito, bosque de fondo, arbustos al pie del muro (`hedges`), sombras y parches de grava/musgo bajo cada lugar, bruma y luz del día por filtro de color; el lugar cerrado se ve desaturado con candado. Bonsái armado (mesa + maceta + pino). Sectores = las 3 vistas de antes (decoración 4×3 y cuidados por sector, sin migrar datos); la vista aérea dibuja el plano entero. `ui/mirador/mirador_view.dart`: `MiradorController` (`goTo`, `lookAt`, `stroll`), marcadores (regalos, cuidados, visitante, té, torre, huecos), descubiertos al llegar a cada mirador. Se borraron el Sendero viejo y su balance; `GardenView` (vistas pintadas viejas) sigue en el código pero no se usa. Para revisar el aspecto sin simulador: render fuera de pantalla con un test descartable (PictureRecorder → PNG). **Arte**: Bloque 26 rehecho como «Los Miradores» (20 imágenes, primero en `docs/prompts.md`): `pano_sky`, `pano_far_mountains`, `pano_forest` (franjas que dan la vuelta sin costura), `tex_pano_ground_detail` (casi blanca: el suelo la multiplica por su color, pegada al mundo, 2,2 m por copia), portones `obj_path_gate`/`obj_gate_future`, `spr_path_glow_stone` (la flecha la pinta el código), pabellón en capas `obj_pavilion_back`/`obj_pavilion_front` (la galería es código), `obj_path_bush` (arbustos del muro), estaciones `obj_station_sand/leaves/meditation`, huecos, íconos y papel de la vista aérea; la mesa sigue siendo `obj_model_table` (Bloque 25). Todo ya está enganchado en `pano_painter.dart`/`scene_art.dart`: al integrar la primera hay que sumar `assets/images/path/` al `pubspec`. **Pendiente**: borrar `GardenView` y sus partes (código muerto); tocar un hueco abre la vista aérea entera. |
| (este) | **Clásica más cerca**: el mirador central usa cámara propia (`hubFov` 76, `hubEye` 1.2, `hubHorizon` 0.57) para que el piso no ocupe media pantalla; ahí no se dibujan las piedras del sendero y hay matas bajas alrededor (`MiradorWorld.hubPlants`, fuera de lugares y huecos). En la escena ya no se ven las parcelas cerradas (se abren desde la vista aérea); los huecos abiertos se ven más chicos en la Clásica. `hub` en [0.5, −1]: desde ahí se toca todo salvo la casa de té, tapada por el arce de las hojas (se llega por la tira). |
| `540577b` | **Maqueta pulida y paseo.** Cada parcela tiene su pie elegido a mano en cada vista (`model.feet`, 12 [x,y] por zona, mirado con capturas para no tapar lugares; la mesa pasó al fondo derecho del patio, `model.table` [0.12, 0.696, 0.625]). En el patio pintado las piezas van al 70 % (`courtDecorScale`: el lienzo es más ancho que la pantalla). **Paseo en primera persona** (botón «Recorrer» de la maqueta → `garden_walk.dart`): franjas de cine, sin HUD; la cámara camina (vaivén y pasos) de adelante al fondo parándose en cada lugar y decoración, con el nombre abajo, y pasa de zona en zona hasta el bosque; tocar termina. La cámara ahora también se mueve sola en el estanque y el bosque («Ver en el jardín» incluido). **Dar vuelta** una pieza (botón ↻ en la maqueta, `PlacedDecor.flip`, 6º valor del json). `economy_sim` pone lo comprado y abre parcelas (regular 8, intenso 14 en 60 días). Para probar: `--dart-define=SANDORA_DEMO=true` (jardín avanzado con piezas en las 3 zonas, una vez) y `SANDORA_WALK=true` (arranca el paseo solo). |
| `6e5abce` | **Maqueta** (`model_screen.dart`): la decoración sale de las vistas. Una mesa en el patio (`garden_model_table.dart`, balance `model.table`) abre la pantalla con las 3 zonas en grilla 4×3; las parcelas `start` vienen abiertas y las demás cuestan Piedritas (40 × 1,15^compradas, de a 5) y las últimas 2 de cada zona 1 loto. Se elige del cajón y se toca una parcela (o se arrastra); tocar una puesta deja moverla/intercambiarla, guardarla o «Ver en el jardín» (la cámara se acerca y la marca). Las **Mejoras** pasaron a un botón de la maqueta. Se quitó el modo Decorar, el botón del HUD y `perSide`/`perPatio`. `PlacedDecor.cell` + pref `model.cells` por jardín; lo guardado antes migra a la parcela libre más cercana (abre gratis las que falten). Guía: la mesa marca el paso de poner y de decorar. Arte pedido en el bloque 25 de prompts (`obj_model_table`, `model_tray_*`); mientras, código. |
| `7d30c3c` | **Ajustes tras jugar:** meditación de 1 min (cuenta para la racha); **meditación guiada** con frases + campana (`meditation_guide.dart`), se desbloquea una vez por 5 lotos (`meditation.guided.lotus`); **Lluvia** sin gotas simultáneas: los pares llegan con `pairGap` 0,25 s, `minGap` 0,22 s y como mucho 2 en `pairWindow` 0,6 s; vaciar vasija muestra «+60» y el primer toque sobre una que rebalsa ya no suena a fallo; **descanso** de 30 min del Arenero y las Piedras después de jugar (balance `rest`, saltar = 1 loto, no aplica durante la guía; esos dos ya no usan la regla de premio a la mitad). |
| `d1295dc`/`7df64b1` | 41 prompts nuevos; arte existente en lugar de código (linternas del río, cuenco de té, zafu, piedras, hoja de la Flauta, álbum). |
| `37e274b` | **Sonidos del jardín:** puertas de la entrada, aleteo de pájaros, piedra en la arena, rastrillo, hojas y tierra al arrastrar en los cuidados. |
| `5c4c2fd` | **16 imágenes integradas** (fondos de 7 minijuegos, suelos del estanque y del bosque, río, copa y mesa del bonsái, maleza, hojas, regalo del té, toldo del Mercado). IPA 1.0.0+2 generado. |
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
- **Sonidos del jardín (2026-11-06, sin IPA todavía):** `sfx_gate_open` (puertas shoji que se destraban, corren y
  topan; suena en `garden_gate.dart` al abrir la app), `sfx_wings_01/02` (aleteo al tocar el cielo, y 1 de cada 3
  toques canta un pájaro; `garden_touch.dart`), `sfx_stone_sand_01..03` (piedra que se apoya en la arena: golpe sordo
  y arena; reemplaza al "clac" de piedra contra piedra al poner o mover adornos y en el cuidado de piedra y adorno).
  En los cuidados, mientras se arrastra suena el rastrillo (arena, loop), las hojas o la tierra (maleza)
  (`_rubSound` en `garden_care.dart`). El "clac" (`stackPlace`) queda para apilar piedras, juntar piedritas y el
  rastrillo que roza la piedrita del arenero. En el simulador cargan los 43 efectos. No se escucharon en el iPhone.
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
- **IPA 1.0.0+3 generado (2026-11-07)** para subir con Transporter: maqueta, parcelas y paseo en primera persona
  (`540577b`). Hecho con `flutter clean` y verificado con `vtool` (todo `platform IOS`). La próxima subida sería +4.
- **Error 409 "objective_c.framework ... unsupported platform" (2026-11-06):** el IPA llevó el `objective_c`
  de **simulador**, sacado de la caché de native assets que quedó tras correr en el simulador. **Antes de cada
  `flutter build ipa`, hacer `flutter clean`**, y revisar con
  `vtool -show-build Payload/Runner.app/Frameworks/*.framework/*` que todas digan `platform IOS` (no `IOSSIMULATOR`).
  El IPA +2 se regeneró limpio y ya está verificado.
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

Maqueta y paseo (hechos, ver arriba). Queda: piezas grandes de 2×2 (puente, sakura, arce ocupan una parcela y se ven grandes), arte del bloque 25 (mesa y bandejas; mientras, código), y en otros tamaños de pantalla (iPad) revisar `model.feet` del patio, que se eligió para el recorte de iPhone. `economy_sim` no simula el descanso.

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
