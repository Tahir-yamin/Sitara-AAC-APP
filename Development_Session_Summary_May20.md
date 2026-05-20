# Sitara Development Session Summary — May 20, 2026

**Submission Deadline: TODAY — May 20, 2026**
This document covers the final pre-submission testing and debugging session: physical device testing on a real Android phone, finding and resolving critical visual bugs and backend quota issues, culminating in a fully live T1:Gemini agentic stack.

---

## 🚀 Summary of Accomplishments

### 1. Fixed "Ublock Ublock Ublock..." Flood in AI Trace Panel
**Symptom:** The SOVEREIGN TRACE panel and AI Adaptations section on the physical Android device displayed `Ublock Ublock Ublock Ublock Ublock...` flooding the screen, making the agent trace unreadable.

**Root Cause (Deep Investigation):**
- Gemini and OpenRouter LLMs occasionally emit Unicode Mathematical Bold/Italic characters (Unicode block U+1D400–U+1D7FF) in their reasoning output for emphasis (e.g., 𝗯𝗼𝗹𝗱 text).
- Each such character is encoded as a UTF-16 surrogate pair (two 16-bit code units: `0xD835` + `0xDC00–0xDFFF`).
- Flutter's `Courier` font on Android does not include these codepoints. When the text renderer encounters the high surrogate (`0xD835`), it displays `U`; the low surrogate maps to the glyph `block`.
- Result: every bold/italic Unicode character → rendered as the two-character sequence **"U" + "block"** → thousands of these flood the panel.

**Fix (`adk_backend/agent.py` — commit `e0dcd57`):**
```python
def _sanitize_reasoning(text: str) -> str:
    """Strip Unicode Mathematical Bold/Italic chars (U+1D400–U+1D7FF).
    LLMs sometimes emit these for emphasis; they render as 'Ublock' in Flutter's
    Courier font on Android because of UTF-16 surrogate rendering artifacts."""
    if not text:
        return text
    return "".join(c for c in text if not (0x1D400 <= ord(c) <= 0x1D7FF))
```
Applied to both the Gemini response path and the OpenRouter reasoning before returning to Flutter.

**Status: ✅ FIXED and CONFIRMED on physical device.**

---

### 2. Fixed Praise Audio Cutting Off Mid-Word
**Symptom:** After a correct answer, praise audio (Shabash / Wah Wah) was either not completing or being cut off before the next card loaded.

**Root Cause (Two compounding issues):**

**Issue A — Outer timeout too short:**
In `game_screen.dart`, the `_speakPraiseUrdu()` call was wrapped in a 3-second `.timeout()`. But the praise MP3 files are up to ~4 seconds long, and the internal `TtsService` timeout was also 4 seconds. The outer 3s timeout fired first, creating a race where the praise was cut off.

**Issue B — TTS fallback vs. `speakCard()` collision:**
When a specific praise MP3 was missing/failed, the catch block fell back to `_tts.speak(phrase.urdu)` (the Flutter TTS engine). However, `speakCard()` (called after praise completes) internally calls `_tts.stop()` to clear the engine before speaking the card name. If TTS praise was still running, `_tts.stop()` killed it mid-word.

**Fixes (`sitara_app/lib/screens/game_screen.dart` and `sitara_app/lib/services/tts_service.dart` — commit `e0dcd57`):**

1. **Increased outer timeout from 3s → 5s** in `game_screen.dart`:
   ```dart
   // 5-second timeout: praise MP3s can be up to ~4s; TTS fallback needs ~4s.
   // Must be longer than speakPraise's internal 4s timeout so the outer
   // await never fires first and races with the inner completion.
   await _speakPraiseUrdu(phrase)
       .timeout(const Duration(seconds: 5), onTimeout: () {});
   ```

