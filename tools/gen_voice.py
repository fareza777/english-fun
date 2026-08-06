"""Generate voice-over mp3s for every text in assets/voice/manifest.json
using the ElevenLabs API. The API key is read from ELEVENLABS_API_KEY and is
never written to disk. Re-runnable: skips files that already exist.

Voices:
  teach  -> Alice   (Clear, Engaging Educator)   words, sentences, questions
  story  -> Carla   (Children's Story Narrator)  story lines
  praise -> Jessica (Playful, Bright, Warm)      praise phrases
"""
import json
import os
import sys
import time
import urllib.request
import urllib.error

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(BASE, 'assets', 'voice', 'manifest_full.json')
OUT_DIR = os.path.join(BASE, 'assets', 'voice')

VOICES = {
    'teach': 'Xb7hH8MSUJpSbSDYk0k2',   # Alice
    'story': 'oJebhZNaPllxk6W0LSBA',   # Carla
    'praise': 'cgSgspJ2msm6clMCkdW9',  # Jessica
}
MODEL = 'eleven_turbo_v2_5'


def synth(key: str, voice_id: str, text: str, use_speed: bool = False) -> bytes:
    settings = {
        'stability': 0.55,
        'similarity_boost': 0.75,
        'style': 0.35,
        'use_speaker_boost': True,
    }
    if use_speed:
        settings['speed'] = 0.9  # slightly slower, clearer for kids
    body = json.dumps({
        'text': text,
        'model_id': MODEL,
        'voice_settings': settings,
    }).encode('utf-8')
    req = urllib.request.Request(
        f'https://api.elevenlabs.io/v1/text-to-speech/{voice_id}?output_format=mp3_44100_64',
        data=body,
        headers={
            'xi-api-key': key,
            'Content-Type': 'application/json',
            'Accept': 'audio/mpeg',
        },
        method='POST',
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        return resp.read()


def main() -> int:
    key = os.environ.get('ELEVENLABS_API_KEY', '').strip()
    if not key:
        print('ERROR: set ELEVENLABS_API_KEY')
        return 1
    with open(MANIFEST, encoding='utf-8') as f:
        items = json.load(f)['items']

    todo = [it for it in items
            if not os.path.exists(os.path.join(OUT_DIR, it['id'] + '.mp3'))]
    print(f'total={len(items)} todo={len(todo)}', flush=True)

    failures = []
    done = 0
    for it in todo:
        out = os.path.join(OUT_DIR, it['id'] + '.mp3')
        voice = VOICES.get(it['voice'], VOICES['teach'])
        ok = False
        for attempt in range(3):
            try:
                audio = synth(key, voice, it['text'], use_speed=False)
                with open(out, 'wb') as f:
                    f.write(audio)
                ok = True
                break
            except urllib.error.HTTPError as e:
                detail = e.read()[:200]
                print(f"HTTP {e.code} attempt {attempt + 1} for {it['text'][:40]!r}: {detail}", flush=True)
                if e.code == 401:
                    return 1
                time.sleep(2 * (attempt + 1))
            except Exception as e:  # noqa: BLE001
                print(f"ERR attempt {attempt + 1} for {it['text'][:40]!r}: {e}", flush=True)
                time.sleep(2 * (attempt + 1))
        if not ok:
            failures.append(it['text'])
        done += 1
        if done % 25 == 0:
            print(f'progress {done}/{len(todo)}', flush=True)
        time.sleep(0.25)

    if failures:
        with open(os.path.join(OUT_DIR, 'voice_failed.txt'), 'w', encoding='utf-8') as f:
            f.write('\n'.join(failures))
    print(f'DONE ok={len(todo) - len(failures)} failed={len(failures)}', flush=True)
    return 0 if not failures else 2


if __name__ == '__main__':
    sys.exit(main())
