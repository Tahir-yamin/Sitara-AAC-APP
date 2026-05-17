# Sitara Game Improvements - Complete Changelog

> **Branch:** main (merged)  
> **Date:** 2026-05-17  
> **Status:** ALL 16 TASKS COMPLETE + REVIEWED + HARDENED  
> **Flutter Analyze:** 0 issues | **Tests:** 10/10 pass  
> **Final commit:** `7a58b4c` (fix: cancel _roundTimer when session cap fires)  

---

## Summary

Three tracks of improvements were implemented across 16 tasks:

| Track | Tasks | Focus |
|-------|-------|-------|
| **Track 1: Accessibility** | 1-4 | TalkBack/screen reader support, font safety |
| **Track 2: Game Feel** | 5-11 | Animations, confetti, TTS praise, breathing breaks |
| **Track 3: Analytics** | 12-16 | Telemetry, persistence, session caps, dashboard |

---

## Track 1: Accessibility (Tasks 1-4)

### Task 1 - Semantics on SymbolCardWidget
**File:** lib/widgets/symbol_card_widget.dart | **Commit:** 5cfceef

Wrapped card widget in Semantics(label, button: true) so TalkBack reads card names aloud.

### Task 2 - Semantics on Non-Game Screens
**Files:** home_screen.dart, splash_screen.dart, onboarding_screen.dart | **Commit:** 12996e2

Added semantic labels to Play, Dashboard, splash logo, and onboarding nav buttons.

### Task 3 - Exclude Trace Panel from Semantics
**File:** game_screen.dart | **Commit:** 314df9a

Wrapped AgentTraceWidget in ExcludeSemantics. Added tooltip to brain icon.

### Task 4 - Font Scaling Safety
**File:** symbol_card_widget.dart | **Commit:** b8dc309

Added overflow: TextOverflow.ellipsis, maxLines: 1 to prevent Urdu text overflow.

---

## Track 2: Game Feel (Tasks 5-11)

### Task 5 - Confetti Dependency
**File:** pubspec.yaml | **Commit:** 000c913

Added confetti: ^0.7.0 package.

### Task 6 - Bilingual PhrasePool Praise Logic
**Files:** lib/models/phrase_pool.dart, test/unit/phrase_pool_test.dart | **Commit:** 3d0b304

Tiered praise system (good/great/amazing) based on streak count. Each phrase has displayText (Roman Urdu), ttsText (Urdu script), romanUrdu (fallback). 4 unit tests.

### Task 7 - Bounce and Shake Micro-Animations
**File:** symbol_card_widget.dart | **Commit:** e95d18d

Correct tap: bounce via Transform.scale with spring curve.
Incorrect tap: horizontal shake via Transform.translate with damped oscillation.

### Task 8 - Card Feedback Props + Female ur-PK TTS
**File:** game_screen.dart | **Commit:** cea5854

Connected PhrasePool to game loop. Speaks streak-appropriate Urdu praise via female ur-PK voice.

### Task 9 - Confetti Reward Burst
**File:** game_screen.dart | **Commit:** 961b296

Replaced SnackBar with fullscreen ConfettiWidget explosive burst (30 particles, brand colors) plus floating praise overlay.

### Task 10 - Breathing Break Overlay (24s Auto-Dismiss)
**File:** game_screen.dart | **Commit:** 03818d7

Beautiful animated breathing circle overlay. Scale pulsing 0.75x-1.15x over 4s. Auto-dismisses after 24s. Double-tap to exit.

### Task 11 - Quest Entrance Animation
**File:** quest_screen.dart | **Commit:** 28fdc09

Gold-styled Urdu hook text with Noto Nastaliq Urdu font, entrance fade-in, decorative borders.

---

## Track 3: Analytics (Tasks 12-16)

### Task 12 - GameEvent Telemetry Model
**Files:** lib/models/game_event.dart, test/unit/game_event_test.dart | **Commit:** 33b4569

10-type event enum: cardTapped, rewardTriggered, difficultyAdjusted, breakShown, questStarted, questCompleted, agentSessionEval, interactionCapHit, sessionCapHit, dailyLimitApproached, unknown.

