# Sitara — Google Cloud TTS Audio Generation Log

**Date:** 2026-05-19  
**Author:** Claude Code  
**Scope:** Full regeneration of all 59 audio assets (47 card names + 12 praise/feedback files)  
**API:** Google Cloud Text-to-Speech REST API v1  
**Endpoint:** `https://texttospeech.googleapis.com/v1/text:synthesize`  
**Script:** `sitara_app/assets/audio/generate_audio.py`

---

## 1. Why This Was Done

All original audio files were generated using **gTTS** (Google Translate TTS library) — a free but low-quality tool that:
- Used Hindi engine (`lang='hi'`) for some files and Urdu (`lang='ur'`) for others — inconsistent accent
- Produced neutral/male-sounding voice in many cases
- Had no SSML support for controlling pitch, rate, or emphasis
- Gave incorrect pronunciation on ambiguous Urdu homographs (e.g. کشتی = boat vs. wrestling)

**Goal:** Replace all files with Google Cloud TTS `ur-IN-Chirp3-HD` (female, neural quality) with 5 SSML profiles for natural voice variation.

---

## 2. Google Cloud TTS Setup (Free Tier)

### Steps to Enable
1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create or select a project
3. Search **"Cloud Text-to-Speech API"** → Enable
4. Go to **APIs & Services → Credentials → + CREATE CREDENTIALS → API Key**
5. Copy the key into `adk_backend/.env` as `GOOGLE_API_KEY=your_key_here`

### Free Tier Limits
| Voice Type | Free Monthly Characters |
|---|---|
| Standard voices | 4,000,000 characters |
| WaveNet voices | 1,000,000 characters |
| Neural2 / Chirp3-HD voices | 1,000,000 characters |

**Total characters used for all 59 files: ~2,000** — negligible, completely free.

### Security
- API key stored ONLY in `adk_backend/.env` (listed in `.gitignore` — never committed)
- Key cleared from `.env` immediately after each run
- Key never written to any tracked file or log

---

## 3. Critical Discovery: No ur-PK Voices Exist

### Error (First Run)
```
Voice 'ur-PK-Wavenet-A' does not exist. Is it misspelled?
Voice 'ur-PK-Standard-A' does not exist. Is it misspelled?
All 66 files failed.
```

### Root Cause
Google Cloud TTS does **not** offer any `ur-PK` (Urdu Pakistan) locale voices. The entire `ur-PK` locale is absent from their catalog.

### Available Urdu Voices (ur-IN only — 34 voices)
Queried via `GET https://texttospeech.googleapis.com/v1/voices?languageCode=ur-IN&key={key}`

| Voice Name | Gender | Type |
|---|---|---|
| `ur-IN-Chirp3-HD-Achernar` | FEMALE | Chirp3-HD (newest, highest quality) |
| `ur-IN-Chirp3-HD-Aoede` | FEMALE | Chirp3-HD |
| `ur-IN-Chirp3-HD-Autonoe` | FEMALE | Chirp3-HD |
| `ur-IN-Chirp3-HD-Callirrhoe` | FEMALE | Chirp3-HD |
| `ur-IN-Chirp3-HD-Despina` | FEMALE | Chirp3-HD |
| `ur-IN-Chirp3-HD-Erinome` | FEMALE | Chirp3-HD |
| `ur-IN-Chirp3-HD-Gacrux` | FEMALE | Chirp3-HD |
| `ur-IN-Chirp3-HD-Kore` | FEMALE | Chirp3-HD |
| `ur-IN-Chirp3-HD-Laomedeia` | FEMALE | Chirp3-HD |
| `ur-IN-Chirp3-HD-Leda` | FEMALE | Chirp3-HD |
| `ur-IN-Chirp3-HD-Pulcherrima` | FEMALE | Chirp3-HD |
| `ur-IN-Chirp3-HD-Sulafat` | FEMALE | Chirp3-HD |
| `ur-IN-Chirp3-HD-Vindemiatrix` | FEMALE | Chirp3-HD |
| `ur-IN-Chirp3-HD-Zephyr` | FEMALE | Chirp3-HD |
| `ur-IN-Chirp3-HD-Achird` | MALE | Chirp3-HD |
| *(+ 13 more male Chirp3-HD)* | MALE | Chirp3-HD |
| `ur-IN-Standard-A` | FEMALE | Standard |
| `ur-IN-Standard-B` | MALE | Standard |
| `ur-IN-Wavenet-A` | FEMALE | WaveNet |
| `ur-IN-Wavenet-B` | MALE | WaveNet |

