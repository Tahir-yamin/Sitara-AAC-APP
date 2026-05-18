"""
generate_audio.py — Regenerate ALL Sitara audio assets using
Google Cloud Text-to-Speech with ur-PK-Wavenet-A (female Pakistani voice).

SETUP (one-time, free):
  1. Go to: https://console.cloud.google.com
  2. Create or select a project
  3. Enable "Cloud Text-to-Speech API" at:
       https://console.cloud.google.com/apis/library/texttospeech.googleapis.com
  4. Go to: APIs & Services → Credentials → + CREATE CREDENTIALS → API Key
  5. Copy the key into adk_backend/.env as:  GOOGLE_API_KEY=your_key_here

FREE TIER: 1 million characters/month for WaveNet voices.
This entire script uses ~2,000 characters total — completely free.

Usage:
    cd sitara_app/assets/audio
    python generate_audio.py

Voice: ur-PK-Wavenet-A (female, Pakistani Urdu, WaveNet quality)
Fallback: ur-PK-Standard-A (female, Standard quality) if WaveNet quota exhausted
"""

import os
import sys
import base64
import requests

# ── Load API key ──────────────────────────────────────────────────────────────
API_KEY = os.environ.get('GOOGLE_API_KEY', '')
if not API_KEY:
    dotenv_path = os.path.join(os.path.dirname(__file__), '..', '..', '..', 'adk_backend', '.env')
    if os.path.exists(dotenv_path):
        with open(dotenv_path) as f:
            for line in f:
                line = line.strip()
                if line.startswith('GOOGLE_API_KEY='):
                    API_KEY = line.split('=', 1)[1].strip().strip('"').strip("'")
                    break

if not API_KEY:
    print('ERROR: GOOGLE_API_KEY not found.')
    print('Set it in adk_backend/.env  or  export GOOGLE_API_KEY=your_key_here')
    sys.exit(1)

TTS_URL = f'https://texttospeech.googleapis.com/v1/text:synthesize?key={API_KEY}'

# ── Voice ─────────────────────────────────────────────────────────────────────
# Google does not offer ur-PK voices. ur-IN = Urdu (India) — same script,
# same language, fully natural for Pakistani children.
# Chirp3-HD is Google's newest highest-quality neural voice.
# Fallback: ur-IN-Wavenet-A (proven WaveNet female).
VOICE = {'languageCode': 'ur-IN', 'name': 'ur-IN-Chirp3-HD-Kore', 'ssmlGender': 'FEMALE'}
VOICE_FALLBACK = {'languageCode': 'ur-IN', 'name': 'ur-IN-Wavenet-A', 'ssmlGender': 'FEMALE'}

# ── 5 SSML profiles for natural voice variation ───────────────────────────────
#
#  CARD     — slow, clear, gentle. Child hears the word once, clearly.
#  GOOD     — tier-1 praise (streak 1-2). Warm and encouraging.
#  GREAT    — tier-2 praise (streak 3-5). Noticeably more excited.
#  AMAZING  — tier-3 praise (streak 6+). Maximum energy, feel-good.
#  GENTLE   — wrong answer. Soft, reassuring — never demoralising.

def ssml_card(text):
    return (
        '<speak>'
        '<prosody rate="slow" pitch="+1st">'
        f'{text}'
        '</prosody>'
        '</speak>'
    )

def ssml_good(text):
    return (
        '<speak>'
        '<prosody rate="medium" pitch="+2st">'
        f'<emphasis level="moderate">{text}</emphasis>'
        '</prosody>'
        '</speak>'
    )

def ssml_great(text):
    return (
        '<speak>'
        '<prosody rate="medium" pitch="+3st">'
        f'<emphasis level="strong">{text}</emphasis>'
        '</prosody>'
        '</speak>'
    )

def ssml_amazing(text):
    return (
        '<speak>'
        '<prosody rate="fast" pitch="+5st">'
        f'<emphasis level="strong">{text}</emphasis>'
        '<break time="100ms"/>'
        '</prosody>'
        '</speak>'
    )

def ssml_gentle(text):
    # Wrong answer — warm pause after "Oho", then soft reassurance
    return (
        '<speak>'
        '<prosody rate="medium" pitch="+2st">'
        f'<emphasis level="moderate">{text}</emphasis>'
        '</prosody>'
        '</speak>'
    )

AUDIO_CONFIG = {
    'audioEncoding': 'MP3',
    'speakingRate': 1.0,   # overridden by SSML prosody tags
    'pitch': 0.0,          # overridden by SSML prosody tags
    'volumeGainDb': 2.0,   # slight boost for tablet/phone speakers
}