Full JSON roundtrip with 3 unit tests.

### Task 13 - AnalyticsService + LocalDbService Persistence
**Files:** analytics_service.dart, local_db_service.dart, analytics_service_test.dart | **Commit:** acd4a57

- AnalyticsService: log, query, export game events
- LocalDbService: JSON via SharedPreferences + FlutterSecureStorage
- 1000 event FIFO cap per child
- getTodayPlayMinutes() / addPlayMinutes() for time tracking
- exportEventsAsJson() for hackathon

### Task 14 - Round Timer + Daily Session Cap
**File:** game_screen.dart | **Commit:** d80b69d, **Fix:** 7a58b4c

Round Timer (60s): `_resetRoundTimer()` resets on each card load and tap. Auto-advances after 60s inactivity. Logs `interactionCapHit`.

Daily Cap (15 min): `_initSessionCaps()` loads today minutes from SharedPreferences. Timer increments every 60s. At 15min cancels both `_sessionMinuteTimer` AND `_roundTimer`, shows bilingual end-of-session overlay ("آج کے لیے بس!" / "That's enough for today!") with Go Home button. Logs `sessionCapHit`.

**Research basis:** ASD sustained attention span 10-15 min (Diomampo et al., 2025); WHO/AAP recommends ≤60 min/day screen time ages 3-8.

**Code review fix (7a58b4c):** `_roundTimer` was not cancelled when session cap fired, leaving an orphaned timer. Fixed by adding `_roundTimer?.cancel()` in the cap handler.

### Task 15 - Full Telemetry Instrumentation
**File:** game_screen.dart | **Commit:** d80b69d

`_analytics.log()` at every gameplay endpoint — fire-and-forget (not awaited in hot paths):

| Endpoint | Event Type | Properties |
|----------|-----------|------------|
| Card tap | `cardTapped` | card_id, category, correct |
| Reward shown | `rewardTriggered` | text, streak |
| Difficulty change | `difficultyAdjusted` | cards_per_round, category |
| Break prompt | `breakShown` | session_minutes, score |
| Agent evaluation | `agentSessionEval` | actions_count, mode (agentic\|heuristic) |
| Round timeout (60s) | `interactionCapHit` | category, target |
| Session cap (15 min) | `sessionCapHit` | minutes_played |

**Mode field** differentiates agentic vs fixed-rule sessions for baseline comparison (Antigravity FAQ requirement).

### Task 16 - Daily Usage Bar + Dual Export
**File:** parent_dashboard.dart | **Commit:** d80b69d

**Daily Usage Progress Bar:** Shows "Today: X / 15 min" with `LinearProgressIndicator`. Color-coded:
- 0-69%: Teal (`0xFF43C59E`) — "X min left"
- 70-99%: Orange — "X min left"
- 100%: Red — "Done for today"

**Dual Export (Hackathon Artefact):** Single AppBar download button exports:
1. Agent reasoning traces JSON (`_agentService.exportTracesAsJson()`)
2. Analytics game events JSON, last 7 days (`_analytics.exportEventsAsJson(limitDays: 7)`)

Both printed to `debugPrint` with `[TRACE EXPORT]` and `[ANALYTICS EXPORT]` labels for `adb logcat` capture. Satisfies hackathon requirement: "Antigravity traces/logs exported from Agent Trace Panel."

---

## Files Modified

| File | Tracks |
|------|--------|
| lib/widgets/symbol_card_widget.dart | 1, 2 |
| lib/screens/home_screen.dart | 1 |
| lib/screens/splash_screen.dart | 1 |
| lib/screens/onboarding_screen.dart | 1 |
| lib/screens/game_screen.dart | 1, 2, 3 |
| lib/screens/quest_screen.dart | 2 |
| lib/screens/parent_dashboard.dart | 3 |
| lib/models/phrase_pool.dart | 2 |
| lib/models/game_event.dart | 3 |
| lib/services/analytics_service.dart | 3 |
| lib/services/local_db_service.dart | 3 |
| pubspec.yaml | 2 |

## Files Created

