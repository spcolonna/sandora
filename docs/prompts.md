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

## Bloque 14 — Bosque: Casa de té (Matcha), Bambú (Flauta) y Río (Linternas) (7) ⬜

Archivos, en orden: `obj_tea_house.png`, `obj_bamboo_grove.png`, `obj_tea_bowl.png`, `obj_tea_whisk.png`, `obj_bamboo_flute.png`, `obj_river_lantern.png`, `bg_river.png`. Carpeta: `store/art/forest/`.
La tercera vista del jardín y las piezas de sus minijuegos. El código dibuja la espuma del té, las ráfagas de viento y la corriente, así que cada pieza va sola y recortada. Adjuntá `store/art/style/style_keyart.webp`.

```
Generate exactly 7 separate images. Start generating immediately, without asking questions or requesting confirmation. Each image has its own complete instructions below; follow them separately. Each image is its own file: do NOT combine them into a grid, collage or contact sheet.

Image 1 — obj_tea_house:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 260 pixels tall), so the image must contain ONLY the object.

SUBJECT: A tiny Japanese tea house (chashitsu): a low wooden platform, paper shoji walls with a thin wooden grid, a dark indigo noren curtain over the small entrance and a heavy dark thatched roof with softly curved eaves. Seen from the front and a little from above.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 2 — obj_bamboo_grove:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 320 pixels tall), so the image must contain ONLY the object.

SUBJECT: A tight grove of eight tall green bamboo culms of different heights and shades, with visible nodes and light fans of thin leaves near the tops, growing from a small mossy mound. Seen from the front.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 3 — obj_tea_bowl:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 300 pixels wide), so the image must contain ONLY the object.

SUBJECT: A single Japanese matcha bowl (chawan) seen straight from ABOVE: a thick, slightly irregular rim of dark brown glazed clay with a lighter drip, and the inside EMPTY, showing the pale bottom of the bowl.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style; tea, foam, whisk or spoon.

Image 4 — obj_tea_whisk:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 120 pixels wide), so the image must contain ONLY the object.

SUBJECT: A single bamboo tea whisk (chasen) seen straight from ABOVE: a pale bamboo center with many thin curved tines opening in a circle around it.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style; bowl or tea.

Image 5 — obj_bamboo_flute:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 420 pixels tall), so the image must contain ONLY the object.

SUBJECT: A single Japanese bamboo flute (shakuhachi-like) standing exactly upright: pale golden bamboo with three darker nodes and FOUR round finger holes evenly spaced along the middle.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style; hands or strings.

Image 6 — obj_river_lantern:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 80 pixels tall), so the image must contain ONLY the object.

SUBJECT: A single small floating paper lantern (tōrō nagashi) seen from above at a slight angle: a square wooden base and a glowing warm paper cube on top.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style; water.

Image 7 — bg_river:
Create a PORTRAIT image with a 2:3 aspect ratio (1024×1536, not square, not landscape), fully opaque, with NO transparency.

PURPOSE: This is the background of the river lanterns minigame in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The code draws the stones, the lantern, the dock and the current on top of it.

SUBJECT: A calm river seen straight from above, flowing from top to bottom and filling the middle 84% of the width, with narrow sandy and grassy banks on both sides and a few soft ripples.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The water is even and calm everywhere, without rocks or objects, so the pieces on top read clearly. The game shows this on tall phone screens (9:16), so the left and right 8% of the image may be cropped: keep everything important inside the central 84% of the width.

DO NOT INCLUDE: stones in the water; boats, lanterns or docks; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; people or animals; frame or border; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 15 — Decoraciones del jardín (2 de 2) (6) ⬜

Archivos, en orden: `obj_decor_basin.png`, `obj_decor_bench.png`, `obj_decor_jizo.png`, `obj_decor_pagoda.png`, `obj_decor_maple.png`, `obj_decor_sakura.png`. Carpeta: `store/art/decor/`.
Las seis decoraciones de nivel alto del modo Decorar. Igual que el Bloque 3: van a `assets/images/decor/obj_decor_<id>.webp` y reemplazan la versión pintada con código. Adjuntá `store/art/style/style_keyart.webp` y `style_plants.png`.

```
Generate exactly 6 separate images. Start generating immediately, without asking questions or requesting confirmation. Each image has its own complete instructions below; follow them separately. Each image is its own file: do NOT combine them into a grid, collage or contact sheet.

Image 1 — obj_decor_basin:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 100 pixels wide), so the image must contain ONLY the object.

SUBJECT: A low Japanese stone water basin (tsukubai): a rough rounded gray stone with a shallow bowl of still, clear water carved in its top, and a thin bamboo spout above one side letting a tiny trickle fall in.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 2 — obj_decor_bench:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 140 pixels wide), so the image must contain ONLY the object.

SUBJECT: A simple low Japanese garden bench made of warm brown wooden planks on two thick dark wooden legs, slightly weathered, seen from the front and a little from the side.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 3 — obj_decor_jizo:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 110 pixels tall), so the image must contain ONLY the object.

SUBJECT: A small, round and friendly Jizō stone statue: a smooth gray stone figure with a bald round head, closed eyes and a gentle smile, wearing a faded red cloth bib, standing on a low square stone base.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 4 — obj_decor_pagoda:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 200 pixels tall), so the image must contain ONLY the object.

SUBJECT: A slender stone pagoda (sekitō) with five stacked tiers: each tier a small square stone block under a wide, slightly curved stone roof, getting smaller towards the top, with a thin finial. Weathered gray stone with a little moss on the lower roofs.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 5 — obj_decor_maple:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 180 pixels tall), so the image must contain ONLY the object.

SUBJECT: A small Japanese maple tree (momiji) in autumn: a dark, gracefully forked trunk and a soft, layered rounded canopy of red and orange leaves.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.

Image 6 — obj_decor_sakura:
Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 190 pixels tall), so the image must contain ONLY the object.

SUBJECT: A small cherry tree in full bloom: a dark, gently twisting trunk and a soft, rounded canopy of pale pink blossoms with a few petals falling.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

---

# Ya incluidas (48)

| Imagen | Archivo en el juego | Uso |
|---|---|---|
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
| `obj_decor_azalea` | `assets/images/decor/obj_decor_azalea.webp` | Azalea del modo Decorar, 480 px; el aspect del balance sigue al arte (`garden_decor.dart`). |
