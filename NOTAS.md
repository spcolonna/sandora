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
  minijuego o a meditar (`_away` en `lib/ui/garden_screen.dart`, que además evita que el reloj de 20 s vuelva a
  prender el viento en un minijuego). Se apaga con el interruptor "Música" de Ajustes.
- **Verificado:** afinación del koto (< 1 cent), picos sin recorte, loops sin costura.
- **No verificado:** cómo suena. **Está pendiente que el usuario lo escuche** y pida ajustes (volumen de la música,
  reverb, brillo del koto, etc.). Regenerar: `python3 tool/gen_audio.py [prefijos]`, unos 12 s.
- Idea no hecha: silenciar nuestra música cuando el usuario ya está escuchando la suya (hoy se mezclan:
  `AVAudioSessionCategory.ambient` + `mixWithOthers`).

## Estado actual / en curso

- **Build de iOS para TestFlight: bloqueado del lado del usuario.** `flutter build ipa --release` falla con
  "No Accounts" y perfiles sin Game Center ni iCloud. Hay certificados "Apple Distribution: Sebastian Perez
  (RZGQPAGH53)" en el llavero. Falta:
  1. Xcode → Settings → Accounts → + Apple ID del equipo `RZGQPAGH53`.
  2. App Store Connect → crear la app con bundle `com.oraki.sandora` (si no existe).
  3. Después: `flutter build ipa --release` (la firma automática suma Game Center e iCloud al App ID) y subirlo
     (Transporter, Organizer de Xcode o `xcodebuild -exportArchive` con destino upload).
  Versión actual en `pubspec.yaml`: `1.0.0+1`.
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
