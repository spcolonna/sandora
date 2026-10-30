# Pendientes

## Antes de la primera subida a las tiendas
- [ ] **Marca "Sandora".** El juego pasó a llamarse Sandora el 2026-10-27 ("Zen Garden" está muy usado en el App
      Store). No hay juegos ni apps con ese nombre en App Store ni en Play. Riesgos: es una marca de jugos de PepsiCo
      en Ucrania (otra clase, pero empresa grande) y se parece a "Pandora" (música, clase 9). Buscar en USPTO, EUIPO
      y MIEM, clases 9 y 41, y reservar el nombre en App Store Connect y Play Console.
- [x] Bundle id `com.oraki.sandora` (iOS y Android) y paquete Dart `sandora`. Solo la carpeta sigue como `ZenGarden`.
- [x] **Repo remoto:** `https://github.com/spcolonna/sandora` (pusheado el 2026-10-28). Siempre como spcolonna, nunca con la cuenta de Ironhide.
- [x] Ícono de la app (`flutter_launcher_icons.yaml`, original en `store/icon/`). El splash de Oraki Games ya está,
      igual que en Hexiege: `flutter_native_splash.yaml` + `lib/ui/brand_intro.dart`.
- [x] Textos de tienda en 5 idiomas y declaraciones de privacidad (`docs/store-listing.md`), política de privacidad
      bilingüe lista para publicar (`docs/privacy/index.html`). Falta: el contacto y publicar la página.

## Prototipo (fase 1)
- [ ] Medir rendimiento en un Android de gama media real.
- [ ] Calibrar la latencia de audio de la lluvia en Android (`audioOffsetMs`).
- [ ] Probar con 10 personas sin explicación.
- [ ] Integrar el arte del Lote 1 (`docs/prompts.md`) cuando esté.
- [x] Meditación: notificación local con la campana final (`lib/garden/reminders.dart`), por si la app queda en
      segundo plano.
- [x] Meditación: objetos de racha cada 7 días (`meditation.streakObjects` del balance): cuenco tibetano, cojín de
      brocado y farol de papel que de noche se enciende, junto al cerezo. Son de la cuenta. Dibujados con código hasta
      tener arte.
- [ ] Integrar `store_feature` (Bloque 9, solo para la tienda). Ya están el logo, el fondo del título
      (`title_bg`) y el cartel del jardín (`ui_garden_sign`).
- [x] Ampliaciones: los patios agrandan el jardín; el Estanque abre el Estanque de lotos, la Sala de caligrafía el
      Ensō y el Templo la Campana (`unlocks.zones` en el balance).
- [x] **Vista del bosque** (tercera página del jardín): Casa de té (Matcha, Madera), Bosque de bambú (Flauta, Madera)
      y Río (Linternas, Agua). Ya no queda ninguna zona "Próximamente". Dibujados con código hasta tener el arte del
      Bloque 14. Probar: `--dart-define=SANDORA_GAME=matcha` (flute, lanterns).
  - Matcha: batir en zigzag al ritmo de la cuenta; tres tramos de 6 s con ritmos distintos; la espuma crece con cada
    batida a tiempo.
  - Flauta: las ráfagas llegan por la fila de uno de los 4 huecos; hay que mantenerlo tapado mientras pasan. Notas
    sintetizadas (re pentatónica, `sfx_flute_note_01–04`); reemplazar por grabaciones reales.
  - Linternas: hasta 4 piedras por linterna (tocar pone o saca, arrastrar mueve) y se toca la linterna para
    soltarla. La corriente es determinista; un test comprueba que cada linterna se puede llevar al muelle.
- [x] Matcha: el té servido recibe visitas que dejan regalos (balance `teaVisits`).
- [x] Ensō: el mejor trazo se guarda (`enso.ink`) y se cuelga en el rollo del pabellón, en lugar del que trae el dibujo.

## Próximo: menú y jardín vivo
- [x] **Entrada al jardín:** puertas shoji que se corren con un destello (`lib/ui/garden/garden_gate.dart`).
- [x] **Jardín como menú:** cada lugar se toca (arenero, torre, vasijas, cojín, puesto del Mercado, tablón).
      Dibujado con código hasta tener el arte del Lote 1; las posiciones están en `GardenLayout`.
