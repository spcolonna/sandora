# Prompts para generar el arte

Prompts para **ChatGPT** (generador de imágenes), en inglés porque así sigue mejor las instrucciones. Cubren el arte
que todavía falta, de lo más importante a lo opcional. **Generado por `tool/gen_prompts.py`: no editar a mano.**

**Cómo usarlos:**
- **Un prompt por imagen.** Cada bloque gris es un mensaje: copialo entero y pegalo en una conversación nueva (o
  seguí en la misma). Arranca a generar sin preguntar.
- **Van en orden de importancia:** la número 1 es la que más conviene hacer ahora. Cada bloque dice por qué está ahí.
- Antes de pegar, **adjuntá la referencia** que indica cada imagen (arrastrala a la conversación).
- Cada prompt trae toda su descripción (formato, estilo, qué no incluir), así sale consistente en cualquier
  conversación o cuenta.
- Guardá el PNG con el nombre y la carpeta que se indican (`store/` no se commitea) y pedile a Claude que las integre.
- **Integrar** es siempre: pasar el PNG a `.webp` en `assets/images/`, usarlo en el juego donde va y sumarlo a
  `INCLUDED` en este script. Así sale de la lista y queda en "Ya incluidas", al final.

**Fuera de este archivo:** los sonidos (los placeholders salen de `tool/gen_placeholder_audio.py`; los finales
conviene grabarlos), los shaders (`shd_*`, son código), el mapa de alturas de la arena y las animaciones Rive
(`char_*.riv`, se arman en Rive a partir de las imágenes del Bloque 5).

---

# Para generar ahora

## Bloque 14 — Bosque: Casa de té (Matcha), Bambú (Flauta) y Río (Linternas) (4)

**Por qué ahora:** Lo que falta del bosque: batidor, flauta, linterna y el río.

La tercera vista del jardín y las piezas de sus minijuegos. El código dibuja la espuma del té, las ráfagas de viento y la corriente, así que cada pieza va sola y recortada. Adjuntá `store/art/style/style_keyart.webp`.

### 1. `obj_tea_whisk` ⬜

Guardala como `store/art/forest/obj_tea_whisk.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 120 pixels wide), so the image must contain ONLY the object.

SUBJECT: A single bamboo tea whisk (chasen) seen straight from ABOVE: a pale bamboo center with many thin curved tines opening in a circle around it.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style; bowl or tea.
```

### 2. `obj_bamboo_flute` ⬜

Guardala como `store/art/forest/obj_bamboo_flute.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 420 pixels tall), so the image must contain ONLY the object.

SUBJECT: A single Japanese bamboo flute (shakuhachi-like) standing exactly upright: pale golden bamboo with three darker nodes and FOUR round finger holes evenly spaced along the middle.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style; hands or strings.
```

### 3. `obj_river_lantern` ⬜

Guardala como `store/art/forest/obj_river_lantern.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 80 pixels tall), so the image must contain ONLY the object.

SUBJECT: A single small floating paper lantern (tōrō nagashi) seen from above at a slight angle: a square wooden base and a glowing warm paper cube on top.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style; water.
```

### 4. `bg_river` ⬜

Guardala como `store/art/forest/bg_river.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a PORTRAIT image with a 2:3 aspect ratio (1024×1536, not square, not landscape), fully opaque, with NO transparency.

PURPOSE: This is the background of the river lanterns minigame in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The code draws the stones, the lantern, the dock and the current on top of it.

SUBJECT: A calm river seen straight from above, flowing from top to bottom and filling the middle 84% of the width, with narrow sandy and grassy banks on both sides and a few soft ripples.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The water is even and calm everywhere, without rocks or objects, so the pieces on top read clearly. The game shows this on tall phone screens (9:16), so the left and right 8% of the image may be cropped: keep everything important inside the central 84% of the width.

DO NOT INCLUDE: stones in the water; boats, lanterns or docks; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; people or animals; frame or border; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 12 — Vista del estanque (1)

**Por qué ahora:** El suelo de la vista del estanque.

Segunda vista del jardín (se llega deslizando). Va encima del mismo cielo y las mismas colinas que el patio. Adjuntá `store/art/style/style_keyart.webp` y `bg_base_ground`.

### 5. `bg_east_ground` ⬜

Guardala como `store/art/bg/bg_east_ground.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a PORTRAIT image with a 2:3 aspect ratio (1024×1536, not square, not landscape), PNG with a transparent background (real alpha channel) wherever the description says the image is empty. If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is the ground layer of the second garden view in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars), the pond side. The game places the shishi-odoshi, the bonsai, the mossy rocks and the leafy path on top of it.