2. **Added `_praisePlayer`-based audio fallback in `TtsService.speakPraise()` catch block:**
   The MP3 fallback now uses `_praisePlayer` (a dedicated `AudioPlayer` instance) instead of the TTS engine. Since `speakCard()` only calls `_tts.stop()`, a `_praisePlayer`-based fallback is completely immune to interruption.
   ```dart
   // Use _praisePlayer (not _tts) so speakCard()'s _tts.stop() cannot interrupt
   await _praisePlayer.play(AssetSource('audio/shabash.mp3'));
   await _praisePlayCompleter!.future.timeout(const Duration(seconds: 4), ...);
   ```
   TTS engine is now the absolute last resort, only if all MP3 files are broken.

**Status: ✅ FIXED.**

---

### 3. Fixed Google API Key: 403 PERMISSION_DENIED (API_KEY_SERVICE_BLOCKED)
**Symptom:** Cloud Run logs showed:
```
403 PERMISSION_DENIED: API_KEY_SERVICE_BLOCKED
```
All Gemini calls failing → T1 always down → T4:Heuristic shown in trace panel → `AGENT AVG: N/A`.

**Root Cause:**
The original GOOGLE_API_KEY stored in Cloud Run Secret Manager (versions 1–3) was an older AI Studio key that had **GCP API restrictions** configured on it in the Google Cloud Console. Specifically, it was restricted to certain APIs, and `generativelanguage.googleapis.com` was not in the allowed list.

**Fix:**
User provided a fresh, unrestricted key from https://aistudio.google.com. Stored as version 4 in Secret Manager:
```powershell
echo "<REDACTED — revoke this key in GCP Console>" | `
  gcloud secrets versions add GOOGLE_API_KEY --data-file=- --project=sitara-v1-495117
```
Redeployed → revision `sitara-backend-00031-mmj`. The 403 was gone but a new issue appeared (quota exhaustion — see below).

**Lesson:** AI Studio keys can have API restrictions. Always generate keys at aistudio.google.com with no GCP API restrictions, or explicitly add `generativelanguage.googleapis.com` to the allowed APIs list in Cloud Console.

**Status: ✅ FIXED.**

---

### 4. Fixed Gemini Quota Exhaustion: `limit: 0` on Free Tier
**Symptom:** After fixing the 403, Cloud Run logs showed:
```
429 RESOURCE_EXHAUSTED
Quota exceeded for metric: generate_content_free_tier_requests, limit: 0
```
Every T1:Gemini call failed immediately → all sessions fell to T3:Heuristic → `AGENT AVG: N/A` in trace panel → judges would only see heuristic baseline, never real agentic reasoning (this would destroy the 25% Antigravity Integration score).

**Investigation Steps:**
1. First attempted `gemini-2.0-flash` → 429 with `limit: 0`
2. Switched to `gemini-1.5-flash` → **404 NOT_FOUND** (model removed from `v1beta` API endpoint)
3. Queried available models via Google GenAI API → confirmed `gemini-2.0-flash-lite` is available
4. Switched to `gemini-2.0-flash-lite` → **STILL 429 with `limit: 0`**

**Root Cause:**
The GCP project `sitara-v1-495117`'s **free-tier daily quota was fully exhausted** for ALL `flash` model variants. The `limit: 0` indicates zero remaining quota on the free tier — not a per-request limit, but the daily aggregate was used up. Notably, `gemini-1.5-flash` was also no longer available (model deprecation in v1beta).

**Final Fix (commit `f202032`):**
Switched all three agents to **`gemini-2.5-flash`** — a newer model generation that has its **own separate quota bucket**:
```python
# All three agents: therapy_director, story_weaver, progress_guardian
model="gemini-2.5-flash"
```
The `gemini-2.5-flash` model has a fresh free-tier allocation that is not shared with `gemini-2.0-flash` or `gemini-2.0-flash-lite`.

**Verification:**
```
GET /health → "active_tier": "T1:Gemini", "model": "gemini-2.5-flash"
POST /evaluate-session → "mode": "agentic", "agent": "therapy_director", "active_tier": "T1:Gemini"
POST /generate-quest → "mode": "agentic", "qc_status": "passed"
```
Cloud Run startup log: `[Startup] OK Active AI tier on boot: GEMINI`

**Status: ✅ FIXED — T1:Gemini fully operational on revision `sitara-backend-00034-sgc`.**

---

### 5. Fixed OpenRouter "Illegal Header Value" Error
**Symptom:** T2:OpenRouter fallback was always failing with:
```
Illegal header value b'Bearer sk-or-v1-...  \r\n'
```

**Root Cause:**
Google Cloud Secret Manager stores secret values as raw bytes including the newline that terminates the `echo` command used to add the secret. When the key is retrieved with `os.environ.get("OPENROUTER_API_KEY")`, it includes a trailing `\r\n`. Python's `httpx` rejects any HTTP header containing `\r` or `\n` because those characters are used as header delimiters (HTTP spec RFC 7230) — injecting them could enable header-injection attacks.

**Fix (commit `f202032`):**
Added `.strip()` to every `os.environ.get()` call that reads an API key:
```python
# All three locations in agent.py
api_key = os.environ.get("OPENROUTER_API_KEY", "").strip()

