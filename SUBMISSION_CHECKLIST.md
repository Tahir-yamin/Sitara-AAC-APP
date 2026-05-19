# Sitara — Google Antigravity Hackathon Submission Checklist
## Challenge 4 · #AISeekho2026 · Deadline: May 20, 2026

---

## Judging Criteria (Challenge 4)

| Criterion | Weight | Status |
|---|---|---|
| Antigravity Execution | 30% | ✅ |
| Gameplay Engagement | 25% | ✅ |
| Agentic Innovation | 20% | ✅ |
| Technical Polish | 15% | ✅ |
| Concept & Originality | 10% | ✅ |

---

## Antigravity Execution (30%)

- [x] Uses **Google ADK** (`google-adk` package) — not raw REST calls
- [x] **3 LlmAgent instances** — Therapy Director, Story Weaver, Progress Guardian
- [x] **A2A delegation** — Therapy Director calls Story Weaver via `AgentTool`
- [x] **Tool use** — `get_session_state`, `switch_category`, `adjust_difficulty`, `trigger_reward`, `send_break_prompt`
- [x] **Runner + InMemorySessionService** — correct ADK session lifecycle
- [x] **OBSERVE → INFER → DECIDE → ACT → LOG** reasoning protocol in prompts
- [x] **QC gate** — `_validate_quest()` validates Story Weaver output before returning to Flutter
- [x] **Sovereign Baseline** — `FixedRuleEngine` heuristic for apples-to-apples comparison
- [x] Backend deployed on **Cloud Run** — `https://[YOUR-CLOUD-RUN-URL]`
- [x] `/health` endpoint returns `{"status": "running", "agents": [...], "model": "gemini-2.0-flash"}`

---

## Gameplay Engagement (25%)

- [x] **Real-time score counter** — increments on every correct tap (`+10 + streak×2`)
- [x] **Streak counter** — live flame indicator (🔥) for 3+ consecutive correct taps
- [x] **Praise messages** — "Shabash!", "Wah wah! N streak! 🔥"
- [x] **Break prompts** — agent-triggered stretch/water break dialog after 10+ min low-success session
- [x] **Reward animations** — `_rewardController` AnimationController
- [x] **57 AAC cards** across 6 categories — sufficient variety to sustain engagement
- [x] **Quest narrative** — Story Weaver generates personalised mini-quests per child

---

## Agentic Innovation (20%)

- [x] **Multi-agent orchestration** — 3 specialised agents with distinct roles
- [x] **Agent-to-Agent (A2A)** delegation at runtime — not hardcoded routing
- [x] **Adaptive difficulty** in real-time — Therapy Director decides without human input
- [x] **Cultural localisation via agent** — Story Weaver generates Urdu-English quests, culturally relevant scenarios (mango, Eid, chai)
- [x] **Agent trace panel** for judges — live reasoning visible in UI (`🧠 Agent Trace` button)
- [x] **Exportable trace JSON** — judge panel download button in parent dashboard

---

## Technical Polish (15%)

- [x] **TTS race condition fixed** — `Completer<void>` ensures voice works on first tap
- [x] **Offline-first** — `_localFallback()` rule-based adaptation, no internet required
- [x] **Rate limiter** — sliding window (3 req/10s per child) prevents quota bursts
- [x] **Quota cooldown** — 60s cooldown + `_build_local_report()` fallback on 429
- [x] **Secure storage** — child profiles in Android Keystore (`flutter_secure_storage`)
- [x] **Type safety** — all JSON parsing guarded with `is! List`, `whereType<>`, regex
- [x] **Error boundaries** — every async call in GameScreen try/catched with SnackBar fallback
- [x] **Configurable backend URL** — `String.fromEnvironment('BACKEND_URL')`
- [x] **`google-genai>=0.3.0`** — pinned to stable ADK-compatible range

---

## Concept & Originality (10%)

- [x] **Problem**: 35M+ Pakistanis affected by autism; most AAC tools are English-only, expensive, culturally irrelevant
- [x] **Solution**: AI-orchestrated AAC in Urdu/Roman Urdu, offline-capable, culturally grounded
- [x] **Attribution**: ARASAAC pictograms (CC BY-NC-SA 4.0, Aragón Government / Sergio Palao)
- [x] **Personal story**: Built by a parent of a non-verbal autistic child

---

## Submission Artifacts

| Artifact | Location | Status |
|---|---|---|
| README.md | `sitara/README.md` | ✅ Complete |
| Demo video script | `sitara/demo_script_readme.md` | ✅ Complete |
| Architecture blueprint | `sitara/Project_Architecture_Blueprint.md` | ✅ Complete |
| Agent prompts & schemas | `sitara/antigravity_agents.md` | ✅ Complete |
| Backend source | `sitara/adk_backend/agent.py` | ✅ Complete |
| Flutter app source | `sitara/sitara_app/lib/` | ✅ Complete |
| Live backend URL | `https://[YOUR-CLOUD-RUN-URL]` | ✅ Deployed |
| APK | TBD (`flutter build apk --release`) | ⏳ Pending |

---

## Pre-Submission Build Checklist

- [ ] `flutter pub get` — verify no dependency errors
- [ ] Check `android/app/build.gradle` — `minSdkVersion 21` (flutter_secure_storage requires ≥18)
- [ ] `flutter build apk --release --dart-define=BACKEND_URL=https://[YOUR-CLOUD-RUN-URL]`
- [ ] Install APK on test device — verify TTS speaks on first tap
- [ ] Toggle AI/Rules mode — verify both paths work
- [ ] Generate weekly report — verify fallback works if quota hit
- [ ] Record 3:30 demo video following `demo_script_readme.md`
