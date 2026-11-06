"""Genera todo el audio del juego de forma procedural: efectos, ambientes y música.

Sin grabaciones ni servicios externos: cada sonido sale de síntesis (modal,
Karplus-Strong, soplido, ruido granular) pasada por una reverb de jardín, así
que es todo nuestro y no hay licencias que cuidar. Uso:

    python3 tool/gen_audio.py                   # todo
    python3 tool/gen_audio.py sfx_miss music    # solo esos (prefijo del nombre)
    python3 tool/gen_audio.py --preview DIR     # además deja los .wav en DIR

Escribe .m4a (AAC) con ffmpeg en assets/audio/.

Todo suena en la pentatónica de Do (Do Re Mi Sol La): la música, las gotas,
las celebraciones y la flauta nunca chocan entre sí, suene lo que suene junto.
"""

import os
import subprocess
import sys
import tempfile
import wave

import numpy as np
from scipy.signal import butter, fftconvolve, lfilter, sosfilt

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")

_args = sys.argv[1:]
PREVIEW = None
if "--preview" in _args:
    _i = _args.index("--preview")
    PREVIEW = _args[_i + 1]
    del _args[_i:_i + 2]
# Prefijos pedidos por línea de comandos: si hay, solo se escriben esos.
ONLY = _args

rng = np.random.default_rng(7)

# --------------------------------------------------------------------------
# Básicos


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


PENTA = {0, 2, 4, 7, 9}


def scale(lo, hi):
    """Notas MIDI de la pentatónica de Do entre [lo] y [hi]."""
    return [m for m in range(lo, hi + 1) if m % 12 in PENTA]


def t(seconds):
    return np.arange(int(SR * seconds)) / SR


def ramp(x, seconds):
    """Subida suave (seno²) en los primeros [seconds]."""
    return np.sin(np.pi / 2 * np.clip(x / seconds, 0, 1)) ** 2


def noise(n):
    return rng.standard_normal(n)


def lp(x, f, order=2):
    return sosfilt(butter(order, f, "lowpass", fs=SR, output="sos"), x)


def hp(x, f, order=2):
    return sosfilt(butter(order, f, "highpass", fs=SR, output="sos"), x)


def bp(x, lo, hi, order=2):
    return sosfilt(butter(order, [lo, hi], "bandpass", fs=SR, output="sos"), x)


def norm(x):
    return x / (np.std(x) or 1)


def pink(n):
    """Ruido rosa armado en frecuencia: es periódico, así que loopea perfecto."""
    spec = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1 / SR)
    f[0] = f[1]
    return norm(np.fft.irfft(spec / np.sqrt(f), n))


def looped(fn, x):
    """Aplica el filtro [fn] a una señal periódica sin costura: filtra dos
    vueltas y se queda con la segunda, cuando el filtro ya se asentó."""
    n = len(x)
    return fn(np.concatenate([x, x]))[n:]


def slow(n, seconds, count, k_max):
    """Movimiento lento que vuelve exacto al principio (frecuencias múltiplo de
    1/[seconds]): ráfagas de viento, olas de lluvia."""
    x = np.arange(n) / SR
    s = np.zeros(n)
    for _ in range(count):
        k = rng.integers(1, k_max + 1)
        s += np.sin(2 * np.pi * k / seconds * x + rng.uniform(0, 2 * np.pi)) / k ** 0.5
    return s / (np.max(np.abs(s)) or 1)


def stereo(x, pan=0.0):
    """Mono a estéreo con paneo de igual potencia (-1 izquierda, 1 derecha)."""
    a = (pan + 1) * np.pi / 4
    return np.vstack([x * np.cos(a), x * np.sin(a)])


def place(buf, sig, start, circular=False):
    """Suma [sig] en [buf] desde la muestra [start]."""
    sig = np.atleast_2d(sig)
    n = buf.shape[-1]
    if circular:
        idx = (start + np.arange(sig.shape[-1])) % n
        np.add.at(buf, (slice(None), idx) if buf.ndim == 2 else idx, sig if buf.ndim == 2 else sig[0])
        return
    j = min(n, start + sig.shape[-1])
    if j <= start:
        return
    if buf.ndim == 2:
        buf[:, start:j] += sig[:, :j - start]
    else:
        buf[start:j] += sig[0, :j - start]


def mix(*sigs):
    """Suma señales de distinto largo (mono o estéreo)."""
    st = any(np.ndim(s) == 2 for s in sigs)
    n = max(np.shape(s)[-1] for s in sigs)
    out = np.zeros((2, n)) if st else np.zeros(n)
    for s in sigs:
        if st and np.ndim(s) == 1:
            s = stereo(s)
        place(out, s, 0)
    return out


def at(sig, seconds):
    """[sig] corrido [seconds] hacia adelante."""
    pad = int(SR * seconds)
    if np.ndim(sig) == 2:
        return np.pad(sig, ((0, 0), (pad, 0)))
    return np.pad(sig, (pad, 0))


