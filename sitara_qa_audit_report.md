# Sitara AAC App — Comprehensive QA Audit Report

**Date**: 2026-05-19
**Auditor**: Claude Code (static analysis + source verification)
**Method**: Full source-code audit against test plan — all findings are evidence-based with file:line citations
**Scope**: All 7 test areas, 47 symbol cards, all 6 categories

---

## 🚀 Build Status

| Check | Result |
|---|---|
| `flutter build apk --release` | ✅ `app-release.apk` 50.7 MB (prior session) |
| `flutter analyze` | ⚠️ **7 issues** (2 warnings + 5 infos) — **NOT 0 as previously claimed** |
| `flutter test` | ✅ 14/14 pass |

**flutter analyze issues:**
```
WARNING  home_screen.dart:26       — _generateAndLaunchStory declared but never called (dead code)
WARNING  parent_dashboard.dart:1   — Unused import 'dart:convert'
info     phrase_pool.dart:162      — prefer_function_declarations_over_variables
info     parent_dashboard.dart:721 — prefer_const_constructors (×2)
info     antigravity_service.dart:238-239 — prefer_const_declarations (×2)
```

---

## TEST AREA 1 — BACKEND AGENTS

| ID | Result | Notes |
|---|---|---|
| T1.1 | ⏭️ SKIPPED | No live backend access in this audit environment |
| T1.2 | ⏭️ SKIPPED | Requires live backend |
| T1.3 | ⏭️ SKIPPED | Requires live backend |
| T1.4 | ⏭️ SKIPPED | Requires live backend |
| T1.5 | ⏭️ SKIPPED | Requires live backend |
| T1.6 | ⏭️ SKIPPED | Requires live backend |
| T1.7 | ⚠️ PARTIAL | See detail below |

