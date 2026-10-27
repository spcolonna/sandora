# Sandora — Game Design Document

Oct 27, 2026 · @Sebastian Pérez

## Visión y pilares

Sandora es un juego casual para móvil donde minijuegos de 30 a 90 segundos generan tokens para cuidar, mejorar y ampliar un jardín zen propio, que otros jugadores visitan y puntúan.

**Público:** cualquier edad, partidas en el ómnibus, en una sala de espera o en la fila. Pantalla vertical, con el celular en las manos y como máximo dos dedos. Se disfruta con sonido, pero se puede jugar en silencio.

**Promesa:** un rato agradable que te deja la sensación de "soy muy bueno en esto", y un jardín que es tuyo y que otros ven.

### Pilares de diseño

1. **Máximo dos dedos.** Cada minijuego se juega con el celular sostenido en las manos, usando como mucho los dos pulgares. Nunca se piden más de dos acciones al mismo tiempo. Muchos minijuegos se juegan con una sola mano, pero no es una condición obligatoria.
2. **El sonido es el alma del juego.** Lluvia, arena que se mueve, viento, piedras que se apilan y que caen: cada acción tiene su sonido, diseñado con el mismo cuidado que lo visual. El juego se recomienda con sonido. Sin sonido sigue siendo jugable, porque todo momento de timing tiene también una señal visual y una vibración.
3. **Sesiones cortas y pausables.** Cada minijuego dura menos de 90 segundos. Cerrar la app nunca hace perder lo ganado.
4. **Asistencia invisible.** Hitboxes generosos, imanes sutiles, tolerancia en el timing. El jugador ve su acierto, no la ayuda.
5. **Celebración proporcional al logro.** Bien, genial y perfecto tienen tres niveles de partículas, sonido y vibración claramente distintos.
6. **Fallar no frustra.** No hay game over duro: siempre hay un puntaje, estrellas o una altura alcanzada.
7. **El jardín es identidad.** Lo que se gana se ve. El estatus, no el poder, es lo que se compra.
8. **Nada es brusco.** Todo lo que el juego devuelve es suave: transiciones con fundido, animaciones que aceleran y frenan despacio (nunca rebotes, sacudidas ni destellos), sonidos con ataque suave y graves cálidos (madera, agua, campanas; nunca zumbidos, alarmas ni ruidos de error) y vibraciones cortas y livianas. Un error o una caída se cuentan con calma: la piedra rueda, suena un "toc" grave y el juego sigue. La celebración crece con el logro (pilar 5), pero incluso "perfecto" es un brillo cálido, no una explosión.

## Loop principal

El jugador juega minijuegos cortos, gana tokens, mejora su jardín y recibe visitas; las visitas y los eventos lo traen de vuelta.

```
Jugar un minijuego (30–90 s)
        │
        ▼
Ganar tokens (Piedritas y esencias)
        │
        ▼
Mejorar el jardín (objetos, reparar, ampliar)
        │
        ▼
Sube el puntaje (serenidad + valoración + originalidad)  ◄── Eventos: viento, gato (bajan la serenidad)
        │
        ▼
Visitas y ofrendas (te visitan y te avisan)
        │  ganas de volver
        └──────────► vuelve a "Jugar un minijuego"
```

**Sesión típica (2 a 5 minutos):** abrir la app, ver qué cambió (torre caída, bonsái crecido, ofrendas nuevas), jugar 2 o 3 minijuegos, gastar los tokens en el jardín, cerrar.

**Meta a mediano plazo (semanas):** desbloquear zonas, completar la colección de koi y objetos, subir en el ranking y ganar algún concurso semanal.

### Nivel del jardín

El nivel del jardín muestra cuánto jugó la persona en total y decide **qué tan grande puede ser su jardín**: cada ampliación pide un nivel mínimo. Se ve en el jardín, junto a la Serenidad, con una barra de Calma hasta el próximo nivel.

- Cada partida de un minijuego da **Calma** (experiencia): 10 por jugar más 10 por estrella, es decir de 10 a 40. El Modo meditación también da Calma.
- La Calma no se gasta ni baja: el nivel nunca retrocede.
- Curva inicial: el nivel 2 pide 60 de Calma y cada nivel siguiente pide 40 % más que el anterior, con un tope de 500 por nivel. Con 2 o 3 sesiones por día, el nivel 3 llega el primer día, el 5 entre el día 3 y el 4, y el 7 hacia el día 6.
- **El nivel habilita, los tokens pagan.** Llegar al nivel de una ampliación no la abre sola: la muestra como disponible y el jugador la compra con Piedritas y esencias. Así el nivel premia la constancia y los tokens siguen teniendo un destino.
- Subir de nivel tiene su propia celebración (la más grande del juego, por encima de "perfecto"): el jardín se ilumina, aparece "Nivel N" y se muestra lo que se destrabó.
- Los valores viven en `game_balance.json` (`level.xpPerRun`, `level.xpPerStar`, `level.first`, `level.growth`, `level.maxStep`, `expansions`).

| Nivel | Se destraba | Costo |
| --- | --- | --- |
| 3 | **Patio I:** el jardín inicial crece; más lugar para objetos | 120 Piedritas, 10 Arena |
| 5 | **Modo meditación** (ver más abajo) | — |
| 7 | **Estanque** (primera zona nueva: Koi y Luciérnagas) | 500 Piedritas, 30 Agua, 10 Luz |
| 9 | **Patio II:** el jardín ocupa todo el terreno | 400 Piedritas, 30 Arena, 15 Agua |
| 10 | Sala de caligrafía | 700 Piedritas, 40 Arena |
| 12 | Casa de té | 800 Piedritas, 40 Madera |
| 14 | Templo | 900 Piedritas, 40 Luz |
| 16 | Bosque de bambú | 1000 Piedritas, 40 Madera |
| 18 | Río | 1100 Piedritas, 40 Agua |