# --------------------------------------------------------------------------
# Reverb: respuestas al impulso sintéticas (ruido que se apaga, con las
# frecuencias altas muriendo antes, como en un patio de madera y piedra).


def make_ir(seconds, decay, damp_hz, seed):
    r = np.random.default_rng(seed)
    x = t(seconds)
    ir = np.zeros((2, len(x)))
    for c in range(2):
        n = r.standard_normal(len(x))
        ir[c] = 0.4 * n * np.exp(-x / (decay * 0.3)) + lp(n, damp_hz) * np.exp(-x / decay)
        for d, a in [(0.009, 0.6), (0.017, 0.45), (0.029, 0.35), (0.041, 0.25), (0.058, 0.18)]:
            ir[c, int(SR * (d + 0.0023 * c * (1 + d * 40)))] += a * r.choice([-1, 1]) * 3
    ir = np.pad(ir, ((0, 0), (int(SR * 0.01), 0)))[:, :len(x)]
    ir *= ramp(x, 0.004)
    return ir / np.sqrt(np.sum(ir ** 2, axis=1, keepdims=True))


GARDEN = make_ir(1.6, 0.32, 3800, 1)
HALL = make_ir(5.0, 1.2, 2600, 2)
TEMPLE = make_ir(6.0, 1.6, 2200, 3)


def verb(x, ir, wet):
    """Seco al centro más la cola en estéreo."""
    if x.ndim == 1:
        x = stereo(x)
    tail = np.vstack([fftconvolve(x[c], ir[c]) for c in range(2)])
    return mix(x * (1 - 0.3 * wet), tail * wet)


def verb_loop(x, ir, wet):
    """Reverb circular: la cola del final cae sobre el principio y el loop no
    tiene costura."""
    n = x.shape[-1]
    tail = np.vstack([np.fft.irfft(np.fft.rfft(x[c]) * np.fft.rfft(ir[c], n), n) for c in range(2)])
    return x * (1 - 0.3 * wet) + tail * wet


def trim(x, db=-62):
    """Corta el silencio del final, con un fundido corto."""
    a = np.max(np.abs(np.atleast_2d(x)), axis=0)
    loud = np.nonzero(a > a.max() * 10 ** (db / 20))[0]
    end = min(a.size, (loud[-1] if loud.size else a.size) + int(SR * 0.02))
    x = x[..., :end].copy()
    k = min(end, int(SR * 0.03))
    x[..., end - k:] *= np.linspace(1, 0, k)
    return x


# --------------------------------------------------------------------------
# Instrumentos


def kalimba(f, seconds=1.8, decay=0.9, bright=1.0):
    """Lengüeta metálica suave: fundamental con un batido lento, un octavo que
    se apaga rápido y el "ping" inarmónico de la púa."""
    x = t(seconds)
    s = np.sin(2 * np.pi * f * x) * np.exp(-x / decay)
    s += 0.5 * np.sin(2 * np.pi * f * 1.0018 * x + 1.3) * np.exp(-x / (decay * 0.8))
    s += 0.16 * bright * np.sin(2 * np.pi * f * 2 * x) * np.exp(-x / (decay * 0.35))
    s += 0.10 * bright * np.sin(2 * np.pi * f * 5.93 * x) * np.exp(-x / 0.05)
    click = 0.08 * bright * hp(noise(len(x)), 2500) * np.exp(-x / 0.0015)
    return (s + click) * ramp(x, 0.0015)


def koto(f, seconds=3.0, t60=2.0, bright=0.5, pos=0.2):
    """Cuerda pulsada (Karplus-Strong con retardo fraccional): una vuelta de
    ruido que se filtra a sí misma hasta sonar como una cuerda de seda."""
    n = int(SR * seconds)
    d = SR / f - 0.5
    ni = int(d)
    fr = d - ni
    g = 10 ** (-3 / (f * t60))
    a = np.zeros(ni + 3)
    a[0] = 1
    a[ni] -= g * 0.5 * (1 - fr)
    a[ni + 1] -= g * 0.5
    a[ni + 2] -= g * 0.5 * fr
    burst = lp(noise(ni + 1), 1200 + 7000 * bright)
    k = max(1, int(pos * ni))
    burst = burst - np.concatenate([np.zeros(k), burst[:-k]])
    exc = np.zeros(n)
    exc[:len(burst)] = burst
    y = lfilter([1.0], a, exc)
    # La uña sobre la cuerda y la caja de madera.
    x = t(seconds)
    y += 0.15 * bright * norm(hp(noise(n), 3000)) * np.exp(-x / 0.003) * np.std(y[:ni * 4])
    y += 0.35 * bp(y, 160, 420) + 0.18 * bp(y, 650, 1400)
    y *= 1 - ramp(x - (seconds - 0.08), 0.08)
    return y / (np.max(np.abs(y)) or 1)


