# Sitara Game Improvements — Design Spec
**Date:** 2026-05-17  
**Author:** Tahir Yamin — Google Antigravity Hackathon, Challenge 4  
**Status:** Approved — ready for implementation  
**Scope:** Three parallel improvement tracks: Accessibility → Game Feel → Analytics

---

## Context

Sitara is a Google Antigravity Hackathon submission (Challenge 4, due 2026-05-20). It is a Flutter Android game for non-verbal autistic children in Pakistan, using Google ADK multi-agent orchestration (Therapy Director → Story Weaver) with offline fallback.

**Hackathon evaluation weights this spec targets:**
| Criterion | Weight |
|---|---|
| Gameplay engagement & retention | 25% |
| Antigravity integration | 25% |
| Agentic innovation | 20% |
| Technical polish | 15% |
| Originality & creativity | 10% |
| Comparative proof bonus | +5% |

**Approach:** All three tracks run in parallel (Approach B) with impact-ranked implementation (Approach C) and deep dives per track (Approach A). Priority order: Accessibility → Game Feel → Analytics.

---

## Track 1 — Accessibility

### Skill: `design:accessibility-review`

### Scope
All 6 screens: `game_screen.dart`, `home_screen.dart`, `quest_screen.dart`, `splash_screen.dart`, `onboarding_screen.dart`, `parent_dashboard.dart`.

### Requirements

#### 1.1 Touch Targets
- All tappable widgets must meet **minimum 48×48 dp** touch target size
- Symbol cards on game screen: minimum `120×120 dp` (larger targets reduce motor error for children with coordination challenges)
- Bottom nav / action buttons: audit with `flutter_test` `find.byType` + size assertions

#### 1.2 Colour Contrast
- All text on coloured backgrounds must meet **WCAG AA (4.5:1)** contrast ratio minimum
- Urdu text (`NotoNastaliqUrdu`) on gradient backgrounds: verify contrast at all opacity levels
- Agent trace panel (dark background `0xFF1A1A2E`): cyan + white text — verify ratios

#### 1.3 Sensory Overload Audit
- No auto-playing animations longer than **2 seconds** without user initiation
- No flashing/strobing effects (>3 Hz violates WCAG 2.3.1)
- Sound effects must be **opt-in** via a parent-controlled toggle in settings, not auto-play
- Reward animations: max 1.5 seconds, no rapid colour cycling

#### 1.4 Screen Reader / TalkBack
- Every tappable `GestureDetector` and `InkWell` must have a `Semantics` wrapper with a meaningful `label`
- Symbol cards: label = `"${card.nameEnglish}, ${card.nameRomanUrdu}"` (English first for TalkBack)
- Agent trace panel: mark as `excludeSemantics: true` (judge overlay, not child-facing)
- AppBar brain icon button: `tooltip` already set — verify `Semantics` label matches

#### 1.5 RTL Layout
- All Urdu text widgets must use `textDirection: TextDirection.rtl`
- `TextAlign.right` for all Urdu labels
- Verify `Directionality` widget wraps Urdu text sections, not entire scaffold (to avoid breaking LTR layout of English elements)

#### 1.6 Font Scaling
- App must not break at system font scale 1.5× and 2.0×
- Use `MediaQuery.textScalerOf(context)` — do not hardcode pixel sizes for body text
- Symbol card Urdu label: allow up to 2 lines before truncating

### Output files
- Updated `symbol_card_widget.dart`
- Updated `game_screen.dart`
- Updated `home_screen.dart`
- Updated `onboarding_screen.dart`

---

## Track 2 — Game Feel & Animations

### Skills: `design:design-critique` + `design:ux-copy`

### Requirements

#### 2.1 Symbol Card Feedback Animation
- **Correct tap:** Scale bounce `1.0 → 1.15 → 1.0` over 300ms + green border flash + `Colors.greenAccent` overlay fade
- **Incorrect tap:** Horizontal shake (3 cycles, 8dp amplitude, 250ms) + red border flash
- Implementation: `AnimationController` in `SymbolCardWidget` state; `TweenSequence` for scale bounce
- No animation if `reduceMotion` accessibility flag is set (check `MediaQuery.accessibleNavigation`)

#### 2.2 Reward Burst Animation
- Replaces current static `SnackBar` when `trigger_reward` action fires
- Full-screen confetti/star burst overlay: 1.5 seconds, auto-dismiss
- Package: `confetti: ^0.7.0` (add to `pubspec.yaml`)
- Overlay sits above `GameScreen` using an `OverlayEntry`
- Triggers in `_applyAction()` when `action.type == 'trigger_reward'`

#### 2.3 Break Prompt Overlay
- Currently `send_break_prompt` action has no visible UI — add a gentle full-screen breathing animation
- Soft blue/purple gradient background (`0xFF6C63FF` → `0xFF43C59E`)
- Animated breathing circle (scale `0.8 → 1.2`, 4s cycle, repeat 3×)
- Urdu + English text: "وقفہ کریں" / "Time for a little break"
- Dismissible by parent tap; child cannot dismiss (requires double-tap or back button held 2s)

