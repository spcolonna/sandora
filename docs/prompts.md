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

**Fuera de este archivo:** los sonidos (los placeholders salen de `tool/gen_audio.py`; los finales
conviene grabarlos), los shaders (`shd_*`, son código), el mapa de alturas de la arena y las animaciones Rive
(`char_*.riv`, se arman en Rive a partir de las imágenes del Bloque 5).

---

# Para generar ahora

## Bloque 26 — Los Miradores (20)

**Por qué ahora:** Los Miradores son el jardín principal: hoy cielo, bosque, suelo, portones y pabellón son de código.

El jardín principal: un patio grande que se recorre **de mirador en mirador**; en cada uno se gira 360° y se camina por senderos de piedras al siguiente. Los objetos se ven **de frente, a la altura de los ojos** (no desde arriba como el patio viejo); lo plano del suelo (piedra con luz, huecos) se ve **desde arriba**. Las franjas tienen que **repetirse a lo ancho sin costura** (dan la vuelta entera). El suelo, el muro, el estanque, los surcos del rastrillo y la galería del pabellón los dibuja el juego. **Reusan arte que ya existe** (no hace falta pedirlo): árboles, rocas, azaleas, faroles y bambú de la decoración (`obj_decor_*`), Lluvia `obj_court_jars`, Apilar `obj_stack_pedestal`, Shishi `obj_shishi_basin`, Musgo `obj_moss_rock`, Bonsái `obj_bonsai_table` + `obj_bonsai_pot` + `obj_decor_pine`, Ensō `obj_callig_hall`, Campana `obj_temple_belltower`, Té `obj_tea_house`, Flauta `obj_bamboo_flute`, Linternas `obj_river_lantern`, tablón `obj_court_board`, agua `bg_pond_water`, visitantes `char_visitor_*`. La mesa de la Maqueta es `obj_model_table` (Bloque 25). **Adjuntá `store/art/style/style_courtyard_ref.webp`.** En el juego van en `assets/images/path/`.

### 1. `pano_sky` ⬜

Guardala como `store/art/path/pano_sky.png`. Adjuntá `store/art/style/style_courtyard_ref.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a LANDSCAPE image with a 3:2 aspect ratio (1536×1024, not square, not portrait), fully opaque, with NO transparency.

PURPOSE: This is a background band of the 360-degree garden lookouts of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars): the player stands in the garden and drags to turn all the way around, and the game repeats this band side by side around them, so it must tile horizontally without any visible seam.

SUBJECT: A soft watercolor sky: pale warm cream near the bottom fading to a gentle light blue at the top, with a few long, thin, softly brushed clouds drifting across.

STYLE: Detailed hand-painted watercolor and gouache illustration, exactly like the attached reference image of the courtyard: rich but soft, natural proportions and believable materials (weathered granite, deep green moss, finely raked pale gravel, aged warm wood, clay plaster). Atmospheric perspective: the distance is lighter, bluer and misty. Warm soft morning light from the upper left with gentle cast shadows toward the lower right. Subtle paper grain and visible soft brush texture, no harsh outlines.

COMPOSITION: Frontal view at eye level. The sky fills the whole canvas, fully opaque, with no land at all. Seamless horizontally: the left edge continues exactly into the right edge (same height, same colors, no object cut at either edge). Soft, airy and calm, with no single striking feature that would look repeated.

DO NOT INCLUDE: buildings, paths, walls, people, animals, sun, any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters, photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 2. `pano_far_mountains` ⬜

Guardala como `store/art/path/pano_far_mountains.png`. Adjuntá `store/art/style/style_courtyard_ref.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a LANDSCAPE image with a 3:2 aspect ratio (1536×1024, not square, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a background band of the 360-degree garden lookouts of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars): the player stands in the garden and drags to turn all the way around, and the game repeats this band side by side around them, so it must tile horizontally without any visible seam.

SUBJECT: A soft range of distant blue-grey mountains with gentle rounded peaks, washed in morning mist, very light and airy like the far mountains in the reference.

STYLE: Detailed hand-painted watercolor and gouache illustration, exactly like the attached reference image of the courtyard: rich but soft, natural proportions and believable materials (weathered granite, deep green moss, finely raked pale gravel, aged warm wood, clay plaster). Atmospheric perspective: the distance is lighter, bluer and misty. Warm soft morning light from the upper left with gentle cast shadows toward the lower right. Subtle paper grain and visible soft brush texture, no harsh outlines.

COMPOSITION: Frontal view at eye level. The mountains occupy the lower 40% of the canvas; everything above them is fully transparent (the game paints the sky). Their base is flat and fades softly into mist. Seamless horizontally: the left edge continues exactly into the right edge (same height, same colors, no object cut at either edge). Soft, airy and calm, with no single striking feature that would look repeated.

DO NOT INCLUDE: buildings, paths, walls, people, animals, sun, any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters, photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 3. `pano_forest` ⬜

Guardala como `store/art/path/pano_forest.png`. Adjuntá `store/art/style/style_courtyard_ref.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a LANDSCAPE image with a 3:2 aspect ratio (1536×1024, not square, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a background band of the 360-degree garden lookouts of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars): the player stands in the garden and drags to turn all the way around, and the game repeats this band side by side around them, so it must tile horizontally without any visible seam.

SUBJECT: The edge of a calm forest seen beyond a garden wall: a continuous row of tree crowns of different heights (Japanese black pines with cloud-shaped layers, tall cedars, a few maples with orange touches and clumps of bamboo), in soft greens with a light haze.

STYLE: Detailed hand-painted watercolor and gouache illustration, exactly like the attached reference image of the courtyard: rich but soft, natural proportions and believable materials (weathered granite, deep green moss, finely raked pale gravel, aged warm wood, clay plaster). Atmospheric perspective: the distance is lighter, bluer and misty. Warm soft morning light from the upper left with gentle cast shadows toward the lower right. Subtle paper grain and visible soft brush texture, no harsh outlines.

COMPOSITION: Frontal view at eye level. The crowns occupy the lower 60% of the canvas, with a varied, natural top edge; everything above is fully transparent. The bottom 15% is a flat, even band of dark foliage (a wall will cover it). Seamless horizontally: the left edge continues exactly into the right edge (same height, same colors, no object cut at either edge). Soft, airy and calm, with no single striking feature that would look repeated.

DO NOT INCLUDE: buildings, paths, walls, people, animals, sun, any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters, photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 4. `tex_pano_ground_detail` ⬜

Guardala como `store/art/path/tex_pano_ground_detail.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), fully opaque, with NO transparency.

