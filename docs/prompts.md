# Prompts para generar el arte

Prompts para **ChatGPT** (generador de imágenes), en inglés porque así sigue mejor las instrucciones. Cubren la guía
de estilo (Lote 0) y el arte del MVP (Lote 1 del GDD). **Generado por `tool/gen_prompts.py`: no editar a mano.**

**Cómo usarlos:**
- Cada bloque gris es **un solo mensaje**: copialo entero y pegalo en una conversación nueva. Arranca a generar sin
  preguntar.
- Los bloques tienen **10 imágenes como máximo**.
- Cada imagen repite toda su descripción (formato, estilo, qué no incluir). Así sale consistente aunque la corras
  sola, en otra conversación o en otra cuenta.
- ChatGPT no les pone nombre: salen en el orden de la lista. Guardá cada PNG con el nombre que figura en
  `Image N — <nombre>`, en la carpeta que se indica (`store/` no se commitea), y pedile a Claude que las integre.
- **Integrar** es siempre: pasar el PNG a `.webp` en `assets/images/`, borrar el PNG, usarlo en el juego donde va y
  sumarlo a `INCLUDED` en este script. Así sale de los bloques y queda en "Ya incluidas", al final.
- Si una sale mal, regenerala sola: pegá `Create ONE single image. Start immediately, without asking questions.` y
  debajo el texto de esa imagen (desde su línea `Create a ...` hasta su `DO NOT INCLUDE`).
- **Orden:** primero el Bloque 0. Cuando el estilo te guste, el resto en cualquier orden, siempre adjuntando
  `store/art/style/style_keyart.webp` como referencia.

**Fuera de este archivo:** los sonidos (los placeholders salen de `tool/gen_placeholder_audio.py`; los finales
conviene grabarlos), los shaders (`shd_*`, son código), el mapa de alturas de la arena y las animaciones Rive
(`char_*.riv`, se arman en Rive a partir de las imágenes del Bloque 5).

---

# Para generar ahora

## Bloque 0 — Guía de estilo (2) ⬜

Archivos, en orden: `style_stones.png`, `style_plants.png`. Carpeta: `store/art/style/`.
Van primero: fijan el estilo de todo lo demás. Guardalas en `store/art/style/` y **adjuntá `store/art/style/style_keyart.webp` como referencia en cada bloque siguiente** (arrastrala a la conversación antes de pegar el prompt). Si el estilo no te convence, se cambia el párrafo STYLE en `tool/gen_prompts.py` y se regenera este archivo.

```
Generate exactly 2 separate images. Start generating immediately, without asking questions or requesting confirmation. Each image has its own complete instructions below; follow them separately. Each image is its own file: do NOT combine them into a grid, collage or contact sheet.

Image 1 — style_stones:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), fully opaque, with NO transparency.

PURPOSE: This is a material reference sheet for the stones in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). Artists will copy how stone looks from it.

SUBJECT: Nine different garden stones arranged in a loose 3×3 grid on plain warm paper: three flat round river stones for stacking (smooth, wider than tall), three rough upright decorative rocks with a little moss on top, and three small pebbles of different tones (cool gray, warm gray, almost white). Each stone is painted with a lit upper-left side, a soft shadow side and a subtle speckled texture.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: Each stone is separated from the others with generous empty paper around it. The background is plain warm paper (#F3ECDD) edge to edge.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; labels; grid lines; frame or border; cast shadows on the paper; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 2 — style_plants:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), fully opaque, with NO transparency.

PURPOSE: This is a material reference sheet for the plants in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). Artists will copy how foliage looks from it.

SUBJECT: Nine garden plants arranged in a loose 3×3 grid on plain warm paper: a cloud-pruned pine, a small Japanese maple, a bamboo clump, a mound of moss, a fern, an azalea bush with a few pink flowers, a tuft of ornamental grass, a lotus leaf, and a small bonsai in a shallow pot. Foliage is painted as soft grouped masses with a few crisp leaf shapes on the edges, never leaf by leaf.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: Each plant is separated from the others with generous empty paper around it. The background is plain warm paper (#F3ECDD) edge to edge.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; labels; grid lines; frame or border; cast shadows on the paper; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 1 — Fondos del jardín y del alero (5) ⬜

Archivos, en orden: `bg_base_sky.png`, `bg_base_far.png`, `bg_base_ground.png`, `bg_base_foliage.png`, `bg_rain_roof.png`. Carpeta: `store/art/bg/`.
Capas con parallax: el cielo es opaco y las otras tres tienen partes transparentes para apilarlas. El día y la noche los hace un shader, así que todas van **de día**. Adjuntá `store/art/style/style_keyart.webp`.

```
Generate exactly 5 separate images. Start generating immediately, without asking questions or requesting confirmation. Each image has its own complete instructions below; follow them separately. Each image is its own file: do NOT combine them into a grid, collage or contact sheet.

Image 1 — bg_base_sky:
Create a PORTRAIT image with a 2:3 aspect ratio (1024×1536, not square, not landscape), fully opaque, with NO transparency.

PURPOSE: This is the farthest background layer (the sky) of the garden screen in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). Other layers are drawn on top of it.