**T1.7 — _validate_quest quality gate: PARTIAL**
- `_validate_quest` **exists** at [agent.py:40](file:///D:/my-dev-knowledge-base/sitara/adk_backend/agent.py#L40) and is called at lines 347 and 694.
- What it validates:
  - `quest_title` is non-empty ✅
  - `story_text` has ≥ 2 sentences ✅
  - `target_category` is in `VALID_CATEGORIES` ✅
  - `difficulty` is one of `easy/medium/hard` ✅
- **MISSING**: The test plan requires that if Story Weaver targets a category with >80% failure rate for this child, the quest must be **rejected and regenerated**. This failure-rate check is **not implemented** — `_validate_quest` has no access to per-child session history and cannot enforce this threshold. The function is a pure structural validator, not an adaptive quality gate.

---

## TEST AREA 2 — FLUTTER APP CORE GAME

| ID | Result | Notes |
|---|---|---|
| T2.1 | ✅ PASS | Home screen: child name via route args, category dropdown, session progress bar all present in code |
| T2.2 | ✅ PASS | After ARASAAC fix: all 47 card IDs verified via API; emoji fallback if network fails |
| T2.3 | ✅ PASS | Bounce (correct) and shake (incorrect) animations confirmed in `symbol_card_widget.dart` |
| T2.4 | ✅ PASS | `AgentTraceWidget` wired; trace entries include timestamp, action, reasoning, agent name |
| T2.5 | ✅ PASS | All 6 action types handled in `game_screen.dart._applyAction()` without crash paths |
| T2.6 | ✅ PASS | Parent dashboard has weekly stats, session count, AI vs Heuristic comparison card |
| T2.7 | ✅ PASS | `useHeuristic` toggle in AppBar; `_heuristicAdaptation()` routes to client-side rules |

**T2.2 detail:** Cards load ARASAAC images via `Image.network()`. With the 20 corrected IDs (committed in this session), all 47 cards now display the correct image. Emoji fallback activates automatically on image load failure — child never sees a broken layout.

---

## TEST AREA 3 — TTS VOICE QUALITY

| ID | Result | Notes |
|---|---|---|
| T3.1 | ✅ PASS | Female voice detection checks `gender == 'female'` + name substrings `urc/ura/urf`; pre-recorded MP3s are primary voice |
| T3.2 | ✅ PASS | `PhrasePool.tryAgain` = `'واہ! پھر سے!' / 'Wow! Try again!'` — warm, bilingual, non-demoralising |
| T3.3 | ⏭️ SKIPPED | Requires physical device with audio output |
| T3.4 | ✅ PASS | 3-tier escalation confirmed: good (`Shabash/Bilkul Sahi`) → great (`WOW WOW! Brilliant!`) → amazing (`CHAMPION! Masha Allah!`) |
| T3.5 | ✅ PASS | `tts_service.dart:211` reads `LocalDbService.instance.getTtsLanguageMode()` — english-only/bilingual/urdu-only all branched |
| T3.6 | ❌ FAIL | See critical detail below |

**T3.6 — ARASAAC CDN requests: FAIL**
The test plan states "confirm no ARASAAC CDN network requests are made" and "cards must display correctly with WiFi disabled."

**Reality:** 46 of 47 cards use `_pic(id)` which generates `https://static.arasaac.org/pictograms/{id}/{id}_500.png`. The widget calls `Image.network(widget.card.imagePath)` for all non-asset paths — CDN requests ARE made whenever the network is available.

Only the Namaz card uses a local asset (`assets/namaz.png`).

**Offline behaviour:** The emoji fallback in the `errorBuilder` means cards display the emoji if the network request fails. So the app is *usable* offline, but it is NOT "zero CDN requests" as the test requires. The widget docstring says "emoji-primary" but the visual implementation is image-primary with emoji as fallback.

**File:** [symbol_card_widget.dart:240](file:///D:/my-dev-knowledge-base/sitara/sitara_app/lib/widgets/symbol_card_widget.dart#L240)

---

## TEST AREA 4 — SYMBOL CARDS VISUAL QUALITY

| ID | Result | Notes |
|---|---|---|
| T4.1 | ✅ PASS | All 47 cards audited; 20 wrong IDs corrected (ARASAAC API verified) |
| T4.2 | ✅ PASS | Namaz card: `imagePath: 'assets/namaz.png'` — local Islamic prayer image, no ARASAAC dependency |
| T4.3 | ✅ PASS | Category colours confirmed in `symbol_card_widget.dart:51-56`: animals=green `#2EB87E`, food=amber `#E8930A`, family=rose `#E0457B`, emotions=indigo `#6C63FF`, routines=cyan `#0097B2`, transport=orange `#F07020` |

**T4.1 corrected IDs (for record):**

| Card | Old (wrong) ID | New (correct) ID |
|---|---|---|
| Banana | 5490 | 2530 |
| Milk | 4893 | 2445 |
| Egg | 5492 | 2427 |
| Bread | 5504 | 10232 |
| Orange | 10225 | 2483 |
| Baby | 38288 | 2275 |
| Angry | 35534 | 35539 |
| Scared | 35540 | 35535 |
| Tired | 6348 | 35537 |
| Play | 10286 | 6537 |
| Walk | 5538 | 8649 |
| Study | 3307 | 6495 |
| Brush Teeth | 5404 | 6971 |
| Pray | 35447 | assets/namaz.png (local) |
| Car | 2640 | 2339 |
| Bus | 5534 | 2262 |
| Bicycle | 2512 | 6935 |
| Airplane | 2461 | 6924 |
| Boat | 2514 | 6932 |
| Motorcycle | 2627 | 7166 |

---

## TEST AREA 5 — STORYBOOK

| ID | Result | Notes |
|---|---|---|
| T5.1 | ✅ PASS | 4 stories confirmed; badge renders `'{pageCount} Pages of Joy'` dynamically |
| T5.2 | ✅ PASS | Each page has `'en'` and `'ur'` keys; Urdu in Noto Nastaliq; progress dots confirmed |
| T5.3 | ✅ PASS | All 4 interactive elements confirmed in code; Ammi (👩) and Dada Abu (👴) are in Jugnu story pages 1/4/5/7/8 |
| T5.4 | ✅ PASS | 12h cooldown active; long-press on badge calls `_bypassCooldown()` at line 559; bypass button also at line 673 |

**T5.1 detail:** Stories are: The Shiny Little Star ⭐, Coco the Kind Cat 🐱, The Forest Train Adventure 🚂, Sitara Aur Jugnu 🌙. All 4 present. Each has exactly 9 pages (36 total `'en'` entries ÷ 4 = 9). Badge shows computed page count dynamically at [storybook_screen.dart:785](file:///D:/my-dev-knowledge-base/sitara/sitara_app/lib/screens/storybook_screen.dart#L785).

---

## TEST AREA 6 — OFFLINE RESILIENCE

| ID | Result | Notes |
|---|---|---|
| T6.1 | ⚠️ PARTIAL | See detail below |
| T6.2 | ✅ PASS | 30s `_agentCheckTimer` resumes API calls automatically; no restart needed |
| T6.3 | ✅ PASS | `antigravity_service.dart` uses `.timeout(const Duration(seconds: 10))` → falls to `_localFallback` |

**T6.1 — Offline gameplay: PARTIAL**

The game remains playable offline (no crash, cards load with emoji fallback). However, `_localFallback()` returns `{'actions': []}` — zero adaptive actions are applied in offline mode. The trace logs `'[OFFLINE MODE] No internet — preserving current category'` but there is no category switch, difficulty adjustment, or reward trigger.

The test requires "_localFallback() is used (check via Agent Trace — should say 'source: local_fallback' or 'heuristic')" — the reasoning string IS logged, but the `source` field is not explicitly set as a top-level key. The trace panel will show offline reasoning text but the adaptation engine is effectively disabled.

**File:** [antigravity_service.dart:350-358](file:///D:/my-dev-knowledge-base/sitara/sitara_app/lib/services/antigravity_service.dart#L350)

---

## TEST AREA 7 — BUILD & SUBMISSION READINESS

| ID | Result | Notes |
|---|---|---|
| T7.1 | ✅ PASS | APK built: `app-release.apk` 50.7 MB (prior session) |
| T7.2 | ⏭️ SKIPPED | Physical device required |
| T7.3 | ❌ FAIL | `flutter analyze` returns **7 issues** — existing report's claim of "0 issues" is incorrect |
| T7.4 | ⏭️ SKIPPED | Physical device required |

**T7.3 Issues requiring fix before submission:**

```dart
// FIX 1 — home_screen.dart:26 (warning — dead code)
// Remove or wire up _generateAndLaunchStory()
void _generateAndLaunchStory(String childName) async { ... }  // never called

// FIX 2 — parent_dashboard.dart:1 (warning — unused import)
import 'dart:convert';  // remove this line
```

The 5 `info` items are style suggestions and non-blocking.

---

## 🐛 Issues Summary

| # | Severity | Area | Issue | File |
|---|---|---|---|---|
| 1 | 🔴 Critical | Build | `flutter analyze` reports 7 issues, not 0 | `home_screen.dart:26`, `parent_dashboard.dart:1` |
| 2 | 🟡 Medium | T3.6 / T6.1 | ARASAAC images load via CDN — 46/47 cards require network for best visual | `symbol_card_widget.dart:240` |
| 3 | 🟡 Medium | T1.7 | `_validate_quest` validates structure only, not per-child failure rate | `agent.py:40-51` |
| 4 | 🟡 Medium | T6.1 | `_localFallback` returns empty `actions:[]` — no offline adaptive behaviour | `antigravity_service.dart:350` |
| 5 | 🟢 Minor | T7.3 | Dead function `_generateAndLaunchStory` triggers analyzer warning | `home_screen.dart:26` |
| 6 | 🟢 Minor | T7.3 | Unused `dart:convert` import | `parent_dashboard.dart:1` |

---

## 📊 Overall Readiness Score

**7.5 / 10**

### Submission Recommendation

The app is feature-complete and the core hackathon requirements (multi-agent ADK, TTS, confetti, session caps, analytics, storybook, offline fallback, baseline comparison toggle) are all implemented and code-verified. Two issues need fixing before submission day: the two `flutter analyze` warnings (dead function + unused import, ~5 minutes of work) must be cleared because judges who run `flutter analyze` will see them. The ARASAAC CDN dependency is a known design choice with emoji fallback — acceptable for the hackathon context but worth noting in the README that images require connectivity for full visual quality. The offline adaptive engine returning `actions:[]` means children get a static experience offline, which is functional but not the AI-adaptive experience described in the pitch — flag this in demo notes if testing without connectivity. Fix the two warnings first, then submit.

---

*QA Audit compiled 2026-05-19 by Claude Code — all findings verified against source files.*
