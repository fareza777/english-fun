"""Draw a cute fox launcher icon (adaptive foreground + legacy mipmaps)."""
import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
RES = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')

SKY_TOP = (94, 201, 255)     # light blue
SKY_BOT = (43, 123, 255)     # deep blue
ORANGE = (255, 138, 61)
ORANGE_DARK = (230, 110, 40)
CREAM = (255, 240, 220)
DARK = (60, 40, 30)


def vertical_gradient(size, top, bottom):
    img = Image.new('RGB', (size, size))
    for y in range(size):
        t = y / (size - 1)
        c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        for x in range(size):
            img.putpixel((x, y), c)
    return img


def draw_fox(draw, cx, cy, s):
    """Draw a fox face centered at (cx, cy) with scale s (head radius)."""
    # ears (triangles)
    for side in (-1, 1):
        ex = cx + side * s * 0.62
        ey = cy - s * 0.55
        draw.polygon([(ex - side * s * 0.34, ey + s * 0.28),
                      (ex + side * s * 0.30, ey + s * 0.34),
                      (ex + side * s * 0.02, ey - s * 0.62)], fill=ORANGE)
        # inner ear
        draw.polygon([(ex - side * s * 0.20, ey + s * 0.24),
                      (ex + side * s * 0.17, ey + s * 0.27),
                      (ex + side * s * 0.01, ey - s * 0.34)], fill=ORANGE_DARK)
    # head
    draw.ellipse([cx - s, cy - s * 0.85, cx + s, cy + s * 0.85], fill=ORANGE)
    # white muzzle patches
    for side in (-1, 1):
        draw.ellipse([cx + side * s * 0.52 - s * 0.46, cy + s * 0.05,
                      cx + side * s * 0.52 + s * 0.46, cy + s * 0.75], fill=CREAM)
    draw.ellipse([cx - s * 0.42, cy + s * 0.18, cx + s * 0.42, cy + s * 0.8], fill=CREAM)
    # eyes (happy closed arcs -> use big shiny eyes)
    for side in (-1, 1):
        ex = cx + side * s * 0.42
        ey = cy - s * 0.08
        r = s * 0.15
        draw.ellipse([ex - r, ey - r, ex + r, ey + r], fill=DARK)
        draw.ellipse([ex - r * 0.4, ey - r * 0.55, ex + r * 0.15, ey - r * 0.05], fill=(255, 255, 255))
    # nose
    nr = s * 0.16
    draw.ellipse([cx - nr, cy + s * 0.28 - nr, cx + nr, cy + s * 0.28 + nr], fill=DARK)
    # smile
    draw.arc([cx - s * 0.3, cy + s * 0.3, cx + s * 0.3, cy + s * 0.62], 20, 160, fill=DARK, width=max(2, int(s * 0.05)))


def rounded_mask(size, radius_ratio=0.22):
    mask = Image.new('L', (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=int(size * radius_ratio), fill=255)
    return mask


def make_legacy(size):
    img = vertical_gradient(size, SKY_TOP, SKY_BOT)
    d = ImageDraw.Draw(img)
    # sparkle stars
    for (sx, sy, r) in ((0.18, 0.2, 0.03), (0.82, 0.16, 0.022), (0.86, 0.78, 0.028), (0.14, 0.82, 0.02)):
        x, y, rr = sx * size, sy * size, r * size
        d.polygon([(x, y - rr), (x + rr * 0.3, y - rr * 0.3), (x + rr, y), (x + rr * 0.3, y + rr * 0.3),
                   (x, y + rr), (x - rr * 0.3, y + rr * 0.3), (x - rr, y), (x - rr * 0.3, y - rr * 0.3)],
                  fill=(255, 255, 255))
    draw_fox(d, size / 2, size * 0.54, size * 0.30)
    out = Image.new('RGBA', (size, size))
    out.paste(img, (0, 0))
    out.putalpha(rounded_mask(size))
    return out


def make_adaptive_fg(size):
    """Foreground with transparent padding (safe zone ~66%)."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    draw_fox(d, size / 2, size * 0.55, size * 0.22)
    return img


def make_adaptive_bg(size):
    return vertical_gradient(size, SKY_TOP, SKY_BOT).convert('RGBA')


DENSITIES = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
ADAPTIVE = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}

for name, px in DENSITIES.items():
    folder = os.path.join(RES, f'mipmap-{name}')
    os.makedirs(folder, exist_ok=True)
    make_legacy(px).save(os.path.join(folder, 'ic_launcher.png'))
    make_legacy(px).save(os.path.join(folder, 'ic_launcher_round.png'))

for name, px in ADAPTIVE.items():
    folder = os.path.join(RES, f'mipmap-{name}')
    make_adaptive_fg(px).save(os.path.join(folder, 'ic_launcher_foreground.png'))
    make_adaptive_bg(px).save(os.path.join(folder, 'ic_launcher_background.png'))

anydpi = os.path.join(RES, 'mipmap-anydpi-v26')
os.makedirs(anydpi, exist_ok=True)
with open(os.path.join(anydpi, 'ic_launcher.xml'), 'w') as f:
    f.write('<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
            '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
            '</adaptive-icon>\n')
with open(os.path.join(anydpi, 'ic_launcher_round.xml'), 'w') as f:
    f.write('<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
            '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
            '</adaptive-icon>\n')

print('ICONS DONE')
