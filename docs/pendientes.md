# Pendientes

## Antes de la primera subida a las tiendas
- [ ] **Marca "Sandora".** El juego pasó a llamarse Sandora el 2026-10-27 ("Zen Garden" está muy usado en el App
      Store). No hay juegos ni apps con ese nombre en App Store ni en Play. Riesgos: es una marca de jugos de PepsiCo
      en Ucrania (otra clase, pero empresa grande) y se parece a "Pandora" (música, clase 9). Buscar en USPTO, EUIPO
      y MIEM, clases 9 y 41, y reservar el nombre en App Store Connect y Play Console.
- [ ] **Nombre del paquete Dart** (`zen_garden`) y carpeta del proyecto: siguen con el nombre viejo. Se pueden
      cambiar junto con el bundle id.
- [ ] **Bundle id:** hoy es `com.spcolonna.zenGarden` (iOS) y `com.spcolonna.zen_garden` (Android), los que puso
      `flutter create`. No se pueden cambiar después de publicar: definirlos antes de publicar (por ejemplo `com.spcolonna.sandora`).
- [ ] Ícono, textos de tienda por idioma, política de privacidad. (El splash de Oraki Games ya está, igual que en
      Hexiege: `flutter_native_splash.yaml` + `lib/ui/brand_intro.dart`.)

## Prototipo (fase 1)
- [ ] Medir rendimiento en un Android de gama media real.
- [ ] Calibrar la latencia de audio de la lluvia en Android (`audioOffsetMs`).
- [ ] Probar con 10 personas sin explicación.
- [ ] Integrar el arte del Lote 1 (`docs/prompts.md`) cuando esté.
- [ ] Meditación: notificación local con la campana final (`flutter_local_notifications`) y objetos de racha cada 7 días
      (cuenco, cojín, farol) cuando exista el sistema de objetos.
- [ ] Integrar el resto del Bloque 9 (`title_bg`, `store_feature`, `ui_garden_sign`). El logo ya está (símbolo y
      nombre, en la pantalla de título); el cartel del jardín se dibuja con código.
- [ ] Ampliaciones: hoy solo los patios hacen algo; las zonas quedan "Próximamente" (`ready: false` en el balance).

## Etapa avanzada
- [ ] **Más de un jardín:** comprar espacios para tener varios jardines con nombre (GDD, "Más de un jardín"). Implica
      pasar el estado del jardín (torre, arena, ampliaciones, nombre) a una lista por jardín en `Progress`.

## Diseño (inconsistencias del GDD)
- [ ] El Apilado dura "sin límite" y el pilar 3 dice "menos de 90 s". Hoy se termina cuando el jugador quiere o
      cuando se cae la torre.
- [ ] La regla de las esencias por zona no es uniforme (Piedra da Arena en Apilado y Madera en Musgo; Ensō da Arena).
      Ningún minijuego inicial da Luz (ahora la da el Modo meditación, desde el nivel 5).
- [ ] Casa de té y Bosque de bambú cuestan Madera, pero ningún minijuego inicial da Madera.
- [ ] La zona "Piedra" no existe en la convención de nombres de assets (`stack`, `moss`).