SUBJECT: A soft early-morning sky: a gentle vertical gradient from pale blue-gray at the top (#BFD8DC) to warm cream near the bottom (#F4E7CF), with a few long, thin, soft clouds. No sun disk.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The bottom third can stay plain: hills will cover it. The game shows this on tall phone screens (9:16), so the left and right 8% of the image may be cropped: keep everything important inside the central 84% of the width.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; birds; mountains, hills, trees or any ground; frame or border; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 2 — bg_base_far:
Create a PORTRAIT image with a 2:3 aspect ratio (1024×1536, not square, not landscape), PNG with a transparent background (real alpha channel) wherever the description says the image is empty. If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a far background layer of the garden screen in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars): distant hills seen through morning mist. It is drawn on top of a separate sky layer.

SUBJECT: A soft range of rounded misty hills with a few tiny pine silhouettes on the ridges, fading into mist. Muted blue-green, low contrast.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The hills fill only the lower half of the image; their top edge is an irregular soft line around the middle of the canvas. Everything ABOVE the hills is fully transparent. The game shows this on tall phone screens (9:16), so the left and right 8% of the image may be cropped: keep everything important inside the central 84% of the width.

DO NOT INCLUDE: any sky color or clouds; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; buildings; people; frame or border; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 3 — bg_base_ground:
Create a PORTRAIT image with a 2:3 aspect ratio (1024×1536, not square, not landscape), PNG with a transparent background (real alpha channel) wherever the description says the image is empty. If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is the ground layer of the garden screen in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). Objects, the stone tower and the sand drawing are placed on top of it by the game.

SUBJECT: The empty ground of a small zen garden seen from a gentle three-quarter view from above: a large bed of pale sand, flat and smooth with no rake lines, framed by a low border of dark stones and a thin strip of moss along the back edge. A few stepping stones lead from the bottom edge into the sand.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The ground fills only the lower 55% of the image; above the back moss edge everything is fully transparent. The sand must be mostly empty and calm. The game shows this on tall phone screens (9:16), so the left and right 8% of the image may be cropped: keep everything important inside the central 84% of the width.

DO NOT INCLUDE: rake lines or patterns in the sand; rocks, lanterns, plants or objects on the sand; sky; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; people or animals; frame or border; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 4 — bg_base_foliage:
Create a PORTRAIT image with a 2:3 aspect ratio (1024×1536, not square, not landscape), PNG with a transparent background (real alpha channel) wherever the description says the image is empty. If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is the nearest decorative layer of the garden screen in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars): it frames the scene from the sides and moves faster than the rest (parallax).

SUBJECT: Out-of-focus foreground foliage framing the view: maple leaves hanging from the top-left corner and a clump of bamboo leaves entering from the bottom-right corner. Soft, slightly blurred.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The foliage covers ONLY the top-left corner (about 25% of the width) and the bottom-right corner (about 25% of the width). The whole center of the image is fully transparent.

DO NOT INCLUDE: anything in the center of the image; ground; sky; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; flowers; frame or border; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 5 — bg_rain_roof:
Create a PORTRAIT image with a 2:3 aspect ratio (1024×1536, not square, not landscape), fully opaque, with NO transparency.

PURPOSE: This is the background of the "rain in the jars" minigame in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the jars, the raindrops and the meditating person on top.

SUBJECT: A view looking up from inside a wooden veranda on a rainy day: the lower edge of a dark tiled roof eave runs straight across the top of the image, with round tile ends and a wooden beam under them. Below it, a soft gray rainy garden in the distance (blurred maples and a misty wall), and at the bottom a polished dark wooden floor of the veranda.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The roof eave is a straight horizontal band occupying the top 15% of the image. The middle 60% is calm and low contrast so the jars and drops on top stay readable. The game shows this on tall phone screens (9:16), so the left and right 8% of the image may be cropped: keep everything important inside the central 84% of the width.

DO NOT INCLUDE: jars, pots or vessels; raindrops in the foreground; people; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; frame or border; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 2 — Piedras para apilar (6) ⬜

Archivos, en orden: `obj_stack_stone_01.png`, `obj_stack_stone_02.png`, `obj_stack_stone_03.png`, `obj_stack_stone_04.png`, `obj_stack_stone_05.png`, `obj_stack_stone_06.png`. Carpeta: `store/art/stack/`.
Seis piedras distintas para el minijuego de apilado. Hoy se dibujan con código (río, laja, canto rodado, huevo, peñasco y cuña); estas las reemplazarían. Tienen que ser más anchas que altas y con base plana. Adjuntá `store/art/style/style_keyart.webp`.