| File | Purpose |
|------|---------|
| lib/models/phrase_pool.dart | Bilingual praise phrase model |
| lib/models/game_event.dart | Telemetry event model |
| lib/services/analytics_service.dart | Analytics logging layer |
| test/unit/phrase_pool_test.dart | PhrasePool unit tests (4 tests) |
| test/unit/game_event_test.dart | GameEvent unit tests (3 tests) |
| test/unit/analytics_service_test.dart | AnalyticsService unit tests (2 tests) |

---

## Code Reviews & Hardening

### Task 13 Review (youthful-archimedes-88ac5b worktree)
- **Critical fix:** Test double was pulling uninitialized `LocalDbService.instance` singleton. Added `@visibleForTesting` named constructors (`AnalyticsService.withDb()`, `LocalDbService.forTesting()`).
- **Important fixes (4):** `fromKey` → `fromString` (spec alignment); play-minutes keys made per-child; dead `toJsonString()` removed; `_todayDateString()` helper extracted.
- **Minor fix:** Added 6th test covering `addMinutes` accumulation.

### Tasks 14-16 Review (main branch)
- **Important fix (7a58b4c):** `_roundTimer` not cancelled when 15-min session cap fired — orphaned timer could call `_loadCards()` + `setState()` after cap overlay. Fixed.
- **False positive resolved:** "Go Home" button correctly pops GameScreen back to HomeScreen.
- **Minor (non-blocking):** Dashboard bar is one-shot on `initState()`; property key casing could be more consistent; `_todayMinutes` staleness is low-risk behind `_sessionCapped` guard.

---

## Documentation Added

| Document | Contents |
|----------|----------|
| `antigravity_agents.md` — Track 3 section | Full GameEvent schema, AnalyticsService API, LocalDbService persistence layer, two-clock system architecture, all 7 callsites, error handling, hackathon checklist |
| `docs/superpowers/plans/subagent_execution_log.md` | Complete execution timeline with audit results for all 16 tasks |

---

## Verification

```
flutter analyze: No issues found!
flutter test: 10/10 All tests passed!
```

---

## Error Handling & Resilience

| Scenario | Defence |
|----------|---------|
| SharedPreferences unavailable | Gameplay continues without persistence; log() is guarded |
| Event store > 1000 entries | FIFO `removeRange(0, n-1000)` trim — newest 1000 retained |
| Timer leak (widget disposed) | `dispose()` cancels `_roundTimer`, `_sessionMinuteTimer`, `_agentCheckTimer` |
| Session cap + orphaned timer | `_roundTimer?.cancel()` added in cap handler (7a58b4c) |
| Multi-child household | All keys scoped to `childId` — no cross-pollution |
| Agent quota (429) | Falls back to `get_heuristic_adaptation()` — `mode: "heuristic"` logged |

---

## Final Commit History (main)

```
7a58b4c fix: cancel _roundTimer when 15-min session cap fires
dc280b1 docs: add complete game improvements changelog (16 tasks, 3 tracks)
aceb6f2 docs: mark all 16 tasks complete in execution log
d80b69d feat: add round/session caps, telemetry instrumentation, and daily usage dashboard
acd4a57 feat: add AnalyticsService + game event persistence in LocalDbService
33b4569 feat: add GameEvent model with 10-event type enum and JSON roundtrip
28fdc09 feat: add entrance animation and gold Urdu hook styling to QuestScreen
03818d7 feat: replace break AlertDialog with breathing animation overlay
961b296 feat: replace SnackBar reward with confetti burst overlay
cea5854 feat: wire card feedback props + female ur-PK TTS praise via PhrasePool
e95d18d feat: add correct bounce and incorrect shake animations to SymbolCardWidget
3d0b304 feat: add PhrasePool model with tiered Urdu praise phrases
000c913 feat: add confetti package dependency
b8dc309 feat: add font scaling safety to SymbolCardWidget text
314df9a feat: exclude trace panel from semantics tree
12996e2 feat: add semantics labels to non-game screens
5cfceef feat: add accessibility semantics to SymbolCardWidget
```

---

*Generated 2026-05-17 | Updated with code reviews, fixes, and documentation*