# Also applied to the main key
GOOGLE_API_KEY = (os.environ.get("GOOGLE_API_KEY") or os.environ.get("GEMINI_API_KEY", "")).strip()
```

**Lesson:** **Always `.strip()` secrets from environment variables.** Secret Manager, `.env` files, and shell `echo` all append trailing whitespace/newlines. Never pass raw env values directly into HTTP headers.

**Status: ✅ FIXED — no "Illegal header value" errors in revision `sitara-backend-00034-sgc` logs.**

---

## 🔍 Detailed Investigation: Why Gemini Models Kept Failing

| Attempt | Model | Error | Root Cause |
|---------|-------|-------|------------|
| 1 | `gemini-2.0-flash` | 403 PERMISSION_DENIED | API key had GCP restrictions |
| 2 | `gemini-2.0-flash` | 429 RESOURCE_EXHAUSTED (`limit: 0`) | Free-tier daily quota exhausted |
| 3 | `gemini-1.5-flash` | 404 NOT_FOUND | Model deprecated/removed from v1beta endpoint |
| 4 | `gemini-2.0-flash-lite` | 429 RESOURCE_EXHAUSTED (`limit: 0`) | Same shared quota pool as flash, also exhausted |
| 5 ✅ | `gemini-2.5-flash` | **200 OK** | Separate quota bucket, fresh allocation |

**Key Learning:** Gemini model families (`2.0-flash`, `2.0-flash-lite`) share the same free-tier quota pool within a GCP project. Switching between them does NOT reset the quota. `gemini-2.5-flash` is a different generation with its own pool.

---

## 6. Fixed "Sovereign Baseline" Showing in AI Mode (Flutter Timeout)
**Symptom (physical device, new APK):** Even with AGENTIC toggle ON, SOVEREIGN TRACE showed "SOVEREIGN BASELINE" entries and T4:Heuristic badge. Mode Comparison showed 0 Antigravity Agent sessions.

**Root Cause 1 — Flutter HTTP timeout too short (10 seconds):**
`AntigravityService._post()` used `.timeout(const Duration(seconds: 10))`. Cloud Run cold start + `gemini-2.5-flash` inference consistently takes 20–25 seconds. Every single `evaluate-session` call silently timed out and fell into `_localFallback()` which returns `mode: 'baseline_fallback'` → shows as "Sovereign Baseline" in the trace.

**Fix:** Increased timeout to 30 seconds:
```dart
.timeout(const Duration(seconds: 30));
// Cloud Run cold start + gemini-2.5-flash inference can take 20-25s.
```

**Root Cause 2 — `generate-quest` reading `mode` from wrong JSON level:**
`_post()` wraps successful quest responses as `{'quest': data}`. But `generateQuest()` read `response['mode']` — which is always `null` on the wrapper level, defaulting to `'agentic'`. So the trace always showed "Story Weaver [QC: ...]" even when the backend returned a fallback quest. Meanwhile the real `mode` was inside `questMap` (the `data` object).

**Fix:**
```dart
// BEFORE (always null, defaults to 'agentic'):
final mode = response['mode'] as String? ?? 'agentic';