### Resolution
Changed voice config from `ur-PK-Wavenet-A` to `ur-IN-Chirp3-HD-Kore` (primary) with `ur-IN-Wavenet-A` (fallback). `ur-IN` = Urdu India — same script, same language, fully natural for Pakistani children.

---

## 4. Errors Encountered

### Error 1 — UnicodeEncodeError (Windows cp1252)
**When:** First successful run attempt after fixing voice names  
**Error:**
```
UnicodeEncodeError: 'charmap' codec can't encode character '\u2192'
in position 22: character maps to <undefined>
```
**Cause:** Windows default terminal encoding is cp1252, which cannot render the `→` arrow character in the print statement.  
**Fix:** Replaced `→` with `->` in the print string. Added `-X utf8` Python flag to all run commands.

---

### Error 2 — Voice `ur-PK-Wavenet-A` does not exist (all 66 failures)
**Already documented in Section 3 above.**

---

### Error 3 — kashti.mp3 Wrong Pronunciation (homograph)
**When:** After first successful full generation  
**Symptom:** `kashti.mp3` pronounced as "kushthi" (کُشتی = wrestling) instead of "kashti" (کَشتی = boat)  
**Root Cause:** کشتی is an Urdu homograph — same spelling, two meanings, two pronunciations:
- کَشتی (fatha on kaf, sukun on shin) = boat (kashti)
- کُشتی (damma on kaf) = wrestling (kushthi)

Without diacritical marks, the TTS engine guessed the wrong reading.

**Fix Attempts:**
| Attempt | Voice | Text Used | Result |
|---|---|---|---|
| 1 | `ur-IN-Wavenet-A` | `کَشْتِی` (with harakat) | Still wrong |
| 2 | `ur-IN-Chirp3-HD-Zephyr` | `کَشْتِی` | ✅ Correct — KEPT |
| 3 | `ur-IN-Chirp3-HD-Sulafat` | `کَشْتِی` | OK but not as clear |
| 4 | `ur-IN-Wavenet-A` | `کَشْتِی` | ❌ Rejected by user |

**Final file:** `kashti.mp3` — Voice: `ur-IN-Chirp3-HD-Zephyr`, Text: `کَشْتِی`

---

### Error 4 — nahana.mp3 Poor Pronunciation
**When:** After first successful full generation  
**Symptom:** Voice quality not natural for the word نہانا (to bathe)  
**Fix Attempts:**
| Attempt | Voice | Text Used | Result |
|---|---|---|---|
| 1 | `ur-IN-Wavenet-A` | `نَہانا` | Poor quality — rejected by user |
| 2 | `ur-IN-Chirp3-HD-Zephyr` | `نَہانا` | ❌ Rejected by user |
| 3 | `ur-IN-Chirp3-HD-Gacrux` | `نَہانا` | ✅ Correct — KEPT |
| 4 | `ur-IN-Wavenet-A` | `نَہانا` | ❌ Rejected |

**Final file:** `nahana.mp3` — Voice: `ur-IN-Chirp3-HD-Gacrux`, Text: `نَہانا`

---

### Error 5 — praise_11.mp3 Multiple Regeneration Rounds

**Target phrase:** شیر بچہ! واہ! (Sher Bacha! Wah! — "Brave one! Wow!")  
**User requirement:** Slow, excited, adult female voice 25–30 years old. NOT child-sounding.

| Round | Voice | SSML Settings | Result |
|---|---|---|---|
| Round 1 | `ur-IN-Wavenet-A` | `rate="medium" pitch="+3st"` | ❌ "Make it better" |
| Round 2 | `ur-IN-Chirp3-HD-Leda` | `rate="fast" pitch="+5st"` | ❌ Child voice |
| Round 3 opt1 | `ur-IN-Chirp3-HD-Gacrux` | `rate="slow" pitch="+3st" emphasis="strong"` | ✅ KEPT |
| Round 3 opt2 | `ur-IN-Chirp3-HD-Laomedeia` | same | ❌ Rejected |
| Round 3 opt3 | `ur-IN-Chirp3-HD-Aoede` | same | ❌ Rejected |
| Round 3 opt4 | `ur-IN-Chirp3-HD-Zephyr` | same | ❌ Rejected |