```
Generate exactly 6 separate images. Start generating immediately, without asking questions or requesting confirmation. Each image has its own complete instructions below; follow them separately. Each image is its own file: do NOT combine them into a grid, collage or contact sheet.

Image 1 — obj_stack_stone_01:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 90 to 160 pixels wide), so the image must contain ONLY the object.

SUBJECT: A flat, smooth oval river stone in cool medium gray, seen from the side, about three times wider than tall, with a gently flat bottom and a softly domed top.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 2 — obj_stack_stone_02:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 90 to 160 pixels wide), so the image must contain ONLY the object.

SUBJECT: A flat river stone in warm gray with a faint lighter band of quartz running across it, seen from the side, about two and a half times wider than tall, with a flat bottom and a flat top.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 3 — obj_stack_stone_03:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 90 to 160 pixels wide), so the image must contain ONLY the object.

SUBJECT: A small, thick, rounded river stone in dark slate gray, seen from the side, about twice as wide as tall, with a flat bottom and a slightly rounded top.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 4 — obj_stack_stone_04:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 90 to 160 pixels wide), so the image must contain ONLY the object.

SUBJECT: A long, thin flat stone in pale gray, almost white, seen from the side, about four times wider than tall, with a flat bottom and a flat top and slightly irregular ends.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 5 — obj_stack_stone_05:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 90 to 160 pixels wide), so the image must contain ONLY the object.

SUBJECT: A flat river stone in greenish gray with a few tiny tufts of moss on its top edge, seen from the side, about two and a half times wider than tall, with a flat bottom and a softly domed top.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 6 — obj_stack_stone_06:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 90 to 160 pixels wide), so the image must contain ONLY the object.

SUBJECT: A slightly asymmetrical flat stone in warm brownish gray, thicker on the left than on the right, seen from the side, about three times wider than tall, with a flat bottom.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 3 — Objetos del jardín (catálogo inicial) (10) ⬜

Archivos, en orden: `obj_base_lantern.png`, `obj_base_bridge.png`, `obj_base_pine.png`, `obj_base_bamboo.png`, `obj_base_rock_01.png`, `obj_base_rock_02.png`, `obj_base_rock_03.png`, `obj_base_rock_04.png`, `obj_base_plant_01.png`, `obj_base_plant_02.png`. Carpeta: `store/art/garden/`.
Diez objetos que se compran con Piedritas. Adjuntá `store/art/style/style_keyart.webp` y `style_plants.png`.

```
Generate exactly 10 separate images. Start generating immediately, without asking questions or requesting confirmation. Each image has its own complete instructions below; follow them separately. Each image is its own file: do NOT combine them into a grid, collage or contact sheet.

Image 1 — obj_base_lantern:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 120 pixels tall), so the image must contain ONLY the object.

SUBJECT: A traditional Japanese stone lantern (tōrō, kasuga style): a hexagonal stone cap, a small light chamber with a soft warm amber glow inside, a slim post and a round base. Weathered gray stone with a little moss on the cap.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 2 — obj_base_bridge:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 200 pixels wide), so the image must contain ONLY the object.

SUBJECT: A small arched wooden footbridge with low railings, painted in a soft faded vermilion with dark wood planks, seen from the side and a little from above.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 3 — obj_base_pine:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 120 pixels tall), so the image must contain ONLY the object.

SUBJECT: A young Japanese black pine pruned in the niwaki cloud style: a gracefully curving dark trunk with four rounded pads of deep green needles.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 4 — obj_base_bamboo:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 120 pixels tall), so the image must contain ONLY the object.

SUBJECT: A small clump of five green bamboo stalks of different heights with a few leaves at the top, growing from a low mound of earth.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 5 — obj_base_rock_01:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 120 pixels tall), so the image must contain ONLY the object.

SUBJECT: A tall upright garden rock in cool gray, rough and angular, a little like a small mountain peak, with some moss at its base.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 6 — obj_base_rock_02:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 120 pixels tall), so the image must contain ONLY the object.

SUBJECT: A low, wide, rounded garden boulder in warm gray with soft patches of bright moss on top.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 7 — obj_base_rock_03:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 120 pixels tall), so the image must contain ONLY the object.

SUBJECT: A group of three small rounded garden rocks of different sizes resting together, in slightly different grays.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 8 — obj_base_rock_04:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 80 pixels wide), so the image must contain ONLY the object.

SUBJECT: A flat, dark stepping stone, almost round, seen from above at a steep angle, with tiny moss along one edge.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 9 — obj_base_plant_01:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 120 pixels tall), so the image must contain ONLY the object.

SUBJECT: A soft round mound of bright green moss with two small ferns growing from it.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 10 — obj_base_plant_02:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 120 pixels tall), so the image must contain ONLY the object.

SUBJECT: A small rounded azalea bush trimmed into a soft dome, dark green leaves with a scattering of soft pink flowers.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 4 — Lluvia en vasijas y arenero (9) ⬜

Archivos, en orden: `obj_rain_vessel_01.png`, `obj_rain_vessel_02.png`, `obj_rain_vessel_03.png`, `obj_rain_vessel_04.png`, `obj_rain_vessel_05.png`, `fx_rain_drop.png`, `fx_rain_splash.png`, `spr_sand_rake_01.png`, `tex_sand_base.png`. Carpeta: `store/art/rain_sand/`.
Vasijas, gotas, rastrillo y textura de arena. El mapa de alturas de la arena (`tex_sand_height`) no va acá: lo genera el código. Adjuntá `store/art/style/style_keyart.webp`.

