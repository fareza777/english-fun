"""Subset NotoColorEmoji.ttf to only the emojis used by the app.

Scans all Dart sources for non-ASCII chars (emojis, ZWJ, VS16, keycaps),
then runs fontTools subset so the bundled font stays small (~1-3 MB
instead of ~10 MB) and every device renders identical emoji artwork.
"""
import os
import re

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(BASE, 'tools', 'NotoColorEmoji.ttf')
OUT = os.path.join(BASE, 'assets', 'fonts', 'NotoColorEmojiSubset.ttf')
TXT = os.path.join(BASE, 'tools', 'emojis_used.txt')


def collect_chars() -> str:
    chars = set()
    for root, _dirs, files in os.walk(os.path.join(BASE, 'lib')):
        for fn in files:
            if not fn.endswith('.dart'):
                continue
            with open(os.path.join(root, fn), encoding='utf-8') as f:
                text = f.read()
            for c in text:
                o = ord(c)
                # emoji blocks + modifiers + joiners/selectors
                if o >= 0x2000:
                    chars.add(c)
    # keycap sequences need digits, #, * and combining enclosing keycap
    chars.update('0123456789#*️⃣‍')
    return ''.join(sorted(chars))


def main() -> None:
    chars = collect_chars()
    with open(TXT, 'w', encoding='utf-8') as f:
        f.write(chars)
    print(f'unique chars: {len(chars)}')

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    from fontTools import subset
    subset.main([
        SRC,
        f'--output-file={OUT}',
        f'--text-file={TXT}',
        '--no-hinting',
        '--glyph-names',
    ])
    size = os.path.getsize(OUT)
    print(f'subset font: {size / 1024 / 1024:.2f} MB -> {OUT}')


if __name__ == '__main__':
    main()