**Key SSML insight:** `pitch="+5st" rate="fast"` sounds childlike. `pitch="+3st" rate="slow" emphasis="strong"` gives adult-female excited delivery.

**Final file:** `praise_11.mp3` — Voice: `ur-IN-Chirp3-HD-Gacrux`, SSML: slow + strong emphasis + pitch +3st  
**Urdu text used:** `شَیْر بَچَّہ! واہ!` (with explicit diacritical marks to force "sher bacha" pronunciation)

---

### Error 6 — mehnat.mp3 Referenced But Missing
**When:** Sync audit after all regenerations  
**Error:**
```
MISSING: mehnat.mp3
  Referenced in: services/tts_service.dart:45
                 services/tts_service.dart:56
                 services/tts_service.dart:307
```
**Root Cause:** `mehnat.mp3` was the original gTTS wrong-answer file. It was replaced by `koi_baat_nai.mp3` in `phrase_pool.dart`, but `tts_service.dart` still had 3 hardcoded references to `mehnat.mp3` — including an explicit `|| phrase.audioAsset == 'audio/mehnat.mp3'` bypass check on line 307.  
**Fix:** Cleared `_badAudioAssets` blacklist (all files now good quality), removed the explicit `mehnat.mp3` check from `speakPraise()`.

---

### Error 7 — `cross:` Parameter Undefined in PDF Generation
**When:** Post-sync `flutter analyze`  
**Error:**
```
error - The named parameter 'cross' isn't defined
  lib\screens\parent_dashboard.dart:1578:17
  lib\screens\parent_dashboard.dart:1624:11
  lib\screens\parent_dashboard.dart:1662:17
  lib\screens\parent_dashboard.dart:1820:11
```
**Root Cause:** The `pdf` package's `pw.Row` widget uses `crossAxisAlignment`, not `cross` (a shorthand that doesn't exist in this API version).  
**Fix:** Replaced all 4 occurrences: `cross:` → `crossAxisAlignment:`

---

### Error 8 — `physicalTaps` Unused Local Variable Warning
**When:** Post-sync `flutter analyze`  
**Error:**
```
warning - The value of the local variable 'physicalTaps' isn't used
  lib\services\antigravity_service.dart:354:12
```
**Root Cause:** `physicalTaps` was declared and assigned in all 3 branches but never interpolated into the report string. Dead code.  
**Fix:** Removed the declaration and all 3 assignments.

---

### Error 9 — Orphaned Audio Files After Pool Restructure
**When:** Post-sync audit  
**Orphaned files found:**
| File | Reason Orphaned |
|---|---|
| `praise_0.mp3` | Duplicate of `shabash.mp3` — pool uses named constant `shabash` instead |
| `praise_2.mp3` | Duplicate of `zabardast.mp3` — pool uses named constant `zabardast` instead |
| `praise_7.mp3` | Generated but never added to `_great` tier (also duplicate of `zabardast`) |

**Fix:** All 3 deleted from disk.

---

## 5. Praise Files Removed by User

After hearing on device, user requested 4 praise files be permanently removed from the app:

| File | Pool Tier | Urdu Text | Reason |
|---|---|---|---|
| `praise_8.mp3` | `_great` (streak ≥ 3) | سپر! ایک اور! | User removed |
| `praise_10.mp3` | `_amazing` (streak ≥ 6) | چیمپئن! ماشاءاللہ! | User removed |
| `praise_12.mp3` | `_amazing` (streak ≥ 6) | سپر! بہت اچھا! | User removed |
| `praise_14.mp3` | `_amazing` (streak ≥ 6) | سپر ہیرو! | User removed |

`phrase_pool.dart` updated accordingly:
- `_great` tier reduced from 5 → 4 entries
- `_amazing` tier reduced from 5 → 2 entries (praise_11 + praise_13)

---

## 6. Wrong-Answer Audio: mehnat → koi_baat_nai

**User requirement:** Warm, comforting "Oho! Koi baat nahi!" — NOT demoralising  
**Old file:** `mehnat.mp3` — gTTS Hindi, text: "Mehnat karo" (Try harder) — wrong tone  