# ── Full asset list ───────────────────────────────────────────────────────────
# (filename, urdu_text, ssml_builder_function)

FILES = [
    # ── CARD NAMES: Animals (spoken slowly and clearly) ──────────────────────
    ('billi.mp3',        'بلی',               ssml_card),
    ('kutta.mp3',        'کتا',               ssml_card),
    ('parinda.mp3',      'پرندہ',             ssml_card),
    ('machli.mp3',       'مچھلی',             ssml_card),
    ('gaaye.mp3',        'گائے',              ssml_card),
    ('ghoora.mp3',       'گھوڑا',             ssml_card),
    ('haathi.mp3',       'ہاتھی',             ssml_card),
    ('khargosh.mp3',     'خرگوش',             ssml_card),
    ('titli.mp3',        'تتلی',              ssml_card),
    ('sher.mp3',         'شیر',               ssml_card),

    # ── CARD NAMES: Food ──────────────────────────────────────────────────────
    ('aam.mp3',          'آم',                ssml_card),
    ('roti.mp3',         'روٹی',              ssml_card),
    ('chawal.mp3',       'چاول',              ssml_card),
    ('paani.mp3',        'پانی',              ssml_card),
    ('saib.mp3',         'سیب',               ssml_card),
    ('kela.mp3',         'کیلا',              ssml_card),
    ('doodh.mp3',        'دودھ',              ssml_card),
    ('anda.mp3',         'انڈہ',              ssml_card),
    ('double_roti.mp3',  'ڈبل روٹی',          ssml_card),
    ('malta.mp3',        'مالٹا',             ssml_card),

    # ── CARD NAMES: Family ────────────────────────────────────────────────────
    ('ammi.mp3',         'امی',               ssml_card),
    ('abu.mp3',          'ابو',               ssml_card),
    ('dadi.mp3',         'دادی',              ssml_card),
    ('bhai.mp3',         'بھائی',             ssml_card),
    ('behan.mp3',        'بہن',               ssml_card),
    ('dada.mp3',         'دادا',              ssml_card),
    ('bachcha.mp3',      'بچہ',               ssml_card),

    # ── CARD NAMES: Emotions ──────────────────────────────────────────────────
    ('khush.mp3',        'خوش',               ssml_card),
    ('udaas.mp3',        'اداس',              ssml_card),
    ('bhooka.mp3',       'بھوکا',             ssml_card),
    ('gussa.mp3',        'غصہ',               ssml_card),
    ('dara.mp3',         'ڈرا ہوا',           ssml_card),
    ('thaka.mp3',        'تھکا ہوا',          ssml_card),

    # ── CARD NAMES: Daily Routines ────────────────────────────────────────────
    ('sona.mp3',         'سونا',              ssml_card),
    ('khaana.mp3',       'کھانا',             ssml_card),
    ('nahana.mp3',       'نہانا',             ssml_card),
    ('khelna.mp3',       'کھیلنا',            ssml_card),
    ('chalna.mp3',       'چلنا',              ssml_card),
    ('parhna.mp3',       'پڑھنا',             ssml_card),
    ('daant.mp3',        'دانت صاف کرنا',     ssml_card),
    ('namaz.mp3',        'نماز',              ssml_card),

    # ── CARD NAMES: Transport ─────────────────────────────────────────────────
    ('gaadi.mp3',        'گاڑی',              ssml_card),
    ('bus.mp3',          'بس',                ssml_card),
    ('cycle.mp3',        'سائیکل',            ssml_card),
    ('hawai_jahaz.mp3',  'ہوائی جہاز',        ssml_card),
    ('kashti.mp3',       'کشتی',              ssml_card),
    ('motor_cycle.mp3',  'موٹر سائیکل',       ssml_card),

    # ── WRONG ANSWER: Warm, gentle, never demoralising ────────────────────────
    ('koi_baat_nai.mp3', 'اوہو! کوئی بات نہیں!', ssml_gentle),

    # ── PRAISE: Tier 1 — streak 1-2 (warm encouragement) ─────────────────────
    ('shabash.mp3',      'شاباش!',            ssml_good),
    ('bohat_acha.mp3',   'بہت اچھا!',         ssml_good),
    ('praise_0.mp3',     'شاباش!',            ssml_good),
    ('praise_1.mp3',     'بلکل سہی!',         ssml_good),
    ('praise_2.mp3',     'زبردست!',           ssml_good),
    ('praise_3.mp3',     'واہ! سہی جواب!',    ssml_good),
    ('praise_4.mp3',     'کمال ہے!',          ssml_good),

    # ── PRAISE: Tier 2 — streak 3-5 (excited) ────────────────────────────────
    ('zabardast.mp3',    'زبردست!',           ssml_great),
    ('praise_5.mp3',     'واہ واہ! کمال!',    ssml_great),
    ('praise_6.mp3',     'بہت خوب!',          ssml_great),
    ('praise_7.mp3',     'زبردست!',           ssml_great),
    ('praise_8.mp3',     'سپر! ایک اور!',     ssml_great),
    ('praise_9.mp3',     'شاندار!',           ssml_great),

    # ── PRAISE: Tier 3 — streak 6+ (maximum energy) ──────────────────────────
    ('praise_10.mp3',    'چیمپئن! ماشاءاللہ!', ssml_amazing),
    ('praise_11.mp3',    'شیر بچہ! واہ!',     ssml_amazing),
    ('praise_12.mp3',    'سپر! بہت اچھا!',    ssml_amazing),
    ('praise_13.mp3',    'ماشاءاللہ! واہ!',   ssml_amazing),
    ('praise_14.mp3',    'سپر ہیرو!',         ssml_amazing),
]