PURPOSE: This is a seamless ground DETAIL texture for the 360-degree garden of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game lays it flat on the ground in perspective, repeats it in a grid and MULTIPLIES it by its own ground colors (pale gravel, green moss), so the texture itself must be almost white: only soft light-grey shading gives the detail.

SUBJECT: Fine raked gravel and tiny pebbles: soft parallel rake grooves, scattered small pebbles with gentle light-grey shading, a few faint specks, all very pale.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: Seen straight from above (top-down, 90 degrees), evenly lit with no directional shadows, filling the whole canvas edge to edge. Overall very light (mostly 85-100% brightness), desaturated, low contrast. Seamless: the left edge continues exactly into the right edge and the top into the bottom. Details stay small and evenly spread, with no single feature that would repeat visibly.

DO NOT INCLUDE: color tints, dark areas, large stones, plants, objects, borders, vignette, light spots, any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters, photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 5. `obj_path_gate` ⬜

Guardala como `store/art/path/obj_path_gate.png`. Adjuntá `store/art/style/style_courtyard_ref.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This object stands in the 360-degree garden of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars), which the player explores from lookouts, turning around and walking between them. It is behind the player when they arrive at the garden. The game draws the ground, fog and distance itself and scales the object by distance (up to the full screen height), so the image must contain ONLY the object, matching the attached courtyard reference in light and brushwork.

SUBJECT: The main wooden gate of the garden seen from inside: a roofed gate (yakuimon style) with two thick posts, a small dark-tiled roof with upturned eaves, and its two wooden doors swung fully open toward the viewer, so through the opening you see a stone path leaving between trees outside. About as wide as tall.

STYLE: Detailed hand-painted watercolor and gouache illustration, exactly like the attached reference image of the courtyard: rich but soft, natural proportions and believable materials (weathered granite, deep green moss, finely raked pale gravel, aged warm wood, clay plaster). Atmospheric perspective: the distance is lighter, bluer and misty. Warm soft morning light from the upper left with gentle cast shadows toward the lower right. Subtle paper grain and visible soft brush texture, no harsh outlines.

COMPOSITION: Camera: a person standing in the garden at eye level (about 1.6 m), looking straight ahead at the object a few steps away: a frontal, almost horizontal view with only a very slight look down (about 5 degrees), no strong perspective distortion. The object is centered and fills about 85% of the canvas height. Its base sits on an imaginary flat ground line near the bottom of the canvas with only a very soft contact shadow right under it. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold silhouette that still reads when it is small in the distance.

DO NOT INCLUDE: any background, ground patch, sky, path or scenery behind the object; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 6. `obj_gate_future` ⬜

Guardala como `store/art/path/obj_gate_future.png`. Adjuntá `store/art/style/style_courtyard_ref.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This object stands in the 360-degree garden of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars), which the player explores from lookouts, turning around and walking between them. It closes the way to new areas of the garden that will open later. The game draws the ground, fog and distance itself and scales the object by distance (up to the full screen height), so the image must contain ONLY the object, matching the attached courtyard reference in light and brushwork.

SUBJECT: The same roofed wooden garden gate (yakuimon style), now with its two doors closed: a thick twisted straw shimenawa rope with white zigzag paper streamers hangs across the doors, and a small round blank wooden plaque hangs from its middle (the game draws a lock on it). About as wide as tall.

STYLE: Detailed hand-painted watercolor and gouache illustration, exactly like the attached reference image of the courtyard: rich but soft, natural proportions and believable materials (weathered granite, deep green moss, finely raked pale gravel, aged warm wood, clay plaster). Atmospheric perspective: the distance is lighter, bluer and misty. Warm soft morning light from the upper left with gentle cast shadows toward the lower right. Subtle paper grain and visible soft brush texture, no harsh outlines.

COMPOSITION: Camera: a person standing in the garden at eye level (about 1.6 m), looking straight ahead at the object a few steps away: a frontal, almost horizontal view with only a very slight look down (about 5 degrees), no strong perspective distortion. The object is centered and fills about 85% of the canvas height. Its base sits on an imaginary flat ground line near the bottom of the canvas with only a very soft contact shadow right under it. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold silhouette that still reads when it is small in the distance.

DO NOT INCLUDE: any background, ground patch, sky, path or scenery behind the object; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 7. `spr_path_glow_stone` ⬜