| Version | Voice | Text | Result |
|---|---|---|---|
| v1 (gTTS) | Hindi engine | Mehnat karo, aap kar saktay hain | ❌ Wrong phrase, wrong voice |
| v2 (gTTS ur) | Urdu engine | واہ! پھر سے! | ❌ Still used gTTS |
| v3 (Cloud TTS) | `ur-IN-Chirp3-HD-Kore` | اوہو! کوئی بات نہیں! | ✅ Final |

**SSML profile:** `rate="medium" pitch="+2st" emphasis="moderate"` — warm and gentle, not fast/emphatic  
**File:** `koi_baat_nai.mp3` — referenced by `PhrasePool.tryAgain`

---

## 7. SSML Profiles Used

Five distinct SSML prosody profiles for natural voice variation across file types:

```xml
<!-- CARD NAMES — slow and clear for children to follow -->
<speak>
  <prosody rate="slow" pitch="+1st">
    {word}
  </prosody>
</speak>

<!-- WRONG ANSWER — warm, gentle, comforting -->
<speak>
  <prosody rate="medium" pitch="+2st">
    <emphasis level="moderate">{text}</emphasis>
  </prosody>
</speak>

<!-- PRAISE TIER 1 (streak 1-2) — warm and encouraging -->
<speak>
  <prosody rate="medium" pitch="+2st">
    <emphasis level="moderate">{text}</emphasis>
  </prosody>
</speak>

<!-- PRAISE TIER 2 (streak 3-5) — noticeably excited -->
<speak>
  <prosody rate="medium" pitch="+3st">
    <emphasis level="strong">{text}</emphasis>
  </prosody>
</speak>

<!-- PRAISE TIER 3 (streak 6+) — maximum energy -->
<speak>
  <prosody rate="fast" pitch="+5st">
    <emphasis level="strong">{text}</emphasis>
    <break time="100ms"/>
  </prosody>
</speak>
```

**Note for praise_11 specifically:** Uses `rate="slow" pitch="+3st"` — slow delivery but strong emphasis creates "excited but not rushed" effect, avoiding the child-voice problem caused by `pitch="+5st"`.

---

## 8. Final Voice Assignments Per File

| File Group | Voice Used | Notes |
|---|---|---|
| 44 card names (default) | `ur-IN-Chirp3-HD-Kore` | Main female voice, consistent accent |
| `kashti.mp3` | `ur-IN-Chirp3-HD-Zephyr` | Fixes homograph — forces boat pronunciation |
| `nahana.mp3` | `ur-IN-Chirp3-HD-Gacrux` | Clearer pronunciation than Kore for this word |
| `praise_11.mp3` | `ur-IN-Chirp3-HD-Gacrux` | Adult female excited tone — 3 rounds to get right |
| All other praise files | `ur-IN-Chirp3-HD-Kore` | Consistent with card names |
| `koi_baat_nai.mp3` | `ur-IN-Chirp3-HD-Kore` | Gentle wrong-answer feedback |

---

## 9. Code Changes Made in This Session

| File | Change |
|---|---|
| `lib/models/phrase_pool.dart` | `tryAgain` → `koi_baat_nai.mp3`, `'اوہو! کوئی بات نہیں!'`; removed 4 praise entries |
| `lib/services/tts_service.dart` | Cleared `_badAudioAssets` set (22 entries → empty); removed `mehnat.mp3` hardcoded bypass |
| `lib/screens/parent_dashboard.dart` | Fixed 4x `cross:` → `crossAxisAlignment:` in `pw.Row` |
| `lib/services/antigravity_service.dart` | Removed `physicalTaps` dead variable (4 lines) |
| `assets/audio/generate_audio.py` | Full rewrite — covers all 66 files, 5 SSML profiles, correct `ur-IN` voices |

---

## 10. Final Audio Inventory (59 files — 100% synced)

### Card Names (47 files)