# ── Synthesize ────────────────────────────────────────────────────────────────

def synthesize(urdu_text, ssml_fn, out_path):
    """Call Google TTS API and save MP3. Returns True on success."""
    ssml = ssml_fn(urdu_text)
    payload = {
        'input': {'ssml': ssml},
        'voice': VOICE,
        'audioConfig': AUDIO_CONFIG,
    }
    resp = requests.post(TTS_URL, json=payload, timeout=15)

    if resp.status_code != 200:
        print(f'  WaveNet failed ({resp.status_code}) — trying Standard fallback...')
        payload['voice'] = VOICE_FALLBACK
        resp = requests.post(TTS_URL, json=payload, timeout=15)

    if resp.status_code != 200:
        print(f'  ERROR {resp.status_code}: {resp.text[:200]}')
        return False

    audio_b64 = resp.json().get('audioContent', '')
    if not audio_b64:
        print('  ERROR: no audioContent in response')
        return False

    audio_bytes = base64.b64decode(audio_b64)
    with open(out_path, 'wb') as f:
        f.write(audio_bytes)
    print(f'  OK  {len(audio_bytes):6d} bytes  →  {os.path.basename(out_path)}')
    return True


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    total = len(FILES)

    print('=' * 65)
    print('Sitara — Full Audio Regeneration')
    print('Voice : ur-PK-Wavenet-A  (female Pakistani WaveNet)')
    print('Files : {:d}  (card names + praise + wrong-answer)'.format(total))
    print('Cost  : ~2,000 chars  ->  FREE (1M WaveNet chars/month)')
    print('=' * 65)

    ok_count = 0
    fail_count = 0

    categories = {
        'billi': 'Animals', 'aam': 'Food', 'ammi': 'Family',
        'khush': 'Emotions', 'sona': 'Daily Routines', 'gaadi': 'Transport',
        'koi_baat': 'Wrong Answer', 'shabash': 'Praise Tier 1',
        'zabardast': 'Praise Tier 2', 'praise_10': 'Praise Tier 3',
    }

    current_section = ''
    for filename, urdu_text, ssml_fn in FILES:
        # Print section header when category changes
        stem = filename.replace('.mp3', '')
        for key, label in categories.items():
            if stem.startswith(key) and label != current_section:
                current_section = label
                print(f'\n── {label} ───')
                break

        out_path = os.path.join(script_dir, filename)

        # Back up existing file
        if os.path.exists(out_path):
            bak = out_path + '.bak'
            if not os.path.exists(bak):
                os.rename(out_path, bak)

        ok = synthesize(urdu_text, ssml_fn, out_path)
        if ok:
            ok_count += 1
        else:
            fail_count += 1
            # Restore backup on failure
            bak = out_path + '.bak'
            if os.path.exists(bak):
                os.rename(bak, out_path)
                print(f'  Restored original backup.')

    # Clean up .bak files if all succeeded
    if fail_count == 0:
        for filename, _, _ in FILES:
            bak = os.path.join(script_dir, filename + '.bak')
            if os.path.exists(bak):
                os.remove(bak)
        print('\n✓ Backup files cleaned up.')

    print('\n' + '=' * 65)
    print(f'Done.  Success: {ok_count}  /  Failed: {fail_count}  /  Total: {total}')
    if fail_count > 0:
        print('\nIf failures occurred:')
        print('  • Verify your API key is valid')
        print('  • Enable TTS API at: console.cloud.google.com/apis/library/texttospeech.googleapis.com')
        print('  • Check you have not exceeded quota (unlikely for this script size)')
    print('=' * 65)


if __name__ == '__main__':
    main()