// AFTER (reads actual mode from quest data):
final mode = questMap['mode'] as String? ?? 'agentic';
```

**Root Cause 3 — Quest generation not counted in Mode Comparison:**
`generateQuest()` never incremented `agentSessions` or `baselineSessions`, so Mode Comparison always showed "Antigravity Agent: 0 sessions".

**Fix:** Added counter increment after every `generateQuest()` call.

**Root Cause 4 — Offline fallback quest was empty:**
When `generate-quest` timed out, `_localFallback()` returned `{'reasoning': 'Offline mode', 'actions': []}` with no quest fields, causing the game to start with no quest content.

**Fix:** `_localFallback` for generate-quest now returns a complete minimal quest:
```dart
return {
  'mode': 'baseline_fallback',
  'quest_title': 'Aaj Ka Safar',
  'story_text': 'Chalo, aaj hum nayi cheezein seekhein! ...',
  'target_category': body['preferred_category'] ?? 'animals',
  ...
};
```

**Status: ✅ FIXED — commit `3a58b2d`.**

---

## 7. Fixed Gemini Permanently Locked Out After One 429 (RPM Quota Bug)
**Symptom:** After any quota hit, the SOVEREIGN TRACE showed T4:Heuristic for all subsequent sessions, even after waiting several minutes. The `/health` endpoint showed `"gemini": false` indefinitely.

**Root Cause (Critical backend bug):**
The `gemini-2.5-flash` free tier enforces **5 requests per minute (RPM)** per project — not a daily limit. When a 429 hit, the backend set `_tier_health["gemini"] = False` and never reset it back to `True`.

`_refresh_tier_health()` only probes OpenRouter — it never re-probes Gemini. Once `gemini=False`, it stayed `False` for the entire process lifetime (until Cloud Run restarted). This meant a single burst of Judge Sandbox button presses (Simulate Wins → Simulate Fails → Eval Now in rapid succession) would lock out Gemini for hours.

The 429 error itself contains the exact recovery time:
```
Please retry in 56.125539665s
```
The backend was ignoring this entirely.

**Fix (`agent.py` — commit `8652926`):**

Added `_gemini_quota_reset_at` datetime and two helper functions:
```python
def _mark_gemini_quota_hit(retry_delay_seconds: float = 65.0):
    """Mark Gemini quota-exhausted; schedule auto-recovery after retryDelay."""
    global _gemini_quota_reset_at
    _tier_health["gemini"] = False
    _gemini_quota_reset_at = datetime.now() + timedelta(seconds=retry_delay_seconds)

def _check_gemini_quota_recovery():
    """Restore Gemini health flag when the retry window has passed."""
    global _gemini_quota_reset_at
    if _gemini_quota_reset_at and datetime.now() >= _gemini_quota_reset_at:
        _tier_health["gemini"] = True
        _gemini_quota_reset_at = None
        print("[QUOTA] Gemini quota window expired — T1:Gemini restored")