Las zonas de temporada (Cerezo, Invierno) no dependen del nivel: se abren con el evento. Costos y niveles son iniciales: se ajustan con datos del soft launch.

### Nombre del jardín

El jardín tiene nombre propio, elegido por el jugador. Es parte del pilar 7: lo que otros ven cuando visitan o en el ranking es "El jardín de la Bruma", no un número.

- Se elige la primera vez que se entra al jardín, con una sugerencia ya escrita que se puede aceptar tal cual. Se puede cambiar cuando se quiera, tocando el cartel de madera del jardín.
- Máximo 24 caracteres. Mientras no tenga nombre, el cartel invita a ponérselo.
- Como lo ven otros jugadores, entra en la moderación (ver Preguntas abiertas) cuando exista la parte social.

### Más de un jardín (etapa avanzada)

Más adelante, el jugador podrá tener **varios jardines**, cada uno con su nombre, comprando un *espacio* nuevo (con Jade, o con un precio alto en Piedritas para quien juega mucho). Cada jardín tiene sus propias ampliaciones y objetos; el nivel, las monedas y la racha de meditación son de la cuenta. Sirve para probar estilos distintos (un jardín de musgo, uno de invierno) sin desarmar el principal. No entra en el MVP: se evalúa después del lanzamiento global, cuando haya datos de cuánta gente completa su primer jardín.

## Economía

Hay cuatro monedas: dos se ganan jugando, una por constancia y una se compra. Ninguna compra puntos de ranking directamente.

| Moneda | Cómo se gana | Para qué sirve |
| --- | --- | --- |
| **Piedritas** (blanda) | Jugando cualquier minijuego; más con mejor puntaje | Reparar, comprar objetos comunes, mantener el jardín |
| **Esencias** (por zona: Agua, Arena, Madera, Luz) | Cada minijuego da la esencia de su zona; el Modo meditación da Luz | Desbloquear objetos y mejoras de esa zona; obliga a variar de minijuego |
| **Lotos** (escasa) | La ofrenda del día (la primera partida o meditación), cada nivel nuevo y cada semana de racha meditando | Trueques del Mercado sin límite diario. A futuro, también se venden |
| **Jade** (premium) | Compra; pequeñas cantidades por logros y concursos | Cosméticos premium, pase de estación, acelerar crecimiento |

### Qué se compra con tokens

- **Reparar:** devolver piedras caídas, limpiar hojas, quitar maleza. Barato, para que nunca frustre.
- **Objetos:** faroles, puentes, plantas, piedras decorativas. Cada objeto tiene una rareza, que afecta la originalidad del jardín.
- **Mejoras de minijuego:** un rastrillo mejor que deja trazos más finos, vasijas con mejor sonido, una base más ancha para apilar. Dan comodidad y estética, no puntos de ranking.
- **Ampliaciones:** agrandar el patio o abrir una zona nueva del jardín (ver Nivel del jardín y Minijuegos de ampliación). Cada una pide un nivel mínimo; cada zona trae minijuegos, objetos y su propia esencia.

### Mercado

Ningún minijuego da todas las esencias (hoy nadie da Madera). Lo que falta se consigue en el Mercado, con trueques:

- **Trueques del día:** piedritas o una esencia por otra, con un límite de veces por día. Así una moneda escasa sigue escasa y conviene volver mañana.
- **Con lotos:** sin límite diario, porque el loto ya es escaso. Es la moneda para hacer escaso algo y, más adelante, venderlo.

Diversificar las monedas permite ajustar qué es escaso sin tocar los minijuegos. Ofertas y límites viven en `game_balance.json` (`shop`).

### Reglas de balance

- Todos los valores de costos, recompensas y tiempos viven en `game_balance.json`, para ajustar sin recompilar.
- Una sesión de 3 minutos alcanza para una reparación o un objeto común. Esa es la medida base de "progreso visible por sesión".
- Una ampliación de zona cuesta entre 5 y 7 días de juego casual (2 a 3 sesiones por día). Es una cifra inicial para ajustar con datos.

## Puntaje del jardín y ranking

El puntaje del jardín suma tres partes: cuidado, valoración de visitantes y originalidad. Así no gana solo el que más juega ni solo el que más paga.

```latex
Puntaje = Serenidad \times 0.35 + Valoración \times 0.35 + Originalidad \times 0.30
```

Los pesos son iniciales y viven en `game_balance.json`. Cada componente va de 0 a 1000.

### Serenidad (cuidado)

- Sube al jugar minijuegos y reparar el jardín.
- Baja lentamente cuando no se juega: unos 5% por día sin cuidado, con un piso del 40%. Nunca se pierde todo.
- Los eventos (viento, el gato, lluvia de hojas) bajan la serenidad hasta que se reparan.
- La suscripción Jardinero frena la baja mientras el jugador no está.

### Valoración (otros jugadores)

- Al visitar un jardín, el visitante puede dejar una ofrenda (una piedrita, una flor, una linterna). Cada ofrenda suma valoración.
- Una ofrenda por visitante por día y por jardín, para evitar abuso.
- Las ofrendas de jugadores con jardines bien puntuados valen un poco más.
- La valoración decae con el tiempo (ventana de 14 días), para que el ranking se mueva.

### Originalidad (rareza e influencia)

Reemplaza la idea de penalizar copias, que es difícil de detectar y castiga a los principiantes.

- **Rareza:** cada objeto vale más cuanto menos jugadores lo usan. Se recalcula cada día en el servidor a partir del porcentaje de jardines que tienen ese objeto.
- **Combinación:** bonus por pares de objetos poco frecuentes juntos (por ejemplo, un farol de nieve junto a un estanque de koi).
- **Influencia:** si un jugador "sigue" tu jardín o guarda una de tus composiciones como inspiración, sumás Influencia. Que te copien pasa a ser un logro.
- **Obra propia:** los dibujos del arenero y los ensō de caligrafía son únicos por definición y siempre suman originalidad.