| File | Urdu Text | Category |
|---|---|---|
| `aam.mp3` | آم | Food |
| `abu.mp3` | ابو | Family |
| `ammi.mp3` | امی | Family |
| `anda.mp3` | انڈہ | Food |
| `bachcha.mp3` | بچہ | Family |
| `behan.mp3` | بہن | Family |
| `bhai.mp3` | بھائی | Family |
| `bhooka.mp3` | بھوکا | Emotions |
| `billi.mp3` | بلی | Animals |
| `bus.mp3` | بس | Transport |
| `chalna.mp3` | چلنا | Daily Routines |
| `chawal.mp3` | چاول | Food |
| `cycle.mp3` | سائیکل | Transport |
| `daant.mp3` | دانت صاف کرنا | Daily Routines |
| `dada.mp3` | دادا | Family |
| `dadi.mp3` | دادی | Family |
| `dara.mp3` | ڈرا ہوا | Emotions |
| `doodh.mp3` | دودھ | Food |
| `double_roti.mp3` | ڈبل روٹی | Food |
| `gaadi.mp3` | گاڑی | Transport |
| `gaaye.mp3` | گائے | Animals |
| `ghoora.mp3` | گھوڑا | Animals |
| `gussa.mp3` | غصہ | Emotions |
| `haathi.mp3` | ہاتھی | Animals |
| `hawai_jahaz.mp3` | ہوائی جہاز | Transport |
| `kashti.mp3` | کَشْتِی *(with harakat)* | Transport |
| `kela.mp3` | کیلا | Food |
| `khaana.mp3` | کھانا | Daily Routines |
| `khargosh.mp3` | خرگوش | Animals |
| `khelna.mp3` | کھیلنا | Daily Routines |
| `khush.mp3` | خوش | Emotions |
| `kutta.mp3` | کتا | Animals |
| `machli.mp3` | مچھلی | Animals |
| `malta.mp3` | مالٹا | Food |
| `motor_cycle.mp3` | موٹر سائیکل | Transport |
| `nahana.mp3` | نَہانا *(with harakat)* | Daily Routines |
| `namaz.mp3` | نماز | Daily Routines |
| `paani.mp3` | پانی | Food |
| `parhna.mp3` | پڑھنا | Daily Routines |
| `parinda.mp3` | پرندہ | Animals |
| `roti.mp3` | روٹی | Food |
| `saib.mp3` | سیب | Food |
| `sher.mp3` | شیر | Animals |
| `sona.mp3` | سونا | Daily Routines |
| `thaka.mp3` | تھکا ہوا | Emotions |
| `titli.mp3` | تتلی | Animals |
| `udaas.mp3` | اداس | Emotions |

### Praise & Feedback (12 files)

| File | Urdu Text | Pool Tier | SSML Profile |
|---|---|---|---|
| `koi_baat_nai.mp3` | اوہو! کوئی بات نہیں! | Wrong answer | Gentle |
| `shabash.mp3` | شاباش! | Tier 1 (streak 1-2) | Good |
| `bohat_acha.mp3` | بہت اچھا! | Tier 1 | Good |
| `praise_1.mp3` | بلکل سہی! | Tier 1 | Good |
| `praise_3.mp3` | واہ! سہی جواب! | Tier 1 | Good |
| `praise_4.mp3` | کمال ہے! | Tier 1 | Good |
| `zabardast.mp3` | زبردست! | Tier 2 (streak 3-5) | Great |
| `praise_5.mp3` | واہ واہ! کمال! | Tier 2 | Great |
| `praise_6.mp3` | بہت خوب! | Tier 2 | Great |
| `praise_9.mp3` | شاندار! | Tier 2 | Great |
| `praise_11.mp3` | شَیْر بَچَّہ! واہ! | Tier 3 (streak 6+) | Amazing (slow) |
| `praise_13.mp3` | ماشاءاللہ! واہ! | Tier 3 | Amazing |

---

## 11. Sync Verification

Final audit result after all changes:

```
Matched  : 59  (every code reference has a file on disk)
Missing  : 0   (no broken references)
Orphan   : 0   (no unused files on disk)
```

```
flutter analyze:
  errors   : 0
  warnings : 0
  infos    : 3 (style hints only — non-blocking)
```

---

## 12. How to Regenerate (Future Reference)

If any file needs to be regenerated:

1. Add `GOOGLE_API_KEY=your_key` to `adk_backend/.env`
2. Run: `cd sitara_app/assets/audio && python -X utf8 generate_audio.py`
3. Clear the key: `echo "GOOGLE_API_KEY=your_key_here" > adk_backend/.env`

To add a new audio file:
1. Add an entry to `FILES` list in `generate_audio.py` with the correct SSML profile function
2. Add the `audioAsset` reference in `phrase_pool.dart` or `symbols_data.dart`
3. Run the script — new file will be auto-detected by Flutter (directory is declared as `assets/audio/` wildcard in `pubspec.yaml`)

---

*Document created 2026-05-19 by Claude Code*