def shakuhachi(f, seconds, breath=0.2, vib=0.006):
    """Flauta de bambú: entra subiendo desde abajo, el vibrato llega tarde y el
    soplido se oye todo el tiempo."""
    x = t(seconds)
    n = len(x)
    glide = 1 - 0.03 * np.exp(-x / 0.09)
    wobble = 1 + vib * np.clip((x - 0.35) / 0.6, 0, 1) * np.sin(2 * np.pi * 5.0 * x + rng.uniform(0, 6))
    drift = 1 + 0.0015 * norm(lp(noise(n), 4))
    ph = 2 * np.pi * np.cumsum(f * glide * wobble * drift) / SR
    tone = np.sin(ph) + 0.28 * np.sin(2 * ph) + 0.12 * np.sin(3 * ph) + 0.05 * np.sin(4 * ph)
    amp = ramp(x, 0.16) * (1 - ramp(x - (seconds - 0.45), 0.45))
    amp *= 1 + 0.08 * norm(lp(noise(n), 2))
    air = norm(bp(noise(n), f * 0.9, min(f * 4, 16000))) * breath
    chiff = norm(bp(noise(n), f * 2, min(f * 6, 18000))) * np.exp(-x / 0.035) * 0.5
    return lp((tone / 1.3 + air) * amp + chiff * ramp(x, 0.01), 5500)


def pad(freqs, seconds, attack=3.5, release=4.0, air=0.15):
    """Colchón: cada nota son tres voces apenas desafinadas que respiran."""
    x = t(seconds)
    out = np.zeros((2, len(x)))
    for f in freqs:
        for det, pan in [(-0.0035, -0.7), (0.0, 0.0), (0.0035, 0.7)]:
            ph = rng.uniform(0, 2 * np.pi)
            lfo = 1 + 0.18 * np.sin(2 * np.pi * rng.uniform(0.04, 0.11) * x + rng.uniform(0, 6))
            ff = f * (1 + det)
            s = np.sin(2 * np.pi * ff * x + ph) + 0.16 * np.sin(4 * np.pi * ff * x + ph) \
                + 0.05 * np.sin(6 * np.pi * ff * x + ph)
            out += stereo(s * lfo, pan)
    # Un poco de aire filtrado para que no suene a órgano.
    out += np.vstack([air * 0.4 * norm(bp(noise(len(x)), 300, 1800)) for _ in range(2)])
    shape = ramp(x, attack) * (1 - ramp(x - (seconds - release), release))
    return out * shape / (len(freqs) * 3)


def bowl(f=220.0, seconds=8.0):
    """Cuenco: parciales inarmónicos en pares apenas separados, que baten."""
    x = t(seconds)
    s = np.zeros(len(x))
    for ratio, amp, decay in [(1.0, 1.0, 3.4), (2.71, 0.5, 2.1), (5.15, 0.22, 1.2), (8.25, 0.09, 0.6),
                              (11.9, 0.04, 0.35)]:
        beat = 0.5 + ratio * 0.3
        s += amp * 0.55 * (np.sin(2 * np.pi * f * ratio * x)
                           + 0.8 * np.sin(2 * np.pi * (f * ratio + beat) * x + 0.6)) * np.exp(-x / decay)
    strike = 0.35 * norm(lp(noise(len(x)), 1400)) * np.exp(-x / 0.008)
    return (s + strike * 0.3) * ramp(x, 0.004)


def stone(base, seconds=0.45, hard=1.0):
    """Piedra contra piedra: modos inarmónicos cortos, el roce del contacto y
    un golpe sordo debajo."""
    x = t(seconds)
    n = len(x)
    s = np.zeros(n)
    for ratio, amp, decay in [(1.0, 1.0, 0.07), (2.32, 0.5, 0.04), (3.91, 0.3, 0.022), (5.6, 0.16, 0.012)]:
        s += amp * np.sin(2 * np.pi * base * ratio * x + rng.uniform(0, 6)) * np.exp(-x / decay)
    contact = 0.35 * hard * norm(bp(noise(n), 900, 6000)) * np.exp(-x / 0.0025)
    thump = 0.6 * norm(lp(noise(n), 260)) * np.exp(-x / 0.025)
    return (s + contact + thump) * ramp(x, 0.0008)


def bamboo(f=410.0, seconds=0.45):
    """Toc de caña hueca: modos de tubo y un poco de ruido que resuena adentro."""
    x = t(seconds)
    n = len(x)
    s = np.zeros(n)
    for ratio, amp, decay in [(1.0, 1.0, 0.08), (2.48, 0.55, 0.035), (4.1, 0.25, 0.015)]:
        s += amp * np.sin(2 * np.pi * f * ratio * x) * np.exp(-x / decay)
    hollow = 0.5 * norm(bp(noise(n), f * 0.92, f * 1.08, 2)) * np.exp(-x / 0.05)
    hit = 0.4 * norm(hp(noise(n), 2000)) * np.exp(-x / 0.002)
    return (s + hollow + hit) * ramp(x, 0.0006)