Guardala como `store/art/path/spr_path_glow_stone.png`. Adjuntá `store/art/style/style_courtyard_ref.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is the stepping stone the player taps to walk to the next lookout of the 360-degree garden of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game lays it flat on the ground in perspective and paints a small arrow on top pointing where it leads.

SUBJECT: One flat, rounded, slightly irregular granite stepping stone, warm grey, with a soft warm golden glow around its edge as if lit from below at dusk, and a thin ring of moss.

STYLE: Detailed hand-painted watercolor and gouache illustration, exactly like the attached reference image of the courtyard: rich but soft, natural proportions and believable materials (weathered granite, deep green moss, finely raked pale gravel, aged warm wood, clay plaster). Atmospheric perspective: the distance is lighter, bluer and misty. Warm soft morning light from the upper left with gentle cast shadows toward the lower right. Subtle paper grain and visible soft brush texture, no harsh outlines.

COMPOSITION: Seen straight from above (top-down), centered, filling about 80% of the canvas, almost round. The center of the stone stays plain and smooth (the arrow goes there). All four corners stay empty and transparent.

DO NOT INCLUDE: any background, gravel, grass, arrows, symbols, other stones, any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters, photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 8. `obj_pavilion_back` ⬜

Guardala como `store/art/path/obj_pavilion_back.png`. Adjuntá `store/art/style/style_courtyard_ref.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a LANDSCAPE image with a 3:2 aspect ratio (1536×1024, not square, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is the BACK layer of the small wooden pavilion of the 360-degree garden of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws three layers: this back wall, then the raised wooden floor with the meditation cushion and a low table, then the front posts and roof (another image). Seen from the garden at eye level.

SUBJECT: The rear wall of a small open Japanese pavilion: dark weathered wooden frame, sliding shoji panels pushed open to both sides, and in the dim warm interior a tokonoma alcove with a hanging ink scroll and a small vase with one branch. The wall stands on the floor line at the bottom.

STYLE: Detailed hand-painted watercolor and gouache illustration, exactly like the attached reference image of the courtyard: rich but soft, natural proportions and believable materials (weathered granite, deep green moss, finely raked pale gravel, aged warm wood, clay plaster). Atmospheric perspective: the distance is lighter, bluer and misty. Warm soft morning light from the upper left with gentle cast shadows toward the lower right. Subtle paper grain and visible soft brush texture, no harsh outlines.

COMPOSITION: Frontal view at eye level, perfectly straight, centered, filling the whole canvas width (about 1.6 times wider than tall). The bottom edge is the floor line. Nothing above the wall: no roof (it is in the front layer). All corners above the wall stay transparent.

DO NOT INCLUDE: roof, front posts, floor or deck, people, cushions, tables, ground, sky, any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters, photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 9. `obj_pavilion_front` ⬜

Guardala como `store/art/path/obj_pavilion_front.png`. Adjuntá `store/art/style/style_courtyard_ref.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a LANDSCAPE image with a 3:2 aspect ratio (1536×1024, not square, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is the FRONT layer of the small wooden pavilion of the 360-degree garden of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars): it is drawn over the floor, the meditation cushion and the table, so everything between the posts must be fully transparent to let them show through.

SUBJECT: Only the front posts and the roof of a small Japanese pavilion: two slender dark wooden posts at the far left and far right edges, a wooden beam joining them under the eaves, and a hip-and-gable roof with dark grey tiles, a ridge on top and gently upturned eave corners, matching the rear wall layer.

STYLE: Detailed hand-painted watercolor and gouache illustration, exactly like the attached reference image of the courtyard: rich but soft, natural proportions and believable materials (weathered granite, deep green moss, finely raked pale gravel, aged warm wood, clay plaster). Atmospheric perspective: the distance is lighter, bluer and misty. Warm soft morning light from the upper left with gentle cast shadows toward the lower right. Subtle paper grain and visible soft brush texture, no harsh outlines.

COMPOSITION: Frontal view at eye level, perfectly straight, centered, filling the whole canvas width (about 1.6 times wider than tall). The roof takes the upper 40%; the posts run down to the bottom edge. The whole area between the posts below the beam is EMPTY and transparent.

DO NOT INCLUDE: walls, shoji, interior, floor, people, plants, sky, ground, any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters, photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 10. `obj_path_bush` ⬜

Guardala como `store/art/path/obj_path_bush.png`. Adjuntá `store/art/style/style_courtyard_ref.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This object stands in the 360-degree garden of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars), which the player explores from lookouts, turning around and walking between them. Rows of them grow along the foot of the garden wall. The game draws the ground, fog and distance itself and scales the object by distance (up to a third of the screen width), so the image must contain ONLY the object, matching the attached courtyard reference in light and brushwork.

SUBJECT: A rounded clipped azalea shrub pruned into soft cloud-like mounds (karikomi), dense deep and light greens with a few small pink flowers. Wider than tall.

STYLE: Detailed hand-painted watercolor and gouache illustration, exactly like the attached reference image of the courtyard: rich but soft, natural proportions and believable materials (weathered granite, deep green moss, finely raked pale gravel, aged warm wood, clay plaster). Atmospheric perspective: the distance is lighter, bluer and misty. Warm soft morning light from the upper left with gentle cast shadows toward the lower right. Subtle paper grain and visible soft brush texture, no harsh outlines.

COMPOSITION: Camera: a person standing in the garden at eye level (about 1.6 m), looking straight ahead at the object a few steps away: a frontal, almost horizontal view with only a very slight look down (about 5 degrees), no strong perspective distortion. The object is centered and fills about 85% of the canvas height. Its base sits on an imaginary flat ground line near the bottom of the canvas with only a very soft contact shadow right under it. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold silhouette that still reads when it is small in the distance.

DO NOT INCLUDE: any background, ground patch, sky, path or scenery behind the object; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 11. `obj_station_sand` ⬜

Guardala como `store/art/path/obj_station_sand.png`. Adjuntá `store/art/style/style_courtyard_ref.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This object stands in the 360-degree garden of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars), which the player explores from lookouts, turning around and walking between them. Tapping it opens the sand raking game. The game draws the ground, fog and distance itself and scales the object by distance (up to half the screen width), so the image must contain ONLY the object, matching the attached courtyard reference in light and brushwork.

SUBJECT: A small rectangular raked-sand garden in a low wooden frame: pale sand with concentric rake lines around two small stones, and a wooden rake leaning on the frame. Wider than tall.

STYLE: Detailed hand-painted watercolor and gouache illustration, exactly like the attached reference image of the courtyard: rich but soft, natural proportions and believable materials (weathered granite, deep green moss, finely raked pale gravel, aged warm wood, clay plaster). Atmospheric perspective: the distance is lighter, bluer and misty. Warm soft morning light from the upper left with gentle cast shadows toward the lower right. Subtle paper grain and visible soft brush texture, no harsh outlines.

COMPOSITION: Camera: a person standing in the garden at eye level (about 1.6 m), looking straight ahead at the object a few steps away: a frontal, almost horizontal view with only a very slight look down (about 5 degrees), no strong perspective distortion. The object is centered and fills about 85% of the canvas height. Its base sits on an imaginary flat ground line near the bottom of the canvas with only a very soft contact shadow right under it. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold silhouette that still reads when it is small in the distance.

DO NOT INCLUDE: any background, ground patch, sky, path or scenery behind the object; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 12. `obj_station_leaves` ⬜

Guardala como `store/art/path/obj_station_leaves.png`. Adjuntá `store/art/style/style_courtyard_ref.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This object stands in the 360-degree garden of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars), which the player explores from lookouts, turning around and walking between them. Tapping it opens the leaf sweeping game. The game draws the ground, fog and distance itself and scales the object by distance (up to half the screen height), so the image must contain ONLY the object, matching the attached courtyard reference in light and brushwork.