SUBJECT: A small Japanese garden seen from a gentle three-quarter view from above: grass and moss ground with a calm irregular pond in the lower left, a curving gravel path from the bottom edge to the right, and a few low flat stones around the pond edge.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The ground fills only the lower 55% of the image; above it everything is fully transparent. Leave open, calm areas at the upper right, the middle right and above the pond for the objects. The game shows this on tall phone screens (9:16), so the left and right 8% of the image may be cropped: keep everything important inside the central 84% of the width.

DO NOT INCLUDE: lanterns, trees, bamboo or objects; sky; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; people or animals; frame or border; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 9 — Marca Sandora (1)

**Por qué ahora:** Para la ficha de la tienda: hace falta antes de publicar.

Piezas de la marca. El logo (símbolo y nombre) ya está incluido; el juego los pone encima de `title_bg` y `store_feature`, así que esas imágenes van sin texto. El nombre del jardín de cada jugador lo escribe el juego sobre `ui_garden_sign`, así que esa pieza va vacía. Adjuntá `store/art/style/style_keyart.webp`.

### 6. `store_feature` ⬜

Guardala como `store/art/brand/store_feature.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a LANDSCAPE image with a 3:2 aspect ratio (1536×1024, not square, not portrait), fully opaque, with NO transparency.

PURPOSE: This is the wide banner for the Google Play store page of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is cropped to a wide 1024×500 strip from the middle of the image, and the logo is added on top of the left half later.

SUBJECT: A wide, calm view of the zen garden at golden hour: on the right half, the small stack of stones on raked sand, the stone lantern glowing softly and the ginger cat sleeping on the little bridge. The left half is a soft empty stretch of raked sand and mist, quiet enough to hold the logo.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: Landscape composition. All important elements in the right half, away from the edges. The left half stays calm and nearly empty. The top 17% and bottom 17% of the image will be cropped away: keep everything important in the middle band.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; the game name or any logo; people; frame or border; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 8 — Interfaz base (6)

**Por qué ahora:** Opcional: el kit washi ya dibuja botones y paneles con código.

Piezas que el juego estira (nine-slice) y sobre las que escribe su propio texto. Adjuntá `store/art/style/style_keyart.webp`.

### 7. `ui_button` ⬜

Guardala como `store/art/ui/ui_button.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is an interface element in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game stretches it with nine-slice scaling and writes its own text on top, so the image must be clean, symmetrical and empty in the middle.

