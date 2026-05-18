# Development & Quality Assurance Session Summary (May 17-18, 2026)

## 🌟 Project: Sitara Augmentative & Alternative Communication (AAC) App

This document serves as the comprehensive session log containing all key improvements, verified QA statuses, and live deployment coordinates. Use this to instantly recall the project state in future sessions.

---

## 🌐 Deployed Coordinates & Builds

*   **Live Firebase Web App**: 🔗 **[https://sitara-v1.web.app/](https://sitara-v1.web.app/)**
*   **Production Release APK**: `D:\my-dev-knowledge-base\sitara\sitara_app\build\app\outputs\flutter-apk\app-release.apk` *(File Size: 50.7 MB)*
*   **FastAPI Backend on Cloud Run**: `https://sitara-backend-178558547254.asia-south1.run.app`

---

## ⚙️ Key Technical Implementations

### 1. High-Quality Pakistani Female Voice (Appreciation Audio)
*   **The Issue**: The device-level `flutter_tts` defaulted to robotic or male voices for Urdu because web browsers and standard Android TTS engines lack high-quality localized Urdu models.
*   **Audio Assets Integration**:
    *   Pre-generated 15 highly realistic, female, Pakistani-accented MP3 audio files for all gameplay praise phrases (e.g., "Shabash!", "Bohat acha!", "Zabardast!", "Mehnat karo").
    *   Linked `audioplayers` package inside `pubspec.yaml` to handle multi-platform playback.
*   **Web App Support (Fixed in Final Pass)**:
    *   Removed early-return `if (kIsWeb)` blocks from `TtsService.speakPraise()`. The live Firebase web application now plays high-quality MP3 assets natively using the browser HTML5 audio element instead of falling back to robotic English-engine Roman Urdu TTS.
*   **AI Therapist Adaptive Reward Mapping**:
    *   Added a robust `PhrasePool.findPhrase(String text)` normalizer helper that maps arbitrary praise phrases from the AI therapist backend (`trigger_reward`) to pre-recorded female audio files.
    *   Wired `trigger_reward` inside `game_screen.dart` to trigger the matched pre-recorded audio natively, enabling the AI voice to sound authentic and warm on both mobile and web.

### 2. Audio Lifecycles & QA Fixes
*   **Singleton AudioPlayer Survival (Fixed)**: Discovered and removed a fatal bug where `_audioPlayer.dispose()` was called in `stop()`, crashing subsequent game sessions. The AudioPlayer singleton now safely calls `stop()` and survives indefinitely.
*   **Wired Orphaned Constants**: Connected `PhrasePool.shabash`, `PhrasePool.bohatAcha`, and `PhrasePool.zabardast` directly into the `_good` and `_great` gameplay pools so they are triggered naturally during gameplay.
*   **Multi-Audio Overlap Protection**: Made card tapping asynchronous and awaited praise voiceovers before initiating the next round's cards and target voiceovers, preventing audio streams from overlapping.
*   **Corrected Tap Speed Calculations**: Replaced fragile `.reduce` operations with a highly robust `.fold` accumulator to protect stats screens from crashing on empty tap histories.

### 3. Backend, Security & State Hardening
*   **API Key Purge**: Wiped all legacy testing scripts and permanently removed hardcoded Google API keys from Git history using `git filter-repo`.
*   **Backend Authentication**: Implemented and injected `X-Sitara-Token` header verification middleware between the Flutter frontend (`AntigravityService`) and FastAPI backend (`agent.py`).
*   **Privacy-Safe Onboarding**: Replaced real name transmissions with a privacy-safe 8-character hex ID generation for all `child_id` fields.
*   **Rate-Limit Fallback Resilience**: Resolved 429 quota exhaustion errors by moving backend weekly report generation from `gemini-2.0-flash` to `gemini-1.5-flash` for high-throughput resilience.
*   **Global State Scope**: Refactored `main.dart` to expose `AnalyticsService` globally via a `ProxyProvider` bound to `SessionTracker`.

---

## 🚦 Verification & Quality Gates

*   ✅ **`flutter analyze`** ➔ **0 issues found** (100% clean codebase).
*   ✅ **`flutter test`** ➔ **14/14 unit tests passed** (100% success rate).
*   ✅ **CI/CD Deployment** ➔ Verified GitHub Actions run #20 completed successfully, compiling the web app and pushing it to Firebase Hosting automatically.

---

## 📝 Future Recall Instructions
When starting a future session, check:
1.  **[walkthrough.md](file:///D:/my-dev-knowledge-base/sitara/walkthrough.md)**: Contains the visual verification screenshots and latest build information.
2.  **[sitara_qa_audit_report.md](file:///D:/my-dev-knowledge-base/sitara/sitara_qa_audit_report.md)**: Lists all 19 confirmed claims and implementation evidence.
3.  **Repository Branch**: Work directly on `main` branch to push features and deploy to the live site.