SUBJECT: A small Japanese maple tree with red and orange leaves, a few leaves falling, and a soft pile of fallen leaves at its foot with a bamboo broom leaning on the trunk.

STYLE: Detailed hand-painted watercolor and gouache illustration, exactly like the attached reference image of the courtyard: rich but soft, natural proportions and believable materials (weathered granite, deep green moss, finely raked pale gravel, aged warm wood, clay plaster). Atmospheric perspective: the distance is lighter, bluer and misty. Warm soft morning light from the upper left with gentle cast shadows toward the lower right. Subtle paper grain and visible soft brush texture, no harsh outlines.

COMPOSITION: Camera: a person standing in the garden at eye level (about 1.6 m), looking straight ahead at the object a few steps away: a frontal, almost horizontal view with only a very slight look down (about 5 degrees), no strong perspective distortion. The object is centered and fills about 85% of the canvas height. Its base sits on an imaginary flat ground line near the bottom of the canvas with only a very soft contact shadow right under it. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold silhouette that still reads when it is small in the distance.

DO NOT INCLUDE: any background, ground patch, sky, path or scenery behind the object; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 13. `obj_station_meditation` ⬜

Guardala como `store/art/path/obj_station_meditation.png`. Adjuntá `store/art/style/style_courtyard_ref.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This object stands in the 360-degree garden of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars), which the player explores from lookouts, turning around and walking between them. It rests on the wooden floor of the pavilion; tapping it starts a meditation. The game draws the ground, fog and distance itself and scales the object by distance (up to a fifth of the screen width), so the image must contain ONLY the object, matching the attached courtyard reference in light and brushwork.

SUBJECT: A round dark-blue zafu meditation cushion on a small square tatami mat, with a tiny bronze singing bowl and an incense holder with a thin wisp of smoke beside it. Wider than tall.

STYLE: Detailed hand-painted watercolor and gouache illustration, exactly like the attached reference image of the courtyard: rich but soft, natural proportions and believable materials (weathered granite, deep green moss, finely raked pale gravel, aged warm wood, clay plaster). Atmospheric perspective: the distance is lighter, bluer and misty. Warm soft morning light from the upper left with gentle cast shadows toward the lower right. Subtle paper grain and visible soft brush texture, no harsh outlines.

COMPOSITION: Camera: a person standing in the garden at eye level (about 1.6 m), looking straight ahead at the object a few steps away: a frontal, almost horizontal view with only a very slight look down (about 5 degrees), no strong perspective distortion. The object is centered and fills about 85% of the canvas height. Its base sits on an imaginary flat ground line near the bottom of the canvas with only a very soft contact shadow right under it. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold silhouette that still reads when it is small in the distance.

DO NOT INCLUDE: any background, ground patch, sky, path or scenery behind the object; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 14. `spr_path_slot` ⬜

Guardala como `store/art/path/spr_path_slot.png`. Adjuntá `store/art/style/style_courtyard_ref.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This marks a free spot of the 360-degree garden of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars) where the player can place a decoration. The game lays it flat on the ground in perspective and makes it pulse softly.

SUBJECT: A soft circle of tiny pale pebbles on the ground with a faint warm glow in the middle, like an invitation, very light and delicate.

STYLE: Detailed hand-painted watercolor and gouache illustration, exactly like the attached reference image of the courtyard: rich but soft, natural proportions and believable materials (weathered granite, deep green moss, finely raked pale gravel, aged warm wood, clay plaster). Atmospheric perspective: the distance is lighter, bluer and misty. Warm soft morning light from the upper left with gentle cast shadows toward the lower right. Subtle paper grain and visible soft brush texture, no harsh outlines.

COMPOSITION: Seen straight from above (top-down), centered, filling about 85% of the canvas. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, objects, plants, any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters, photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 15. `spr_path_slot_locked` ⬜

Guardala como `store/art/path/spr_path_slot_locked.png`. Adjuntá `store/art/style/style_courtyard_ref.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This marks a spot of the 360-degree garden of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars) that is still closed; the player can pay to open it. The game lays it flat on the ground in perspective.

SUBJECT: A small square of rough unraked earth bordered by four little wooden stakes joined by a thin straw rope.

STYLE: Detailed hand-painted watercolor and gouache illustration, exactly like the attached reference image of the courtyard: rich but soft, natural proportions and believable materials (weathered granite, deep green moss, finely raked pale gravel, aged warm wood, clay plaster). Atmospheric perspective: the distance is lighter, bluer and misty. Warm soft morning light from the upper left with gentle cast shadows toward the lower right. Subtle paper grain and visible soft brush texture, no harsh outlines.

COMPOSITION: Seen straight from above (top-down), centered, filling about 85% of the canvas. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, plants, padlock, any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters, photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 16. `icon_btn_aerial` ⬜

Guardala como `store/art/path/icon_btn_aerial.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a round button icon on the main screen of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown about 44 pixels wide over the garden scene, so it must read instantly at that size.