```

The 429 handler now parses the exact retryDelay from the error:
```python
retry_match = re.search(r"retry\s+in\s+([\d.]+)s", str(e), re.IGNORECASE)
retry_delay = float(retry_match.group(1)) + 5 if retry_match else 65.0
_mark_gemini_quota_hit(retry_delay)
```

`_check_gemini_quota_recovery()` is called on every `evaluate-session` request and on `/health` — so Gemini is automatically restored the moment the retry window expires, with no process restart needed.

Also reduced `TIER_RECHECK_SECONDS` from 180 → 65 seconds.

**Stress test confirmation:**
```
Call 1 → T3:Heuristic  (quota hit)
Call 2 → T3:Heuristic  (cooling down, retryDelay ~60s)
Call 3 → T3:Heuristic  (cooling down)
Call 4 → T1:Gemini ✅  (auto-recovered after window expired)
Call 5 → T1:Gemini ✅  (fully live)
Call 6 → T3:Heuristic  (new quota hit after 5 calls in new window)
```

**Status: ✅ FIXED — revision `sitara-backend-00035-spm`.**

**Demo note:** For normal gameplay (1 `evaluate-session` every 30s = 2 RPM), the 5 RPM limit is never reached. Only rapid-fire Judge Sandbox button presses exhaust it — and the system now auto-recovers in ~65 seconds.

---

### 8. Fixed Gemini Daily Quota Exhaustion (AI Developer API 20 RPD Cap)
**Symptom:** After the RPM fix was live, Gemini started 429-ing again shortly after deployment with a different error:
```
429 RESOURCE_EXHAUSTED
GenerateRequestsPerDayPerProjectPerModel-FreeTier
```
`/health` showed `"gemini": false` and the RPM recovery timer (65s) had no effect — Gemini never came back.

**Root Cause — Two completely separate quota limits:**

The Gemini free tier enforces **two independent limits**:
| Limit | Value | Scope |
|-------|-------|-------|
| `GenerateRequestsPerMinutePerProjectPerModel-FreeTier` | 5 RPM | Resets every ~60 seconds |
| `GenerateRequestsPerDayPerProjectPerModel-FreeTier` | **20 RPD** | Resets at midnight Pacific |

The 20 RPD cap applies to `generativelanguage.googleapis.com` (the AI Developer API). This cap is **completely independent of GCP billing** — adding billing credit to the GCP project does NOT increase or remove this limit. We confirmed this by linking the GCP project to a $5 billing account — the 429s continued unchanged.

**Why billing didn't help:**
- `generativelanguage.googleapis.com` = AI Studio / AI Developer API path. Has its own free-tier enforcement regardless of GCP billing.
- `aiplatform.googleapis.com` = Vertex AI path. Uses GCP billing directly. No per-day free-tier cap.

**Fix (Round 3 — Vertex AI switch):**

1. **Switched SDK endpoint to Vertex AI** by setting env var `GOOGLE_GENAI_USE_VERTEXAI=1` in Cloud Run. The google-genai Python SDK automatically routes to `aiplatform.googleapis.com` when this is set — no code changes needed.
2. **Created new GCP API key** (version 5 in Secret Manager) — the previous key (v4) was created for AI Developer API; Vertex AI uses Application Default Credentials (service account), not API keys.
3. **Granted `roles/aiplatform.user`** to the Cloud Run service account `178558547254-compute@developer.gserviceaccount.com`:
   ```powershell
   gcloud projects add-iam-policy-binding sitara-v1-495117 `
     --member="serviceAccount:178558547254-compute@developer.gserviceaccount.com" `
     --role="roles/aiplatform.user"
   ```
4. **Deployed revision `sitara-backend-00039-t7g`** with new env vars:
   ```
   GOOGLE_GENAI_USE_VERTEXAI=1
   GOOGLE_CLOUD_PROJECT=sitara-v1-495117
   GOOGLE_CLOUD_LOCATION=us-central1
   ```

**Verification result:**
```
GET /health → {"active_tier": "T1:Gemini", "model": "gemini-2.5-flash"}
POST /evaluate-session → {"mode": "agentic", "agent": "therapy_director"}
```
Vertex AI test returned `"OK"` instantly. Daily quota no longer a concern with GCP billing.

**Status: ✅ FIXED — revision `sitara-backend-00039-t7g`, Vertex AI, no daily cap.**

---

### 9. Fixed PerDay Quota Detection (Wrong Recovery Timer)
**Symptom:** After switching to Vertex AI, we added detection logic for the case where a future PerDay quota hit would use an appropriate recovery cooldown. Testing revealed the original code treated PerDay and PerMinute identically — parsing the `"retry in Xs"` value from the error message (which is only valid for RPM, not RPD).

**Root Cause:**
A `GenerateRequestsPerDayPerProjectPerModel-FreeTier` 429 does not carry a meaningful `retry in Xs` field — it's a daily reset, not a minute-level backoff. If the code parsed `retry_delay = 22s` from the error and set a 22-second cooldown, it would hammer the API every 22 seconds all day, burning any remaining quota on other models.

**Fix (commit `09c16e9`):**
```python
is_daily = "PERDAY" in exc_str or "PER_DAY" in exc_str or "PER DAY" in exc_str
if is_daily:
    retry_delay = 7200.0  # 2 hours — daily quota won't reset sooner
    print(f"[QUOTA] Gemini DAILY quota exhausted — marking T1 down for 2h.")