### Ranking

- Rankings separados: global, por país, entre amigos y concurso semanal temático.
- El concurso semanal ("Jardín de otoño", "Solo piedras") se decide por votos de la comunidad y da un objeto exclusivo al top 100.
- **Jardín privado:** opción gratuita para quien no quiere ser visitado. Un jardín privado no aparece en el ranking global.
- Nada que se compre suma puntos directamente. El Jade compra objetos, y los objetos aportan rareza como cualquier otro.

## Minijuegos del jardín inicial

El jardín inicial trae 7 minijuegos: 3 desde el primer minuto y 4 que se desbloquean en la primera semana. Cada uno da Piedritas y la esencia de su zona.

| Minijuego | Zona / esencia | Desbloqueo | Gesto | Duración |
| --- | --- | --- | --- | --- |
| Apilado de piedras | Piedra / Arena | Inicio | Tocar para soltar | Sin límite |
| Arenero | Arena / Arena | Inicio | Trazo continuo | 20–40 s |
| Lluvia en vasijas | Techo / Agua | Inicio | Tocar a tiempo | 60–90 s |
| Shishi-odoshi | Agua / Agua | Día 2 | Mantener y soltar | 45 s |
| Hojas al viento | Camino / Madera | Día 3 | Deslizar | 30 s |
| Musgo | Piedra / Madera | Día 4 | Pintar con el dedo | 30–45 s |
| Poda del bonsái | Bonsái / Madera | Día 5 | Cortar deslizando | 20–40 s |

### Apilado de piedras

**Qué busca:** la tensión suave de "una más" y una recompensa pasiva que crece con el tiempo.

**Gameplay:** una piedra se balancea arriba de la pantalla. El jugador toca para soltarla sobre la torre. La torre queda en el jardín y **genera Piedritas por hora según su altura**. En cualquier momento un evento puede tirarla: ráfaga de viento (avisada 3 segundos antes con hojas volando) o el gato de la vecina.

**Puntaje:** altura de la torre más un bonus por piedra "perfecta" (centrada dentro del 10%).

**Asistencia invisible:** un imán sutil hacia el centro y física amortiguada en las primeras 5 piedras.

**Defensa ante eventos:** durante el aviso de viento, tocar la torre la "sostiene" (gesto de mantener). Si se cae, queda registrada la altura récord.

### Arenero

**Qué busca:** la sensación de "lo dibujé yo" y la obra única que suma originalidad.

**Gameplay:** aparece una figura guía tenue en la arena (círculo, ola, espiral, hoja, montaña). El jugador la recorre sin levantar el dedo. Al terminar, la guía desaparece y **un rastrillo recorre el trazo del jugador**, dejando surcos con líneas paralelas. El dibujo queda en el jardín hasta el próximo.

**Puntaje:** precisión (distancia media a la guía), continuidad (sin cortes) y suavidad (pocos cambios bruscos de dirección). Hasta 3 estrellas.

**Asistencia invisible:** el trazo se suaviza en tiempo real y la tolerancia de distancia es amplia en las primeras figuras.

**Modo libre:** desbloqueado después de 10 figuras. Dibujás lo que quieras y queda en tu jardín para los visitantes.

### Lluvia en vasijas

**Qué busca:** el juego rítmico del jardín, relajante y con sensación de flow.

**Gameplay:** comienza con la silueta de una persona meditando bajo un techo. La cámara sube hasta el alero, donde hay de 3 a 5 vasijas. Empieza a llover y las gotas caen del techo hacia las vasijas. El jugador toca la vasija en el momento en que la gota la alcanza. Cada vasija tiene una nota distinta, afinadas en una escala pentatónica, así que cualquier secuencia de aciertos suena bien.

**Puntaje:** combo de aciertos; "bien", "genial" y "perfecto" según la ventana de tiempo. Al final, la cámara baja al meditador y el puntaje aparece como "profundidad de meditación".

**Asistencia invisible:** ventana de acierto de ±120 ms para "bien" y ±40 ms para "perfecto". Sin sonido, cada gota proyecta un anillo que se cierra sobre la vasija, para jugar mirando.

**Progresión:** más vasijas, lluvia más densa, gotas dobles. Tormentas como evento de temporada.

### Shishi-odoshi

**Qué busca:** un solo gesto con un "toc" muy satisfactorio.

**Gameplay:** el bambú se llena de agua mientras el jugador mantiene el dedo apretado. Hay que soltar justo antes de que rebalse. Si soltás en la zona ideal, el bambú golpea la piedra con un "toc" limpio. Si soltás temprano, el golpe es débil; si te pasás, el agua se derrama. Cada ronda cambia la velocidad del chorro.

**Puntaje:** precisión del soltado en cada una de 10 rondas.

**Asistencia invisible:** el nivel de agua tiembla levemente al entrar en la zona ideal.

### Hojas al viento

**Qué busca:** orden a partir del caos, con mínimo esfuerzo.

**Gameplay:** hojas caídas sobre el camino de piedra. El jugador desliza para barrerlas hacia un montón. Cada tanto, el viento las desordena un poco. Al terminar, el montón se convierte en abono para el jardín.

**Puntaje:** porcentaje de hojas en el montón y cantidad de gestos usados (menos es mejor).

**Asistencia invisible:** el área de barrido es más ancha que el dedo, y las hojas cercanas al montón se "enganchan".

### Musgo

**Qué busca:** relajación pura, tipo "colorear sin salirse".

**Gameplay:** el jugador pinta musgo sobre las piedras con el dedo, sin tocar la arena que las rodea. El musgo cubre las piedras del jardín de forma permanente y crece un poco solo cada día.