```
Generate exactly 9 separate images. Start generating immediately, without asking questions or requesting confirmation. Each image has its own complete instructions below; follow them separately. Each image is its own file: do NOT combine them into a grid, collage or contact sheet.

Image 1 — obj_rain_vessel_01:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 80 to 110 pixels wide), so the image must contain ONLY the object.

SUBJECT: A small round clay jar with a wide open mouth, unglazed terracotta, seen from the front and a little from above so the dark water inside the open mouth is visible.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 2 — obj_rain_vessel_02:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 80 to 110 pixels wide), so the image must contain ONLY the object.

SUBJECT: A medium clay water jar with a soft teal-blue glaze dripping unevenly over a brown body, wide open mouth, seen from the front and a little from above so the water inside is visible.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 3 — obj_rain_vessel_03:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 80 to 110 pixels wide), so the image must contain ONLY the object.

SUBJECT: A squat, wide stoneware bowl-shaped vessel in moss-green celadon glaze, seen from the front and a little from above so the water inside is visible.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 4 — obj_rain_vessel_04:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 80 to 110 pixels wide), so the image must contain ONLY the object.

SUBJECT: A tall clay jar with a narrow neck that opens into a wide lip, glazed in warm amber, seen from the front and a little from above so the water inside is visible.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 5 — obj_rain_vessel_05:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 80 to 110 pixels wide), so the image must contain ONLY the object.

SUBJECT: A large, heavy dark stoneware basin with a rough texture and an open top, seen from the front and a little from above so the water inside is visible.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 6 — fx_rain_drop:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a falling raindrop sprite in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown tiny (about 12×20 pixels) and many at once.

SUBJECT: A single clear raindrop falling straight down: a slim teardrop shape, pale blue-white, slightly transparent in the middle, with a bright highlight on the upper left and a short soft motion trail above it.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The drop points down, is perfectly centered and vertical, and fills about 70% of the canvas height. All corners are empty and transparent.

DO NOT INCLUDE: any background, puddle or splash; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; several drops; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 7 — fx_rain_splash:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a water splash sprite in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars), shown when a raindrop hits the water in a jar. It is shown small (about 48 pixels).

SUBJECT: A small crown-shaped water splash seen from the side: a thin ring of water rising, with a few tiny droplets flying up and outward. Pale blue-white, partly transparent.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The base of the splash is a flat horizontal line in the lower third of the canvas; the splash is centered and symmetrical. All corners are empty and transparent.

DO NOT INCLUDE: any background, jar or ground; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 8 — spr_sand_rake_01:
Create a LANDSCAPE image with a 3:2 aspect ratio (1536×1024, not square, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is the rake sprite of the sand-raking minigame in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game moves and rotates it along the path the player drew, so it is seen from straight above.

SUBJECT: A traditional wooden zen garden rake seen from directly above: a straight crossbar on the RIGHT side of the image, oriented vertically, with five short wooden teeth pointing to the right, and a long straight wooden handle extending horizontally to the LEFT from the middle of the crossbar. Light natural wood with darker grain.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The handle is perfectly horizontal and centered vertically. The whole rake fits inside the canvas with empty margins. All corners are empty and transparent.

DO NOT INCLUDE: any background, sand or grooves; a hand or person; cast shadow; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; perspective tilt; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 9 — tex_sand_base:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), fully opaque, with NO transparency.

PURPOSE: This is a repeating ground texture in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars): the sand of the garden, tiled many times. Raked grooves are added on top by the game.

SUBJECT: Fine, pale, warm sand seen from directly above (#E8DCC2), smooth and calm, with a subtle grain of tiny lighter and darker specks and a very soft, low-contrast variation in tone.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: A SEAMLESS, TILEABLE texture: the left edge continues perfectly into the right edge and the top edge into the bottom edge. Even lighting with no direction, no vignette, no obvious repeated feature.

DO NOT INCLUDE: rake lines, footprints, stones, leaves or any object; shadows or light spots; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; frame or border; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 5 — Personajes (referencia para Rive) (3) ⬜

Archivos, en orden: `char_meditator.png`, `char_cat.png`, `char_monk.png`. Carpeta: `store/art/characters/`.
Una pose limpia de cada personaje. Sirven de placeholder en el prototipo y de modelo para animarlos después en Rive. Adjuntá `store/art/style/style_keyart.webp`. El gato todavía no tiene nombre (pregunta abierta del GDD).

```
Generate exactly 3 separate images. Start generating immediately, without asking questions or requesting confirmation. Each image has its own complete instructions below; follow them separately. Each image is its own file: do NOT combine them into a grid, collage or contact sheet.

Image 1 — char_meditator:
Create a PORTRAIT image with a 2:3 aspect ratio (1024×1536, not square, not landscape), PNG with a transparent background (real alpha channel) wherever the description says the image is empty. If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is the meditating person of the "rain in the jars" minigame in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It appears small at the bottom of the screen, under a roof, while it rains.

SUBJECT: A person of no particular age or gender sitting in a calm cross-legged meditation pose, seen from the front, eyes closed, hands resting in the lap, wearing a simple loose robe in muted indigo (#3A4660) with a light gray sash. Peaceful and simple, almost a silhouette with soft details.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: Full body, centered, filling about 75% of the canvas height, sitting on an imaginary floor line near the bottom. Everything around the figure is fully transparent.

DO NOT INCLUDE: any background, floor, cushion or cast shadow; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other characters; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 2 — char_cat:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is the neighbor's cat, the mascot of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars): a recurring troublemaker who knocks over stone towers and walks on the raked sand, but sometimes leaves rare gifts. Players should love and hate it at the same time.

SUBJECT: A plump ginger-and-white cat with a short bobtail, round cheeks and a slightly smug, half-closed look, sitting upright and looking at the viewer with its tail curled around its paws. One small nick in the left ear.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: Full body, three-quarter view, centered, filling about 75% of the canvas. Everything around the cat is fully transparent.

DO NOT INCLUDE: any background, ground or cast shadow; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; collar, bell or accessories; other animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 3 — char_monk:
Create a PORTRAIT image with a 2:3 aspect ratio (1024×1536, not square, not landscape), PNG with a transparent background (real alpha channel) wherever the description says the image is empty. If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is the old gardener monk of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars), who takes care of the garden when the player is away.