def drop(f0, rise=2.0, decay=0.045, seconds=0.3):
    """Gota en el agua: la burbuja que se cierra sube de tono de golpe."""
    x = t(seconds)
    f = f0 * np.exp(np.log(rise) * np.clip(x / 0.07, 0, 1))
    ph = 2 * np.pi * np.cumsum(f) / SR
    s = np.sin(ph) * np.exp(-x / decay) * ramp(x, 0.001)
    splash = 0.1 * norm(hp(noise(len(x)), 3500)) * np.exp(-x / 0.004)
    return s + splash * ramp(x, 0.0008)


def grains(seconds, density, lo, hi, bed=0.3, shape_pow=1.5):
    """Textura granular: cientos de chasquidos chiquitos (hojas, cerdas,
    arena) sobre un soplo suave."""
    x = t(seconds)
    n = len(x)
    imp = (rng.random(n) < density / SR) * rng.lognormal(0, 0.7, n) * rng.choice([-1, 1], n)
    crackle = norm(bp(imp, lo, min(hi, 20000)))
    soft = norm(bp(noise(n), lo * 0.6, min(hi * 0.8, 20000)))
    shape = np.sin(np.pi * np.clip(x / seconds, 0, 1)) ** shape_pow
    return (crackle + bed * soft) * shape


def meow(seconds=0.6):
    """Maullido corto: una voz armónica que sube y baja, y una boca que se abre
    (los formantes se mueven) en "mi-a-u"."""
    x = t(seconds)
    n = len(x)
    u = x / seconds
    f = 560 + 280 * np.sin(np.pi * np.clip(u * 1.4, 0, 1)) - 140 * u
    f *= 1 + 0.01 * np.sin(2 * np.pi * 7 * x)
    ph = 2 * np.pi * np.cumsum(f) / SR
    src = sum(np.sin(k * ph) / k for k in range(1, 12))
    mouth = 700 + 800 * np.sin(np.pi * np.clip(u * 1.2, 0, 1))
    out = np.zeros(n)
    for b in [650, 950, 1300, 1700]:
        w = np.exp(-((np.log2(mouth / b)) / 0.3) ** 2)
        out += w * bp(src, b * 0.85, b * 1.15)
    out += 0.3 * bp(src, 2700, 3500)
    return out * np.sin(np.pi * u) ** 0.7 * ramp(x, 0.03)


def snip(f=3400.0):
    """Tijera de podar ("pachin"): dos chasquidos metálicos muy cortos, el
    segundo apenas más grave, y la ramita que cae entre las hojas."""
    def click(f0, a):
        x = t(0.09)
        n = len(x)
        s = np.zeros(n)
        for ratio, amp, decay in [(1.0, 1.0, 0.012), (1.47, 0.6, 0.008), (2.18, 0.4, 0.005), (3.05, 0.2, 0.003)]:
            s += amp * np.sin(2 * np.pi * f0 * ratio * x + rng.uniform(0, 6)) * np.exp(-x / decay)
        tick = 0.5 * norm(hp(noise(n), 2500)) * np.exp(-x / 0.0015)
        return a * (s + tick) * ramp(x, 0.0004)
    leaves = lp(grains(0.22, 1100, 1500, 8000, 0.2), 7000) * 0.22
    return mix(click(f, 1.0), at(click(f * 0.86, 0.7), 0.055), at(leaves, 0.07))


def whisk_loop(seconds):
    """Batidor de bambú en el matcha: un vaivén rápido (7 por segundo) de
    espuma que chisporrotea, con burbujitas que revientan."""
    n = int(SR * seconds)
    x = np.arange(n) / SR
    rate = round(7 * seconds) / seconds
    stroke = 0.3 + 0.7 * np.abs(np.sin(np.pi * rate * x)) ** 1.5
    out = np.zeros((2, n))
    for c in range(2):
        froth = norm(looped(lambda s: bp(s, 1800, 9000), noise(n)))
        liquid = norm(looped(lambda s: bp(s, 300, 1400), pink(n)))
        bubbles = np.zeros(n)
        for _ in range(int(seconds * 260)):
            b = drop(rng.uniform(2200, 5200), rng.uniform(1.2, 1.6), rng.uniform(0.002, 0.005), 0.02)
            place(bubbles, b * rng.uniform(0.2, 1.0), int(rng.integers(n)), circular=True)
        g = np.roll(stroke, int(SR * 0.004 * c))
        out[c] = (0.5 * froth + 0.25 * liquid) * g + 0.9 * norm(bubbles) * g
    return out


def chirp(f1, f2, seconds, curve=1.0, amp=1.0):
    """Un trino de pájaro: un silbido que se desliza de [f1] a [f2]."""
    x = t(seconds)
    u = (x / seconds) ** curve
    f = f1 + (f2 - f1) * u
    ph = 2 * np.pi * np.cumsum(f) / SR
    env = np.sin(np.pi * np.clip(x / seconds, 0, 1)) ** 0.8
    return amp * (np.sin(ph) + 0.12 * np.sin(2 * ph)) * env


