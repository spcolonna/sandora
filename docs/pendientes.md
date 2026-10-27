# Pendientes

## Antes de la primera subida a las tiendas
- [ ] **Marca "Sandora".** El juego pasó a llamarse Sandora el 2026-10-27 ("Zen Garden" está muy usado en el App
      Store). No hay juegos ni apps con ese nombre en App Store ni en Play. Riesgos: es una marca de jugos de PepsiCo
      en Ucrania (otra clase, pero empresa grande) y se parece a "Pandora" (música, clase 9). Buscar en USPTO, EUIPO
      y MIEM, clases 9 y 41, y reservar el nombre en App Store Connect y Play Console.
- [x] Bundle id `com.oraki.sandora` (iOS y Android) y paquete Dart `sandora`. Solo la carpeta sigue como `ZenGarden`.
- [ ] **Repo remoto:** crear `spcolonna/sandora` (privado) y pushear. Siempre como spcolonna, nunca con la cuenta de Ironhide.
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

## Próximo: menú y jardín vivo
- [ ] **Entrada al jardín:** dos puertas que se abren con un brillo que encandila al pasar, en lugar de un menú de
      pestañas. Desde el jardín, tocar cada zona lleva a su minijuego; el Mercado y el ranking también son lugares
      del jardín (un puesto, un tablón), no botones sueltos. Todo con el mismo lenguaje visual.
- [ ] **Día y noche** según la hora del dispositivo: el jardín se ve de día o de noche y hay eventos propios de cada
      momento.
- [ ] **Clima:** si se puede, el mismo clima que muestra el celular; si no, uno por defecto.
- [ ] Hoy el Mercado se abre con un botón en el jardín; pasa a ser un lugar del jardín con el menú nuevo.

## Etapa avanzada
- [ ] **Vender lotos** (compra dentro de la app): ya son la moneda escasa del Mercado.
- [ ] **Más de un jardín:** comprar espacios para tener varios jardines con nombre (GDD, "Más de un jardín"). Implica
      pasar el estado del jardín (torre, arena, ampliaciones, nombre) a una lista por jardín en `Progress`.

## Diseño (inconsistencias del GDD)
- [ ] El Apilado dura "sin límite" y el pilar 3 dice "menos de 90 s". Hoy se termina cuando el jugador quiere o
      cuando se cae la torre.
- [ ] La regla de las esencias por zona no es uniforme (Piedra da Arena en Apilado y Madera en Musgo; Ensō da Arena).
      Ningún minijuego inicial da Luz (ahora la da el Modo meditación, desde el nivel 5).
- [x] Casa de té y Bosque de bambú cuestan Madera y ningún minijuego la da: ahora se consigue en el Mercado
      (trueque por piedritas o arena con límite diario, o por lotos).
- [ ] La zona "Piedra" no existe en la convención de nombres de assets (`stack`, `moss`).
