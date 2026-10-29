#!/usr/bin/env python3
"""Genera docs/prompts.md: los prompts de imágenes para ChatGPT.

Cada imagen repite toda su descripción (formato, estilo, qué no incluir) para
que salga consistente aunque se corra sola o en otra conversación. Los bloques
tienen 10 imágenes como máximo. Para cambiar un prompt se edita acá y se
vuelve a generar:

    python3 tool/gen_prompts.py
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'docs' / 'prompts.md'

GAME = ('a calm, cozy mobile game about caring for your own small Japanese zen garden '
        '(stone stacking, raking sand, rain falling into clay jars)')

STYLE = ('Soft hand-painted gouache illustration with light watercolor washes, like a picture book: calm, warm and '
         'cozy. Gentle muted natural palette: moss green (#6E8B5B), warm sand (#E8DCC2), stone gray (#8C8A85), '
         'dark wood (#8A5A3C), still-water teal (#5C9EA8), soft lantern amber (#E9A84C), and a warm ink '
         'brown-black (#2F2B28) only for the darkest accents. Subtle paper grain and visible soft brush texture. '
         'Clean, simple, readable shapes with soft edges and no harsh black outlines. Soft diffuse daylight from the '
         'upper left.')

NO_TEXT = 'any text, letters, numbers, signature, watermark, seal stamp or Chinese/Japanese characters'
NO_STYLE = 'photographic realism, 3D render, glossy plastic look, anime or cartoon style, pixel art, flat vector style'

# Formatos: (primera línea, frase para la composición)
SQUARE_ALPHA = ('Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), PNG with a fully '
                'transparent background (real alpha channel, no white or checkerboard background).')
SQUARE_OPAQUE = ('Create a SQUARE image (1:1 aspect ratio, 1024×1024, not landscape, not portrait), fully opaque, '
                 'with NO transparency.')
PORTRAIT_OPAQUE = ('Create a PORTRAIT image with a 2:3 aspect ratio (1024×1536, not square, not landscape), fully '
                   'opaque, with NO transparency.')
PORTRAIT_ALPHA = ('Create a PORTRAIT image with a 2:3 aspect ratio (1024×1536, not square, not landscape), PNG with '
                  'a transparent background (real alpha channel) wherever the description says the image is empty.')
LANDSCAPE_OPAQUE = ('Create a LANDSCAPE image with a 3:2 aspect ratio (1536×1024, not square, not portrait), fully '
                    'opaque, with NO transparency.')
LANDSCAPE_ALPHA = ('Create a LANDSCAPE image with a 3:2 aspect ratio (1536×1024, not square, not portrait), PNG with '
                   'a fully transparent background (real alpha channel, no white or checkerboard background).')

ALPHA_FALLBACK = (' If transparency is impossible, use a perfectly flat pure magenta (#FF00FF) background with no '
                  'gradient, no shadow and no texture.')

CROP_NOTE = ('The game shows this on tall phone screens (9:16), so the left and right 8% of the image may be cropped: '
             'keep everything important inside the central 84% of the width.')


def img(name, fmt, purpose, subject, composition, exclude, style=STYLE):
    return dict(name=name, fmt=fmt, purpose=purpose, subject=subject, composition=composition, exclude=exclude,
                style=style)


def obj(name, subject, size_hint='about 120 pixels tall', extra_excl=''):
    """Objeto suelto del jardín, recortado sobre transparente."""
    return img(
        name, SQUARE_ALPHA + ALPHA_FALLBACK,
        f'This is a decorative object that the player places in their garden in {GAME}. The game draws the ground '
        f'and shadows itself and shows the object small ({size_hint}), so the image must contain ONLY the object.',
        subject,
        'The object stands upright, seen from the front and slightly above (about 20 degrees), perfectly centered, '
        'filling about 80% of the canvas height. The bottom of the object sits on an imaginary flat ground line near '
        'the bottom of the canvas. The whole object is visible, nothing is cropped. All four corners stay empty and '
        'transparent. Bold, simple silhouette that still reads at small size.',
        f'any background, ground, grass patch, floor, cast shadow, frame or border; {NO_TEXT}; other objects; '
        f'people or animals; {NO_STYLE}{extra_excl}.')


def icon(name, subject):
    return img(
        name, SQUARE_ALPHA + ALPHA_FALLBACK,
        f'This is a currency or interface icon in {GAME}. It is shown very small (about 32 to 48 pixels) next to a '
        'number, so it must read instantly at that size.',
        subject,
        'One single object, perfectly centered, filling about 80% of the canvas. Very bold and simple shape, '
        'strong value contrast between the lit side and the shadow side, a soft light rim around the edge so it '
        'stays readable on both light and dark backgrounds. All four corners stay empty and transparent.',
        f'any background, frame, circle, coin border, badge or plaque; {NO_TEXT}; extra objects; fine detail that '
        f'disappears at small size; {NO_STYLE}.')


def ui(name, subject, composition):
    return img(
        name, SQUARE_ALPHA + ALPHA_FALLBACK,
        f'This is an interface element in {GAME}. The game stretches it with nine-slice scaling and writes its '
        'own text on top, so the image must be clean, symmetrical and empty in the middle.',
        subject, composition,
        f'{NO_TEXT}; icons or symbols unless described; any background or scenery; drop shadow outside the '
        f'element; {NO_STYLE}.')


def tile(name, subject):
    """Ficha de un tablero: una sola cosa centrada, que se lea chica."""
    return img(
        name, SQUARE_ALPHA + ALPHA_FALLBACK,
        f'This is a tile of a match-three board in {GAME}. It is shown small (about 60 to 80 pixels) on dark '
        'water, next to many other tiles, so it must read instantly by its shape and color.',
        subject,
        'One single object, perfectly centered, filling about 75% of the canvas. Bold, simple silhouette, soft '
        'light rim around the edge. All four corners stay empty and transparent.',
        f'any background, water, frame, tile border or square; {NO_TEXT}; extra objects; {NO_STYLE}.')


BLOCKS = [
    dict(
        id='0', title='Guía de estilo', folder='store/art/style/',
        intro=('Van primero: fijan el estilo de todo lo demás. Guardalas en `store/art/style/` y **adjuntá '
               '`store/art/style/style_keyart.webp` como referencia en cada bloque siguiente** (arrastrala a la conversación antes '
               'de pegar el prompt). Si el estilo no te convence, se cambia el párrafo STYLE en '
               '`tool/gen_prompts.py` y se regenera este archivo.'),
        images=[
            img('style_keyart', PORTRAIT_OPAQUE,
                f'This is the key art and style reference for {GAME}. Every later asset will be painted to match it.',
                'A small, intimate zen garden seen from a gentle three-quarter view from above, in the soft light of '
                'early morning. In the foreground, a bed of pale raked sand with a few concentric groove circles '
                'around a mossy rock. On the right, a small stack of five flat river stones balanced on a low stone '
                'pedestal. On the left, a stone lantern (tōrō) and a young pine shaped like a cloud. In the middle '
                'ground, a tiny arched wooden bridge over a narrow stream, and a clump of bamboo. In the background, '
                'the eave of a wooden roof with three clay jars under it, and soft misty hills. A plump ginger-and-'
                'white cat sleeps on the bridge. Calm, cozy, inviting: a place you want to take care of.',
                'Rich but uncluttered scene with clear depth: foreground, middle ground and background read as '
                'separate layers. Plenty of calm empty sand. ' + CROP_NOTE,
                f'{NO_TEXT}; people; frame or border; {NO_STYLE}.'),
            img('style_stones', SQUARE_OPAQUE,
                f'This is a material reference sheet for the stones in {GAME}. Artists will copy how stone looks '
                'from it.',
                'Nine different garden stones arranged in a loose 3×3 grid on plain warm paper: three flat round '
                'river stones for stacking (smooth, wider than tall), three rough upright decorative rocks with a '
                'little moss on top, and three small pebbles of different tones (cool gray, warm gray, almost '
                'white). Each stone is painted with a lit upper-left side, a soft shadow side and a subtle speckled '
                'texture.',
                'Each stone is separated from the others with generous empty paper around it. The background is '
                'plain warm paper (#F3ECDD) edge to edge.',
                f'{NO_TEXT}; labels; grid lines; frame or border; cast shadows on the paper; {NO_STYLE}.'),
            img('style_plants', SQUARE_OPAQUE,
                f'This is a material reference sheet for the plants in {GAME}. Artists will copy how foliage looks '
                'from it.',
                'Nine garden plants arranged in a loose 3×3 grid on plain warm paper: a cloud-pruned pine, a small '
                'Japanese maple, a bamboo clump, a mound of moss, a fern, an azalea bush with a few pink flowers, a '
                'tuft of ornamental grass, a lotus leaf, and a small bonsai in a shallow pot. Foliage is painted as '
                'soft grouped masses with a few crisp leaf shapes on the edges, never leaf by leaf.',
                'Each plant is separated from the others with generous empty paper around it. The background is '
                'plain warm paper (#F3ECDD) edge to edge.',
                f'{NO_TEXT}; labels; grid lines; frame or border; cast shadows on the paper; {NO_STYLE}.'),
        ]),
    dict(
        id='1', title='Fondos del jardín y del alero', folder='store/art/bg/',
        intro=('Capas con parallax: el cielo es opaco y las otras tres tienen partes transparentes para apilarlas. '
               'El día y la noche los hace un shader, así que todas van **de día**. Adjuntá `store/art/style/style_keyart.webp`.'),
        images=[
            img('bg_base_sky', PORTRAIT_OPAQUE,
                f'This is the farthest background layer (the sky) of the garden screen in {GAME}. Other layers are '
                'drawn on top of it.',
                'A soft early-morning sky: a gentle vertical gradient from pale blue-gray at the top (#BFD8DC) to warm '
                'cream near the bottom (#F4E7CF), with a few long, thin, soft clouds. No sun disk.',
                'The bottom third can stay plain: hills will cover it. ' + CROP_NOTE,
                f'{NO_TEXT}; birds; mountains, hills, trees or any ground; frame or border; {NO_STYLE}.'),
            img('bg_base_far', PORTRAIT_ALPHA + ALPHA_FALLBACK,
                f'This is a far background layer of the garden screen in {GAME}: distant hills seen through morning '
                'mist. It is drawn on top of a separate sky layer.',
                'A soft range of rounded misty hills with a few tiny pine silhouettes on the ridges, fading into '
                'mist. Muted blue-green, low contrast.',
                'The hills fill only the lower half of the image; their top edge is an irregular soft line around '
                'the middle of the canvas. Everything ABOVE the hills is fully transparent. ' + CROP_NOTE,
                f'any sky color or clouds; {NO_TEXT}; buildings; people; frame or border; {NO_STYLE}.'),
            img('bg_base_ground', PORTRAIT_ALPHA + ALPHA_FALLBACK,
                f'This is the ground layer of the garden screen in {GAME}. Objects, the stone tower and the sand '
                'drawing are placed on top of it by the game.',
                'The empty ground of a small zen garden seen from a gentle three-quarter view from above: a large '
                'bed of pale sand, flat and smooth with no rake lines, framed by a low border of dark stones and a '
                'thin strip of moss along the back edge. A few stepping stones lead from the bottom edge into the '
                'sand.',
                'The ground fills only the lower 55% of the image; above the back moss edge everything is fully '
                'transparent. The sand must be mostly empty and calm. ' + CROP_NOTE,
                f'rake lines or patterns in the sand; rocks, lanterns, plants or objects on the sand; sky; '
                f'{NO_TEXT}; people or animals; frame or border; {NO_STYLE}.'),
            img('bg_base_foliage', PORTRAIT_ALPHA + ALPHA_FALLBACK,
                f'This is the nearest decorative layer of the garden screen in {GAME}: it frames the scene from the '
                'sides and moves faster than the rest (parallax).',
                'Out-of-focus foreground foliage framing the view: maple leaves hanging from the top-left corner and '
                'a clump of bamboo leaves entering from the bottom-right corner. Soft, slightly blurred.',
                'The foliage covers ONLY the top-left corner (about 25% of the width) and the bottom-right corner '
                '(about 25% of the width). The whole center of the image is fully transparent.',
                f'anything in the center of the image; ground; sky; {NO_TEXT}; flowers; frame or border; '
                f'{NO_STYLE}.'),
            img('bg_rain_roof', PORTRAIT_OPAQUE,
                f'This is the background of the "rain in the jars" minigame in {GAME}. The game draws the jars, '
                'the raindrops and the meditating person on top.',
                'A view looking up from inside a wooden veranda on a rainy day: the lower edge of a dark tiled roof '
                'eave runs straight across the top of the image, with round tile ends and a wooden beam under '
                'them. Below it, a soft gray rainy garden in the distance (blurred maples and a misty wall), and at '
                'the bottom a polished dark wooden floor of the veranda.',
                'The roof eave is a straight horizontal band occupying the top 15% of the image. The middle 60% is '
                'calm and low contrast so the jars and drops on top stay readable. ' + CROP_NOTE,
                f'jars, pots or vessels; raindrops in the foreground; people; {NO_TEXT}; frame or border; '
                f'{NO_STYLE}.'),
        ]),
    dict(
        id='2', title='Piedras para apilar', folder='store/art/stack/',
        intro=('Seis piedras distintas para el minijuego de apilado. Hoy se dibujan con código (río, laja, canto '
               'rodado, huevo, peñasco y cuña); estas las reemplazarían. Tienen que ser más anchas que altas y con '
               'base plana. Adjuntá `store/art/style/style_keyart.webp`.'),
        images=[obj(f'obj_stack_stone_{i:02d}', s, 'about 90 to 160 pixels wide') for i, s in enumerate([
            'A flat, smooth oval river stone in cool medium gray, seen from the side, about three times wider than '
            'tall, with a gently flat bottom and a softly domed top.',
            'A flat river stone in warm gray with a faint lighter band of quartz running across it, seen from the '
            'side, about two and a half times wider than tall, with a flat bottom and a flat top.',
            'A small, thick, rounded river stone in dark slate gray, seen from the side, about twice as wide as '
            'tall, with a flat bottom and a slightly rounded top.',
            'A long, thin flat stone in pale gray, almost white, seen from the side, about four times wider than '
            'tall, with a flat bottom and a flat top and slightly irregular ends.',
            'A flat river stone in greenish gray with a few tiny tufts of moss on its top edge, seen from the side, '
            'about two and a half times wider than tall, with a flat bottom and a softly domed top.',
            'A slightly asymmetrical flat stone in warm brownish gray, thicker on the left than on the right, seen '
            'from the side, about three times wider than tall, with a flat bottom.',
        ], start=1)]),
    dict(
        id='3', title='Objetos del jardín (catálogo inicial)', folder='store/art/garden/',
        intro='Diez objetos que se compran con Piedritas. Adjuntá `store/art/style/style_keyart.webp` y `style_plants.png`.',
        images=[
            obj('obj_base_lantern', 'A traditional Japanese stone lantern (tōrō, kasuga style): a hexagonal stone '
                'cap, a small light chamber with a soft warm amber glow inside, a slim post and a round base. '
                'Weathered gray stone with a little moss on the cap.'),
            obj('obj_base_bridge', 'A small arched wooden footbridge with low railings, painted in a soft faded '
                'vermilion with dark wood planks, seen from the side and a little from above.', 'about 200 pixels '
                'wide'),
            obj('obj_base_pine', 'A young Japanese black pine pruned in the niwaki cloud style: a gracefully curving '
                'dark trunk with four rounded pads of deep green needles.'),
            obj('obj_base_bamboo', 'A small clump of five green bamboo stalks of different heights with a few '
                'leaves at the top, growing from a low mound of earth.'),
            obj('obj_base_rock_01', 'A tall upright garden rock in cool gray, rough and angular, a little like a '
                'small mountain peak, with some moss at its base.'),
            obj('obj_base_rock_02', 'A low, wide, rounded garden boulder in warm gray with soft patches of bright '
                'moss on top.'),
            obj('obj_base_rock_03', 'A group of three small rounded garden rocks of different sizes resting '
                'together, in slightly different grays.'),
            obj('obj_base_rock_04', 'A flat, dark stepping stone, almost round, seen from above at a steep angle, '
                'with tiny moss along one edge.', 'about 80 pixels wide'),
            obj('obj_base_plant_01', 'A soft round mound of bright green moss with two small ferns growing from '
                'it.'),
            obj('obj_base_plant_02', 'A small rounded azalea bush trimmed into a soft dome, dark green leaves with a '
                'scattering of soft pink flowers.'),
        ]),
    dict(
        id='4', title='Lluvia en vasijas y arenero', folder='store/art/rain_sand/',
        intro=('Vasijas, gotas, rastrillo y textura de arena. El mapa de alturas de la arena (`tex_sand_height`) '
               'no va acá: lo genera el código. Adjuntá `store/art/style/style_keyart.webp`.'),
        images=[
            *[obj(f'obj_rain_vessel_{i:02d}', s, 'about 80 to 110 pixels wide') for i, s in enumerate([
                'A small round clay jar with a wide open mouth, unglazed terracotta, seen from the front and a '
                'little from above so the dark water inside the open mouth is visible.',
                'A medium clay water jar with a soft teal-blue glaze dripping unevenly over a brown body, wide open '
                'mouth, seen from the front and a little from above so the water inside is visible.',
                'A squat, wide stoneware bowl-shaped vessel in moss-green celadon glaze, seen from the front and a '
                'little from above so the water inside is visible.',
                'A tall clay jar with a narrow neck that opens into a wide lip, glazed in warm amber, seen from the '
                'front and a little from above so the water inside is visible.',
                'A large, heavy dark stoneware basin with a rough texture and an open top, seen from the front and a '
                'little from above so the water inside is visible.',
            ], start=1)],
            img('fx_rain_drop', SQUARE_ALPHA + ALPHA_FALLBACK,
                f'This is a falling raindrop sprite in {GAME}. It is shown tiny (about 12×20 pixels) and many at '
                'once.',
                'A single clear raindrop falling straight down: a slim teardrop shape, pale blue-white, slightly '
                'transparent in the middle, with a bright highlight on the upper left and a short soft motion '
                'trail above it.',
                'The drop points down, is perfectly centered and vertical, and fills about 70% of the canvas '
                'height. All corners are empty and transparent.',
                f'any background, puddle or splash; {NO_TEXT}; several drops; {NO_STYLE}.'),
            img('fx_rain_splash', SQUARE_ALPHA + ALPHA_FALLBACK,
                f'This is a water splash sprite in {GAME}, shown when a raindrop hits the water in a jar. It is shown '
                'small (about 48 pixels).',
                'A small crown-shaped water splash seen from the side: a thin ring of water rising, with a few tiny '
                'droplets flying up and outward. Pale blue-white, partly transparent.',
                'The base of the splash is a flat horizontal line in the lower third of the canvas; the splash is '
                'centered and symmetrical. All corners are empty and transparent.',
                f'any background, jar or ground; {NO_TEXT}; {NO_STYLE}.'),
            img('spr_sand_rake_01', LANDSCAPE_ALPHA + ALPHA_FALLBACK,
                f'This is the rake sprite of the sand-raking minigame in {GAME}. The game moves and rotates it along '
                'the path the player drew, so it is seen from straight above.',
                'A traditional wooden zen garden rake seen from directly above: a straight crossbar on the RIGHT '
                'side of the image, oriented vertically, with five short wooden teeth pointing to the right, and a '
                'long straight wooden handle extending horizontally to the LEFT from the middle of the crossbar. '
                'Light natural wood with darker grain.',
                'The handle is perfectly horizontal and centered vertically. The whole rake fits inside the canvas '
                'with empty margins. All corners are empty and transparent.',
                f'any background, sand or grooves; a hand or person; cast shadow; {NO_TEXT}; perspective tilt; '
                f'{NO_STYLE}.'),
            img('tex_sand_base', SQUARE_OPAQUE,
                f'This is a repeating ground texture in {GAME}: the sand of the garden, tiled many times. Raked '
                'grooves are added on top by the game.',
                'Fine, pale, warm sand seen from directly above (#E8DCC2), smooth and calm, with a subtle grain of '
                'tiny lighter and darker specks and a very soft, low-contrast variation in tone.',
                'A SEAMLESS, TILEABLE texture: the left edge continues perfectly into the right edge and the top '
                'edge into the bottom edge. Even lighting with no direction, no vignette, no obvious repeated '
                'feature.',
                f'rake lines, footprints, stones, leaves or any object; shadows or light spots; {NO_TEXT}; frame '
                f'or border; {NO_STYLE}.'),
        ]),
    dict(
        id='5', title='Personajes (referencia para Rive)', folder='store/art/characters/',
        intro=('Una pose limpia de cada personaje. Sirven de placeholder en el prototipo y de modelo para animarlos '
               'después en Rive. Adjuntá `store/art/style/style_keyart.webp`. El gato todavía no tiene nombre (pregunta abierta del '
               'GDD).'),
        images=[
            img('char_meditator', PORTRAIT_ALPHA + ALPHA_FALLBACK,
                f'This is the meditating person of the "rain in the jars" minigame in {GAME}. It appears small at '
                'the bottom of the screen, under a roof, while it rains.',
                'A person of no particular age or gender sitting in a calm cross-legged meditation pose, seen from '
                'the front, eyes closed, hands resting in the lap, wearing a simple loose robe in muted indigo '
                '(#3A4660) with a light gray sash. Peaceful and simple, almost a silhouette with soft details.',
                'Full body, centered, filling about 75% of the canvas height, sitting on an imaginary floor line '
                'near the bottom. Everything around the figure is fully transparent.',
                f'any background, floor, cushion or cast shadow; {NO_TEXT}; other characters; {NO_STYLE}.'),
            img('char_cat', SQUARE_ALPHA + ALPHA_FALLBACK,
                f'This is the neighbor\'s cat, the mascot of {GAME}: a recurring troublemaker who knocks over stone '
                'towers and walks on the raked sand, but sometimes leaves rare gifts. Players should love and hate '
                'it at the same time.',
                'A plump ginger-and-white cat with a short bobtail, round cheeks and a slightly smug, half-closed '
                'look, sitting upright and looking at the viewer with its tail curled around its paws. One small '
                'nick in the left ear.',
                'Full body, three-quarter view, centered, filling about 75% of the canvas. Everything around the cat '
                'is fully transparent.',
                f'any background, ground or cast shadow; {NO_TEXT}; collar, bell or accessories; other animals; '
                f'{NO_STYLE}.'),
            img('char_monk', PORTRAIT_ALPHA + ALPHA_FALLBACK,
                f'This is the old gardener monk of {GAME}, who takes care of the garden when the player is away.',
                'A small, kind elderly monk with a shaved head, round friendly face and a short white beard, wearing '
                'a simple ochre-and-brown work robe with sleeves tied back, holding a bamboo broom upright in one '
                'hand and smiling gently.',
                'Full body, three-quarter view facing right, centered, filling about 80% of the canvas height, '
                'standing on an imaginary floor line near the bottom. The whole broom fits inside the image. '
                'Everything around the figure is fully transparent.',
                f'any background, ground or cast shadow; {NO_TEXT}; other characters; weapons; {NO_STYLE}.'),
        ]),
    dict(
        id='6', title='Íconos de monedas y estrella', folder='store/art/icons/',
        intro='Se ven a 32–48 px: tienen que leerse al instante. Adjuntá `store/art/style/style_keyart.webp`.',
        images=[
            icon('icon_pebble', 'A single smooth, round, slightly flattened river pebble in soft gray with a white '
                 'speckle and a bright highlight: the soft currency of the game.'),
            icon('icon_essence_water', 'A single plump water droplet in clear teal (#5C9EA8), glowing softly from '
                 'inside, with a tiny ripple ring at its base.'),
            icon('icon_essence_sand', 'A tiny round mound of warm golden sand (#D9C08E) with three curved rake '
                 'grooves across it, glowing softly.'),
            icon('icon_essence_wood', 'A single fresh green leaf sprouting from a small slice of wood (#8A5A3C) '
                 'showing its growth rings, glowing softly.'),
            icon('icon_essence_light', 'A small paper lantern flame shape in warm amber (#E9A84C), a soft glowing '
                 'teardrop of light with a few tiny sparks around it.'),
            icon('icon_lotus', 'A single small lotus flower seen from the side, soft pink petals (#E8A6B4) with '
                 'pale tips opening around a warm golden center, resting on a tiny round green lily pad: the '
                 'premium currency.'),
            icon('icon_star', 'A soft five-pointed star with rounded points in warm gold (#E9A84C), slightly '
                 'puffy, with a gentle highlight, like a star cut from washi paper.'),
        ]),
    dict(
        id='7', title='Ícono de la app', folder='store/icon/',
        intro=('Archivo: `store/icon/app_icon.png` (lo usa `flutter_launcher_icons`). 1024×1024, **sin transparencia '
               'ni esquinas redondeadas**: iOS y Android las recortan solos. Adjuntá `store/art/style/style_keyart.webp` y el símbolo del '
               'logo (`assets/images/brand/logo_symbol.webp`), para que el ícono y el logo de Sandora se '
               'parezcan.'),
        images=[
            img('app_icon', SQUARE_OPAQUE + ' NO rounded corners.',
                f'This is the app icon of {GAME}. It is shown on phone home screens at about 60×60 pixels next to '
                'many other apps, and iOS and Android crop it into a rounded square or a circle.',
                'The same symbol as the attached logo: one single smooth gray river stone resting on pale raked '
                'sand, with three concentric raked rings around it. Soft morning light from the upper left.',
                'The stone is centered, bold and simple, the rings filling about 70% of the canvas. The raked sand '
                'fills the whole square edge to edge as the background. Nothing important within 10% of the edges.',
                f'{NO_TEXT}; the game name; a frame or border; rounded corners; transparency; {NO_STYLE}.'),
        ]),
    dict(
        id='8', title='Interfaz base', folder='store/art/ui/',
        intro=('Piezas que el juego estira (nine-slice) y sobre las que escribe su propio texto. Adjuntá '
               '`store/art/style/style_keyart.webp`.'),
        images=[
            ui('ui_button', 'A wide rounded rectangular button made of smooth light wood (#C9A27A) with a thin '
               'darker wooden rim and a soft highlight along the top edge, slightly raised.',
               'The button is centered, about 80% of the canvas width and 30% of its height, perfectly symmetrical. '
               'The middle is plain wood with no pattern so text fits on it. Everything around it is transparent.'),
            ui('ui_panel', 'A large rounded rectangular panel of warm washi paper (#F3ECDD) with subtle fibers, '
               'mounted on a thin dark wooden frame with softly rounded corners.',
               'The panel is centered and fills about 90% of the canvas, perfectly symmetrical. The paper area is '
               'plain and calm. Everything outside the frame is transparent.'),
            ui('ui_score_frame', 'A small rounded plaque of dark polished wood (#5A3E2B) with a thin pale stone '
               'inset border, used behind a score number.',
               'The plaque is centered, about 70% of the canvas width and 35% of its height, perfectly symmetrical. '
               'The middle is plain so a number fits on it. Everything around it is transparent.'),
            ui('ui_serenity_bar', 'A long, thin, empty horizontal bar: a shallow groove carved into smooth pale '
               'stone, with rounded ends and a soft inner shadow. A small moss-covered rounded stone decorates the '
               'left end.',
               'The bar is centered, horizontal, about 90% of the canvas width and 10% of its height. The inside of '
               'the groove is empty (the game fills it). Everything around it is transparent.'),
            ui('ui_result', 'A result card: a tall rounded panel of warm washi paper with a thin dark wooden frame, '
               'and a soft painted band of pale mist across its upper third where three stars will be placed by the '
               'game.',
               'The card is centered, about 75% of the canvas width and 90% of its height, perfectly symmetrical. '
               'No stars, no text. Everything outside the frame is transparent.'),
            ui('ui_pause', 'A round button of smooth gray river stone with a soft highlight, carrying a simple pause '
               'symbol made of two short vertical moss-green bars in the center.',
               'The button is centered and fills about 80% of the canvas. The pause symbol is the only mark on it. '
               'Everything around it is transparent.'),
        ]),
    dict(
        id='9', title='Marca Sandora', folder='store/art/brand/',
        intro=('Piezas de la marca. El logo (símbolo y nombre) ya está incluido; el juego los pone encima de '
               '`title_bg` y `store_feature`, así que esas imágenes van sin texto. El nombre del jardín de cada '
               'jugador lo escribe el juego sobre `ui_garden_sign`, así que esa pieza va vacía. Adjuntá '
               '`store/art/style/style_keyart.webp`.'),
        images=[
            img('title_bg', PORTRAIT_OPAQUE,
                f'This is the background of the title screen of {GAME}. The game draws its logo on the upper part '
                'and a "Play" button on the lower part, so both areas must be calm and empty.',
                'The same small zen garden as the key art, seen from a little further away at dawn, wrapped in soft '
                'morning mist. Raked sand, the stone lantern, the cloud-shaped pine and the small stack of stones in '
                'the lower middle. A pale peach and cream sky fills the upper third, with one or two soft clouds and '
                'nothing else. A few cherry petals drift slowly in the air.',
                'The upper 35% of the image is mostly open sky, quiet and evenly lit, where the logo will be placed. '
                'The lowest 20% is plain raked sand where a button will be placed. ' + CROP_NOTE,
                f'{NO_TEXT}; the game name or any logo; people; frame or border; {NO_STYLE}.'),
            img('store_feature', LANDSCAPE_OPAQUE,
                f'This is the wide banner for the Google Play store page of {GAME}. It is cropped to a wide '
                '1024×500 strip from the middle of the image, and the logo is added on top of the left half later.',
                'A wide, calm view of the zen garden at golden hour: on the right half, the small stack of stones on '
                'raked sand, the stone lantern glowing softly and the ginger cat sleeping on the little bridge. The '
                'left half is a soft empty stretch of raked sand and mist, quiet enough to hold the logo.',
                'Landscape composition. All important elements in the right half, away from the edges. The left half '
                'stays calm and nearly empty. The top 17% and bottom 17% of the image '
                'will be cropped away: keep everything important in the middle band.',
                f'{NO_TEXT}; the game name or any logo; people; frame or border; {NO_STYLE}.'),
            ui('ui_garden_sign', 'A small hanging wooden sign at the entrance of a zen garden: a horizontal plank of '
               'warm light wood (#C9A27A) with softly rounded corners, hanging by two short ropes from a thin '
               'bamboo bar, with a tiny sprig of moss on one corner. The player\'s garden name will be written on it '
               'by the game.',
               'The sign is centered, about 80% of the canvas width and 35% of its height including the bamboo bar '
               'and ropes, perfectly symmetrical. The plank face is plain wood with no pattern so a name fits on it. '
               'Everything around it is transparent.'),
        ]),
    dict(
        id='10', title='Estanque de lotos (3 en línea)', folder='store/art/pond/',
        intro=('Fichas y poderes del 3 en línea del estanque. Se ven chicas (60 a 80 px) sobre agua oscura, así que '
               'cada una tiene que leerse por su forma y su color, no por el detalle. Adjuntá '
               '`store/art/style/style_keyart.webp`.'),
        images=[
            *[tile(f'spr_pond_tile_{n}', d) for n, d in [
                ('lotus', 'A single open lotus flower seen from slightly above, soft pink petals with a pale yellow '
                 'center.'),
                ('pad', 'A single round lily pad seen from above, bright green with its typical notch and a few soft '
                 'veins.'),
                ('stone', 'A single smooth, round river stone seen from above, pale gray, wet and slightly shiny.'),
                ('koi', 'A single small koi fish seen from above, curved as if swimming, white with orange-red '
                 'patches.'),
                ('drop', 'A single big water drop, clear blue with a bright highlight, slightly flattened as if '
                 'resting on a leaf.'),
            ]],
            *[tile(f'spr_pond_power_{n}', d) for n, d in [
                ('wave', 'A small curling water wave in teal and white foam, stylized like a sumi-e ink wave, '
                 'clearly moving to the side.'),
                ('bloom', 'A burst of lotus petals opening outward from a bright center, like a flower blooming in '
                 'one instant, with a soft golden glow.'),
                ('moon', 'A pale full moon reflected on water: a glowing cream disk with soft concentric ripples '
                 'around it.'),
            ]],
            img('bg_pond_water', PORTRAIT_OPAQUE,
                f'This is the background of the lotus pond match-three minigame in {GAME}. The game draws a grid of '
                'tiles on top of it.',
                'Calm, deep pond water seen straight from above: dark green-blue with soft light ripples, a few '
                'out-of-focus lily pads and stones only along the edges.',
                'The central 80% of the image is calm, even and dark so the tiles on top stay readable. ' + CROP_NOTE,
                f'tiles or grid; fish or flowers in the center; {NO_TEXT}; frame or border; {NO_STYLE}.'),
        ]),
    dict(
        id='11', title='Shishi-odoshi, hojas, musgo y bonsái', folder='store/art/east/',
        intro=('Piezas de los cuatro minijuegos de la vista del estanque. El código las mueve (el bambú vuelca, las '
               'hojas giran, las ramas crecen), así que cada pieza va sola y recortada. Adjuntá '
               '`store/art/style/style_keyart.webp`.'),
        images=[
            obj('obj_shishi_bamboo', 'A single thick green bamboo tube cut at a slant at one end, lying horizontally, '
                'with two visible nodes. Seen exactly from the side.', 'about 260 pixels wide'),
            obj('obj_shishi_basin', 'A low round stone water basin (tsukubai) seen from the front and a little from '
                'above, gray granite with moss at its base and dark water inside.', 'about 140 pixels wide'),
            *[obj(f'spr_leaf_{i:02d}', d, 'about 30 pixels long') for i, d in enumerate([
                'A single fallen Japanese maple leaf, bright orange, seen flat from above.',
                'A single fallen Japanese maple leaf, deep red, seen flat from above.',
                'A single fallen ginkgo leaf, golden yellow, seen flat from above.',
                'A single fallen dry oak-like leaf, warm brown, slightly curled, seen flat from above.',
            ], start=1)],
            img('tex_moss', SQUARE_OPAQUE,
                f'This is a seamless texture used to paint moss on rocks in {GAME}. The game masks it with the '
                'player\'s brush strokes.',
                'Dense, soft cushion moss seen from directly above: many tiny green tufts in light and dark greens, '
                'very even.',
                'Perfectly tileable on all four sides, uniform with no focal point and no lighting gradient.',
                f'rocks, sand or soil; flowers; {NO_TEXT}; frame or border; {NO_STYLE}.'),
            obj('obj_moss_rock', 'A large, low, rounded garden rock seen from slightly above, bare gray stone with '
                'subtle cracks and NO moss at all (the player paints it).', 'about 260 pixels wide'),
            obj('obj_bonsai_pot', 'A wide, shallow rectangular bonsai pot in dark reddish-brown unglazed clay, with '
                'small feet, empty and seen from the front.', 'about 200 pixels wide'),
            obj('obj_bonsai_trunk', 'The bare trunk of a small bonsai tree with no leaves: a twisting dark trunk '
                'rising from a little mound of soil and splitting into three main branches that end in bare tips.',
                'about 260 pixels tall'),
        ]),
    dict(
        id='12', title='Vista del estanque', folder='store/art/bg/',
        intro=('Segunda vista del jardín (se llega deslizando). Va encima del mismo cielo y las mismas colinas que '
               'el patio. Adjuntá `store/art/style/style_keyart.webp` y `bg_base_ground`.'),
        images=[
            img('bg_east_ground', PORTRAIT_ALPHA + ALPHA_FALLBACK,
                f'This is the ground layer of the second garden view in {GAME}, the pond side. The game places the '
                'shishi-odoshi, the bonsai, the mossy rocks and the leafy path on top of it.',
                'A small Japanese garden seen from a gentle three-quarter view from above: grass and moss ground with '
                'a calm irregular pond in the lower left, a curving gravel path from the bottom edge to the right, '
                'and a few low flat stones around the pond edge.',
                'The ground fills only the lower 55% of the image; above it everything is fully transparent. Leave '
                'open, calm areas at the upper right, the middle right and above the pond for the objects. '
                + CROP_NOTE,
                f'lanterns, trees, bamboo or objects; sky; {NO_TEXT}; people or animals; frame or border; '
                f'{NO_STYLE}.'),
        ]),
    dict(
        id='13', title='Caligrafía (Ensō) y Templo (Campana)', folder='store/art/temple/',
        intro=('Las dos zonas nuevas de la vista del estanque y las piezas de sus minijuegos. El código dibuja la '
               'tinta del ensō y mueve el tronco y la campana, así que cada pieza va sola y recortada. Adjuntá '
               '`store/art/style/style_keyart.webp`.'),
        images=[
            obj('obj_callig_hall', 'A tiny open Japanese calligraphy pavilion: dark curved tile roof, two wooden '
                'posts, a paper back wall with one hanging scroll showing a black ensō circle, on a low wooden floor. '
                'Seen from the front and a little from above.', 'about 220 pixels tall'),
            obj('obj_temple_belltower', 'A small Japanese bell tower (shōrō) with NO bell inside: four wooden posts, '
                'a dark curved tile roof and a crossbeam to hang a bell from. Seen from the front.',
                'about 300 pixels tall', '; any bell'),
            obj('obj_temple_bell', 'A single Japanese bronze temple bell (bonshō) hanging alone, tall and rounded, '
                'aged greenish-brown bronze with raised bands and rows of small round knobs near the top, with a small loop on '
                'top to hang it from.', 'about 260 pixels tall', '; any rope, chain, beam or tower'),
            obj('obj_temple_log', 'A single horizontal wooden striking log (shumoku) for a temple bell, a smooth '
                'round beam of pale wood with a darker worn tip at the RIGHT end, lying exactly sideways.',
                'about 240 pixels wide', '; any rope, hook or bell'),
            img('bg_enso_paper', PORTRAIT_OPAQUE,
                f'This is the background of the ensō minigame in {GAME}. The player paints a black brush circle on '
                'top of it.',
                'A sheet of warm cream washi paper seen straight on, with soft visible fibers, a few faint '
                'darker fiber flecks and a slightly warmer, softly shaded edge.',
                'Even and calm everywhere, especially the center, so the black ink reads clearly. ' + CROP_NOTE,
                f'ink strokes or circles; characters or writing; {NO_TEXT}; frame or border; {NO_STYLE}.'),
        ]),
    dict(
        id='14', title='Bosque: Casa de té (Matcha), Bambú (Flauta) y Río (Linternas)', folder='store/art/forest/',
        intro=('La tercera vista del jardín y las piezas de sus minijuegos. El código dibuja la espuma del té, las '
               'ráfagas de viento y la corriente, así que cada pieza va sola y recortada. Adjuntá '
               '`store/art/style/style_keyart.webp`.'),
        images=[
            obj('obj_tea_house', 'A tiny Japanese tea house (chashitsu): a low wooden platform, paper shoji walls with '
                'a thin wooden grid, a dark indigo noren curtain over the small entrance and a heavy dark thatched '
                'roof with softly curved eaves. Seen from the front and a little from above.', 'about 260 pixels tall'),
            obj('obj_bamboo_grove', 'A tight grove of eight tall green bamboo culms of different heights and shades, '
                'with visible nodes and light fans of thin leaves near the tops, growing from a small mossy mound. '
                'Seen from the front.', 'about 320 pixels tall'),
            obj('obj_tea_bowl', 'A single Japanese matcha bowl (chawan) seen straight from ABOVE: a thick, slightly '
                'irregular rim of dark brown glazed clay with a lighter drip, and the inside EMPTY, showing the pale '
                'bottom of the bowl.', 'about 300 pixels wide', '; tea, foam, whisk or spoon'),
            obj('obj_tea_whisk', 'A single bamboo tea whisk (chasen) seen straight from ABOVE: a pale bamboo center '
                'with many thin curved tines opening in a circle around it.', 'about 120 pixels wide',
                '; bowl or tea'),
            obj('obj_bamboo_flute', 'A single Japanese bamboo flute (shakuhachi-like) standing exactly upright: pale '
                'golden bamboo with three darker nodes and FOUR round finger holes evenly spaced along the middle.',
                'about 420 pixels tall', '; hands or strings'),
            obj('obj_river_lantern', 'A single small floating paper lantern (tōrō nagashi) seen from above at a '
                'slight angle: a square wooden base and a glowing warm paper cube on top.', 'about 80 pixels tall',
                '; water'),
            img('bg_river', PORTRAIT_OPAQUE,
                f'This is the background of the river lanterns minigame in {GAME}. The code draws the stones, the '
                'lantern, the dock and the current on top of it.',
                'A calm river seen straight from above, flowing from top to bottom and filling the middle 84% of the '
                'width, with narrow sandy and grassy banks on both sides and a few soft ripples.',
                'The water is even and calm everywhere, without rocks or objects, so the pieces on top read clearly. '
                + CROP_NOTE,
                f'stones in the water; boats, lanterns or docks; {NO_TEXT}; people or animals; frame or border; '
                f'{NO_STYLE}.'),
        ]),
]


# Imágenes ya integradas al juego: no se vuelven a pedir. Nombre -> (dónde está, para qué se usa).
INCLUDED = {
    'logo_symbol': ('assets/images/brand/logo_symbol.webp', 'Símbolo del logo (piedra sobre arena rastrillada). '
                    'Pantalla de título (`lib/ui/title_intro.dart`); referencia para el ícono.'),
    'logo_wordmark': ('assets/images/brand/logo_wordmark.webp', 'Nombre "Sandora". Pantalla de título. La versión clara para '
                      'fondos oscuros se saca con código cuando haga falta.'),
    'style_keyart': ('store/art/style/style_keyart.webp', 'Referencia de estilo: no va en el juego (`store/` no se '
                     'sube al repo). Adjuntala en cada bloque siguiente.'),
    'title_bg': ('assets/images/title/title_bg.webp', 'Fondo de la pantalla de título (`lib/ui/title_intro.dart`), con '
                 'el logo sobre el cielo.'),
    'ui_garden_sign': ('assets/images/ui/ui_garden_sign.webp', 'Cartel del jardín, recortado (`lib/ui/widgets/'
                       'garden_sign.dart`). Se usa de ancho fijo con el nombre sobre la tabla, sin nine-slice.'),
    'app_icon': ('store/icon/app_icon.png', 'Ícono de la app (no se sube: `store/`). Se regenera con `dart run '
                 'flutter_launcher_icons` (`flutter_launcher_icons.yaml`); en Android, adaptable sobre arena lisa.'),
    'icon_lotus': ('assets/images/icons/icon_lotus.webp', 'Lotos, recortado a 160 px (`currency.dart`).'),
    'icon_pebble': ('assets/images/icons/icon_pebble.webp', 'Piedritas, recortado a 160 px (`lib/ui/widgets/currency.dart`).'),
    'icon_essence_water': ('assets/images/icons/icon_essence_water.webp', 'Agua, recortado a 160 px (`currency.dart`).'),
    'icon_essence_sand': ('assets/images/icons/icon_essence_sand.webp', 'Arena, recortado a 160 px (`currency.dart`).'),
    'icon_essence_wood': ('assets/images/icons/icon_essence_wood.webp', 'Madera, recortado a 160 px (`currency.dart`).'),
    'icon_essence_light': ('assets/images/icons/icon_essence_light.webp', 'Luz, recortado a 160 px (`currency.dart`).'),
    'icon_star': ('assets/images/icons/icon_star.webp', 'Estrellas del resultado de cada partida, apagadas con '
                  'transparencia (`minigame_screen.dart`).'),
    'obj_callig_hall': ('assets/images/temple/obj_callig_hall.webp', 'Pabellón del Ensō en la vista del estanque '
                        '(`garden_east.dart`, cargado por `scene_art.dart`).'),
    'obj_temple_belltower': ('assets/images/temple/obj_temple_belltower.webp', 'Campanario del estanque; la campana '
                             'y el tronco se cuelgan del gancho de la viga (`garden_east.dart`).'),
    'obj_temple_bell': ('assets/images/temple/obj_temple_bell.webp', 'Campana: en el campanario y en el juego de la '
                        'Campana, donde tiembla y se entibia al sonar (`bell_game.dart`).'),
    'obj_temple_log': ('assets/images/temple/obj_temple_log.webp', 'Tronco (shumoku), punta gastada a la derecha; '
                       'el código dibuja las sogas (`bell_game.dart`).'),
    'bg_enso_paper': ('assets/images/temple/bg_enso_paper.webp', 'Papel washi del Ensō, recortado para llenar la '
                      'pantalla; el sello rojo lo dibuja el código (`enso_game.dart`).'),
    'bg_base_sky': ('assets/images/bg/bg_base_sky.webp', 'Cielo del jardín, estirado a la mitad de arriba de la '
                    'pantalla; se funde con el degradado del día y de noche no se ve (`garden_scene.dart`).'),
    'bg_base_far': ('assets/images/bg/bg_base_far.webp', 'Lomas con niebla, recortadas desde las cimas; las cimas '
                    'quedan al 31 % de la altura y el suelo tapa el resto, en las dos vistas del jardín.'),
}


def pending(b):
    return [im for im in b['images'] if im['name'] not in INCLUDED]


def image_text(i, im):
    return '\n\n'.join([
        f'Image {i} — {im["name"]}:\n{im["fmt"]}',
        f'PURPOSE: {im["purpose"]}',
        f'SUBJECT: {im["subject"]}',
        f'STYLE: {im["style"]}',
        f'COMPOSITION: {im["composition"]}',
        f'DO NOT INCLUDE: {im["exclude"]}',
    ])


def block_text(b):
    images = pending(b)
    n = len(images)
    assert n <= 10, b['id']
    files = ', '.join(f'`{im["name"]}.png`' for im in images)
    if n == 1:
        head = 'Create ONE single image. Start generating immediately, without asking questions or requesting confirmation.'
        body = image_text(1, images[0]).split('\n', 1)[1]
        prompt = f'{head}\n\n{body}'
    else:
        head = (f'Generate exactly {n} separate images. Start generating immediately, without asking questions or '
                'requesting confirmation. Each image has its own complete instructions below; follow them '
                'separately. Each image is its own file: do NOT combine them into a grid, collage or contact sheet.')
        prompt = head + '\n\n' + '\n\n'.join(image_text(i, im) for i, im in enumerate(images, start=1))
    return (f'## Bloque {b["id"]} — {b["title"]} ({n}) ⬜\n\n'
            f'Archivos, en orden: {files}. Carpeta: `{b["folder"]}`.\n'
            f'{b["intro"]}\n\n```\n{prompt}\n```\n')


HEADER = '''# Prompts para generar el arte

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
'''


def included_text():
    rows = '\n'.join(f'| `{name}` | `{path}` | {use} |' for name, (path, use) in INCLUDED.items())
    return f'''---

# Ya incluidas ({len(INCLUDED)})

| Imagen | Archivo en el juego | Uso |
|---|---|---|
{rows}
'''


def main():
    OUT.parent.mkdir(exist_ok=True)
    todo = [b for b in BLOCKS if pending(b)]
    total = sum(len(pending(b)) for b in todo)
    text = HEADER + '\n' + '\n'.join(block_text(b) for b in todo) + '\n' + included_text()
    OUT.write_text(text)
    print(f'{len(todo)} bloques, {total} imágenes por generar, {len(INCLUDED)} incluidas -> {OUT.relative_to(ROOT)}')


main()