SUBJECT: A small, kind elderly monk with a shaved head, round friendly face and a short white beard, wearing a simple ochre-and-brown work robe with sleeves tied back, holding a bamboo broom upright in one hand and smiling gently.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: Full body, three-quarter view facing right, centered, filling about 80% of the canvas height, standing on an imaginary floor line near the bottom. The whole broom fits inside the image. Everything around the figure is fully transparent.

DO NOT INCLUDE: any background, ground or cast shadow; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other characters; weapons; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 6 — Íconos de monedas y estrella (4) ⬜

Archivos, en orden: `icon_essence_wood.png`, `icon_essence_light.png`, `icon_jade.png`, `icon_star.png`. Carpeta: `store/art/icons/`.
Se ven a 32–48 px: tienen que leerse al instante. Adjuntá `store/art/style/style_keyart.webp`.

```
Generate exactly 4 separate images. Start generating immediately, without asking questions or requesting confirmation. Each image has its own complete instructions below; follow them separately. Each image is its own file: do NOT combine them into a grid, collage or contact sheet.

Image 1 — icon_essence_wood:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: A single fresh green leaf sprouting from a small slice of wood (#8A5A3C) showing its growth rings, glowing softly.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 2 — icon_essence_light:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: A small paper lantern flame shape in warm amber (#E9A84C), a soft glowing teardrop of light with a few tiny sparks around it.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 3 — icon_jade:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: A polished green jade gem carved into a smooth rounded hexagon, translucent with a deep inner glow and a bright highlight: the premium currency.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 4 — icon_star:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: A soft five-pointed star with rounded points in warm gold (#E9A84C), slightly puffy, with a gentle highlight, like a star cut from washi paper.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 7 — Ícono de la app (1) ⬜

Archivos, en orden: `app_icon.png`. Carpeta: `store/icon/`.
Archivo: `store/icon/app_icon.png` (lo usa `flutter_launcher_icons`). 1024×1024, **sin transparencia ni esquinas redondeadas**: iOS y Android las recortan solos. Adjuntá `store/art/style/style_keyart.webp` y el símbolo del logo (`assets/images/brand/logo_symbol.webp`), para que el ícono y el logo de Sandora se parezcan.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), fully opaque, with NO transparency. NO rounded corners.

PURPOSE: This is the app icon of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown on phone home screens at about 60×60 pixels next to many other apps, and iOS and Android crop it into a rounded square or a circle.

SUBJECT: The same symbol as the attached logo: one single smooth gray river stone resting on pale raked sand, with three concentric raked rings around it. Soft morning light from the upper left.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The stone is centered, bold and simple, the rings filling about 70% of the canvas. The raked sand fills the whole square edge to edge as the background. Nothing important within 10% of the edges.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; the game name; a frame or border; rounded corners; transparency; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 8 — Interfaz base (6) ⬜

Archivos, en orden: `ui_button.png`, `ui_panel.png`, `ui_score_frame.png`, `ui_serenity_bar.png`, `ui_result.png`, `ui_pause.png`. Carpeta: `store/art/ui/`.
Piezas que el juego estira (nine-slice) y sobre las que escribe su propio texto. Adjuntá `store/art/style/style_keyart.webp`.

```
Generate exactly 6 separate images. Start generating immediately, without asking questions or requesting confirmation. Each image has its own complete instructions below; follow them separately. Each image is its own file: do NOT combine them into a grid, collage or contact sheet.

Image 1 — ui_button:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is an interface element in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game stretches it with nine-slice scaling and writes its own text on top, so the image must be clean, symmetrical and empty in the middle.