- [x] **Día y noche** por la hora del dispositivo (`DayCycle`, sección `dayCycle` del balance): amanecer, día,
      atardecer y noche, faroles de noche. Regalos: rocío al amanecer (Agua) y luciérnagas de noche (Luz), 3 por día.
      Para probar otra hora: `flutter run --dart-define=SANDORA_HOUR=22`.
- [ ] **Ranking online:** el tablón muestra los récords propios y avisa que el ranking llega pronto (necesita backend).
- [x] Más eventos del día: semillas que vuelan de día (Madera) y el último rayo del atardecer (Luz).
- [x] **Clima** (`lib/garden/weather.dart`, `weather_service.dart`, sección `weather` del balance): despejado,
      nublado, lluvia, tormenta, niebla y nieve. Por defecto, clima propio que cambia cada 3 horas. Opcional (se elige
      tocando el cartel de arriba a la derecha): clima real con ubicación aproximada y pronóstico de MET Norway.
      Regalos: agua de lluvia en las vasijas (Agua) y copos que brillan (Luz). Con lluvia suena la lluvia.
      Para probar: `flutter run --dart-define=SANDORA_WEATHER=rain` (clear, cloudy, rain, storm, fog, snow).
- [ ] Clima, antes de publicar: poner un contacto (web o mail) en el User-Agent de MET Norway (`_agent` en
      `weather_service.dart`), como piden sus condiciones; nombrar la ubicación y a MET Norway en la política de
      privacidad.
- [x] Permiso de ubicación de iOS traducido (`ios/Runner/*.lproj/InfoPlist.strings`, 5 idiomas).
- [x] Más eventos del clima: arcoíris un rato después de la lluvia (se toca: Luz), charcos que se secan y hojas con
      viento en algunos bloques. Probar: `--dart-define=SANDORA_AFTER_RAIN=20 --dart-define=SANDORA_WEATHER=clear`.

## Minijuegos (2026-10-28)
- [x] **Apilado nuevo:** sin Forge2D; bolsa de 12 piedras por partida (6 tipos) que se suman a la torre guardada.
      Equilibrio con azar (`StackRules`): el balanceo y el riesgo dependen de qué tan centrada cayó y de la altura;
      si cede, se cae un tramo (≈ 2·altura^0.6 según lo mal que quedó). Probar torres altas:
      `--dart-define=SANDORA_TOWER=500`.
- [x] **Vista del estanque** (deslizar o tocar "Estanque" abajo): Estanque de lotos (3 en línea), Shishi-odoshi,
      Hojas al viento, Musgo y Poda del bonsái. Todos disponibles desde el inicio.
- [x] **Desbloqueos por días de juego** (días distintos en que se abrió el jardín; sección `unlocks` del balance):
      shishi día 2, hojas día 3, musgo día 4, bonsái día 5. Se anuncian una vez al entrar. El Estanque de lotos se
      abre al comprar la ampliación Estanque (nivel 7). Probar: `--dart-define=SANDORA_DAY=7` (abre todo).
- [x] Tablón con los récords de los 8 minijuegos (los cerrados muestran "—").
- [x] **Arenero:** figura al azar sin repetir la anterior (la espiral no sale mientras se aprende), variantes de
      tamaño, giro, espejo y forma; a veces una piedrita cerca del camino que desvía el trazo (rodearla limpio suma).
- [x] **Lluvia:** chubascos (la densidad sube y baja) y ráfagas avisadas en las que las gotas caen en diagonal y se
      adelantan o atrasan hasta 0,1 s.
- [x] **Pulido de los juegos del estanque** (probados en el simulador): Shishi con caño fijo y soporte, piedra donde
      apoya, vuelco que derrama al cuenco y "toc" al volver; Musgo con el borde dibujado igual al que puntúa,
      crecimiento suave, textura moteada y porcentaje; Hojas con sombra, vuelo y borde de piedritas; Bonsái con
      follaje en nubes, ramas mejor repartidas y corte sobre la rama curva; Estanque con asentado suave.
      Probar un juego directo: `--dart-define=SANDORA_GAME=moss` (stack, sand, rain, pond, shishi, leaves, moss, bonsai).