#### 2.4 Praise Phrases — Urdu TTS Female Voice
- Current hardcoded pool in `game_screen.dart` replaced with a structured `PhrasePool` class
- **TTS configuration** (via `flutter_tts`, already installed):
  ```dart
  await _tts.setLanguage('ur-PK');
  await _tts.setVoice({'name': 'ur-PK-female', 'locale': 'ur-PK'});
  await _tts.setSpeechRate(0.45);  // slower for children
  await _tts.setPitch(1.1);        // slightly higher, warmer
  ```
- Falls back to `en-US` female voice if `ur-PK` not available on device
- Praise pool (Urdu script + Roman Urdu + English fallback):

| Urdu | Roman Urdu | English fallback |
|---|---|---|
| شاباش! | Shabash! | Well done! |
| بہت اچھا! | Bohat acha! | Excellent! |
| واہ! کمال ہے! | Wah! Kamaal hai! | Amazing! |
| تم بہت ہوشیار ہو! | Tum bohat hoshiyar ho! | You're so smart! |
| زبردست! | Zabardast! | Fantastic! |

- TTS fires on every correct tap; display text shown simultaneously
- Volume respects system volume; no override

#### 2.5 Quest Screen Polish
- Animated entrance for quest card: slide up from bottom + fade in, 400ms, `Curves.easeOutCubic`
- Urdu hook text (`urduHook` field): larger font size (28sp), `NotoNastaliqUrdu`, RTL, gold colour `0xFFFFD700`
- Quest title: `Nunito`, bold, 22sp

#### 2.6 Screen Transitions
- Home → Game: `SlideTransition` left-to-right, 350ms
- Game → Quest: `FadeTransition`, 300ms
- All screens → Home (back): `SlideTransition` right-to-left

### Output files
- `sitara_app/lib/widgets/symbol_card_widget.dart`
- `sitara_app/lib/screens/game_screen.dart`
- `sitara_app/lib/screens/quest_screen.dart`
- `sitara_app/lib/models/phrase_pool.dart` (new)
- `sitara_app/pubspec.yaml` (add `confetti` package)

---

## Track 3 — Analytics, Retention & Research-Backed Session Limits

### Skills: `product-tracking-skills:product-tracking-implement-tracking` + `amplitude:add-analytics-instrumentation`

### Research Basis

Session duration limits are grounded in peer-reviewed evidence:

- Children with ASD aged 8–10 have an **attention span of 10–15 minutes** ([Diomampo et al., 2025, Journal of Education, Learning, and Management](https://consensus.app/papers/details/e5873420a4dc5e83b3860dbf4e2b25aa/?utm_source=sitara_research)) → informs 15-minute total session cap
- WHO/AAP and [Panjeti-Madan et al., 2023](https://consensus.app/papers/details/f52b2f9436d050b3a35f6eccd369a389/?utm_source=sitara_research) recommend **≤60 minutes/day** total screen time for ages 3–8 → informs daily limit shown to parents
- Longer screen time correlates with more severe ASD symptoms in younger children ([Dong et al., 2021, Frontiers in Psychiatry](https://consensus.app/papers/details/736408fae6df596e9a98f6c59593417d/?utm_source=sitara_research)) → supports mandatory break enforcement

### Requirements

#### 3.1 Interaction Caps (Two-Clock System)

Two independent timers run simultaneously during a game session:

| Timer | Duration | What fires |
|---|---|---|
| **Round timer** | 60 seconds | `send_break_prompt` overlay (gentle break after each round) |
| **Session timer** | 15 minutes | Full session end screen: "Great job! Come back soon" |

- Both timers are **separate from** the 30s Therapy Director heartbeat
- Round timer resets when the child dismisses the break overlay
- Session timer does not reset — it counts total elapsed play time per day
- If agent fires `send_break_prompt` before 60s, round timer resets from that point
- `interaction_cap_hit` event fired when round timer triggers (not agent)
- `session_cap_hit` event fired when 15min session timer triggers

#### 3.2 Daily Usage Counter

- `LocalDbService` stores `daily_play_minutes` keyed by date
- Parent Dashboard shows: `"Today: X min / 60 min recommended"` with a progress bar
- At 45 minutes, a soft warning appears in Parent Dashboard (not in-game — no anxiety for child)
- At 60 minutes, a gentle "Zara has had a great day of learning!" message replaces the play button

#### 3.3 Game Event Instrumentation

All events stored to `LocalDbService` and exportable as JSON from Parent Dashboard.

| Event | Properties | Fired from |
|---|---|---|
| `card_tapped` | `symbol_id`, `correct`, `response_time_ms`, `category`, `difficulty` | `game_screen.dart` tap handler |
| `reward_triggered` | `reward_type`, `milestone`, `success_rate_at_trigger`, `triggered_by` (agent/cap) | `_applyAction()` |
| `difficulty_adjusted` | `old_difficulty`, `new_difficulty`, `trigger` (agent/heuristic), `consecutive_failures` | `_applyAction()` |
| `break_shown` | `trigger` (agent/round_cap), `session_minutes`, `consecutive_failures` | break overlay mount |
| `quest_started` | `category`, `difficulty`, `quest_title` | `quest_screen.dart` init |
| `quest_completed` | `category`, `completion_rate`, `time_spent_secs` | quest completion handler |
| `agent_session_eval` | `mode` (agentic/baseline/offline), `success_rate`, `actions_taken`, `session_minutes` | `evaluateSession()` |
| `interaction_cap_hit` | `round_number`, `session_minutes` | round timer callback |
| `session_cap_hit` | `total_minutes`, `total_cards_attempted` | session timer callback |
| `daily_limit_approached` | `minutes_today`, `threshold` (45/60) | daily counter check |

#### 3.4 Retention Metrics in Parent Dashboard

Wire existing `SessionTracker` fields to visible dashboard cards:

| Metric | Source | Display |
|---|---|---|
| Best streak | `_tracker.bestStreak` | Already shown — keep |
| Retry rate | `card_tapped` events where `correct=false` followed by same `symbol_id` | "Tried again: X times" |
| Avg response time | `card_tapped.response_time_ms` mean | "Avg response: Xs" |
| Agent vs baseline win rate | `agentAvgSuccess` vs `baselineAvgSuccess` | Comparison card (already in dashboard) |
| Daily minutes | `daily_play_minutes` from `LocalDbService` | Progress bar vs 60min |

#### 3.5 Event Export

- Extend existing "Export Agent Traces" button in Parent Dashboard to export **both** trace JSON and game events JSON
- Two separate downloads: `sitara_traces_YYYY-MM-DD.json` and `sitara_events_YYYY-MM-DD.json`
- Format matches what hackathon judges expect for Antigravity trace submission

### Output files
- `sitara_app/lib/models/game_event.dart` (new — event schema)
- `sitara_app/lib/services/analytics_service.dart` (new — event store + export)
- `sitara_app/lib/screens/game_screen.dart` (instrument events + two-clock system)
- `sitara_app/lib/services/antigravity_service.dart` (instrument `agent_session_eval`)
- `sitara_app/lib/screens/parent_dashboard.dart` (daily counter + retention cards + dual export)

---

## Implementation Order

Given the three tracks, implement in this sequence to avoid conflicts:

1. **Track 1 (Accessibility)** — touches widgets and layout; do first so Track 2 animations build on correct structure
2. **Track 2 (Game Feel)** — adds animation controllers and new widgets on top of Track 1 fixes
3. **Track 3 (Analytics)** — instruments existing code; do last to capture events from Track 2's new interactions

---

## Files Changed Summary

| File | Track |
|---|---|
| `lib/main.dart` | ✅ Done (font preload) |
| `lib/widgets/symbol_card_widget.dart` | 1, 2 |
| `lib/screens/game_screen.dart` | 1, 2, 3 |
| `lib/screens/home_screen.dart` | 1 |
| `lib/screens/quest_screen.dart` | 2 |
| `lib/screens/onboarding_screen.dart` | 1 |
| `lib/screens/parent_dashboard.dart` | 1, 3 |
| `lib/screens/splash_screen.dart` | 1 |
| `lib/models/phrase_pool.dart` | 2 (new) |
| `lib/models/game_event.dart` | 3 (new) |
| `lib/services/analytics_service.dart` | 3 (new) |
| `lib/services/antigravity_service.dart` | 3 |
| `pubspec.yaml` | 2 (add confetti) |

---

## Research References

1. [Diomampo et al. (2025) — Technology use and ASD development, JELM](https://consensus.app/papers/details/e5873420a4dc5e83b3860dbf4e2b25aa/?utm_source=sitara_research) — 10–15 min attention span for ASD children aged 8–10
2. [Panjeti-Madan et al. (2023) — Screen time impact on development, Multimodal Technol. Interact.](https://consensus.app/papers/details/f52b2f9436d050b3a35f6eccd369a389/?utm_source=sitara_research) — ≤60 min/day recommended for ages 3–8
3. [Dong et al. (2021) — Screen time and ASD symptom severity, Frontiers in Psychiatry](https://consensus.app/papers/details/736408fae6df596e9a98f6c59593417d/?utm_source=sitara_research) — Longer screen time → more severe ASD symptoms in younger children
4. [Ophir et al. (2023) — Screen time and ASD meta-analysis, JAMA Network Open](https://consensus.app/papers/details/752693ae9b6257409523053ef6767eb4/?utm_source=sitara_research) — Mixed evidence; emphasises importance of content quality over duration alone