SUBJECT: A wide rounded rectangular button made of smooth light wood (#C9A27A) with a thin darker wooden rim and a soft highlight along the top edge, slightly raised.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The button is centered, about 80% of the canvas width and 30% of its height, perfectly symmetrical. The middle is plain wood with no pattern so text fits on it. Everything around it is transparent.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; icons or symbols unless described; any background or scenery; drop shadow outside the element; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 8. `ui_panel` ⬜

Guardala como `store/art/ui/ui_panel.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is an interface element in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game stretches it with nine-slice scaling and writes its own text on top, so the image must be clean, symmetrical and empty in the middle.

SUBJECT: A large rounded rectangular panel of warm washi paper (#F3ECDD) with subtle fibers, mounted on a thin dark wooden frame with softly rounded corners.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The panel is centered and fills about 90% of the canvas, perfectly symmetrical. The paper area is plain and calm. Everything outside the frame is transparent.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; icons or symbols unless described; any background or scenery; drop shadow outside the element; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 9. `ui_score_frame` ⬜

Guardala como `store/art/ui/ui_score_frame.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is an interface element in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game stretches it with nine-slice scaling and writes its own text on top, so the image must be clean, symmetrical and empty in the middle.

SUBJECT: A small rounded plaque of dark polished wood (#5A3E2B) with a thin pale stone inset border, used behind a score number.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The plaque is centered, about 70% of the canvas width and 35% of its height, perfectly symmetrical. The middle is plain so a number fits on it. Everything around it is transparent.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; icons or symbols unless described; any background or scenery; drop shadow outside the element; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 10. `ui_serenity_bar` ⬜

Guardala como `store/art/ui/ui_serenity_bar.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is an interface element in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game stretches it with nine-slice scaling and writes its own text on top, so the image must be clean, symmetrical and empty in the middle.

SUBJECT: A long, thin, empty horizontal bar: a shallow groove carved into smooth pale stone, with rounded ends and a soft inner shadow. A small moss-covered rounded stone decorates the left end.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The bar is centered, horizontal, about 90% of the canvas width and 10% of its height. The inside of the groove is empty (the game fills it). Everything around it is transparent.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; icons or symbols unless described; any background or scenery; drop shadow outside the element; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 11. `ui_result` ⬜

Guardala como `store/art/ui/ui_result.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is an interface element in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game stretches it with nine-slice scaling and writes its own text on top, so the image must be clean, symmetrical and empty in the middle.

SUBJECT: A result card: a tall rounded panel of warm washi paper with a thin dark wooden frame, and a soft painted band of pale mist across its upper third where three stars will be placed by the game.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The card is centered, about 75% of the canvas width and 90% of its height, perfectly symmetrical. No stars, no text. Everything outside the frame is transparent.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; icons or symbols unless described; any background or scenery; drop shadow outside the element; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 12. `ui_pause` ⬜

Guardala como `store/art/ui/ui_pause.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is an interface element in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game stretches it with nine-slice scaling and writes its own text on top, so the image must be clean, symmetrical and empty in the middle.

SUBJECT: A round button of smooth gray river stone with a soft highlight, carrying a simple pause symbol made of two short vertical moss-green bars in the center.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The button is centered and fills about 80% of the canvas. The pause symbol is the only mark on it. Everything around it is transparent.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; icons or symbols unless described; any background or scenery; drop shadow outside the element; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 0 — Guía de estilo (2)

**Por qué ahora:** Opcional: el estilo ya quedó fijado por el patio pintado.

Van primero: fijan el estilo de todo lo demás. Guardalas en `store/art/style/` y **adjuntá `store/art/style/style_keyart.webp` como referencia en cada bloque siguiente** (arrastrala a la conversación antes de pegar el prompt). Si el estilo no te convence, se cambia el párrafo STYLE en `tool/gen_prompts.py` y se regenera este archivo.

### 13. `style_stones` ⬜

Guardala como `store/art/style/style_stones.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), fully opaque, with NO transparency.

PURPOSE: This is a material reference sheet for the stones in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). Artists will copy how stone looks from it.