**Puntaje:** porcentaje de piedra cubierta menos la arena manchada.

**Asistencia invisible:** el pincel se ajusta al borde de la piedra cuando el dedo está cerca.

### Poda del bonsái

**Qué busca:** algo que crece en tiempo real y da un motivo para volver cada día.

**Gameplay:** el bonsái crece en tiempo real (unas horas por rama nueva). El jugador ve una silueta guía y corta con un deslizamiento las ramas que se salen de ella. El bonsái cambia de forma a lo largo de semanas y se puede elegir entre varias siluetas.

**Puntaje:** precisión del corte respecto a la silueta y salud del árbol (no cortar de más).

**Asistencia invisible:** el corte se "acomoda" al nodo de rama más cercano.

## Minijuegos de ampliación

Cada ampliación abre una zona nueva con 1 o 2 minijuegos propios, objetos exclusivos y su esencia. El orden sugerido va de lo más fácil de producir a lo más complejo, y cada zona pide un nivel mínimo del jardín.

| Orden | Zona | Nivel | Minijuegos | Esencia |
| --- | --- | --- | --- | --- |
| 1 | Estanque | 7 | Koi, Luciérnagas (de noche) | Agua / Luz |
| 2 | Sala de caligrafía | 10 | Ensō | Arena |
| 3 | Casa de té | 12 | Matcha | Madera |
| 4 | Templo | 14 | Campana, Gongs | Luz |
| 5 | Bosque de bambú | 16 | Flauta de bambú | Madera |
| 6 | Río | 18 | Linternas flotantes | Agua |
| Temporada | Cerezo (primavera) | — | Pétalos | Luz |
| Temporada | Invierno | — | Nieve en las ramas | Agua |

### Estanque: Koi

**Qué busca:** colección y cariño por algo vivo; es el gran motor de retención a largo plazo.

**Gameplay:** el jugador toca el agua para crear ondas. Los koi siguen las ondas, y hay que guiarlos hacia la comida que cae. Si dos ondas convergen sobre la comida, los peces forman una espiral y el puntaje se multiplica.

**Puntaje:** comida consumida y cantidad de espirales.

**Meta:** los koi bien alimentados crecen y, con dos koi adultos, se puede criar una cría con mezcla de patrones. Hay variedades raras, y un koi raro aporta mucha originalidad al jardín.

### Estanque: Luciérnagas

**Qué busca:** un juego tranquilo para la noche real del jugador.

**Gameplay:** de noche (según la hora local) aparecen luciérnagas sobre el estanque. El jugador traza líneas entre ellas para formar constelaciones guía. Las constelaciones completadas quedan brillando en el cielo del jardín esa noche.

**Puntaje:** constelaciones completadas y luciérnagas que no se escaparon.

### Sala de caligrafía: Ensō

**Qué busca:** el "soy muy bueno en esto" más puro. Fácil de entender, casi imposible de perfeccionar.

**Gameplay:** un solo trazo circular con pincel. El ancho del trazo varía con la velocidad del dedo, como tinta real. Más adelante: kanjis simples (agua, árbol, paz) trazo a trazo.

**Puntaje:** redondez, cierre del círculo, constancia de velocidad y ancho del trazo. El mejor ensō se cuelga en el jardín.

**Asistencia invisible:** suavizado del trazo; la tolerancia de redondez es amplia hasta "perfecto", que exige precisión real.

### Casa de té: Matcha

**Qué busca:** ritmo con el cuerpo, más físico que el de la lluvia.

**Gameplay:** el jugador bate el matcha con movimientos de zigzag. Un indicador muestra el ritmo ideal. La espuma va creciendo según la constancia. El té servido sirve para recibir visitas de NPCs que dejan regalos.

**Puntaje:** calidad de la espuma (constancia y velocidad del zigzag).

### Templo: Campana

**Qué busca:** un gesto único con un sonido grave y profundo.

**Gameplay:** el jugador arrastra hacia atrás el tronco que golpea la campana y lo suelta. La fuerza justa da el sonido perfecto; poca fuerza suena opaco, demasiada suena estridente.

**Puntaje:** precisión de la fuerza en 5 golpes, con la zona ideal cambiando cada vez.

### Templo: Gongs

**Qué busca:** el segundo juego rítmico, con secuencias para repetir.

**Gameplay:** un monje toca una secuencia corta en 3 a 5 gongs y cuencos tibetanos. El jugador la repite tocando cada gong en el ritmo correcto. Las secuencias se alargan con cada ronda.

**Puntaje:** secuencias correctas y precisión rítmica.

### Bosque de bambú: Flauta

**Qué busca:** crear una melodía propia sin saber música.

**Gameplay:** el viento pasa por una caña de bambú con 4 huecos. El jugador tapa y destapa huecos cuando pasan las ráfagas marcadas. Las melodías usan escala pentatónica, así que suenan bien aunque haya errores.

**Puntaje:** notas acertadas y fluidez.

### Río: Linternas flotantes

**Qué busca:** un puzzle de física suave, visualmente el más lindo.

**Gameplay:** linternas de papel bajan por el río. El jugador coloca de 2 a 4 piedras en la corriente antes de soltarlas para desviarlas hasta la orilla correcta. Si una se apaga, se reintenta sin castigo.

**Puntaje:** linternas que llegan encendidas y piedras usadas (menos es mejor).

### Cerezo (temporada de primavera): Pétalos

**Qué busca:** un evento de temporada con objetos limitados.

**Gameplay:** los pétalos caen del cerezo con el viento. El jugador arrastra un cuenco con el dedo para atraparlos. Los pétalos dorados y dobles valen más; las ramitas secas restan.

**Puntaje:** pétalos atrapados, con multiplicador por racha.