SUBJECT: A tiny folded paper map of a garden with a winding path drawn in ink, seen slightly from above, in warm washi colors.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single simple object or symbol, perfectly centered, filling about 75% of the canvas. Very bold shape, strong value contrast, a soft light rim so it reads on light and dark scenery. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, circle, button frame, badge; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 17. `icon_btn_quick` ⬜

Guardala como `store/art/path/icon_btn_quick.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a round button icon on the main screen of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown about 44 pixels wide over the garden scene, so it must read instantly at that size.

SUBJECT: A small bamboo signpost with three short arrow planks pointing different ways, in warm wood and green.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single simple object or symbol, perfectly centered, filling about 75% of the canvas. Very bold shape, strong value contrast, a soft light rim so it reads on light and dark scenery. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, circle, button frame, badge; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 18. `icon_btn_path` ⬜

Guardala como `store/art/path/icon_btn_path.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a round button icon on the main screen of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown about 44 pixels wide over the garden scene, so it must read instantly at that size.

SUBJECT: A short path of three glowing stepping stones leading toward a small wooden pavilion, seen from the front.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single simple object or symbol, perfectly centered, filling about 75% of the canvas. Very bold shape, strong value contrast, a soft light rim so it reads on light and dark scenery. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, circle, button frame, badge; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 19. `icon_btn_classic` ⬜

Guardala como `store/art/path/icon_btn_classic.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a round button icon on the main screen of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown about 44 pixels wide over the garden scene, so it must read instantly at that size.

SUBJECT: A small hanging scroll showing a tiny painted garden scene, in warm paper and wood tones.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single simple object or symbol, perfectly centered, filling about 75% of the canvas. Very bold shape, strong value contrast, a soft light rim so it reads on light and dark scenery. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, circle, button frame, badge; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 20. `bg_path_aerial_paper` ⬜

Guardala como `store/art/path/bg_path_aerial_paper.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), fully opaque, with NO transparency.

PURPOSE: This is the paper on which a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars) draws the garden plan seen from above, where the player arranges decorations. The game draws the paths, places and pieces on top and stretches the paper.

SUBJECT: Warm off-white handmade washi paper with soft visible fibers, very faint pale green and beige washes and an almost invisible grid of pale ink lines.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: Flat, evenly lit, filling the whole canvas edge to edge, seamless in both directions, with no strong features.

DO NOT INCLUDE: drawings, maps, objects, stains, folds, borders, any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters, photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 22 — Lo que más se ve y sigue siendo código (10)

**Por qué ahora:** Lo más visible que queda en código: las puertas se ven en cada arranque, el cielo siempre.

Piezas grandes que hoy son formas de código: las puertas de la entrada (se ven en cada arranque), el sol, la luna y las nubes del cielo, los pájaros, y las piezas sueltas del Shishi-odoshi y de las Linternas. Adjuntá `store/art/style/style_keyart.webp`.

### 21. `obj_gate_shoji` ⬜

Guardala como `store/art/garden/obj_gate_shoji.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a PORTRAIT image with a 2:3 aspect ratio (1024×1536, not square, not landscape), PNG with a transparent background (real alpha channel) wherever the description says the image is empty. If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is ONE sliding shoji door panel of the house entrance in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). Every time the app opens, two of these panels (one mirrored) cover the screen and slide apart to reveal the garden.

SUBJECT: A traditional Japanese shoji door seen straight from the front: a frame of warm honey-colored wood, a fine lattice of thin wooden kumiko bars in a regular grid, and translucent cream washi paper glowing softly with morning light from behind. A small round recessed hand pull near the right edge at middle height. Slight paper texture and gentle wear.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The door panel fills the whole canvas edge to edge (its frame touches all four edges), seen perfectly flat and frontal, no perspective. Nothing outside the door.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; walls, floor, room or garden; people or shadows of people; a second door; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 22. `spr_sun` ⬜

Guardala como `store/art/garden/spr_sun.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 70 pixels wide, high in the sky), so the image must contain ONLY the object.

SUBJECT: A soft morning sun: a warm glowing disk of pale gold with a gentle painted halo fading outward, no face.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style, clouds, rays drawn as lines.
```

### 23. `spr_moon` ⬜

Guardala como `store/art/garden/spr_moon.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 60 pixels wide, high in the night sky), so the image must contain ONLY the object.

SUBJECT: A calm full moon: a pale cream-white disk with very soft grey-blue maria and a faint cool glow around it, no face.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style, stars, clouds.
```

### 24. `spr_cloud_01` ⬜

Guardala como `store/art/garden/spr_cloud_01.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 180 pixels wide, drifting slowly), so the image must contain ONLY the object.

SUBJECT: One soft, fluffy, sunlit cumulus cloud, wider than tall, with a warm cream top and a cool lavender-grey underside, painted with loose watercolor edges.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style, sky color, other clouds.
```

### 25. `spr_cloud_02` ⬜

Guardala como `store/art/garden/spr_cloud_02.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 220 pixels wide, drifting slowly), so the image must contain ONLY the object.

SUBJECT: One long, thin, wispy cloud streak, very light and airy, warm white with faint peach tones, painted with loose watercolor edges.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style, sky color, other clouds.
```

### 26. `spr_bird` ⬜

Guardala como `store/art/garden/spr_bird.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 24 pixels wide, several flying away together), so the image must contain ONLY the object.

SUBJECT: One small songbird (a Japanese white-eye, olive-green with a white eye ring) in flight seen from the side, wings raised mid-flap.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style, branches, other birds.
```

### 27. `obj_shishi_post` ⬜

Guardala como `store/art/garden/obj_shishi_post.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 160 pixels tall), so the image must contain ONLY the object.

SUBJECT: A forked support post made of two thick bamboo poles crossed in an X near the top and tied with dark rope, its feet set in the ground. This holds a seesaw bamboo spout.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style, the moving bamboo spout itself, water.
```

### 28. `obj_shishi_stone` ⬜

Guardala como `store/art/garden/obj_shishi_stone.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 80 pixels wide), so the image must contain ONLY the object.