SUBJECT: A wide rounded rectangular button made of smooth light wood (#C9A27A) with a thin darker wooden rim and a soft highlight along the top edge, slightly raised.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The button is centered, about 80% of the canvas width and 30% of its height, perfectly symmetrical. The middle is plain wood with no pattern so text fits on it. Everything around it is transparent.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; icons or symbols unless described; any background or scenery; drop shadow outside the element; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 2 — ui_panel:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is an interface element in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game stretches it with nine-slice scaling and writes its own text on top, so the image must be clean, symmetrical and empty in the middle.

SUBJECT: A large rounded rectangular panel of warm washi paper (#F3ECDD) with subtle fibers, mounted on a thin dark wooden frame with softly rounded corners.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The panel is centered and fills about 90% of the canvas, perfectly symmetrical. The paper area is plain and calm. Everything outside the frame is transparent.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; icons or symbols unless described; any background or scenery; drop shadow outside the element; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 3 — ui_score_frame:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is an interface element in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game stretches it with nine-slice scaling and writes its own text on top, so the image must be clean, symmetrical and empty in the middle.

SUBJECT: A small rounded plaque of dark polished wood (#5A3E2B) with a thin pale stone inset border, used behind a score number.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The plaque is centered, about 70% of the canvas width and 35% of its height, perfectly symmetrical. The middle is plain so a number fits on it. Everything around it is transparent.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; icons or symbols unless described; any background or scenery; drop shadow outside the element; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 4 — ui_serenity_bar:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is an interface element in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game stretches it with nine-slice scaling and writes its own text on top, so the image must be clean, symmetrical and empty in the middle.

SUBJECT: A long, thin, empty horizontal bar: a shallow groove carved into smooth pale stone, with rounded ends and a soft inner shadow. A small moss-covered rounded stone decorates the left end.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The bar is centered, horizontal, about 90% of the canvas width and 10% of its height. The inside of the groove is empty (the game fills it). Everything around it is transparent.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; icons or symbols unless described; any background or scenery; drop shadow outside the element; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 5 — ui_result:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is an interface element in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game stretches it with nine-slice scaling and writes its own text on top, so the image must be clean, symmetrical and empty in the middle.

SUBJECT: A result card: a tall rounded panel of warm washi paper with a thin dark wooden frame, and a soft painted band of pale mist across its upper third where three stars will be placed by the game.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The card is centered, about 75% of the canvas width and 90% of its height, perfectly symmetrical. No stars, no text. Everything outside the frame is transparent.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; icons or symbols unless described; any background or scenery; drop shadow outside the element; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 6 — ui_pause:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is an interface element in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game stretches it with nine-slice scaling and writes its own text on top, so the image must be clean, symmetrical and empty in the middle.

SUBJECT: A round button of smooth gray river stone with a soft highlight, carrying a simple pause symbol made of two short vertical moss-green bars in the center.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The button is centered and fills about 80% of the canvas. The pause symbol is the only mark on it. Everything around it is transparent.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; icons or symbols unless described; any background or scenery; drop shadow outside the element; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 9 — Marca Sandora (1) ⬜

Archivos, en orden: `store_feature.png`. Carpeta: `store/art/brand/`.
Piezas de la marca. El logo (símbolo y nombre) ya está incluido; el juego los pone encima de `title_bg` y `store_feature`, así que esas imágenes van sin texto. El nombre del jardín de cada jugador lo escribe el juego sobre `ui_garden_sign`, así que esa pieza va vacía. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a LANDSCAPE image with a 3:2 aspect ratio (1536×1024, not square, not portrait), fully opaque, with NO transparency.

PURPOSE: This is the wide banner for the Google Play store page of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is cropped to a wide 1024×500 strip from the middle of the image, and the logo is added on top of the left half later.

SUBJECT: A wide, calm view of the zen garden at golden hour: on the right half, the small stack of stones on raked sand, the stone lantern glowing softly and the ginger cat sleeping on the little bridge. The left half is a soft empty stretch of raked sand and mist, quiet enough to hold the logo.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: Landscape composition. All important elements in the right half, away from the edges. The left half stays calm and nearly empty. The top 17% and bottom 17% of the image will be cropped away: keep everything important in the middle band.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; the game name or any logo; people; frame or border; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 10 — Estanque de lotos (3 en línea) (9) ⬜

Archivos, en orden: `spr_pond_tile_lotus.png`, `spr_pond_tile_pad.png`, `spr_pond_tile_stone.png`, `spr_pond_tile_koi.png`, `spr_pond_tile_drop.png`, `spr_pond_power_wave.png`, `spr_pond_power_bloom.png`, `spr_pond_power_moon.png`, `bg_pond_water.png`. Carpeta: `store/art/pond/`.
Fichas y poderes del 3 en línea del estanque. Se ven chicas (60 a 80 px) sobre agua oscura, así que cada una tiene que leerse por su forma y su color, no por el detalle. Adjuntá `store/art/style/style_keyart.webp`.

```
Generate exactly 9 separate images. Start generating immediately, without asking questions or requesting confirmation. Each image has its own complete instructions below; follow them separately. Each image is its own file: do NOT combine them into a grid, collage or contact sheet.

Image 1 — spr_pond_tile_lotus:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a tile of a match-three board in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown small (about 60 to 80 pixels) on dark water, next to many other tiles, so it must read instantly by its shape and color.

SUBJECT: A single open lotus flower seen from slightly above, soft pink petals with a pale yellow center.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 75% of the canvas. Bold, simple silhouette, soft light rim around the edge. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, water, frame, tile border or square; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 2 — spr_pond_tile_pad:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a tile of a match-three board in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown small (about 60 to 80 pixels) on dark water, next to many other tiles, so it must read instantly by its shape and color.

SUBJECT: A single round lily pad seen from above, bright green with its typical notch and a few soft veins.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 75% of the canvas. Bold, simple silhouette, soft light rim around the edge. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, water, frame, tile border or square; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 3 — spr_pond_tile_stone:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a tile of a match-three board in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown small (about 60 to 80 pixels) on dark water, next to many other tiles, so it must read instantly by its shape and color.

SUBJECT: A single smooth, round river stone seen from above, pale gray, wet and slightly shiny.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 75% of the canvas. Bold, simple silhouette, soft light rim around the edge. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, water, frame, tile border or square; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 4 — spr_pond_tile_koi:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a tile of a match-three board in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown small (about 60 to 80 pixels) on dark water, next to many other tiles, so it must read instantly by its shape and color.

SUBJECT: A single small koi fish seen from above, curved as if swimming, white with orange-red patches.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 75% of the canvas. Bold, simple silhouette, soft light rim around the edge. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, water, frame, tile border or square; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 5 — spr_pond_tile_drop:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a tile of a match-three board in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown small (about 60 to 80 pixels) on dark water, next to many other tiles, so it must read instantly by its shape and color.

SUBJECT: A single big water drop, clear blue with a bright highlight, slightly flattened as if resting on a leaf.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 75% of the canvas. Bold, simple silhouette, soft light rim around the edge. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, water, frame, tile border or square; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 6 — spr_pond_power_wave:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a tile of a match-three board in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown small (about 60 to 80 pixels) on dark water, next to many other tiles, so it must read instantly by its shape and color.

SUBJECT: A small curling water wave in teal and white foam, stylized like a sumi-e ink wave, clearly moving to the side.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 75% of the canvas. Bold, simple silhouette, soft light rim around the edge. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, water, frame, tile border or square; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 7 — spr_pond_power_bloom:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a tile of a match-three board in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown small (about 60 to 80 pixels) on dark water, next to many other tiles, so it must read instantly by its shape and color.

SUBJECT: A burst of lotus petals opening outward from a bright center, like a flower blooming in one instant, with a soft golden glow.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 75% of the canvas. Bold, simple silhouette, soft light rim around the edge. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, water, frame, tile border or square; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 8 — spr_pond_power_moon:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a tile of a match-three board in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown small (about 60 to 80 pixels) on dark water, next to many other tiles, so it must read instantly by its shape and color.

SUBJECT: A pale full moon reflected on water: a glowing cream disk with soft concentric ripples around it.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 75% of the canvas. Bold, simple silhouette, soft light rim around the edge. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, water, frame, tile border or square; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 9 — bg_pond_water:
Create a PORTRAIT image with a 2:3 aspect ratio (1024×1536, not square, not landscape), fully opaque, with NO transparency.

PURPOSE: This is the background of the lotus pond match-three minigame in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws a grid of tiles on top of it.

SUBJECT: Calm, deep pond water seen straight from above: dark green-blue with soft light ripples, a few out-of-focus lily pads and stones only along the edges.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The central 80% of the image is calm, even and dark so the tiles on top stay readable. The game shows this on tall phone screens (9:16), so the left and right 8% of the image may be cropped: keep everything important inside the central 84% of the width.

DO NOT INCLUDE: tiles or grid; fish or flowers in the center; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; frame or border; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 11 — Shishi-odoshi, hojas, musgo y bonsái (10) ⬜

Archivos, en orden: `obj_shishi_bamboo.png`, `obj_shishi_basin.png`, `spr_leaf_01.png`, `spr_leaf_02.png`, `spr_leaf_03.png`, `spr_leaf_04.png`, `tex_moss.png`, `obj_moss_rock.png`, `obj_bonsai_pot.png`, `obj_bonsai_trunk.png`. Carpeta: `store/art/east/`.
Piezas de los cuatro minijuegos de la vista del estanque. El código las mueve (el bambú vuelca, las hojas giran, las ramas crecen), así que cada pieza va sola y recortada. Adjuntá `store/art/style/style_keyart.webp`.

```
Generate exactly 10 separate images. Start generating immediately, without asking questions or requesting confirmation. Each image has its own complete instructions below; follow them separately. Each image is its own file: do NOT combine them into a grid, collage or contact sheet.

Image 1 — obj_shishi_bamboo:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 260 pixels wide), so the image must contain ONLY the object.

SUBJECT: A single thick green bamboo tube cut at a slant at one end, lying horizontally, with two visible nodes. Seen exactly from the side.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 2 — obj_shishi_basin:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 140 pixels wide), so the image must contain ONLY the object.

SUBJECT: A low round stone water basin (tsukubai) seen from the front and a little from above, gray granite with moss at its base and dark water inside.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 3 — spr_leaf_01:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 30 pixels long), so the image must contain ONLY the object.