### Invierno (temporada): Nieve en las ramas

**Qué busca:** variar el ritmo con algo de urgencia, dentro de lo amable.

**Gameplay:** la nieve se acumula en las ramas del jardín. El jugador toca las ramas cargadas para sacudirlas antes de que se quiebren. Las ramas cargadas se curvan y cambian de color como aviso.

**Puntaje:** ramas salvadas. Una rama quebrada no se pierde: se repara con Piedritas.

## Modo meditación

Un temporizador para meditar de verdad dentro del jardín. Se desbloquea en el **nivel 5 del jardín**, cuando el jugador ya tiene algo propio y el modo no compite con los minijuegos del primer día. Es lo que lleva el nombre del juego a la práctica, y ninguno de los competidores revisados lo combina con un jardín que progresa.

**Cómo funciona:**
- Se entra desde el meditador del jardín. El jugador elige la duración: 3, 5, 10, 15 o 20 minutos, o una a medida de hasta 60.
- Elige el fondo de sonido entre los ambientes que ya desbloqueó (lluvia, viento, río, bambú), o silencio.
- Una campana marca el comienzo y el final; opcionalmente, campanas de intervalo cada 5 minutos.
- La pantalla muestra el jardín propio en penumbra, un contador grande y un círculo que respira (inhalar 4 s, exhalar 6 s) como guía opcional.
- El teléfono puede quedar boca abajo o con la pantalla apagada: el tiempo sigue contando, con la campana final como notificación local.

**Recompensa: más tiempo, más puntos, con techo.** No hay forma de comprobar que la persona medita, así que la recompensa crece con el tiempo pero se limita por día, para que dejar el teléfono sobre la mesa no sea la mejor estrategia del juego.

| Duración | Piedritas | Luz | Calma | Serenidad |
| --- | --- | --- | --- | --- |
| 3 min | 15 | 1 | 15 | +20 |
| 5 min | 30 | 2 | 25 | +35 |
| 10 min | 70 | 4 | 45 | +60 |
| 15 min | 110 | 6 | 60 | +80 |
| 20 min | 150 | 8 | 75 | +100 |

- La recompensa sube un poco más que proporcional hasta los 20 minutos, para premiar sesiones largas. Pasados los 20 minutos en el día, el tiempo extra no suma más tokens: meditar más sigue disponible, pero sin recompensa.
- **Sesión completa:** terminar la duración elegida da la recompensa entera. Si se corta antes, cobra lo meditado por minuto, sin el bonus de sesión completa.
- **Racha de meditación:** días seguidos con al menos una sesión de 3 minutos. Usa la misma regla de perdón que la racha diaria (un día perdido por semana). Cada 7 días de racha da un objeto exclusivo para el jardín: cuenco tibetano, cojín de meditación, farol de piedra de luz.
- La meditación es la única fuente de Luz en el jardín inicial, lo que también resuelve que ningún minijuego inicial diera esa esencia.
- La meditación suma Serenidad, pero no puntos de ranking directamente, igual que el resto del juego.
- Todos los valores viven en `game_balance.json` (`meditation.unlockLevel`, `meditation.rewards`, `meditation.dailyCapMinutes`).

**Controles anti-abuso, livianos:**
- La recompensa se calcula con el reloj real, no con el reloj del juego. Si el sistema cierra la app, la sesión se retoma al abrirla, con el tiempo transcurrido hasta el máximo elegido.
- Una sola sesión con recompensa a la vez. No se puede acelerar con anuncios ni con Jade.
- No se usa el acelerómetro para "vigilar" al jugador: rompería el clima. El techo diario alcanza.

**Integraciones (fase 3):** guardar los minutos en Apple Health (Mindful Minutes) y Health Connect en Android, con permiso explícito. Es un motivo de retención fuera del juego y un argumento para la ficha de la tienda.

**Celebración:** al final, sin estrellas ni "bien/genial/perfecto". La campana suena, el jardín se ilumina de a poco y aparece "X minutos de calma" con las recompensas. Meditar no se califica.

## Retención

El jugador vuelve por tres motivos: algo cambió en su jardín, alguien lo visitó, y hay algo que no quiere perder. La pérdida tiene que dar ganas de volver, nunca culpa.

### Cosas que cambian solas

- **Crecimiento en tiempo real:** bonsái, musgo, koi. Al abrir la app siempre hay algo nuevo para ver.
- **Torre de piedras:** genera Piedritas por hora mientras sigue en pie. Volver a cobrar es un motivo diario.
- **Ciclo día/noche real:** el jardín se ve distinto a la mañana y a la noche; las luciérnagas solo aparecen de noche.
- **Estaciones reales:** el jardín cambia según la estación del hemisferio del jugador. Cada estación trae objetos y un minijuego propio.

### Eventos

- **Ráfagas de viento:** tiran la torre y desordenan hojas. Se avisan unos segundos antes si el jugador está mirando.
- **Lluvia de hojas:** en otoño, el camino se llena de hojas más seguido.
- **El gato de la vecina:** personaje recurrente con nombre y personalidad, mascota del juego. Tira piedras, pisa el arenero, se duerme en el puente. Pero a veces deja "regalos": objetos raros que no se consiguen de otra forma. El jugador lo odia y lo quiere a la vez.

### Social

- **Visitas y ofrendas:** notificación "Alguien dejó una flor en tu jardín". Las ofrendas recibidas se ven en el jardín por unos días.
- **Seguir jardines:** recibís un aviso cuando un jardín que seguís cambia.
- **Concurso semanal temático** votado por la comunidad, con objeto exclusivo para los ganadores.

### Hábito diario

