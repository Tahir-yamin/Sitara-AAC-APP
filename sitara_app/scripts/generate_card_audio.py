"""
Generate female Urdu TTS audio files for all Sitara AAC cards using gTTS.
gTTS uses Google's TTS engine which has a natural female Pakistani/South Asian Urdu voice.

Run from the sitara_app directory:
    python scripts/generate_card_audio.py
"""
from gtts import gTTS
import os

# Output directory
OUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')
os.makedirs(OUT_DIR, exist_ok=True)

# All card words: (filename_without_ext, urdu_text, language)
CARDS = [
    # ANIMALS
    ('billi',       'بلی',              'ur'),
    ('kutta',       'کتا',              'ur'),
    ('parinda',     'پرندہ',            'ur'),
    ('machli',      'مچھلی',            'ur'),
    ('gaaye',       'گائے',             'ur'),
    ('ghoora',      'گھوڑا',            'ur'),
    ('haathi',      'ہاتھی',            'ur'),
    ('khargosh',    'خرگوش',            'ur'),
    ('titli',       'تتلی',             'ur'),
    ('sher',        'شیر',              'ur'),
    # FOOD
    ('aam',         'آم',               'ur'),
    ('roti',        'روٹی',             'ur'),
    ('chawal',      'چاول',             'ur'),
    ('paani',       'پانی',             'ur'),
    ('saib',        'سیب',              'ur'),
    ('kela',        'کیلا',             'ur'),
    ('doodh',       'دودھ',             'ur'),
    ('anda',        'انڈہ',             'ur'),
    ('double_roti', 'ڈبل روٹی',         'ur'),
    ('malta',       'مالٹا',            'ur'),
    # FAMILY
    ('ammi',        'امی',              'ur'),
    ('abu',         'ابو',              'ur'),
    ('dadi',        'دادی',             'ur'),
    ('bhai',        'بھائی',            'ur'),
    ('behan',       'بہن',              'ur'),
    ('dada',        'دادا',             'ur'),
    ('bachcha',     'بچہ',              'ur'),
    # EMOTIONS
    ('khush',       'خوش',              'ur'),
    ('udaas',       'اداس',             'ur'),
    ('bhooka',      'بھوکا',            'ur'),
    ('gussa',       'غصہ',              'ur'),
    ('dara',        'ڈرا ہوا',          'ur'),
    ('thaka',       'تھکا ہوا',         'ur'),
    # DAILY ROUTINES
    ('sona',        'سونا',             'ur'),
    ('khaana',      'کھانا',            'ur'),
    ('nahana',      'نہانا',            'ur'),
    ('khelna',      'کھیلنا',           'ur'),
    ('chalna',      'چلنا',             'ur'),
    ('parhna',      'پڑھنا',            'ur'),
    ('daant',       'دانت صاف کرنا',   'ur'),
    ('namaz',       'نماز',             'ur'),
    # TRANSPORT
    ('gaadi',       'گاڑی',             'ur'),
    ('bus',         'بس',               'ur'),
    ('cycle',       'سائیکل',           'ur'),
    ('hawai_jahaz', 'ہوائی جہاز',       'ur'),
    ('kashti',      'کشتی',             'ur'),
    ('motor_cycle', 'موٹر سائیکل',      'ur'),
]

def generate():
    ok, skip, fail = 0, 0, 0
    for filename, text, lang in CARDS:
        path = os.path.join(OUT_DIR, f'{filename}.mp3')
        if os.path.exists(path):
            print(f'  SKIP  {filename}.mp3 (already exists)')
            skip += 1
            continue
        try:
            tts = gTTS(text=text, lang=lang, slow=False)
            tts.save(path)
            print(f'  OK    {filename}.mp3')
            ok += 1
        except Exception as e:
            print(f'  FAIL  {filename}.mp3  =>  {e}')
            fail += 1

    print(f'\nDone: {ok} generated, {skip} skipped, {fail} failed.')
    print(f'Audio files saved to: {os.path.abspath(OUT_DIR)}')

if __name__ == '__main__':
    generate()