else:
    retry_match = re.search(r"retry\s+in\s+([\d.]+)s", str(e), re.IGNORECASE)
    retry_delay = float(retry_match.group(1)) + 5 if retry_match else 65.0
_mark_gemini_quota_hit(retry_delay)
```
Also updated OpenRouter probe/fallback model list to current working free models (several had gone offline since the original list was written):
```python
["mistralai/mistral-7b-instruct:free", "microsoft/phi-3-mini-128k-instruct:free",
 "meta-llama/llama-3.2-3b-instruct:free", "google/gemma-3-4b-it:free",
 "meta-llama/llama-3.3-70b-instruct:free"]
```

**Status: ✅ FIXED — commit `09c16e9`.**

---

## 🧑‍💻 Commits in This Session

| Hash | Description |
|------|-------------|
| `e0dcd57` | fix: Unicode Mathematical Bold sanitizer, praise audio timing, 5s outer timeout |
| `85fb9f4` | fix: apply _sanitize_reasoning to Gemini T1 response path |
| `b617d7d` | fix: switch agents to gemini-2.0-flash-lite (was gemini-2.0-flash) |
| `f202032` | fix: switch to gemini-2.5-flash and strip API key whitespace |
| `3a58b2d` | fix: increase HTTP timeout 10s→30s and fix generate-quest mode tracking |
| `8652926` | fix: auto-recover Gemini after RPM quota window expires |
| `09c16e9` | fix: detect PerDay vs PerMinute Gemini quota and update OpenRouter models |
| `a085d1e` | docs: add May 20 session summary |

---

## 🏗️ Cloud Run Deployments in This Session

| Revision | Change | Result |
|----------|--------|--------|
| `sitara-backend-00031-mmj` | New GOOGLE_API_KEY (version 4) | 403 fixed → 429 appeared |
| `sitara-backend-00033-d2q` | Switch to `gemini-2.0-flash-lite` | 429 still, same quota pool |
| `sitara-backend-00034-sgc` | Switch to `gemini-2.5-flash` + `.strip()` all keys | T1:Gemini LIVE |
| `sitara-backend-00035-spm` | Gemini auto-recovery + TIER_RECHECK 65s | RPM auto-recovery working |
| `sitara-backend-00037-*` | Vertex AI env vars (first attempt) | Partial — IAM not yet granted |
| `sitara-backend-00038-*` | `roles/aiplatform.user` granted to service account | Vertex AI calls OK |
| `sitara-backend-00039-t7g` | Final Vertex AI deploy — `GOOGLE_GENAI_USE_VERTEXAI=1` + new API key v5 | ✅ **FINAL** — no daily cap, T1:Gemini fully operational |

**Final live URL:** `https://sitara-backend-178558547254.asia-south1.run.app`

---

## 📚 Lessons & Learnings

### Secret Manager / API Keys
1. **Always `.strip()` keys read from environment.** `gcloud secrets versions add` stores the echo's trailing `\r\n`. Python's httpx, requests, and urllib all reject `\r` or `\n` in header values (HTTP spec).
2. **AI Studio keys can have GCP API restrictions.** If you created the key in Google Cloud Console (not AI Studio), check "API restrictions" and ensure `generativelanguage.googleapis.com` is allowed, or set to "Don't restrict key".
3. **Quota is per model-family, per project.** Exhausting `gemini-2.0-flash` quota also exhausts `gemini-2.0-flash-lite`. Switch to a newer generation (`gemini-2.5-flash`) for a fresh bucket.