SUBJECT: A single fallen Japanese maple leaf, bright orange, seen flat from above.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 4 — spr_leaf_02:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 30 pixels long), so the image must contain ONLY the object.

SUBJECT: A single fallen Japanese maple leaf, deep red, seen flat from above.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 5 — spr_leaf_03:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 30 pixels long), so the image must contain ONLY the object.

SUBJECT: A single fallen ginkgo leaf, golden yellow, seen flat from above.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 6 — spr_leaf_04:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 30 pixels long), so the image must contain ONLY the object.

SUBJECT: A single fallen dry oak-like leaf, warm brown, slightly curled, seen flat from above.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 7 — tex_moss:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), fully opaque, with NO transparency.

PURPOSE: This is a seamless texture used to paint moss on rocks in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game masks it with the player's brush strokes.

SUBJECT: Dense, soft cushion moss seen from directly above: many tiny green tufts in light and dark greens, very even.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: Perfectly tileable on all four sides, uniform with no focal point and no lighting gradient.

DO NOT INCLUDE: rocks, sand or soil; flowers; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; frame or border; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 8 — obj_moss_rock:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 260 pixels wide), so the image must contain ONLY the object.

SUBJECT: A large, low, rounded garden rock seen from slightly above, bare gray stone with subtle cracks and NO moss at all (the player paints it).

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 9 — obj_bonsai_pot:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 200 pixels wide), so the image must contain ONLY the object.

SUBJECT: A wide, shallow rectangular bonsai pot in dark reddish-brown unglazed clay, with small feet, empty and seen from the front.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 10 — obj_bonsai_trunk:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 260 pixels tall), so the image must contain ONLY the object.

SUBJECT: The bare trunk of a small bonsai tree with no leaves: a twisting dark trunk rising from a little mound of soil and splitting into three main branches that end in bare tips.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 12 — Vista del estanque (1) ⬜

