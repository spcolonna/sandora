# Pendientes

## Antes de la primera subida a las tiendas
- [ ] **Marca "Sandora".** El juego pasó a llamarse Sandora el 2026-10-27 ("Zen Garden" está muy usado en el App
      Store). No hay juegos ni apps con ese nombre en App Store ni en Play. Riesgos: es una marca de jugos de PepsiCo
      en Ucrania (otra clase, pero empresa grande) y se parece a "Pandora" (música, clase 9). Buscar en USPTO, EUIPO
      y MIEM, clases 9 y 41, y reservar el nombre en App Store Connect y Play Console.
- [x] Bundle id `com.oraki.sandora` (iOS y Android) y paquete Dart `sandora`. Solo la carpeta sigue como `ZenGarden`.
- [x] **Repo remoto:** `https://github.com/spcolonna/sandora` (pusheado el 2026-10-28). Siempre como spcolonna, nunca con la cuenta de Ironhide.
- [ ] Ícono, textos de tienda por idioma, política de privacidad. (El splash de Oraki Games ya está, igual que en
      Hexiege: `flutter_native_splash.yaml` + `lib/ui/brand_intro.dart`.)

## Prototipo (fase 1)
- [ ] Medir rendimiento en un Android de gama media real.
- [ ] Calibrar la latencia de audio de la lluvia en Android (`audioOffsetMs`).
- [ ] Probar con 10 personas sin explicación.
- [ ] Integrar el arte del Lote 1 (`docs/prompts.md`) cuando esté.
- [ ] Meditación: notificación local con la campana final (`flutter_local_notifications`) y objetos de racha cada 7 días
      (cuenco, cojín, farol) cuando exista el sistema de objetos.
- [ ] Integrar `store_feature` (Bloque 9, solo para la tienda). Ya están el logo, el fondo del título
      (`title_bg`) y el cartel del jardín (`ui_garden_sign`).
- [ ] Ampliaciones: los patios agrandan el jardín y el Estanque abre el Estanque de lotos; las demás zonas quedan
      "Próximamente" (`ready: false` en el balance).

## Próximo: menú y jardín vivo
- [x] **Entrada al jardín:** puertas shoji que se corren con un destello (`lib/ui/garden/garden_gate.dart`).
- [x] **Jardín como menú:** cada lugar se toca (arenero, torre, vasijas, cojín, puesto del Mercado, tablón).
      Dibujado con código hasta tener el arte del Lote 1; las posiciones están en `GardenLayout`.
- [x] **Día y noche** por la hora del dispositivo (`DayCycle`, sección `dayCycle` del balance): amanecer, día,
      atardecer y noche, faroles de noche. Regalos: rocío al amanecer (Agua) y luciérnagas de noche (Luz), 3 por día.
      Para probar otra hora: `flutter run --dart-define=SANDORA_HOUR=22`.
- [ ] **Ranking online:** el tablón muestra los récords propios y avisa que el ranking llega pronto (necesita backend).
- [ ] Más eventos del día (atardecer, día) y más lugares cuando se sumen minijuegos.
- [x] **Clima** (`lib/garden/weather.dart`, `weather_service.dart`, sección `weather` del balance): despejado,
      nublado, lluvia, tormenta, niebla y nieve. Por defecto, clima propio que cambia cada 3 horas. Opcional (se elige
      tocando el cartel de arriba a la derecha): clima real con ubicación aproximada y pronóstico de MET Norway.
      Regalos: agua de lluvia en las vasijas (Agua) y copos que brillan (Luz). Con lluvia suena la lluvia.
      Para probar: `flutter run --dart-define=SANDORA_WEATHER=rain` (clear, cloudy, rain, storm, fog, snow).
- [ ] Clima, antes de publicar: poner un contacto (web o mail) en el User-Agent de MET Norway (`_agent` en
      `weather_service.dart`), como piden sus condiciones; nombrar la ubicación y a MET Norway en la política de
      privacidad; traducir el texto del permiso de ubicación de iOS (`InfoPlist.strings`, hoy solo en inglés).
- [ ] Más eventos del clima: arcoíris cuando para de llover, charcos, hojas con viento.

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
- [ ] Lluvia: vasija que rebalsa (idea del plan, quedó para después si hace falta).
- [x] Prompts de arte: bloques 10 (estanque de lotos), 11 (shishi, hojas, musgo, bonsái) y 12 (vista del estanque).
- [x] Quitado `flame_forge2d`.
- [x] Primer toque perdido: la puerta shoji quedaba encima si se la apuraba tocando, y el jardín se recreaba al
      terminar. Ahora el jardín vive bajo una `GlobalKey` y el PageView se asienta más rápido (300 ms).

## Etapa avanzada
- [ ] **Vender lotos** (compra dentro de la app): ya son la moneda escasa del Mercado.
- [ ] **Más de un jardín:** comprar espacios para tener varios jardines con nombre (GDD, "Más de un jardín"). Implica
      pasar el estado del jardín (torre, arena, ampliaciones, nombre) a una lista por jardín en `Progress`.

## Diseño (inconsistencias del GDD)
- [x] El Apilado duraba "sin límite" contra el pilar 3 ("menos de 90 s"): ahora es una bolsa de 12 piedras.
- [ ] La regla de las esencias por zona no es uniforme (Piedra da Arena en Apilado y Madera en Musgo; Ensō da Arena).
      Ningún minijuego da Luz (la da el Modo meditación, desde el nivel 5). La Madera ya sale de hojas, musgo y bonsái.
- [x] Casa de té y Bosque de bambú cuestan Madera y ningún minijuego la da: ahora se consigue en el Mercado
      (trueque por piedritas o arena con límite diario, o por lotos).
- [ ] La zona "Piedra" no existe en la convención de nombres de assets: se usan `stack`, `moss` y `east`.