### Flutter HTTP / Timeout
4. **Always set HTTP timeout > server processing time + cold start.** Cloud Run cold start is 10–20s, Gemini inference 5–10s — total can reach 25s. A 10s Flutter timeout silently falls to local fallback with no error shown to the user.
5. **JSON wrapper levels matter for nested key reads.** If `_post()` wraps a response as `{'quest': data}`, reading `response['mode']` returns null — the `mode` is inside `data`. Always trace exactly which object you're reading from.
6. **Count every API path in your metrics.** If `generateQuest()` calls the backend but doesn't increment `agentSessions`, the Mode Comparison panel never shows AI wins — even when the agent IS working.

### Flutter Audio Architecture
7. **Three separate `AudioPlayer` instances is intentional.** `_audioPlayer` (card TTS), `_praisePlayer` (praise/shabash), `_bgPlayer` (intro music) must remain isolated. If praise uses the TTS engine (`_tts.speak()`), it WILL be interrupted by the next `speakCard()` call which calls `_tts.stop()`.
8. **Outer `.timeout()` must be longer than inner await.** If `speakPraise` internally times out at 4s, the caller's `await speakPraise().timeout(3s)` fires first and abandons — but the audio keeps playing. Always add 1–2s of buffer to outer timeouts.

### Unicode / LLM Output
9. **LLMs emit Unicode Mathematical Bold (U+1D400–U+1D7FF) for emphasis.** These are surrogate pairs in UTF-16. Android fonts without these codepoints render them as "U" + "block". Always sanitize LLM `reasoning` text before showing it in a Flutter Text widget.
10. **The sanitizer must run server-side, not client-side.** The Flutter app receives JSON — by the time it renders, the damage is done. Strip in Python before serializing.

### Gemini Quota & Rate Limiting
11. **Gemini 2.5-flash free tier = 5 RPM (requests per minute), not requests per day.** This is a sliding 60-second window. 2 calls/minute (one every 30s) is safe. Rapid-fire testing exhausts it in seconds.
12. **Never use a global boolean flag to track quota health without a reset mechanism.** `_tier_health["gemini"] = False` is permanent until process restart unless you explicitly reset it. Always pair a quota-down flag with a timer-based recovery.
13. **Parse `retryDelay` from 429 errors for precise recovery.** The Gemini API returns `"Please retry in 56.125539665s"` in the error body. Use this exact value instead of a hardcoded 60s cooldown — it's more accurate and faster to recover.
14. **Call recovery checks on every hot path, not just a background timer.** Checking `_check_gemini_quota_recovery()` at the start of every `evaluate-session` and `/health` call ensures instant recovery the moment the window expires.

### Gemini Model Lifecycle
15. **`gemini-1.5-flash` was removed from the `v1beta` API endpoint** (returns 404 as of May 2026). Available models: `gemini-2.0-flash`, `gemini-2.0-flash-lite`, `gemini-2.5-flash`, `gemini-2.5-flash-lite`.
16. **`gemini-2.5-flash` is currently the best free-tier option** — higher capability than 2.0 variants, separate quota pool, available in `v1beta`.

### AI Developer API vs Vertex AI (Critical Architecture Decision)
17. **The AI Developer API (`generativelanguage.googleapis.com`) has a hard 20 RPD cap that GCP billing cannot override.** Even after linking a billing account, the cap remains because it is enforced by a separate free-tier quota system at the AI Studio level. Many developers waste time trying to "upgrade" via billing — it doesn't work for this API path.
18. **Vertex AI (`aiplatform.googleapis.com`) is the correct production path.** It uses GCP billing with no artificial per-day caps. Switch via `GOOGLE_GENAI_USE_VERTEXAI=1` — the google-genai SDK handles endpoint routing automatically with no code changes.
19. **Cloud Run service account needs `roles/aiplatform.user` for Vertex AI.** The default Compute service account does NOT have this role. Grant it explicitly: `gcloud projects add-iam-policy-binding ... --role="roles/aiplatform.user"`.
20. **Distinguish PerDay vs PerMinute in 429 error handling.** Daily quota errors contain `"PERDAY"` in the exception string. Use a 2-hour (7200s) cooldown for daily, and the API-provided `retry in Xs` value for per-minute. Never use a short cooldown for daily quota — it will spam the API all day.
21. **Free model lists for OpenRouter rotate over time.** Models listed as available in March may return 404 or 503 by May. Always validate the probe/fallback model list before each hackathon submission. Current working free models (May 2026): `mistral-7b-instruct:free`, `phi-3-mini-128k-instruct:free`, `llama-3.2-3b-instruct:free`, `gemma-3-4b-it:free`, `llama-3.3-70b-instruct:free`.