Archivos, en orden: `bg_east_ground.png`. Carpeta: `store/art/bg/`.
Segunda vista del jardín (se llega deslizando). Va encima del mismo cielo y las mismas colinas que el patio. Adjuntá `store/art/style/style_keyart.webp` y `bg_base_ground`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a PORTRAIT image with a 2:3 aspect ratio (1024×1536, not square, not landscape), PNG with a transparent background (real alpha channel) wherever the description says the image is empty. If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is the ground layer of the second garden view in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars), the pond side. The game places the shishi-odoshi, the bonsai, the mossy rocks and the leafy path on top of it.

SUBJECT: A small Japanese garden seen from a gentle three-quarter view from above: grass and moss ground with a calm irregular pond in the lower left, a curving gravel path from the bottom edge to the right, and a few low flat stones around the pond edge.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The ground fills only the lower 55% of the image; above it everything is fully transparent. Leave open, calm areas at the upper right, the middle right and above the pond for the objects. The game shows this on tall phone screens (9:16), so the left and right 8% of the image may be cropped: keep everything important inside the central 84% of the width.

DO NOT INCLUDE: lanterns, trees, bamboo or objects; sky; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; people or animals; frame or border; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 13 — Caligrafía (Ensō) y Templo (Campana) (5) ⬜

Archivos, en orden: `obj_callig_hall.png`, `obj_temple_belltower.png`, `obj_temple_bell.png`, `obj_temple_log.png`, `bg_enso_paper.png`. Carpeta: `store/art/temple/`.
Las dos zonas nuevas de la vista del estanque y las piezas de sus minijuegos. El código dibuja la tinta del ensō y mueve el tronco y la campana, así que cada pieza va sola y recortada. Adjuntá `store/art/style/style_keyart.webp`.

```
Generate exactly 5 separate images. Start generating immediately, without asking questions or requesting confirmation. Each image has its own complete instructions below; follow them separately. Each image is its own file: do NOT combine them into a grid, collage or contact sheet.

Image 1 — obj_callig_hall:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 220 pixels tall), so the image must contain ONLY the object.

SUBJECT: A tiny open Japanese calligraphy pavilion: dark curved tile roof, two wooden posts, a paper back wall with one hanging scroll showing a black ensō circle, on a low wooden floor. Seen from the front and a little from above.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 2 — obj_temple_belltower:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 300 pixels tall), so the image must contain ONLY the object.

SUBJECT: A small Japanese bell tower (shōrō) with NO bell inside: four wooden posts, a dark curved tile roof and a crossbeam to hang a bell from. Seen from the front.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 3 — obj_temple_bell:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 260 pixels tall), so the image must contain ONLY the object.

SUBJECT: A single Japanese bronze temple bell (bonshō) hanging alone, tall and rounded, aged greenish-brown bronze with raised bands and rows of small round knobs near the top.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 4 — obj_temple_log:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 240 pixels wide), so the image must contain ONLY the object.

SUBJECT: A single horizontal wooden striking log (shumoku) for a temple bell, a smooth round beam of pale wood with a darker worn tip at one end, lying exactly sideways.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 5 — bg_enso_paper:
Create a PORTRAIT image with a 2:3 aspect ratio (1024×1536, not square, not landscape), fully opaque, with NO transparency.

PURPOSE: This is the background of the ensō minigame in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The player paints a black brush circle on top of it.

SUBJECT: A sheet of warm cream washi paper seen straight on, with soft visible fibers and a small red square seal stamp near the lower right corner.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: Even and calm everywhere, especially the center, so the black ink reads clearly. The game shows this on tall phone screens (9:16), so the left and right 8% of the image may be cropped: keep everything important inside the central 84% of the width.

DO NOT INCLUDE: ink strokes or circles; characters or writing; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; frame or border; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

---

# Ya incluidas (8)

| Imagen | Archivo en el juego | Uso |
|---|---|---|
| `logo_symbol` | `assets/images/brand/logo_symbol.webp` | Símbolo del logo (piedra sobre arena rastrillada). Pantalla de título (`lib/ui/title_intro.dart`); referencia para el ícono. |
| `logo_wordmark` | `assets/images/brand/logo_wordmark.webp` | Nombre "Sandora". Pantalla de título. La versión clara para fondos oscuros se saca con código cuando haga falta. |
| `style_keyart` | `store/art/style/style_keyart.webp` | Referencia de estilo: no va en el juego (`store/` no se sube al repo). Adjuntala en cada bloque siguiente. |
| `title_bg` | `assets/images/title/title_bg.webp` | Fondo de la pantalla de título (`lib/ui/title_intro.dart`), con el logo sobre el cielo. |
| `ui_garden_sign` | `assets/images/ui/ui_garden_sign.webp` | Cartel del jardín, recortado (`lib/ui/widgets/garden_sign.dart`). Se usa de ancho fijo con el nombre sobre la tabla, sin nine-slice. |
| `icon_pebble` | `assets/images/icons/icon_pebble.webp` | Piedritas, recortado a 160 px (`lib/ui/widgets/currency.dart`). |
| `icon_essence_water` | `assets/images/icons/icon_essence_water.webp` | Agua, recortado a 160 px (`currency.dart`). |
| `icon_essence_sand` | `assets/images/icons/icon_essence_sand.webp` | Arena, recortado a 160 px (`currency.dart`). |