- **Tarea del día:** 3 pequeños desafíos ("apilá 8 piedras", "conseguí un ensō de 3 estrellas") con recompensa de esencias.
- **Racha con perdón:** la racha de días seguidos tolera un día perdido por semana, para no castigar a quien tuvo un día ocupado.
- **Meditación diaria:** desde el nivel 5, una sesión corta mantiene la racha de meditación (ver Modo meditación).
- **Notificaciones medidas:** como máximo 1 por día, y solo por algo real (visita, torre caída, bonsái listo para podar).

## Monetización

Pagar da opciones y estatus, nunca puntos directos. Si el ranking se puede comprar, deja de valer y nadie paga por él.

| Fuente | Qué ofrece | Motivación que aprovecha | Precio de referencia |
| --- | --- | --- | --- |
| Objetos cosméticos premium | Piedras raras, faroles, variedades de koi, sets de estación | Estatus, identidad | Paquetes de Jade de USD 0.99 a 19.99 |
| Pase de estación | Camino de recompensas por temporada, gratis y pago | Colección, progreso | USD 4.99 por estación (unos 3 meses) |
| Suscripción Jardinero | Un monje cuida el jardín sin jugar (frena la baja de Serenidad) + 20% más de tokens | Aversión a la pérdida | USD 2.99 por mes |
| Anuncios recompensados | Doblar tokens de una partida; que el monje reacomode una torre caída | Comodidad | Gratis para el jugador |
| Sin anuncios | Quita la opción de anuncios y da tokens dobles de por vida en un minijuego | Comodidad | USD 3.99, pago único |
| Estatus en ranking | Marcos de jardín, firma del autor, efectos al visitarte | Ego, reconocimiento | Dentro de los paquetes de Jade |

Los precios son referencias iniciales para validar con pruebas A/B.

### Reglas

- **Sin anuncios intersticiales.** Un anuncio a la fuerza en medio de un juego zen rompe el clima. Solo anuncios que el jugador elige ver.
- **Sin "energía" ni vidas.** Se puede jugar todo lo que se quiera; lo que se limita es cuánto rinde cada minijuego repetido el mismo día.
- **Ofertas de bienvenida** solo después de la primera semana, cuando el jugador ya tiene algo propio que embellecer.
- **Ventana de destacados:** el "jardín destacado del día" se gana por votos. Un empujón pago de visibilidad es posible, pero limitado y marcado como promocionado.

## Viabilidad técnica en Flutter

Sí: todos los efectos y animaciones del documento, incluidos los koi, se pueden hacer en Flutter con calidad de producción en iOS y Android. Steam es viable para una segunda etapa, con dos riesgos acotados: adaptar la pantalla vertical y depender de un paquete de Steamworks chico.

### Stack recomendado