---

## ✅ Final Verification Checklist (End of Session)

| Check | Result |
|-------|--------|
| `/health` → `active_tier: T1:Gemini` | ✅ |
| `/evaluate-session` → `mode: agentic`, real tool calls | ✅ |
| `/generate-quest` → `mode: agentic`, `qc_status: passed` | ✅ |
| T1:Gemini auto-recovers after RPM quota hit (~65s) | ✅ Stress-tested and confirmed |
| No "Ublock" flood in trace panel | ✅ (`_sanitize_reasoning()` deployed) |
| No "Illegal header value" in Cloud Run logs | ✅ (`.strip()` on all API keys) |
| Praise audio completes before next card | ✅ (5s timeout + praisePlayer fallback) |
| "Sovereign Baseline" no longer shown in AI Mode | ✅ (30s timeout + correct mode key) |
| Mode Comparison counts AI sessions | ✅ (`generateQuest` increments counter) |
| Cloud Run on Vertex AI (no 20 RPD daily cap) | ✅ `GOOGLE_GENAI_USE_VERTEXAI=1` deployed |
| Service account has `roles/aiplatform.user` | ✅ Granted to `178558547254-compute@` |
| PerDay quota detection (2h cooldown) | ✅ `"PERDAY"` string detection in 429 handler |
| `deploy_cloud_run.ps1` includes Vertex AI env vars | ✅ |
| `deploy_cloud_run.sh` includes Vertex AI env vars | ✅ |
| Cloud Run revision live | ✅ `sitara-backend-00039-t7g` |
| Git pushed to `main` | ✅ commit `09c16e9` |

---

## 🧭 Remaining Known Issues

| Issue | Priority | Notes |
|-------|----------|-------|
| Firestore database not provisioned in `sitara-v1-495117` | Low | Non-blocking; sessions fall back to SQLite. Firestore 404 in logs but does not affect gameplay. |
| T2:OpenRouter `openrouter_model: null` | Low | Key is clean (header fix applied) but free model probe may return no working model at any given time. T1:Gemini via Vertex AI is live so T2 is backup only. |
| Judge Sandbox rapid-fire exhausts 5 RPM limit | Low | By design. System recovers in ~65s. Normal gameplay (1 req/30s = 2 RPM) never hits this limit. Document in demo script. |

---

## 📋 Submission Status (May 20, 2026)

| Deliverable | Status |
|-------------|--------|
| Working APK | ✅ Built by GitHub Actions CI — commit `3a58b2d` |
| Backend live on Cloud Run | ✅ `sitara-backend-00039-t7g` (Vertex AI) |
| T1:Gemini agentic (for judges) | ✅ `gemini-2.5-flash` via Vertex AI — no daily cap |
| SOVEREIGN TRACE panel (no Ublock) | ✅ `_sanitize_reasoning()` deployed |
| "Sovereign Baseline" in AI Mode fixed | ✅ 30s timeout + correct mode key |
| Mode Comparison shows AI sessions | ✅ `generateQuest` counter fixed |
| Praise audio completes | ✅ 5s timeout + praisePlayer fallback |
| Demo video (~3 min) | See `demo_script_readme.md` |
| Architecture README | See `Project_Architecture_Blueprint.md` |
| Baseline comparison (agentic vs heuristic) | ✅ `FixedRuleEngine` + `_useHeuristic` toggle |
| Robustness evidence | ✅ Quota hit → T3 fallback → T1 auto-recovery (stress-tested) |
| Deploy scripts with Vertex AI env vars | ✅ `deploy_cloud_run.ps1` + `deploy_cloud_run.sh` updated |
| CLAUDE.md updated with Vertex AI requirements | ✅ |