def bird(kind):
    """Pájaros del jardín, de lejos: un ruiseñor japonés ("hoo... hokekyo"),
    un mosquitero que baja en trinos y un ojiblanco que repite dos notas."""
    if kind == 1:
        hold = chirp(1150, 1350, 0.75, 2.0) * (1 + 0.02 * np.sin(2 * np.pi * 9 * t(0.75)))
        call = mix(chirp(1700, 2500, 0.12), at(chirp(2500, 1600, 0.14), 0.16), at(chirp(3000, 2300, 0.32, 0.6), 0.34))
        return mix(hold, at(call, 0.95))
    if kind == 2:
        return mix(*[at(chirp(4200 - 250 * k, 3200 - 250 * k, 0.07, amp=1 - 0.08 * k), 0.11 * k) for k in range(6)])
    note = lambda f: mix(chirp(f, f * 1.25, 0.06), at(chirp(f * 1.25, f * 1.1, 0.08), 0.06))
    return mix(*[at(note(2900 if k % 2 == 0 else 3300), 0.17 * k) for k in range(5)])


def stone_in_sand(base, seconds=0.5):
    """Piedra que se apoya en la arena: un golpe sordo y grave (sin el "clac"
    de piedra contra piedra) y la arena que se acomoda alrededor."""
    x = t(seconds)
    n = len(x)
    body = sum(a * np.sin(2 * np.pi * base * r * x + rng.uniform(0, 6)) * np.exp(-x / d)
               for r, a, d in [(1.0, 1.0, 0.045), (1.9, 0.35, 0.025)])
    thud = 0.9 * norm(lp(noise(n), 320)) * np.exp(-x / 0.03)
    crunch = 0.35 * lp(grains(0.4, 2200, 1200, 6000, 0.5, 0.7), 5500)
    crunch = np.pad(crunch, (0, n - len(crunch)))[:n] * np.exp(-x / 0.12)
    return (0.5 * body + thud + at(crunch, 0.012)[:n]) * ramp(x, 0.0015)


def wings(flaps=7, rate=14.0, seconds=0.7):
    """Pájaros que levantan vuelo: aleteos rápidos (soplos de aire) que se
    alejan y se apagan."""
    x = t(seconds)
    n = len(x)
    air = norm(bp(noise(n), 500, 3500))
    gate = np.zeros(n)
    for k in range(flaps):
        c = k / rate * (1 + 0.04 * rng.standard_normal())
        gate += (0.85 ** k) * np.exp(-((x - c) / 0.018) ** 2)
    return air * gate * np.exp(-x / (seconds * 0.6))


def shoji_slide(seconds=1.6):
    """Puertas corredizas de madera: el destrabe, el roce sobre el riel (que
    arranca, corre y frena) y un tope suave al final."""
    x = t(seconds)
    n = len(x)
    move = np.clip(x / 0.15, 0, 1) * np.clip((seconds - 0.12 - x) / 0.6, 0, 1) ** 1.5
    wobble = 1 + 0.25 * np.sin(2 * np.pi * 17 * x) * np.sin(2 * np.pi * 3.1 * x)
    rub = norm(bp(pink(n), 180, 1600)) * 0.8 + 0.25 * norm(bp(noise(n), 1800, 4500))
    slide = rub * move * wobble
    latch = 0.7 * np.pad(bamboo(520, 0.25), (0, n))[:n]
    stop = np.zeros(n)
    k = int(SR * (seconds - 0.18))
    tok = stone(140, 0.18, 0.2)
    stop[k:k + len(tok)] = tok[:n - k] * 0.5
    return latch + at(slide, 0.08)[:n] * 0.55 + stop


def cricket(seconds=1.6):
    """Grillo campana (suzumushi) de noche: "riiin, riiin", pulsos rápidos de
    un tono agudo, en dos ráfagas."""
    x = t(seconds)
    pulses = (np.sin(2 * np.pi * 38 * x) > 0.2).astype(float)
    pulses = lp(pulses, 300)
    bursts = np.zeros(len(x))
    for start in [0.05, 0.75]:
        u = np.clip((x - start) / 0.45, 0, 1)
        bursts += np.sin(np.pi * u) ** 0.6 * (u > 0) * (u < 1)
    tone = np.sin(2 * np.pi * 4300 * x) + 0.3 * np.sin(2 * np.pi * 4300 * 2.02 * x)
    return tone * pulses * bursts

# --------------------------------------------------------------------------
# Ambientes en loop (todo circular: empalman sin costura)


def wind_loop(seconds):
    n = int(SR * seconds)
    gust = 0.55 + 0.45 * slow(n, seconds, 4, 3)
    center = 520 * 2 ** (0.9 * slow(n, seconds, 3, 4))
    out = np.zeros((2, n))
    for c in range(2):
        base = pink(n)
        bed = looped(lambda s: lp(s, 1100), base)
        whistle = np.zeros(n)
        for b in [260, 360, 500, 700, 980, 1380]:
            w = np.exp(-((np.log2(center / b)) / 0.35) ** 2)
            whistle += w * norm(looped(lambda s, b=b: bp(s, b * 0.93, b * 1.07), base))
        g = np.roll(gust, int(SR * 0.15 * c))
        out[c] = norm(bed) * g + 0.35 * whistle * g ** 2
    return out