| Pieza | Herramienta | Para qué |
| --- | --- | --- |
| Motor de juego | [Flame](https://gamedev.net/news/topic/flame-engine/) 1.38.x, compatible con Flutter 3.47 | Loop de juego, componentes, input, cámara |
| Física | flame_forge2d 0.20 (basado en Box2D v3) | Apilado de piedras, linternas en el río |
| Animación vectorial | [Rive](https://pub.dev/packages/rive) 0.14 (runtime nativo en C++) | Monje, gato, meditador, UI animada |
| Efectos de GPU | [Fragment shaders](https://docs.flutter.dev/ui/design/graphics/fragment-shaders) (GLSL) con Impeller | Agua, ondas, arena, tinta, lluvia, día/noche |
| Estado y arquitectura | Riverpod, go_router; capas Domain / Infrastructure / Delivery | Fuera del juego: jardín, tienda, ranking |
| Backend | Firebase: Auth, Firestore, Storage, Cloud Functions | Jardines, visitas, ofrendas, rareza diaria, ranking |
| Balance | `game_balance.json` | Costos, recompensas, pesos del puntaje |

**Audio:** como el sonido es un pilar, conviene un motor de audio de baja latencia con mezcla de varias capas a la vez (ambiente de lluvia o viento + efectos + notas), variaciones aleatorias de tono y volumen en cada efecto para que no suene repetido, y grabaciones reales (piedra, arena, agua) en lugar de sonidos sintéticos.

### Efecto por efecto

| Efecto | Técnica | Dificultad | Riesgo |
| --- | --- | --- | --- |
| Koi nadando | Cuerpo procedural: cadena de 8 a 12 segmentos que siguen a la cabeza con ondulación senoidal; textura de patrón por variedad | Media | Bajo. Es la técnica estándar para peces 2D y queda muy orgánica |
| Ondas en el agua | Shader de ondas: cada toque agrega una onda (posición, tiempo) como uniform; refracción del fondo | Media | Bajo. Limitar a unas 8 ondas simultáneas |
| Surcos del rastrillo | Se dibuja el trazo como path; un shader de relieve sobre una textura de arena genera los surcos paralelos | Media-alta | Medio. Probar temprano en Android de gama media |
| Trazo de tinta (ensō) | Trazo de ancho variable según velocidad, con textura de pincel y bordes irregulares | Media | Bajo |
| Lluvia y gotas | Partículas de Flame + splash por sprite o shader | Baja | Bajo |
| Apilado con física | Forge2D con amortiguación y un imán al centro aplicado como fuerza | Media | Bajo. Ajustar la estabilidad con varias piedras |
| Personajes (monje, gato) | Rive con state machines (caminar, dormir, empujar piedra) | Media | Bajo |
| Día/noche y estaciones | Shader de gradación de color sobre la escena + capas de sprites por estación | Baja | Bajo |
| Luciérnagas | Partículas con brillo aditivo y movimiento por ruido | Baja | Bajo |
| Hápticos con niveles | Plugin de hápticos con patrones personalizados (Core Haptics en iOS) | Baja | Medio. Android varía mucho entre fabricantes |
| Juego rítmico | Se juzga contra el reloj del juego, no del audio; el audio se calibra con un offset | Media | Medio. La latencia de audio en Android requiere calibración |

### Límites a tener en cuenta

- Flutter solo admite **fragment shaders**, no vertex shaders. Para este juego alcanza: todo lo de agua, arena y luz es por píxel.
- Los shaders pesados deben medirse en un Android de gama media real desde el primer prototipo. Conviene tener una versión "baja calidad" de cada shader.
- El arte procedural (koi, trazos, agua) es donde el código rinde más. El arte pintado a mano (fondos, objetos) conviene producirlo aparte con consistencia de estilo.

### Steam (etapa futura)

- Flutter compila para Windows, macOS y Linux (Steam Deck incluido).
- Para logros, nube y overlay existe [flame_steamworks](https://pub.dev/packages/flame_steamworks), basado en el paquete steamworks vía FFI. Solo soporta escritorio y tiene pocas descargas, así que puede requerir mantenimiento propio.
- **Pantalla:** el juego es vertical. En escritorio, el minijuego ocupa el centro y el jardín se ve a los lados. Hay que diseñar la UI con esto en mente desde el inicio.
- **Input:** tocar y deslizar se traducen a clic y arrastre; funciona bien para todos los minijuegos.
- **Monetización distinta:** en Steam conviene precio único (USD 4.99 a 9.99) con DLC cosméticos, sin anuncios ni suscripción. La economía tiene que poder desactivar esas partes por plataforma.

## Assets: lista, nombres y orden de producción

El lanzamiento necesita unos 120 assets (lotes 1 a 3); el juego completo con ampliaciones y estaciones, unos 250, más el catálogo cosmético que crece por temporada. Las cifras son estimaciones iniciales.

### Convención de nombres

`{tipo}_{zona}_{nombre}_{nn}.{ext}`, todo en minúsculas y con guion bajo.

| Prefijo | Tipo | Formato |
| --- | --- | --- |
| `bg` | Fondo o capa de fondo | PNG/WebP, 1080×1920 |
| `tex` | Textura repetible | PNG, 512×512 tileable |
| `obj` | Objeto del jardín o del minijuego | PNG con alfa, 512 px |
| `spr` | Sprite o sprite sheet animado | PNG + JSON de Flame |
| `char` | Personaje animado | `.riv` (Rive) |
| `fx` | Partícula o efecto | PNG 128 px |
| `ui` / `icon` | Interfaz e íconos | SVG o PNG @3x |
| `shd` | Shader | `.frag` (GLSL) |
| `sfx` / `mus` | Sonido / música | OGG (Android), M4A o CAF (iOS) |

Zonas: `base`, `stack`, `sand`, `rain`, `shishi`, `leaves`, `moss`, `bonsai`, `pond`, `callig`, `tea`, `temple`, `bamboo`, `river`, `sakura`, `winter`, `shop`.

### Lote 0: guía de estilo (antes de todo)

Paleta por estación, una imagen clave del jardín, hoja de referencia de piedras y plantas, tipografía. Sin esto, el resto del arte sale inconsistente. Unos 5 entregables.

### Lote 1: MVP jugable (jardín + 3 minijuegos) — unos 68 assets

| Asset | Cantidad | Notas |
| --- | --- | --- |
| `bg_base_sky`, `bg_base_far`, `bg_base_ground`, `bg_base_foliage` | 4 | Capas con parallax; día/noche por shader |
| `tex_sand_base`, `tex_sand_height` | 2 | Arena y mapa de alturas para los surcos |
| `obj_stack_stone_01` a `_06` | 6 | Piedras de apilado de distintas formas |
| `obj_base_*` (farol, puente, pino, bambú chico, 4 piedras decorativas, 2 plantas) | 10 | Catálogo inicial del jardín |
| `spr_sand_rake_01` | 1 | Rastrillo que recorre el trazo |
| `bg_rain_roof` | 1 | Alero con vigas |
| `obj_rain_vessel_01` a `_05` | 5 | Vasijas de distintos tamaños |
| `fx_rain_drop`, `fx_rain_splash` | 2 | Gota y salpicadura |
| `char_meditator.riv`, `char_cat.riv`, `char_monk.riv` | 3 | Personajes con state machines |
| `icon_pebble`, `icon_essence_water/sand/wood/light`, `icon_jade`, `icon_star` | 7 | Monedas y estrellas |
| `ui_*` (botón, panel, marco de puntaje, barra de serenidad, resultado, pausa) | 6 | Interfaz base |
| `icon_app` | 1 | Ícono de la app |
| `sfx_stack_place_01–03`, `sfx_stack_fall`, `sfx_rain_note_01–05`, `sfx_sand_rake`, `sfx_base_wind`, `sfx_cat_meow`, `sfx_ui_tap`, `sfx_ui_perfect` | 14 | Notas de vasijas en escala pentatónica |
| `mus_base_garden`, `mus_rain_ambient` | 2 | Loops |
| `shd_water_ripple`, `shd_sand_groove`, `shd_daynight`, `shd_ink_stroke` | 4 | Código, no arte |

### Lote 2: resto del jardín inicial y Modo meditación — unos 41 assets

| Minijuego | Assets principales | Cantidad |
| --- | --- | --- |
| Shishi-odoshi | `char_shishi.riv` (bambú animado), `obj_shishi_stone`, `fx_shishi_water` | 3 |
| Hojas al viento | `obj_leaves_leaf_01–04`, `obj_leaves_pile`, `tex_leaves_path` | 6 |
| Musgo | `tex_moss`, `obj_moss_rock_01–04` | 5 |
| Poda del bonsái | `spr_bonsai_trunk`, `spr_bonsai_branch_01–05`, `obj_bonsai_pot`, siluetas guía (vectoriales, 3) | 10 |
| Sonido | `sfx_shishi_toc`, `sfx_shishi_fill`, `sfx_leaves_sweep`, `sfx_moss_paint`, `sfx_bonsai_cut`, y 3 más | 8 |
| Modo meditación | `ui_meditation_breath` (círculo), `obj_meditation_bowl`, `obj_meditation_cushion`, `obj_meditation_lantern`, `sfx_meditation_bell_start`, `sfx_meditation_bell_end`, `sfx_meditation_bell_interval`, `mus_meditation_river`, `mus_meditation_bamboo` | 9 |

### Lote 3: economía, social y tienda — unos 20 assets

Pantallas de tienda (6), ranking y visita (4), íconos de ofrendas (6), marcos premium de jardín (4).

### Lote 4: ampliaciones — unos 70 assets

| Orden | Zona | Assets principales | Cantidad |
| --- | --- | --- | --- |
| 1 | Estanque | `bg_pond`, `tex_koi_pattern_01–08` (variedades), `obj_pond_lily_01–03`, `obj_pond_food`, `fx_pond_firefly`, 4 sfx | 18 |
| 2 | Caligrafía | `bg_callig_room`, `tex_callig_paper`, `tex_callig_brush`, 5 guías de kanji, 2 sfx | 10 |
| 3 | Casa de té | `bg_tea_room`, `obj_tea_bowl`, `obj_tea_whisk`, `tex_tea_foam`, `char_tea_guest.riv`, 3 sfx | 8 |
| 4 | Templo | `bg_temple`, `obj_temple_bell`, `obj_temple_log`, `obj_temple_gong_01–03`, `obj_temple_bowl_01–02`, 8 sfx | 16 |
| 5 | Bambú | `bg_bamboo`, `obj_bamboo_flute`, `fx_bamboo_wind`, 5 notas de flauta | 8 |
| 6 | Río | `bg_river`, `obj_river_lantern_01–03`, `obj_river_stone_01–03`, `shd_river_flow`, 2 sfx | 10 |

### Lote 5: estaciones — unos 18 assets

Cerezo (árbol, 3 pétalos, cuenco, 2 sfx), invierno (textura de nieve, 3 ramas, capa de nieve, 2 sfx) y 4 superposiciones de color de estación para el jardín base.

### Lote 6: catálogo cosmético (continuo)

Primer lote de 40 objetos premium para el lanzamiento de la tienda; después, unos 15 a 20 por temporada para el pase de estación.

### Por qué este orden

- Los lotes 1 y 2 se pueden empezar con placeholders: la jugabilidad se valida antes de invertir en arte final.
- Los shaders y el koi procedural son código, así que se desarrollan en paralelo con el arte.
- El estanque va primero en las ampliaciones porque los koi son el mayor motor de retención y de originalidad.

## Roadmap y preguntas abiertas

El primer paso es un prototipo de 3 minijuegos para validar la sensación al tacto antes de invertir en arte final. Las duraciones son estimaciones para una persona con ayuda de IA.

| Fase | Duración aprox. | Contenido | Prueba para pasar a la siguiente |
| --- | --- | --- | --- |
| 1 · Prototipo | 4 semanas | Apilado, Arenero y Lluvia con placeholders; koi y shaders en paralelo. Medir rendimiento en un Android de gama media desde el primer día. | 10 personas lo juegan sin explicación y piden otra partida |
| 2 · MVP y soft launch | 8 semanas | Jardín, economía, nivel del jardín, 7 minijuegos, Modo meditación, Firebase, arte de los lotes 1 y 2. Lanzamiento en 1 o 2 países chicos. | Retención de día 1 y día 7 en objetivo; sesiones de 2 a 5 min |
| 3 · Lanzamiento global | 6 semanas | Ranking, visitas, ofrendas, tienda, pase de estación, suscripción Jardinero. Primera ampliación: Estanque con koi. | Conversión a pago y uso de anuncios recompensados medidos |
| 4 · Operación continua | Continuo | Una zona nueva cada 6 a 8 semanas, un pase por estación, concursos semanales, 15 a 20 cosméticos por temporada. | Juego estable y comunidad activa |
| 5 · Steam | — | Escritorio con layout horizontal, precio único y DLC cosméticos. Logros y nube con steamworks. | — |

Objetivo de referencia para la fase 2: retención de día 1 de 35% o más y de día 7 de 12% o más, valores habituales para juegos casuales. Ajustar con los datos reales.

### Preguntas abiertas

- [ ] **Nombre:** el juego se llama **Sandora** (antes "ZenGarden", que estaba muy usado). Falta confirmar la marca en las clases 9 y 41 (se parece a "Pandora" y es una marca de jugos de PepsiCo en Ucrania) y reservarlo en App Store Connect y Play Console.
- [ ] **Estilo de arte:** ¿pintado a mano, vectorial plano o mezcla? Define el costo de los lotes 1 a 6.
- [ ] **Moderación:** el arenero en modo libre y los nombres de jardín son contenido que ven otros jugadores. Hace falta un sistema de reportes y, para dibujos, quizás una revisión automática antes de mostrarlos.
- [ ] **Cálculo de rareza:** definir cada cuánto se recalcula en el servidor y cuánto cuesta en Firestore con muchos jugadores.
- [ ] **Pesos del puntaje:** validar 35/35/30 con el soft launch.
- [ ] **Gato de la vecina:** nombre, personalidad y diseño; es la mascota de marketing.
- [ ] **Modo meditación:** validar en el soft launch que el nivel 5 llega en 3 o 4 días, que el techo de 20 minutos diarios no deja la Luz demasiado fácil y cuántos jugadores lo usan a diario. Revisar las reglas de las tiendas sobre apps de bienestar antes de mencionarlo en la ficha.
- [ ] **Hemisferio y estaciones:** confirmar que las estaciones se toman de la ubicación del jugador y no del calendario del norte.
