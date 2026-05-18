"""
generate_audio.py — Regenerate bad-accent Urdu MP3 audio assets using
Google Cloud Text-to-Speech REST API with the ur-PK-Wavenet-A (female) voice.

Usage:
    python generate_audio.py

Requirements:
    pip install requests python-dotenv

Env variable (or set GOOGLE_API_KEY directly below):
    GOOGLE_API_KEY=your_key_here  (also works from adk_backend/.env)

Audio files regenerated (10 files with incorrect Urdu accent / poor energy):
    behan.mp3      — بہن    (sister)
    dara.mp3       — ڈرا ہوا (scared)
    doodh.mp3      — دودھ   (milk)
    kashti.mp3     — کشتی   (boat)
    mehnat.mp3     — محنت   (hard work — tryAgain phrase)
    nahana.mp3     — نہانا  (bath)
    titli.mp3      — تتلی   (butterfly)
    bohat_acha.mp3 — بہت اچھا (very good — praise)
    shabash.mp3    — شاباش  (well done — praise, also used as praise_0)
    praise_2.mp3   — زبردست (fantastic — praise)
"""

import os
import sys
import json
import base64
import requests

# ── Configuration ────────────────────────────────────────────────────────────

# Load from environment or .env (look up two levels for adk_backend/.env)
API_KEY = os.environ.get('GOOGLE_API_KEY', '')
if not API_KEY:
    # Try loading from adk_backend/.env
    dotenv_path = os.path.join(os.path.dirname(__file__), '..', '..', '..', 'adk_backend', '.env')
    if os.path.exists(dotenv_path):
        with open(dotenv_path) as f:
            for line in f:
                line = line.strip()
                if line.startswith('GOOGLE_API_KEY='):
                    API_KEY = line.split('=', 1)[1].strip().strip('"').strip("'")
                    break

if not API_KEY:
    print("ERROR: GOOGLE_API_KEY not found. Set it as an environment variable or in adk_backend/.env")
    sys.exit(1)

TTS_ENDPOINT = f'https://texttospeech.googleapis.com/v1/text:synthesize?key={API_KEY}'

# Female Pakistani Urdu voice — Google WaveNet quality
VOICE_CONFIG = {
    'languageCode': 'ur-PK',
    'name': 'ur-PK-Wavenet-A',   # Female WaveNet voice
    'ssmlGender': 'FEMALE',
}

# Fallback if WaveNet-A isn't available (Standard female is still good quality)
VOICE_CONFIG_FALLBACK = {
    'languageCode': 'ur-PK',
    'name': 'ur-PK-Standard-A',
    'ssmlGender': 'FEMALE',
}

AUDIO_CONFIG = {
    'audioEncoding': 'MP3',
    'speakingRate': 0.85,   # Slightly slower — clear for children
    'pitch': 2.0,           # Slightly higher — warm female Pakistani tone
    'volumeGainDb': 2.0,    # Slightly louder for tablet/phone speakers
}

# ── Files to regenerate ──────────────────────────────────────────────────────
# Format: (filename, urdu_text, ssml_wrapping)
#   ssml=True  → wrap in <speak> tags for better prosody
#   ssml=False → plain text synthesis
FILES = [
    # Card names (spoken slowly and clearly)
    ('behan.mp3',      'بہن',           False),
    ('dara.mp3',       'ڈرا ہوا',       False),
    ('doodh.mp3',      'دودھ',          False),
    ('kashti.mp3',     'کشتی',          False),
    ('nahana.mp3',     'نہانا',         False),
    ('titli.mp3',      'تتلی',          False),
    # Praise phrases (more energetic — use SSML for emphasis and break)
    ('bohat_acha.mp3', 'بہت اچھا!',     True),
    ('shabash.mp3',    'شاباش!',        True),
    ('praise_2.mp3',   'زبردست!',       True),
    # Wrong-answer encouragement (warm, short, high-energy)
    ('mehnat.mp3',     'واہ! پھر سے!', True),
]

# SSML templates — add emphasis and short pauses for energy
def _make_ssml(text: str, is_praise: bool) -> str:
    if is_praise:
        # Enthusiastic emphasis with slight speed-up
        return (
            '<speak>'
            f'<prosody rate="fast" pitch="+4st"><emphasis level="strong">{text}</emphasis></prosody>'
            '</speak>'
        )
    else:
        # Normal clear word pronunciation
        return f'<speak>{text}</speak>'


# ── Main ─────────────────────────────────────────────────────────────────────

def synthesize(text: str, use_ssml: bool, is_praise: bool, out_path: str) -> bool:
    """Call Google TTS REST API and save MP3 to out_path. Returns True on success."""
    if use_ssml:
        input_payload = {'ssml': _make_ssml(text, is_praise)}
    else:
        input_payload = {'text': text}

    payload = {
        'input': input_payload,
        'voice': VOICE_CONFIG,
        'audioConfig': AUDIO_CONFIG,
    }

    response = requests.post(TTS_ENDPOINT, json=payload, timeout=15)

    # If WaveNet-A fails (quota or not available), fall back to Standard-A
    if response.status_code != 200:
        print(f'  WaveNet-A failed ({response.status_code}), trying Standard-A fallback...')
        payload['voice'] = VOICE_CONFIG_FALLBACK
        response = requests.post(TTS_ENDPOINT, json=payload, timeout=15)

    if response.status_code != 200:
        print(f'  ERROR: {response.status_code} — {response.text[:200]}')
        return False

    data = response.json()
    audio_b64 = data.get('audioContent', '')
    if not audio_b64:
        print('  ERROR: No audioContent in response')
        return False

    audio_bytes = base64.b64decode(audio_b64)
    with open(out_path, 'wb') as f:
        f.write(audio_bytes)

    size_kb = len(audio_bytes) / 1024
    print(f'  Saved {os.path.basename(out_path)} ({size_kb:.1f} KB)')
    return True


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))

    print('=' * 60)
    print('Sitara Audio Regeneration — Google Cloud TTS (ur-PK Female)')
    print('Voice: ur-PK-Wavenet-A (Female WaveNet)')
    print('=' * 60)

    success_count = 0
    fail_count = 0

    for filename, urdu_text, use_ssml in FILES:
        out_path = os.path.join(script_dir, filename)
        # Back up old file
        backup_path = out_path + '.bak'
        if os.path.exists(out_path) and not os.path.exists(backup_path):
            os.rename(out_path, backup_path)
            print(f'\n[{filename}] "{urdu_text}"')
            print(f'  Backed up original → {os.path.basename(backup_path)}')
        else:
            print(f'\n[{filename}] "{urdu_text}"')

        is_praise = use_ssml and filename not in ('behan.mp3', 'dara.mp3', 'doodh.mp3',
                                                    'kashti.mp3', 'nahana.mp3', 'titli.mp3')
        ok = synthesize(urdu_text, use_ssml, is_praise, out_path)

        if ok:
            success_count += 1
        else:
            fail_count += 1
            # Restore backup on failure
            if os.path.exists(backup_path):
                os.rename(backup_path, out_path)
                print(f'  Restored original from backup.')

    print('\n' + '=' * 60)
    print(f'Done. Success: {success_count}  Failed: {fail_count}')
    if fail_count > 0:
        print('Check your GOOGLE_API_KEY and ensure Cloud TTS API is enabled.')
        print('Enable at: https://console.cloud.google.com/apis/library/texttospeech.googleapis.com')
    print('=' * 60)


if __name__ == '__main__':
    main()