def rain_loop(seconds):
    n = int(SR * seconds)
    swell = 0.8 + 0.2 * slow(n, seconds, 3, 3)
    out = np.zeros((2, n))
    rumble = norm(looped(lambda s: lp(s, 200), pink(n)))
    for c in range(2):
        bed = norm(looped(lambda s: bp(s, 600, 7000), pink(n)))
        ch = np.zeros(n)
        # Miles de gotitas finas.
        imp = (rng.random(n) < 1100 / SR) * rng.lognormal(-0.5, 0.8, n)
        tick = hp(noise(300), 2500) * np.exp(-np.arange(300) / (SR * 0.0012))
        ch += norm(np.fft.irfft(np.fft.rfft(imp) * np.fft.rfft(tick, n), n)) * 0.6
        # Gotas grandes que pegan en hojas y charcos.
        for _ in range(int(seconds * 5)):
            d = drop(rng.uniform(900, 2600), rng.uniform(1.4, 2.2), rng.uniform(0.01, 0.025), 0.08)
            buf = np.zeros(n)
            place(buf, d * rng.uniform(0.2, 1.0), int(rng.integers(n)), circular=True)
            ch += buf * 2.2
        out[c] = (0.6 * bed + ch) * swell + 0.35 * rumble
    return verb_loop(out, GARDEN, 0.25)


def rake_loop(seconds):
    n = int(SR * seconds)
    x = np.arange(n) / SR
    stroke = 0.35 + 0.65 * np.sin(np.pi * x / seconds) ** 2
    imp = (rng.random(n) < 2600 / SR) * rng.lognormal(0, 0.6, n) * rng.choice([-1, 1], n)
    crunch = norm(looped(lambda s: bp(s, 1300, 6500), imp))
    soft = norm(looped(lambda s: bp(s, 500, 3000), pink(n)))
    return (crunch + 0.6 * soft) * stroke


# --------------------------------------------------------------------------
# Música del jardín: piezas tranquilas de un minuto y medio que terminan en
# silencio; el juego las alterna con una pausa entre una y otra.