SUBJECT: Nine different garden stones arranged in a loose 3×3 grid on plain warm paper: three flat round river stones for stacking (smooth, wider than tall), three rough upright decorative rocks with a little moss on top, and three small pebbles of different tones (cool gray, warm gray, almost white). Each stone is painted with a lit upper-left side, a soft shadow side and a subtle speckled texture.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: Each stone is separated from the others with generous empty paper around it. The background is plain warm paper (#F3ECDD) edge to edge.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; labels; grid lines; frame or border; cast shadows on the paper; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 14. `style_plants` ⬜

Guardala como `store/art/style/style_plants.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), fully opaque, with NO transparency.

PURPOSE: This is a material reference sheet for the plants in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). Artists will copy how foliage looks from it.

SUBJECT: Nine garden plants arranged in a loose 3×3 grid on plain warm paper: a cloud-pruned pine, a small Japanese maple, a bamboo clump, a mound of moss, a fern, an azalea bush with a few pink flowers, a tuft of ornamental grass, a lotus leaf, and a small bonsai in a shallow pot. Foliage is painted as soft grouped masses with a few crisp leaf shapes on the edges, never leaf by leaf.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: Each plant is separated from the others with generous empty paper around it. The background is plain warm paper (#F3ECDD) edge to edge.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; labels; grid lines; frame or border; cast shadows on the paper; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

---

# Ya incluidas (98)

| Imagen | Archivo en el juego | Uso |
|---|---|---|
| `style_courtyard_ref` | `store/art/style/style_courtyard_ref.webp` | Tu referencia del patio (no se sube). Adjuntala en los bloques del patio y de los minijuegos con su estética. |
| `bg_court_sky` | `assets/images/court/bg_court_sky.webp` | Cielo del patio pintado, la capa más lejana: se mueve apenas al acercar (profundidad 0.15, `garden_scene.dart` `_paintCourt`). |
| `bg_court_far` | `assets/images/court/bg_court_far.webp` | Montañas detrás del muro (profundidad 0.3). También, desenfocadas, en el fondo del Apilado (`stack_game.dart`). |
| `bg_court_wall` | `assets/images/court/bg_court_wall.webp` | Muro con el portón y su farol (profundidad 0.7); el farol se enciende al anochecer (`GardenLayout.court`). |
| `bg_court_ground` | `assets/images/court/bg_court_ground.webp` | Suelo del patio: el ripio rastrillado, el plano de los lugares, la torre y las decoraciones (profundidad 1). |
| `bg_court_side_left` | `assets/images/court/bg_court_side_left.webp` | Bambú y tsukubai del frente (profundidad 1.5), corrido un 7 % hacia afuera para enmarcar sin tapar; al acercar se abre. |
| `bg_court_side_right` | `assets/images/court/bg_court_side_right.webp` | Arce y macetas del frente (profundidad 1.5), corrido un 7 % hacia afuera; al acercar se abre. |
| `obj_court_tower_base` | `assets/images/court/obj_court_tower_base.webp` | Laja de la torre, recortada: la cara de arriba al 20 % del alto y el 74 % del ancho es el pedestal. En el patio con la torre guardada encima y de base en el Apilado (`GardenLayout.courtObjects`). |
| `obj_court_board` | `assets/images/court/obj_court_board.webp` | Tablón de récords, recortado, al pie del muro a la izquierda del portón (`GardenLayout.courtObjects`). |
| `obj_court_deck` | `assets/images/court/obj_court_deck.webp` | Tarima de meditación, recortada y espejada, contra el muro bajo el arbolito, mirando al jardín (`GardenLayout.courtObjects`). |
| `obj_court_jars` | `assets/images/court/obj_court_jars.webp` | Vasijas de la Lluvia, recortadas, abajo a la derecha (`GardenLayout.courtObjects`). |
| `obj_court_lantern_tall` | `assets/images/court/obj_court_lantern_tall.webp` | Farol alto, recortado, sobre el musgo de la izquierda; su ventana se enciende al anochecer (`GardenLayout.courtProps`). |
| `obj_court_lantern_small` | `assets/images/court/obj_court_lantern_small.webp` | Farol bajo, recortado, en la loma de musgo del centro; se enciende al anochecer (`GardenLayout.courtProps`). |
| `obj_court_rock` | `assets/images/court/obj_court_rock.webp` | Roca con musgo, recortada, sobre el musgo de la derecha (`GardenLayout.courtProps`). |
| `obj_court_rake` | `assets/images/court/obj_court_rake.webp` | Rastrillo, recortado, apoyado en el poste izquierdo del tablón (`GardenLayout.courtProps`). |
| `fg_court_doorway` | `assets/images/court/fg_court_doorway.webp` | Vano de la casa al entrar: las puertas shoji se corren detrás de los postes y, al cruzar, el marco se agranda y se desvanece (`garden_gate.dart`). A lo ancho de la pantalla, apoyado abajo; arriba se estiran los postes. |
| `bg_stack_far` | `assets/images/stack/bg_stack_far.webp` | Fondo del Apilado: sube más lento que la torre (`stack_game.dart` `_paintFar`). |
| `obj_stack_pedestal` | `assets/images/stack/obj_stack_pedestal.webp` | Laja sobre musgo, recortada: la laja ocupa el 75 % del ancho y el medio de su cara de arriba está al 9 % del alto (`stack_game.dart`). |
| `fg_stack_leaves` | `assets/images/stack/fg_stack_leaves.webp` | Hojas desenfocadas del frente del Apilado, con los extremos desvanecidos para repetirse hacia arriba; cada mitad corrida un 14 % hacia su borde. |
| `char_meditator` | `assets/images/rain/char_meditator.webp` | Meditador de la Lluvia, recortado a 560 px, sentado en el almohadón de la galería (`rain_game.dart`). |
| `char_cat` | `store/art/characters/char_cat.webp` | Gato del vecino, recortado. Referencia para animarlo en Rive; todavía no aparece en el juego (`store/` no se sube). |
| `char_monk` | `store/art/characters/char_monk.webp` | Monje jardinero, recortado. Referencia para animarlo en Rive; todavía no aparece en el juego (`store/` no se sube). |
| `logo_symbol` | `assets/images/brand/logo_symbol.webp` | Símbolo del logo (piedra sobre arena rastrillada). Pantalla de título (`lib/ui/title_intro.dart`); referencia para el ícono. |
| `logo_wordmark` | `assets/images/brand/logo_wordmark.webp` | Nombre "Sandora". Pantalla de título. La versión clara para fondos oscuros se saca con código cuando haga falta. |
| `style_keyart` | `store/art/style/style_keyart.webp` | Referencia de estilo: no va en el juego (`store/` no se sube al repo). Adjuntala en cada bloque siguiente. |
| `title_bg` | `assets/images/title/title_bg.webp` | Fondo de la pantalla de título (`lib/ui/title_intro.dart`), con el logo sobre el cielo. |
| `ui_garden_sign` | `assets/images/ui/ui_garden_sign.webp` | Cartel del jardín, recortado (`lib/ui/widgets/garden_sign.dart`). Se usa de ancho fijo con el nombre sobre la tabla, sin nine-slice. |
| `app_icon` | `store/icon/app_icon.png` | Ícono de la app (no se sube: `store/`). Se regenera con `dart run flutter_launcher_icons` (`flutter_launcher_icons.yaml`); en Android, adaptable sobre arena lisa. |
| `icon_lotus` | `assets/images/icons/icon_lotus.webp` | Lotos, recortado a 160 px (`currency.dart`). |
| `icon_pebble` | `assets/images/icons/icon_pebble.webp` | Piedritas, recortado a 160 px (`lib/ui/widgets/currency.dart`). |
| `icon_essence_water` | `assets/images/icons/icon_essence_water.webp` | Agua, recortado a 160 px (`currency.dart`). |
| `icon_essence_sand` | `assets/images/icons/icon_essence_sand.webp` | Arena, recortado a 160 px (`currency.dart`). |
| `icon_essence_wood` | `assets/images/icons/icon_essence_wood.webp` | Madera, recortado a 160 px (`currency.dart`). |
| `icon_essence_light` | `assets/images/icons/icon_essence_light.webp` | Luz, recortado a 160 px (`currency.dart`). |
| `icon_star` | `assets/images/icons/icon_star.webp` | Estrellas del resultado de cada partida, apagadas con transparencia (`minigame_screen.dart`). |
| `obj_callig_hall` | `assets/images/temple/obj_callig_hall.webp` | Pabellón del Ensō en la vista del estanque (`garden_east.dart`, cargado por `scene_art.dart`). |
| `obj_temple_belltower` | `assets/images/temple/obj_temple_belltower.webp` | Campanario del estanque; la campana y el tronco se cuelgan del gancho de la viga (`garden_east.dart`). |
| `obj_temple_bell` | `assets/images/temple/obj_temple_bell.webp` | Campana: en el campanario y en el juego de la Campana, donde tiembla y se entibia al sonar (`bell_game.dart`). |
| `obj_temple_log` | `assets/images/temple/obj_temple_log.webp` | Tronco (shumoku), punta gastada a la derecha; el código dibuja las sogas (`bell_game.dart`). |
| `bg_enso_paper` | `assets/images/temple/bg_enso_paper.webp` | Papel washi del Ensō, recortado para llenar la pantalla; el sello rojo lo dibuja el código (`enso_game.dart`). |
| `bg_base_sky` | `assets/images/bg/bg_base_sky.webp` | Cielo del jardín, estirado a la mitad de arriba de la pantalla; se funde con el degradado del día y de noche no se ve (`garden_scene.dart`). |
| `bg_base_far` | `assets/images/bg/bg_base_far.webp` | Lomas con niebla, recortadas desde las cimas; las cimas quedan al 31 % de la altura y el suelo tapa el resto, en las dos vistas del jardín. |
| `bg_base_ground` | `assets/images/bg/bg_base_ground.webp` | Patio (arena con borde de piedras), recortado y estirado al terreno cuidado, que crece con las ampliaciones (`garden_scene.dart`). |
| `bg_base_foliage` | `assets/images/bg/bg_base_foliage.webp` | Arce arriba a la izquierda y bambú abajo a la derecha, al 70 % del ancho, en las tres vistas (`garden_scene.dart`). |
| `bg_rain_roof` | `assets/images/rain/bg_rain_roof.webp` | Fondo de la Lluvia: el alero arriba y, abajo, el piso de la galería espejado hasta el meditador (`rain_game.dart`). |
| `obj_rain_vessel_01` | `assets/images/rain/obj_rain_vessel_01.webp` | Vasija 1 de la Lluvia, 360 px; la boca va donde caen las gotas. También en el patio (`rain_game.dart`, `garden_scene.dart`). |
| `obj_rain_vessel_02` | `assets/images/rain/obj_rain_vessel_02.webp` | Vasija 2 de la Lluvia, 360 px; la boca va donde caen las gotas. También en el patio (`rain_game.dart`, `garden_scene.dart`). |
| `obj_rain_vessel_03` | `assets/images/rain/obj_rain_vessel_03.webp` | Vasija 3 de la Lluvia, 360 px; la boca va donde caen las gotas. También en el patio (`rain_game.dart`, `garden_scene.dart`). |
| `obj_rain_vessel_04` | `assets/images/rain/obj_rain_vessel_04.webp` | Vasija 4 de la Lluvia, 360 px; la boca va donde caen las gotas. También en el patio (`rain_game.dart`, `garden_scene.dart`). |
| `obj_rain_vessel_05` | `assets/images/rain/obj_rain_vessel_05.webp` | Vasija 5 de la Lluvia, 360 px; la boca va donde caen las gotas. También en el patio (`rain_game.dart`, `garden_scene.dart`). |
| `fx_rain_drop` | `assets/images/rain/fx_rain_drop.webp` | Gota que cae a su vasija, 128 px de alto (`rain_game.dart`). |
| `fx_rain_splash` | `assets/images/rain/fx_rain_splash.webp` | Corona de agua al acertar, crece y se apaga (`rain_game.dart`). |
| `obj_stack_stone_01` | `assets/images/stack/obj_stack_stone_01.webp` | Piedra tipo río, estirada a la silueta de la física y espejada según la piedra (`stone_painter.dart`). |
| `obj_stack_stone_02` | `assets/images/stack/obj_stack_stone_02.webp` | Piedra tipo peñasco, estirada a la silueta de la física y espejada según la piedra (`stone_painter.dart`). |
| `obj_stack_stone_03` | `assets/images/stack/obj_stack_stone_03.webp` | Piedra tipo canto rodado, estirada a la silueta de la física y espejada según la piedra (`stone_painter.dart`). |
| `obj_stack_stone_04` | `assets/images/stack/obj_stack_stone_04.webp` | Piedra tipo laja, estirada a la silueta de la física y espejada según la piedra (`stone_painter.dart`). |
| `obj_stack_stone_05` | `assets/images/stack/obj_stack_stone_05.webp` | Piedra tipo huevo, estirada a la silueta de la física y espejada según la piedra (`stone_painter.dart`). |
| `obj_stack_stone_06` | `assets/images/stack/obj_stack_stone_06.webp` | Piedra tipo cuña, estirada a la silueta de la física y espejada según la piedra (`stone_painter.dart`). |
| `spr_sand_rake_01` | `assets/images/sand/spr_sand_rake_01.webp` | Rastrillo del Arenero, con los dientes en el trazo (`sand_painter.dart`). |
| `tex_sand_base` | `assets/images/sand/tex_sand_base.webp` | Arena, hecha continua y bajada a 512 px; baldosas de 256 puntos en el Arenero y en el patio (`sand_painter.dart`). |
| `obj_decor_lantern` | `assets/images/decor/obj_decor_lantern.webp` | Farol del modo Decorar, 480 px; el aspect del balance sigue al arte (`garden_decor.dart`). |
| `obj_decor_bridge` | `assets/images/decor/obj_decor_bridge.webp` | Puente del modo Decorar, 480 px; el aspect del balance sigue al arte (`garden_decor.dart`). |
| `obj_decor_pine` | `assets/images/decor/obj_decor_pine.webp` | Pino del modo Decorar, 480 px; el aspect del balance sigue al arte (`garden_decor.dart`). |
| `obj_decor_bamboo` | `assets/images/decor/obj_decor_bamboo.webp` | Bambú del modo Decorar, 480 px; el aspect del balance sigue al arte (`garden_decor.dart`). |
| `obj_decor_peak` | `assets/images/decor/obj_decor_peak.webp` | Roca alta del modo Decorar, 480 px; el aspect del balance sigue al arte (`garden_decor.dart`). |
| `obj_decor_boulder` | `assets/images/decor/obj_decor_boulder.webp` | Peñasco con musgo del modo Decorar, 480 px; el aspect del balance sigue al arte (`garden_decor.dart`). |
| `obj_decor_rocks` | `assets/images/decor/obj_decor_rocks.webp` | Tres rocas del modo Decorar, 480 px; el aspect del balance sigue al arte (`garden_decor.dart`). |
| `obj_decor_step` | `assets/images/decor/obj_decor_step.webp` | Piedra de paso del modo Decorar, 480 px; el aspect del balance sigue al arte (`garden_decor.dart`). |
| `obj_decor_moss` | `assets/images/decor/obj_decor_moss.webp` | Musgo con helechos del modo Decorar, 480 px; el aspect del balance sigue al arte (`garden_decor.dart`). |
| `obj_decor_basin` | `assets/images/decor/obj_decor_basin.webp` | Tsukubai con caño del modo Decorar, 480 px; el aspect del balance sigue al arte (`garden_decor.dart`). |
| `obj_decor_bench` | `assets/images/decor/obj_decor_bench.webp` | Banco de madera del modo Decorar, 480 px; el aspect del balance sigue al arte (`garden_decor.dart`). |
| `obj_decor_jizo` | `assets/images/decor/obj_decor_jizo.webp` | Jizō del modo Decorar, 480 px; el aspect del balance sigue al arte (`garden_decor.dart`). |
| `obj_decor_pagoda` | `assets/images/decor/obj_decor_pagoda.webp` | Pagoda de piedra del modo Decorar, 480 px; el aspect del balance sigue al arte (`garden_decor.dart`). |
| `obj_decor_maple` | `assets/images/decor/obj_decor_maple.webp` | Arce rojo del modo Decorar, 480 px; el aspect del balance sigue al arte (`garden_decor.dart`). |
| `obj_decor_sakura` | `assets/images/decor/obj_decor_sakura.webp` | Cerezo en flor del modo Decorar, 480 px; el aspect del balance sigue al arte (`garden_decor.dart`). |
| `obj_shishi_bamboo` | `assets/images/east/obj_shishi_bamboo.webp` | Bambú del Shishi-odoshi, 640 px, boca a la izquierda; gira y se llena por encima (`shishi_game.dart`). |
| `obj_shishi_basin` | `assets/images/east/obj_shishi_basin.webp` | Cuenco del Shishi-odoshi, con las ondas sobre su agua (`shishi_game.dart`). |
| `spr_leaf_01` | `assets/images/east/spr_leaf_01.webp` | Hoja de arce naranja de Hojas al viento, 128 px, con sombra (`leaves_game.dart`). |
| `spr_leaf_02` | `assets/images/east/spr_leaf_02.webp` | Hoja de arce roja de Hojas al viento, 128 px, con sombra (`leaves_game.dart`). |
| `spr_leaf_03` | `assets/images/east/spr_leaf_03.webp` | Hoja de ginkgo de Hojas al viento, 128 px, con sombra (`leaves_game.dart`). |
| `spr_leaf_04` | `assets/images/east/spr_leaf_04.webp` | Hoja seca de roble de Hojas al viento, 128 px, con sombra (`leaves_game.dart`). |
| `tex_moss` | `assets/images/east/tex_moss.webp` | Musgo continuo a 512 px: da color a los toques sobre la piedra (`moss_game.dart`). |
| `obj_moss_rock` | `assets/images/east/obj_moss_rock.webp` | Piedra del Musgo: se toma su centro, recortado a la forma de cada roca (`moss_game.dart`). |
| `obj_bonsai_pot` | `assets/images/east/obj_bonsai_pot.webp` | Maceta del Bonsái, delante de la tierra del tronco (`bonsai_game.dart`). |
| `obj_bonsai_trunk` | `assets/images/east/obj_bonsai_trunk.webp` | Árbol del Bonsái, estirado de la maceta a la copa de arriba para que sus ramas entren en las copas (`bonsai_game.dart`). |
| `obj_decor_azalea` | `assets/images/decor/obj_decor_azalea.webp` | Azalea del modo Decorar, 480 px; el aspect del balance sigue al arte (`garden_decor.dart`). |
| `spr_pond_tile_lotus` | `assets/images/pond/spr_pond_tile_lotus.webp` | Ficha del 3 en línea, 256 px (`pond_game.dart`). |
| `spr_pond_tile_pad` | `assets/images/pond/spr_pond_tile_pad.webp` | Ficha del 3 en línea, 256 px (`pond_game.dart`). |
| `spr_pond_tile_stone` | `assets/images/pond/spr_pond_tile_stone.webp` | Ficha del 3 en línea, 256 px (`pond_game.dart`). |
| `spr_pond_tile_koi` | `assets/images/pond/spr_pond_tile_koi.webp` | Ficha del 3 en línea, 256 px (`pond_game.dart`). |
| `spr_pond_tile_drop` | `assets/images/pond/spr_pond_tile_drop.webp` | Ficha del 3 en línea, 256 px (`pond_game.dart`). |
| `spr_pond_power_wave` | `assets/images/pond/spr_pond_power_wave.webp` | Onda: halo detrás de la ficha, girado 90° en la de columna (`pond_game.dart`). |
| `spr_pond_power_bloom` | `assets/images/pond/spr_pond_power_bloom.webp` | Flor abierta: halo detrás de la ficha (`pond_game.dart`). |
| `spr_pond_power_moon` | `assets/images/pond/spr_pond_power_moon.webp` | Luna, la pieza sin tipo (`pond_game.dart`). |
| `bg_pond_water` | `assets/images/pond/bg_pond_water.webp` | Fondo del 3 en línea; el tablero apenas se oscurece encima y el HUD va claro (`pond_game.dart`). |
| `obj_tea_house` | `assets/images/forest/obj_tea_house.webp` | Casa de té de la vista del bosque, 480 px; el farolito cuelga del alero izquierdo (`garden_forest.dart`). |
| `obj_bamboo_grove` | `assets/images/forest/obj_bamboo_grove.webp` | Bambú de la vista del bosque, 480 px (`garden_forest.dart`). |
| `obj_tea_bowl` | `assets/images/forest/obj_tea_bowl.webp` | Cuenco del Matcha, 640 px; el té y la espuma llenan el óvalo de la boca (`matcha_game.dart`). |