SUBJECT: A flat, rounded grey river stone with a little moss on one edge, the kind a bamboo deer-scarer strikes when it tips back.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 29. `obj_shishi_feed` ⬜

Guardala como `store/art/garden/obj_shishi_feed.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 200 pixels wide), so the image must contain ONLY the object.

SUBJECT: A thin horizontal bamboo water pipe (kakei) resting on two small crossed bamboo sticks tied with rope, its open end cut at an angle on the right.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style, water stream.
```

### 30. `obj_lantern_dock` ⬜

Guardala como `store/art/garden/obj_lantern_dock.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a LANDSCAPE image with a 3:2 aspect ratio (1536×1024, not square, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is the small wooden dock at the bottom of the river lanterns minigame in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars): the player launches paper lanterns from here.

SUBJECT: A short Japanese wooden dock seen from above at a steep angle: weathered grey-brown planks laid side by side with a few dark nail marks, two thick round posts at the front corners, a faint wet darkening along the edge that touches the water.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The dock spans the full width of the canvas and fills the bottom 55% of it; everything above the dock is fully transparent.

DO NOT INCLUDE: any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; water, river, lanterns, people, boats; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 23 — Íconos pintados de la interfaz (18)

**Por qué ahora:** Los botones del jardín y los sellos de los minijuegos usan íconos genéricos de Material.

Hoy los botones del jardín y los sellos de cada minijuego usan íconos genéricos de Material (se ven de app de oficina). Van chiquitos (28 a 40 px) dentro de botones redondos de papel. Además de la referencia de cada uno, conviene adjuntar `assets/images/icons/icon_lotus.webp` para que sigan el mismo trazo que las monedas.

### 31. `icon_btn_decor` ⬜

Guardala como `store/art/icons/icon_btn_decor.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: A small bonsai pine in a shallow pot, symbolizing "decorate the garden".

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 32. `icon_btn_market` ⬜

Guardala como `store/art/icons/icon_btn_market.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: A small indigo cloth bundle (furoshiki) tied on top, symbolizing "the shop".

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 33. `icon_btn_menu` ⬜

Guardala como `store/art/icons/icon_btn_menu.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: A rolled bamboo scroll with a red cord, symbolizing "the menu".

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 34. `icon_btn_album` ⬜

Guardala como `store/art/icons/icon_btn_album.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: A small stitched Japanese book with a plain indigo cover, symbolizing "album".

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 35. `icon_btn_settings` ⬜

Guardala como `store/art/icons/icon_btn_settings.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: A small round bronze temple bell seen from the front, symbolizing settings and sound.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 36. `icon_game_stack` ⬜

Guardala como `store/art/icons/icon_game_stack.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: Three smooth stones balanced on top of each other.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 37. `icon_game_sand` ⬜

Guardala como `store/art/icons/icon_game_sand.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: A small wooden rake on a patch of raked sand with curved lines.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 38. `icon_game_rain` ⬜

Guardala como `store/art/icons/icon_game_rain.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: One clear blue water drop falling into a small clay jar.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 39. `icon_game_pond` ⬜

Guardala como `store/art/icons/icon_game_pond.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: One pink lotus flower open on a green lily pad.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 40. `icon_game_shishi` ⬜

Guardala como `store/art/icons/icon_game_shishi.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: A short bamboo deer-scarer spout tipped down, pouring a little water.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 41. `icon_game_leaves` ⬜

Guardala como `store/art/icons/icon_game_leaves.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: One orange maple leaf drifting in the wind.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 42. `icon_game_moss` ⬜

Guardala como `store/art/icons/icon_game_moss.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: A rounded grey stone half covered in soft green moss.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 43. `icon_game_bonsai` ⬜

Guardala como `store/art/icons/icon_game_bonsai.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: A small pair of bonsai pruning scissors over a pine twig.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 44. `icon_game_enso` ⬜

Guardala como `store/art/icons/icon_game_enso.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: A single black ink brush circle (enso) with a dry-brush gap.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 45. `icon_game_bell` ⬜

Guardala como `store/art/icons/icon_game_bell.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: A wooden striking log in front of a bronze temple bell.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 46. `icon_game_matcha` ⬜

Guardala como `store/art/icons/icon_game_matcha.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: A small tea bowl of frothy green matcha with a bamboo whisk.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 47. `icon_game_flute` ⬜

Guardala como `store/art/icons/icon_game_flute.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: A short bamboo flute with three finger holes, lying diagonally.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 48. `icon_game_lanterns` ⬜

Guardala como `store/art/icons/icon_game_lanterns.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a currency or interface icon in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). It is shown very small (about 32 to 48 pixels) next to a number, so it must read instantly at that size.

SUBJECT: One glowing paper lantern floating on a small ripple of water.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it stays readable on both light and dark backgrounds. All four corners stay empty and transparent.

DO NOT INCLUDE: any background, frame, circle, coin border, badge or plaque; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; extra objects; fine detail that disappears at small size; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 24 — Detalles que siguen siendo código (11)

**Por qué ahora:** Detalles chicos: los regalos del día, dos cuidados, la escoba, el farolito y el sello del Ensō.

Cosas chicas que se ven menos: los regalos del día, los cuidados que faltan pintar, la escoba del camino de hojas, el farolito de la casa de té y el sello del Ensō. Adjuntá `store/art/style/style_keyart.webp`.

### 49. `obj_care_marks` ⬜

Guardala como `store/art/garden/obj_care_marks.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 70 pixels wide), so the image must contain ONLY the object.

SUBJECT: A small patch of raked sand messed up by footprints and scuffs, the rake lines broken, seen from slightly above.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 50. `obj_care_jar` ⬜

Guardala como `store/art/garden/obj_care_jar.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 50 pixels wide), so the image must contain ONLY the object.

SUBJECT: A small brown clay water jar tipped over on its side with a little water spilled in front of its mouth.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 51. `obj_east_broom` ⬜

Guardala como `store/art/garden/obj_east_broom.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 110 pixels tall), so the image must contain ONLY the object.

