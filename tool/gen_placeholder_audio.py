"""Genera los sonidos placeholder del prototipo (fase 1).

Son sintéticos: sirven para validar timing y sensación al tacto hasta tener
grabaciones reales (ver GDD, "Audio"). Uso:

    python3 tools/gen_placeholder_audio.py

Escribe .wav temporales y los convierte a .m4a (AAC) con ffmpeg en
assets/audio/.
"""

import os
import subprocess
import tempfile
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
rng = np.random.default_rng(7)


def t(seconds):
    return np.arange(int(SR * seconds)) / SR


def env(n, attack=0.005, decay=0.4):
    x = np.arange(n) / SR
    a = np.clip(x / attack, 0, 1)
    return a * np.exp(-x / decay)


def lowpass(x, alpha):
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def bell(freq, seconds=1.6, decay=0.55):
    x = t(seconds)
    s = (np.sin(2 * np.pi * freq * x)
         + 0.35 * np.sin(2 * np.pi * freq * 2.0 * x) * np.exp(-x / 0.25)
         + 0.08 * np.sin(2 * np.pi * freq * 3.01 * x) * np.exp(-x / 0.12))
    # Ataque de 12 ms: suena a campanita de madera, no a click.
    return s * env(len(x), 0.012, decay)


def singing_bowl(freq=220.0, seconds=6.0):
    """Cuenco tibetano: parciales inarmónicos, decaimiento largo y batido lento."""
    x = t(seconds)
    s = np.zeros_like(x)
    for ratio, amp, decay in [(1.0, 1.0, 2.6), (2.71, 0.45, 1.6), (5.15, 0.2, 0.9), (8.2, 0.08, 0.5)]:
        beat = 1 + 0.12 * np.sin(2 * np.pi * 0.9 * ratio * x)
        s += amp * beat * np.sin(2 * np.pi * freq * ratio * x) * np.exp(-x / decay)
    return s * env(len(x), 0.015, 10.0)


def stone_click(base, seconds=0.35):
    """Un "toc" de piedra sobre piedra: grave, redondo y con muy poco ruido."""
    x = t(seconds)
    noise = lowpass(rng.standard_normal(len(x)), 0.1) * np.exp(-x / 0.015)
    body = (np.sin(2 * np.pi * base * x) + 0.3 * np.sin(2 * np.pi * base * 2.4 * x) * np.exp(-x / 0.04)) \
        * np.exp(-x / 0.09)
    return (0.25 * noise + body) * env(len(x), 0.005, 10.0)


def noise_loop(seconds, alpha, mod_hz=0.0, mod_depth=0.0):
    x = t(seconds)
    n = lowpass(rng.standard_normal(len(x)), alpha)
    if mod_hz:
        n *= 1 - mod_depth + mod_depth * np.sin(2 * np.pi * mod_hz * x) ** 2
    # Fundido cruzado de la cola sobre el principio: el loop empalma sin click
    # ni bajón de volumen.
    fade = int(SR * 0.5)
    k = np.sin(np.linspace(0, np.pi / 2, fade)) ** 2
    head = n[:fade] * k + n[-fade:] * (1 - k)
    return np.concatenate([head, n[fade:-fade]])


def arpeggio(freqs, step, decay):
    total = int(SR * (1.2 + step * len(freqs)))
    out = np.zeros(total)
    for k, f in enumerate(freqs):
        note = bell(f, 1.2, decay)
        start = int(SR * step * k)
        out[start:start + len(note)] += note
    return out


def write(name, samples, gain=0.8):
    samples = samples / (np.max(np.abs(samples)) or 1) * gain
    pcm = (samples * 32767).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        path = f.name
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    dst = os.path.join(OUT, f"{name}.m4a")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", path,
                    "-c:a", "aac", "-b:a", "96k", dst], check=True)
    os.remove(path)
    print("ok", dst)


def main():
    os.makedirs(OUT, exist_ok=True)
    # Pentatónica mayor de Do: cualquier secuencia suena bien.
    for i, f in enumerate([523.25, 587.33, 659.25, 783.99, 880.00], start=1):
        write(f"sfx_rain_note_{i:02d}", bell(f))
    for i, f in enumerate([140, 165, 190], start=1):
        write(f"sfx_stack_place_{i:02d}", stone_click(f))
    # La torre que cae: tres "toc" graves que se alejan y un susurro de arena.
    # Se cuenta con calma, no como un choque (GDD, pilar 8).
    fall = np.zeros(int(SR * 1.6))
    for k, (f, amp) in enumerate([(110, 1.0), (96, 0.6), (84, 0.35)]):
        knock = stone_click(f, 0.6) * amp
        start = int(SR * 0.22 * k)
        fall[start:start + len(knock)] += knock
    x = t(1.6)
    fall += 0.12 * lowpass(rng.standard_normal(len(x)), 0.04) * np.exp(-x / 0.5) * env(len(x), 0.2, 10.0)
    write("sfx_stack_fall", fall, 0.6)
    write("sfx_sand_rake", noise_loop(2.0, 0.06, 0.8, 0.4), 0.45)
    write("sfx_base_wind", noise_loop(6.0, 0.02, 0.15, 0.7), 0.55)
    write("sfx_rain_ambient", noise_loop(8.0, 0.15, 0.1, 0.25), 0.35)
    write("sfx_ui_tap", stone_click(300, 0.15), 0.35)
    # Celebraciones en la pentatónica, en registro medio y sin prisa.
    write("sfx_ui_good", bell(523.25, 0.9, 0.3), 0.45)
    write("sfx_ui_great", arpeggio([523.25, 659.25], 0.11, 0.35), 0.5)
    write("sfx_ui_perfect", arpeggio([392.0, 523.25, 659.25, 783.99], 0.11, 0.45), 0.55)
    write("sfx_meditation_bell", singing_bowl(), 0.7)
    write("sfx_cat_meow", bell(700, 0.5, 0.15) * np.sin(2 * np.pi * 6 * t(0.5)) ** 2, 0.4)


if __name__ == "__main__":
    main()
