# Sitara QA Issues Remediation Plan

This plan addresses all 22 reported QA issues, with immediate priority given to the critical audio/TTS bugs (#17, #18, #10).

## User Review Required

> [!WARNING]  
> The plan handles 22 issues simultaneously. Please review the proposed changes, especially the handling of audio fallbacks and the `AnalyticsService` provider approach.

## Open Questions

> [!NOTE]  
> - For `#19` (Pre-recorded voice quality unverifiable), since we don't have generation scripts, I will document this in the README or comments. If you'd rather we delete the pre-recorded assets and rely strictly on live TTS, let me know. I will assume we keep the MP3s and wire them up for now.
> - For `#22` (Voice consistency gap), if we use MP3s for praise and live TTS for card names, they will naturally sound different. To fix this, we can make the app exclusively use live TTS (flutter_tts) for praise as well. For now, I will keep the MP3s but improve the `flutter_tts` fallback.

## Proposed Changes

---
### 1. `lib/services/tts_service.dart`

Address TTS audio delays, Pakistani accent localization, and missing fallback handling:

#### [MODIFY] tts_service.dart
- **#10**: Replace `await Future.delayed(const Duration(milliseconds: 1500))` with `await _audioPlayer.onPlayerComplete.first` inside `speakPraise()`.
- **#9**: Remove the redundant `.replaceFirst('audio/', 'audio/')`.
- **#12**: Remove the `1.3` pitch manipulation for female fallback. If no female voice is found, we won't artificially distort the pitch.
- **#13**: In `_setEnglishProfile()`, check and try `en-PK` and `en-IN` before defaulting to `en-US`.
- **#14**: In voice detection, check `v['gender']?.toString().toLowerCase() == 'female'` explicitly to support OEM devices.
- **#16**: Call `await _audioPlayer.stop()` and `_audioPlayer.dispose()` gracefully where appropriate, though as a singleton, disposing isn't strictly necessary until app exit.
- **#20**: In `speakPraise` fallback, ensure we try `ur-PK` instead of hard-failing to `en-US`.

---
### 2. `lib/screens/game_screen.dart`

Address critical missing audio for agent rewards and incorrect answers, and fix async overlapping.

#### [MODIFY] game_screen.dart
- **#17**: In `_applyAction` under the `trigger_reward` case, invoke `_tts.speak(phrase, language: 'ur-PK')` so agent rewards are not completely silent.
- **#18**: In `_onCardTapped` for the incorrect answer branch, invoke `_tts.speakPraise(PhrasePool.tryAgain)` to provide audio feedback (`mehnat.mp3`) instead of just visual shake.
- **#11**: Make `_onCardTapped` an `async` function and `await _speakPraiseUrdu(phrase)` so audio streams don't overlap with the next card.
- **#8**: Wrap the Urdu text in `_BreakOverlay` with `GoogleFonts.notoNastaliqUrdu()`.
- **#1**: Switch `_analytics = AnalyticsService(...)` initialization to fetch from `context.read<AnalyticsService>()`.

---
### 3. `lib/main.dart`

#### [MODIFY] main.dart
- **#1**: Add `ProxyProvider<SessionTracker, AnalyticsService>` so `AnalyticsService` is shared across the app context rather than created per-screen.

---
### 4. `lib/models/phrase_pool.dart`

#### [MODIFY] phrase_pool.dart
- **#15, #21**: Add references to the orphaned audio assets (`mehnat.mp3`, `shabash.mp3`, `bohat_acha.mp3`, `zabardast.mp3`) inside the `PhrasePool` so they are fully wired up. Create a dedicated `tryAgain` phrase for `mehnat.mp3`.

---
### 5. `lib/services/antigravity_service.dart`

#### [MODIFY] antigravity_service.dart
- **#4**: Fix `_buildWeekSummary()` counting logic (use `a.type.contains('category')` rather than `.contains`).
- **#5**: Remove the hardcoded `'dev-token-sitara'` fallback binary string in headers. Change `defaultValue` to `''`.
- **#6**: Replace `events.map(...).reduce((a, b) => a + b)` with `events.fold(0.0, (sum, e) => sum + e.tapSpeed)` to avoid fragile reductions on empty lists.

---
### 6. `lib/services/local_db_service.dart`

#### [MODIFY] local_db_service.dart
- **#2**: Add a guard in `_p` getter, or refactor usages to `_prefs?` to prevent runtime crashes if `init()` is missed.
- **#3**: Wrap `jsonDecode` calls in `try-catch` blocks and filter out corrupted un-decodable data.
- **#7**: Wrap `jsonEncode` in `try-catch` during I/O boundaries.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure 0 issues.
- Run `flutter test` to ensure unit tests still pass (14/14).

### Manual Verification
- Verify that `mehnat.mp3` correctly plays when tapping a wrong card.
- Verify that the agent reward triggers actual TTS audio output.
- Verify praise audio waits dynamically using `onPlayerComplete` stream.
