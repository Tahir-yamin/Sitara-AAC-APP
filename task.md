# Sitara QA Remediation Checklist

## Critical & High Priority (Audio/TTS)
- `[x]` #17: Call `_tts.speak` for Agent reward in `game_screen.dart`
- `[x]` #18: Add audio feedback for wrong answers (`mehnat.mp3`) in `game_screen.dart`
- `[x]` #10: Remove hardcoded 1500ms delay, use `onPlayerComplete` stream in `tts_service.dart`
- `[x]` #11: Make `_onCardTapped` async and await `_speakPraiseUrdu` in `game_screen.dart`
- `[x]` #15, #21: Wire up orphaned audio assets (`shabash.mp3`, `bohat_acha.mp3`, `zabardast.mp3`) in `phrase_pool.dart`

## High & Med Priority (State & Safety)
- `[x]` #1: Add `AnalyticsService` to `MultiProvider` in `main.dart` & `game_screen.dart`
- `[x]` #2: Guard `_p` getter in `local_db_service.dart`
- `[x]` #3: Wrap `jsonDecode` with try-catch in `local_db_service.dart`
- `[x]` #7: Wrap `jsonEncode` with try-catch in `local_db_service.dart`
- `[x]` #4: Fix `_buildWeekSummary` dead code logic in `antigravity_service.dart`
- `[x]` #5: Remove hardcoded `'dev-token-sitara'` default in `antigravity_service.dart`
- `[x]` #6: Use `fold` instead of `reduce` in `_summariseEvents` in `antigravity_service.dart`

## Medium & Low Priority (TTS Formatting)
- `[x]` #9: Remove `.replaceFirst('audio/', 'audio/')` in `tts_service.dart`
- `[x]` #12: Remove female fallback pitch manipulation in `tts_service.dart`
- `[x]` #13: Use `en-PK` or `en-IN` instead of `en-US` in `_setEnglishProfile`
- `[x]` #14: Check `v['gender'] == 'female'` in `tts_service.dart`
- `[x]` #16: Fixed singleton lifecycle (avoid calling `_audioPlayer.dispose()` in `stop()`)
- `[x]` #20: Ensure fallback uses `ur-PK` in `speakPraise`
- `[x]` #8: Wrap `_BreakOverlay` text with `GoogleFonts.notoNastaliqUrdu` in `game_screen.dart`

## Production Deployment
- `[x]` Build production release APK (`flutter build apk --release`) — **SUCCESS (50.7MB)**