- [x] Lluvia: la vasija se llena con los aciertos y a veces rebalsa; no resta, suena apagada hasta vaciarla con doble
      toque (bonus).
- [x] Prompts de arte: bloques 10 (estanque de lotos), 11 (shishi, hojas, musgo, bonsái) y 12 (vista del estanque).
- [x] Quitado `flame_forge2d`.
- [x] Primer toque perdido: la puerta shoji quedaba encima si se la apuraba tocando, y el jardín se recreaba al
      terminar. Ahora el jardín vive bajo una `GlobalKey` y el PageView se asienta más rápido (300 ms).

## Para la prueba con gente (2026-10-28)
- [x] **Primera partida guiada:** brillo y burbuja sobre el arenero ("Tocá un lugar"), después sobre el Mercado; quien ya
      jugaba no la ve. Cada minijuego muestra la primera vez una tarjeta con el gesto animado y qué hacer.
- [x] **Recordatorio diario** (19:00, se cambia o apaga en Ajustes): se reprograman los próximos 7 días al abrir la app,
      empezando mañana; el texto habla de la racha, la torre, la serenidad o algo tranquilo. El permiso se pide después de
      la primera partida. Probar: `--dart-define=SANDORA_REMINDER_MIN=1` (el primero llega en un minuto).
- [ ] Recordatorios en Android: probar en un teléfono real (permiso de Android 13+, reinicio del teléfono).

## Etapa avanzada
- [ ] **Vender lotos:** el código está (`lib/garden/lotus_store.dart`, `in_app_purchase`) pero apagado. Para
      prenderlo: crear los consumibles `com.oraki.sandora.lotus5`, `lotus12` y `lotus30` en App Store Connect y Play
      Console con sus precios y poner `shop.lotusPacks.enabled: true`. Falta validar recibos en un servidor si hace falta.
- [x] **Más de un jardín:** tocando el cartel se ven los jardines; uno nuevo cuesta 25 lotos desde el nivel 8 (hasta
      4, sección `gardens`). Cada uno tiene torre, arena, nombre, ampliaciones y serenidad; monedas, nivel y récords son
      de la cuenta.

## Balance (2026-10-29)
- [x] **Simulador de economía** (`test/sim/`): juega 60–90 días con el `Progress` y el balance reales para tres perfiles
      (Casual, Regular, Dedicado). Informe: `SANDORA_SIM=1 flutter test test/sim`; otro balance:
      `SANDORA_SIM_BALANCE=<archivo>`.
- [x] Rebalance v3: antes nada se ahorraba (cada ampliación se compraba el día que llegaba el nivel) y la torre daba el
      70–80 % de las piedritas. Ahora: costos de ampliaciones ×2,5 en piedritas y ×3 en esencias, torre 0,5/h, tope de
      Calma por nivel 700, sin lotos por nivel y jardín nuevo a 25 lotos. Regular: todas las zonas hacia el día 46.
- [ ] Recalibrar con la prueba de 10 personas (reparto de estrellas por perfil y caída de la torre son supuestos).
- [x] Sumidero del final: **modo Decorar**, 16 decoraciones que se compran y se ponen libres en las tres vistas
      (cada copia ×1,35). En la simulación, Regular termina con ~450 piedritas en vez de ~10.000 y gasta ~10.000 en
      decoraciones, sin atrasar las ampliaciones.
- [x] Oferta del día en el Mercado: una decoración con 40 % menos, una vez por día (`shop.deal`).
- [ ] Arte de las decoraciones: bloques 3 y 15 de `docs/prompts.md` (hoy se pintan con código).

## Diseño (inconsistencias del GDD)
- [x] El Apilado duraba "sin límite" contra el pilar 3 ("menos de 90 s"): ahora es una bolsa de 12 piedras.
- [x] Regla de las esencias: cada minijuego da la de su material (Agua, Arena, Madera; Luz de meditación, regalos y
      Campana). La esencia vive solo en el balance (`rewards.<id>.essence`) y un test la fija.
- [x] Casa de té y Bosque de bambú cuestan Madera y ningún minijuego la da: ahora se consigue en el Mercado
      (trueque por piedritas o arena con límite diario, o por lotos).
- [x] La zona "Piedra" usa `stack` y `moss` en los assets (aclarado en la convención del GDD).