SUBJECT: A traditional Japanese bamboo garden broom (takebouki): a long thin bamboo handle and a wide fan of fine twigs, leaning slightly.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 52. `obj_tea_lamp` ⬜

Guardala como `store/art/garden/obj_tea_lamp.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 30 pixels tall), so the image must contain ONLY the object.

SUBJECT: A small hanging paper lantern (chochin) of warm cream paper with thin bamboo ribs, glowing softly from inside, hanging from a short dark cord.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 53. `obj_enso_seal` ⬜

Guardala como `store/art/garden/obj_enso_seal.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 40 pixels wide), so the image must contain ONLY the object.

SUBJECT: A red cinnabar artist seal stamp impression (hanko) as a soft-edged square, carved with an abstract swirl of a pebble and raked lines, slightly uneven ink like a real stamp on paper.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style, the carved stone seal itself.
```

### 54. `spr_gift_dew` ⬜

Guardala como `store/art/garden/spr_gift_dew.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 36 pixels wide), so the image must contain ONLY the object.

SUBJECT: One perfectly round, sparkling dewdrop resting on a small green leaf.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 55. `spr_gift_firefly` ⬜

Guardala como `store/art/garden/spr_gift_firefly.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 36 pixels wide), so the image must contain ONLY the object.

SUBJECT: One small firefly with a soft warm yellow-green glowing tail.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 56. `spr_gift_snowflake` ⬜

Guardala como `store/art/garden/spr_gift_snowflake.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 36 pixels wide), so the image must contain ONLY the object.

SUBJECT: One delicate six-pointed snowflake of pale icy blue, softly glowing.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 57. `spr_gift_rainbow_drop` ⬜

Guardala como `store/art/garden/spr_gift_rainbow_drop.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 36 pixels wide), so the image must contain ONLY the object.

SUBJECT: One water drop holding a tiny rainbow inside, iridescent and luminous.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 58. `spr_gift_seed` ⬜

Guardala como `store/art/garden/spr_gift_seed.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 36 pixels wide), so the image must contain ONLY the object.

SUBJECT: One dandelion seed (pappus) floating, its fine white umbrella of hairs lit by the sun.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

### 59. `spr_gift_sunray` ⬜

Guardala como `store/art/garden/spr_gift_sunray.png`. Adjuntá `store/art/style/style_keyart.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This is a decorative object that the player places in their garden in a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars). The game draws the ground and shadows itself and shows the object small (about 36 pixels wide), so the image must contain ONLY the object.

SUBJECT: One small golden sunbeam crystal: a soft glowing shard of warm light.

STYLE: Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the upper left.

COMPOSITION: The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and transparent. Bold, simple silhouette that still reads at small size.

DO NOT INCLUDE: any background, ground, grass patch, floor, cast shadow, frame or border; any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters; other objects; people or animals; photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

## Bloque 0 — Guía de estilo (2)

**Por qué ahora:** Opcional: el estilo ya quedó fijado por el patio pintado.

Van primero: fijan el estilo de todo lo demás. Guardalas en `store/art/style/` y **adjuntá `store/art/style/style_keyart.webp` como referencia en cada bloque siguiente** (arrastrala a la conversación antes de pegar el prompt). Si el estilo no te convence, se cambia el párrafo STYLE en `tool/gen_prompts.py` y se regenera este archivo.

### 60. `style_stones` ⬜

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

### 61. `style_plants` ⬜

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

## Bloque 25 — La Maqueta (1)

La mesa baja con el jardín en miniatura, adentro del pabellón: tocarla abre la Maqueta para decorar. Los suelos de cada zona (`model_tray_*`) ya no hacen falta: los reemplaza la vista aérea de los Miradores (Bloque 26). Adjuntá `store/art/style/style_courtyard_ref.webp`. En el juego va como `assets/images/court/obj_model_table.webp`.

### 62. `obj_model_table` ⬜

Guardala como `store/art/model/obj_model_table.png`. Adjuntá `store/art/style/style_courtyard_ref.webp`.

```
Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.

Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully transparent background (real alpha channel, no white or checkerboard background). If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no gradient, no shadow and no texture.

PURPOSE: This object sits in the painted courtyard of a calm, cozy mobile game about caring for your own small Japanese zen garden (stone stacking, raking sand, rain falling into clay jars); tapping it opens the decorating screen. The game draws it about 150 pixels wide on top of the raked gravel.

SUBJECT: A low, simple Japanese wooden table of warm, worn cedar on four short legs, holding a shallow wooden tray with a tiny model of a zen garden: raked pale sand, three miniature stones, a little moss mound and a tiny stone lantern. Cozy and handmade, like a craftsman's model.

STYLE: Detailed hand-painted watercolor and gouache illustration, exactly like the attached reference image of the courtyard: rich but soft, natural proportions and believable materials (weathered granite, deep green moss, finely raked pale gravel, aged warm wood, clay plaster). Atmospheric perspective: the distance is lighter, bluer and misty. Warm soft morning light from the upper left with gentle cast shadows toward the lower right. Subtle paper grain and visible soft brush texture, no harsh outlines.

COMPOSITION: Seen from the front and slightly above (about 25 degrees), perfectly centered, filling about 80% of the canvas width. The feet of the table sit on an imaginary ground line near the bottom. Nothing cropped, all four corners empty and transparent.

