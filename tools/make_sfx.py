"""Synthesize kid-friendly sound effects as WAV files (44.1kHz 16-bit mono)."""
import math
import os
import random
import struct
import wave

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'sfx')
os.makedirs(OUT, exist_ok=True)
random.seed(7)


def write_wav(name, samples):
    path = os.path.join(OUT, name)
    with wave.open(path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b''.join(struct.pack('<h', int(max(-1.0, min(1.0, s)) * 32767)) for s in samples)
        w.writeframes(frames)
    print('wrote', name, len(samples))


def tone(freq, dur, vol=0.5, attack=0.005, decay=None, harmonics=((1, 1.0),), vibrato=0.0):
    n = int(SR * dur)
    decay = decay if decay is not None else dur
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SR
        f = freq * (1.0 + vibrato * math.sin(2 * math.pi * 6 * t))
        phase += 2 * math.pi * f / SR
        s = sum(a * math.sin(h * phase) for h, a in harmonics)
        env = min(1.0, t / attack) * max(0.0, 1.0 - t / decay)
        out.append(vol * env * s)
    return out


def sweep(f0, f1, dur, vol=0.5, harmonics=((1, 1.0), (2, 0.25))):
    n = int(SR * dur)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SR
        f = f0 + (f1 - f0) * (i / n)
        phase += 2 * math.pi * f / SR
        s = sum(a * math.sin(h * phase) for h, a in harmonics)
        env = min(1.0, t / 0.008) * max(0.0, 1.0 - t / dur)
        out.append(vol * env * s)
    return out


def whoosh(dur=0.18, vol=0.35):
    n = int(SR * dur)
    out = []
    prev = 0.0
    for i in range(n):
        t = i / SR
        noise = random.uniform(-1, 1)
        prev = 0.85 * prev + 0.15 * noise  # crude lowpass
        env = math.sin(math.pi * i / n) ** 1.5
        out.append(vol * env * prev * 3.0)
    return out


def concat(*parts, gap=0.03):
    out = []
    g = [0.0] * int(SR * gap)
    for p in parts:
        out.extend(p)
        out.extend(g)
    return out


def mix(a, b):
    n = max(len(a), len(b))
    return [(a[i] if i < len(a) else 0) + (b[i] if i < len(b) else 0) for i in range(n)]


# click: short UI tap
write_wav('click.wav', tone(900, 0.05, vol=0.35, decay=0.05, harmonics=((1, 1.0), (3, 0.2))))

# pop: bubble pop for selecting cards
write_wav('pop.wav', sweep(320, 980, 0.09, vol=0.38))

# flip: soft airy tone sweep (no harsh noise)
write_wav('flip.wav', sweep(340, 720, 0.13, vol=0.2, harmonics=((1, 1.0), (2, 0.12))))

# ding: correct answer (C6 -> E6 chime)
write_wav('ding.wav', concat(
    tone(1046.5, 0.14, vol=0.5, decay=0.14, harmonics=((1, 1.0), (2, 0.3), (3, 0.1))),
    tone(1318.5, 0.22, vol=0.5, decay=0.22, harmonics=((1, 1.0), (2, 0.3))),
    gap=0.02,
))

# wrong: gentle low "womp" (not scary for kids)
write_wav('wrong.wav', concat(
    tone(196, 0.16, vol=0.4, decay=0.16, harmonics=((1, 1.0), (2, 0.4))),
    tone(174.6, 0.24, vol=0.4, decay=0.24, harmonics=((1, 1.0), (2, 0.4))),
    gap=0.02,
))

# star: sparkle (fast high arpeggio)
write_wav('star.wav', concat(
    tone(1568, 0.08, vol=0.4, decay=0.08),
    tone(2093, 0.08, vol=0.4, decay=0.08),
    tone(2637, 0.16, vol=0.45, decay=0.16, harmonics=((1, 1.0), (2, 0.35))),
    gap=0.01,
))

# fanfare: unit complete (C E G C' with harmony)
melody = [(523.25, 0.13), (659.25, 0.13), (783.99, 0.13), (1046.5, 0.3)]
parts = []
for f, d in melody:
    parts.append(mix(
        tone(f, d, vol=0.45, decay=d, harmonics=((1, 1.0), (2, 0.3))),
        tone(f / 2, d, vol=0.2, decay=d),
    ))
write_wav('fanfare.wav', concat(*parts, gap=0.03))

# win: big celebration arpeggio with trill ending
notes = [523.25, 587.33, 659.25, 783.99, 1046.5, 1318.5]
parts = [tone(f, 0.11, vol=0.42, decay=0.11, harmonics=((1, 1.0), (2, 0.25))) for f in notes]
ending = mix(
    tone(1568, 0.5, vol=0.45, decay=0.5, vibrato=0.012, harmonics=((1, 1.0), (2, 0.3))),
    tone(1046.5, 0.5, vol=0.3, decay=0.5),
)
write_wav('win.wav', concat(*parts, gap=0.02) + [0.0] * int(SR * 0.05) + ending)

print('ALL SFX DONE')