def music(seed, chords, per, repeats, lead):
    global rng
    rng = np.random.default_rng(seed)
    prog = chords * repeats + [chords[0]]
    length = per * len(prog)
    n = int(SR * (length + 8))
    dry = np.zeros((2, n))
    send = np.zeros((2, n))

    def add(sig, start, pan=0.0, wet=0.35, vol=1.0):
        s = sig if sig.ndim == 2 else stereo(sig, pan)
        i = int(start * SR)
        place(dry, s * vol, i)
        place(send, s * vol * wet, i)

    def chord_at(sec):
        return prog[min(int(sec // per), len(prog) - 1)]

    def snap(notes, idx, sec):
        """Lleva la última nota de una frase a una del acorde que suena."""
        pcs = {m % 12 for m in chord_at(sec)}
        best = min((i for i in range(len(notes)) if notes[i] % 12 in pcs), key=lambda i: abs(i - idx), default=idx)
        return best

    # Colchón: cada acorde entra y sale despacio, encimado con el siguiente.
    for k, ch in enumerate(prog):
        last = k == len(prog) - 1
        start = max(0, k * per - 2)
        dur = per + (4 if k else 2) + (3 if last else 0)
        add(pad([hz(m) for m in ch], dur, attack=3.5, release=6 if last else 4), start, wet=0.3, vol=0.9)
        # Un bajo pulsado marca cada cambio de acorde.
        if lead == "koto" or k % 2 == 0:
            add(koto(hz(ch[0] + 12), 4.5, t60=3.2, bright=0.2) * 0.32, k * per + 0.1, pan=-0.15, wet=0.3)

    if lead == "koto":
        notes = scale(60, 81)
        sec = rng.uniform(3, 4.5)
        while sec < length - 6:
            count = int(rng.integers(3, 7))
            idx = int(rng.integers(3, len(notes) - 3))
            step = rng.choice([0.38, 0.44, 0.5])
            tt = sec
            for j in range(count):
                last = j == count - 1
                if last:
                    idx = snap(notes, idx, tt)
                vel = rng.uniform(0.5, 0.9) * (1.0 if j == 0 else 0.85)
                add(koto(hz(notes[idx]), 4.0 if last else 2.6, t60=2.2 if last else 1.5, bright=0.3 + 0.4 * vel)
                    * vel * 0.55, tt, pan=rng.uniform(-0.35, 0.35), wet=0.38)
                tt += step * rng.choice([1, 1, 1, 2, 0.5], p=[0.45, 0.15, 0.1, 0.2, 0.1]) + rng.normal(0, 0.02)
                idx = int(np.clip(idx + rng.choice([-2, -1, -1, 1, 1, 2]), 0, len(notes) - 1))
            sec = tt + rng.uniform(4, 8)
    else:
        notes = scale(62, 79)
        sec = rng.uniform(4, 6)
        while sec < length - 9:
            count = int(rng.integers(2, 5))
            idx = int(rng.integers(2, len(notes) - 2))
            tt = sec
            for j in range(count):
                last = j == count - 1
                if last:
                    idx = snap(notes, idx, tt)
                dur = rng.uniform(1.4, 2.4) * (1.5 if last else 1)
                add(shakuhachi(hz(notes[idx]), dur) * 0.42, tt, pan=0.12, wet=0.5)
                tt += dur + rng.uniform(0.08, 0.35)
                idx = int(np.clip(idx + rng.choice([-2, -1, 1, 1, 2]), 0, len(notes) - 1))
            sec = tt + rng.uniform(6, 11)

    # Alguna campanita alta, lejos.
    sec = rng.uniform(8, 12)
    while sec < length - 4:
        m = rng.choice(scale(84, 93))
        add(kalimba(hz(m), 2.5, 1.2, 0.6) * 0.16, sec, pan=rng.uniform(-0.6, 0.6), wet=0.6)
        sec += rng.uniform(9, 17)

    wet = np.vstack([fftconvolve(send[c], HALL[c]) for c in range(2)])
    out = mix(dry, wet * 0.55)
    x = np.arange(out.shape[1]) / SR
    out *= 1 - ramp(x - (length + 1), 5)
    return trim(out, -70)


# --------------------------------------------------------------------------
# Escritura


def write(name, x, gain=0.8, rms=None, kbps=96, fade=True):
    if ONLY and not any(name.startswith(o) for o in ONLY):
        return
    x = np.atleast_2d(np.asarray(x, dtype=float))
    if rms:
        x = x * (rms / (np.sqrt(np.mean(x ** 2)) or 1))
        x = np.tanh(x / 0.95) * 0.95
    else:
        x = x / (np.max(np.abs(x)) or 1) * gain
    if fade:
        k = int(SR * 0.008)
        x[:, -k:] *= np.linspace(1, 0, k)
    pcm = (np.clip(x, -1, 1).T * 32767).astype("<i2")
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        path = f.name
    with wave.open(path, "wb") as w:
        w.setnchannels(x.shape[0])
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    dst = os.path.join(OUT, f"{name}.m4a")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", path, "-c:a", "aac", "-b:a", f"{kbps}k", dst],
                   check=True)
    if PREVIEW:
        os.makedirs(PREVIEW, exist_ok=True)
        os.replace(path, os.path.join(PREVIEW, f"{name}.wav"))
    else:
        os.remove(path)
    print("ok", dst)


def wanted(*prefixes):
    return not ONLY or any(p.startswith(o) or o.startswith(p) for p in prefixes for o in ONLY)


def main():
    os.makedirs(OUT, exist_ok=True)

    if wanted("sfx_rain_note"):
        # Do Re Mi Sol La: cualquier secuencia suena bien.
        for i, m in enumerate([72, 74, 76, 79, 81], start=1):
            write(f"sfx_rain_note_{i:02d}", verb(kalimba(hz(m)), GARDEN, 0.22), 0.8)
    if wanted("sfx_ui"):
        write("sfx_ui_tap", stone(900, 0.12, 0.6), 0.35)
        write("sfx_ui_good", verb(kalimba(hz(72), 1.4, 0.6), GARDEN, 0.2), 0.45)
        write("sfx_ui_great", verb(mix(kalimba(hz(72), 1.4, 0.6), at(kalimba(hz(76), 1.6, 0.7), 0.11)), GARDEN, 0.22),
              0.5)
        perfect = mix(*[at(kalimba(hz(m), 1.8, 0.8) * (0.85 + 0.05 * k), 0.11 * k)
                        for k, m in enumerate([67, 72, 76, 79])], at(kalimba(hz(84), 2.2, 1.0, 0.5) * 0.35, 0.5))
        write("sfx_ui_perfect", verb(perfect, GARDEN, 0.28), 0.55)
    if wanted("sfx_stack"):
        for i, f in enumerate([210, 240, 275], start=1):
            write(f"sfx_stack_place_{i:02d}", verb(stone(f), GARDEN, 0.12), 0.8)
        # La torre que cae: tres "toc" que se alejan y un hilo de arena. Se
        # cuenta con calma, no como un choque (GDD, pilar 8).
        fall = mix(*[at(stone(f, 0.6) * a, 0.22 * k) for k, (f, a) in enumerate([(190, 1.0), (170, 0.6), (150, 0.35)])],
                   at(lp(grains(1.3, 1400, 1500, 6000, 0.5, 0.6), 5000) * 0.12 * np.exp(-t(1.3) / 0.6), 0.1))
        write("sfx_stack_fall", verb(fall, GARDEN, 0.2), 0.6)
    if wanted("sfx_sand_rake"):
        write("sfx_sand_rake", np.vstack([rake_loop(2.0), rake_loop(2.0)]), rms=0.12, fade=False)
    if wanted("sfx_base_wind"):
        write("sfx_base_wind", wind_loop(8.0), rms=0.13, fade=False)
    if wanted("sfx_rain_ambient"):
        write("sfx_rain_ambient", rain_loop(8.0), rms=0.11, fade=False)
    if wanted("sfx_meditation_bell"):
        write("sfx_meditation_bell", trim(verb(bowl(220.0, 8.0), TEMPLE, 0.35)), 0.7)
    if wanted("sfx_cat_meow"):
        write("sfx_cat_meow", verb(meow(), GARDEN, 0.15), 0.4)
    if wanted("sfx_miss"):
        # Error: dos notas de cuerda apagadas que bajan. Avisa sin retar.
        miss = mix(koto(hz(64), 0.5, 0.18, 0.15), at(koto(hz(60), 0.55, 0.2, 0.12) * 0.85, 0.1))
        write("sfx_miss", verb(lp(miss, 2500), GARDEN, 0.15), 0.3)
    if wanted("sfx_finish"):
        # Cierre de partida: campanitas que bajan y un cuenco suave debajo.
        bells = mix(*[at(kalimba(hz(m), 2.0, 0.9), 0.16 * k) for k, m in enumerate([79, 76, 72, 67])])
        write("sfx_finish", trim(verb(mix(bells, bowl(196.0, 4.0) * 0.3), GARDEN, 0.3)), 0.5)
    if wanted("sfx_bamboo_tok"):
        write("sfx_bamboo_tok", verb(bamboo(), GARDEN, 0.18), 0.6)
    if wanted("sfx_water_drop"):
        for i, (f0, r) in enumerate([(620, 2.1), (540, 2.3), (720, 1.9)], start=1):
            write(f"sfx_water_drop_{i:02d}", trim(verb(drop(f0, r), GARDEN, 0.3)), 0.45)
    if wanted("sfx_leaf_rustle"):
        for i, d in enumerate([900, 1400], start=1):
            write(f"sfx_leaf_rustle_{i:02d}", grains(0.38, d, 1800, 9000, 0.25), 0.35)
    if wanted("sfx_brush"):
        for i, d in enumerate([300, 450], start=1):
            write(f"sfx_brush_{i:02d}", grains(0.3, d, 900, 4500, 0.9, 1.2), 0.3)
    if wanted("sfx_pluck"):
        # Arrancar maleza: la tierra que cede, un "pop" grave y migas que caen.
        x = t(0.35)
        pop = np.sin(2 * np.pi * np.cumsum(220 * np.exp(-x / 0.08) + 90) / SR) * np.exp(-x / 0.05)
        dirt = grains(0.3, 1800, 400, 2500, 0.4, 0.8) * 0.5
        write("sfx_pluck", verb(mix(pop * ramp(x, 0.002), at(dirt, 0.03)), GARDEN, 0.12), 0.45)
    if wanted("sfx_sweep"):
        write("sfx_sweep", grains(0.5, 2600, 1500, 9500, 0.6, 1.0), 0.4)
    if wanted("sfx_flute_note"):
        for i, m in enumerate([67, 69, 72, 74], start=1):
            write(f"sfx_flute_note_{i:02d}", trim(verb(shakuhachi(hz(m), 1.4), GARDEN, 0.3)), 0.5)

    if wanted("sfx_snip"):
        for i, f in enumerate([3400, 3000], start=1):
            write(f"sfx_snip_{i:02d}", trim(verb(snip(f), GARDEN, 0.1)), 0.45)
    if wanted("sfx_whisk"):
        write("sfx_whisk", whisk_loop(2.0), rms=0.1, fade=False)
    if wanted("sfx_bird"):
        for k in (1, 2, 3):
            write(f"sfx_bird_{k:02d}", trim(verb(lp(bird(k), 7000), GARDEN, 0.35)), 0.35)
    if wanted("sfx_stone_sand"):
        for i, f in enumerate([95, 115, 135], start=1):
            write(f"sfx_stone_sand_{i:02d}", trim(verb(stone_in_sand(f), GARDEN, 0.1)), 0.7)
    if wanted("sfx_wings"):
        for i, (fl, r) in enumerate([(7, 14.0), (9, 17.0)], start=1):
            write(f"sfx_wings_{i:02d}", lp(wings(fl, r), 6000), 0.4)
    if wanted("sfx_gate_open"):
        write("sfx_gate_open", trim(verb(shoji_slide(), HALL, 0.18)), 0.55)
    if wanted("sfx_night_cricket"):
        write("sfx_night_cricket", trim(verb(cricket(), GARDEN, 0.3)), 0.25)

    if wanted("music_garden_01"):
        write("music_garden_01",
              music(11, [[48, 55, 62, 64], [45, 52, 60, 67], [41, 53, 57, 64, 67], [43, 50, 57, 62]], 12, 2, "koto"),
              0.75, kbps=128)
    if wanted("music_garden_02"):
        write("music_garden_02",
              music(23, [[45, 52, 60, 67], [41, 48, 57, 64], [40, 48, 55, 64], [43, 50, 55, 64]], 14, 2, "flute"),
              0.75, kbps=128)


if __name__ == "__main__":
    main()