DO NOT INCLUDE: any background, ground, cast shadow, people, animals, chairs, cushions, any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters, photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style.
```

---

# Ya incluidas (134)

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
| `ui_panel` | `assets/images/ui/ui_panel.webp` | Marco de todos los paneles y diálogos (`WashiCard`, nine-slice en `washi.dart`). |
| `ui_result` | `assets/images/ui/ui_result.webp` | Tarjeta de resultado de los minijuegos; las estrellas caen en la bruma de arriba (`result_panel.dart`). |
| `ui_button` | `assets/images/ui/ui_button.webp` | Botón principal y chico (`InkButton`), con el texto en tinta. |
| `ui_pause` | `assets/images/ui/ui_pause.webp` | Botón de pausa de los minijuegos (`InkIconButton`). |
| `ui_score_frame` | `assets/images/ui/ui_score_frame.webp` | Placa detrás del puntaje de Estanque, Hojas y Apilado (`ScoreFrame`). |
| `ui_serenity_bar` | `assets/images/ui/ui_serenity_bar.webp` | Barra de Calma y Serenidad (`StoneBar`): panel de nivel, próxima meta y resultado. |
| `store_feature` | `store/art/brand/store_feature_play.png` | Gráfico de funciones de Play, 1024×500 con el logo (no va en el juego). Sin logo: `store_feature_1024x500.png`. |
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
| `obj_tea_whisk` | `assets/images/forest/obj_tea_whisk.webp` | Batidor del Matcha, 220 px; salió de costado y se dibuja con las varillas bajo el dedo (`matcha_game.dart`). |
| `obj_bamboo_flute` | `assets/images/forest/obj_bamboo_flute.webp` | Flauta, 900 px de alto; se arma por partes para que sus huecos caigan en las filas del juego (`flute_game.dart`). |
| `obj_river_lantern` | `assets/images/forest/obj_river_lantern.webp` | Linterna del río, 200 px; apagada se dibuja en gris (`lanterns_game.dart`). |
| `bg_river` | `assets/images/forest/bg_river.webp` | Fondo de las Linternas, 768×1152; el agua ocupa el 84 % del ancho, igual que el río del juego (`lanterns_game.dart`). |
| `char_visitor_traveler` | `assets/images/court/char_visitor_traveler.webp` | Viajero, 480 px de alto (`garden_visitor.dart`). El monje usa `char_visitor_monk`, sacado de `char_monk`. |
| `char_visitor_potter` | `assets/images/court/char_visitor_potter.webp` | Alfarero, 480 px de alto. |
| `char_visitor_gardener` | `assets/images/court/char_visitor_gardener.webp` | Jardinero, 480 px de alto. |
| `char_visitor_fisher` | `assets/images/court/char_visitor_fisher.webp` | Pescador, 480 px de alto. |
| `obj_upgrade_border` | `assets/images/court/obj_upgrade_border.webp` | Borde de piedras de las mejoras 1 y 2, 560 px (`garden_upgrades.dart`). |
| `obj_upgrade_bloom` | `assets/images/court/obj_upgrade_bloom.webp` | Borde con flores de la mejora 3, 560 px; el brillo sigue siendo código. |
| `obj_court_zafu` | `assets/images/court/obj_court_zafu.webp` | Zafu de la racha sobre el almohadón de la tarima, 520 px (`_paintCourtStreak`). |
| `obj_court_singing_bowl` | `assets/images/court/obj_court_singing_bowl.webp` | Cuenco de la racha en el rincón del fondo de la tarima, 520 px. |
| `obj_court_paper_lantern` | `assets/images/court/obj_court_paper_lantern.webp` | Farol de papel de la racha colgado del arbolito, 520 px; ya viene encendido y de noche suma el halo. |
| `bg_leaves` | `assets/images/east/bg_leaves.webp` | Fondo de Hojas al viento: el camino de arena va de arriba abajo (`leaves_game.dart`). |
| `bg_bonsai` | `assets/images/east/bg_bonsai.webp` | Fondo de la Poda del bonsái; se dibuja en dos tajadas para que la maceta apoye en su mesa (`_paintRoom`). |
| `bg_shishi` | `assets/images/east/bg_shishi.webp` | Fondo del Shishi-odoshi; el poste, la piedra de apoyo y el bambú siguen encima. |
| `bg_bell` | `assets/images/temple/bg_bell.webp` | Fondo de la Campana del templo: el pabellón reemplaza las vigas de código. |
| `bg_matcha` | `assets/images/forest/bg_matcha.webp` | Fondo del Matcha: el tatami bajo el cuenco. |
| `bg_flute` | `assets/images/forest/bg_flute.webp` | Fondo de la Flauta de bambú: el bambusal reemplaza las cañas de código. |
| `bg_moss` | `assets/images/east/bg_moss.webp` | Fondo del Musgo: la arena bajo las piedras. |
| `bg_east_ground` | `assets/images/east/bg_east_ground.webp` | Suelo de la vista del estanque: se usa la mitad de abajo, cubriendo desde el 43 % de la pantalla (`_groundArt`). |
| `bg_forest_ground` | `assets/images/forest/bg_forest_ground.webp` | Suelo de la vista del bosque, igual que el del estanque. |
| `bg_forest_river` | `assets/images/forest/bg_forest_river.webp` | Río del bosque, 1280 px, recortado en las puntas para cubrir su lugar; las dos linternas siguen siendo código (`paintRiver`). |
| `obj_bonsai_foliage` | `assets/images/east/obj_bonsai_foliage.webp` | Copa del bonsái, 360 px: en el minijuego (las copas y los mechones; el verde claro de lo que sobra es un tinte) y en el jardín. |
| `obj_bonsai_table` | `assets/images/east/obj_bonsai_table.webp` | Mesita del bonsái en la vista del estanque, 520 px (`_bonsaiTable`). |
| `obj_care_weeds` | `assets/images/court/obj_care_weeds.webp` | Maleza de las tareas de cuidado, 320 px; al arrancarla sube y asoman raíces de código (`garden_care.dart`). |
| `obj_care_leaves` | `assets/images/court/obj_care_leaves.webp` | Hojas de las tareas de cuidado, 320 px; al barrer se corren y se apagan. |
| `obj_tea_gift` | `assets/images/forest/obj_tea_gift.webp` | Regalo de la casa de té, 260 px; el brillo que late sigue siendo código (`tea_visit.dart`). |
| `ui_market_awning` | `assets/images/ui/ui_market_awning.webp` | Toldo del Mercado, 1280 px, estirado a lo ancho con su sombra (`market_screen.dart`). |
