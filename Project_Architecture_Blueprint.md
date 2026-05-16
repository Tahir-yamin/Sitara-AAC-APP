# Project Architecture Blueprint: Sitara — AI Companion Game
> Last updated: 2026-05-13 | Revised after grounded review against ADK production docs.

---

## 1. Architecture Detection and Analysis

### Technology Stack
| Layer | Technology | Notes |
|-------|-----------|-------|
| Mobile App | Flutter 3.x (Android-first) | Provider for state management |
| Agent Orchestration | Google ADK + Gemini 2.0 Flash | Event-driven, A2A pattern |
| Backend API | FastAPI + uvicorn | Cloud Run deployable |
| Session Storage | `InMemorySessionService` (dev) / `DatabaseSessionService` (prod) | See §5 |
| Local Persistence | SQLite via `sqflite` + Hive | Offline-first, no internet required |
| Animations | Lottie | Reward sequences |
| Audio | `audioplayers` + `flutter_tts` | Urdu TTS + pre-recorded files |

### Architectural Patterns
- **Backend:** **Multi-Agent Orchestration (Event-Driven)** with true **Agent-to-Agent (A2A)** delegation.
- **Frontend:** **MVVM** using Provider; `AntigravityService` acts as the ViewModel bridging Flutter to ADK.

---

## 2. Architectural Overview

Sitara's architecture follows a **Sense → Reason → Act** loop:

1. **Sense:** Flutter's `SessionTracker` captures interaction events every 30 seconds (tap speed, success rate, consecutive failures) — no camera, no biometrics.
2. **Reason:** The ADK backend runs the **Therapy Director** as the orchestrating agent. It reasons using the `OBSERVE → INFER → DECIDE → ACT → LOG` protocol and delegates to sub-agents as needed.
3. **Act:** The backend returns structured `AdaptationActions` which the Flutter app applies immediately (switch category, trigger reward, load quest).

---

## 3. Corrected Architecture: True A2A Orchestration

> **Critical fix from review:** The original design described three independently-called agents. The correct ADK pattern is one **orchestrating agent** (Therapy Director) that **delegates** to a **sub-agent** (Story Weaver) via a tool call. Progress Guardian remains independently triggered by the parent dashboard.

```
Flutter App (every 30s)
    │
    ▼ POST /evaluate-session
FastAPI Backend
    │
    ▼
Therapy Director (Orchestrator — LlmAgent)
    │
    │  OBSERVE → get_session_state()
    │  INFER  → frustration / engagement / plateau
    │  DECIDE → single adaptation
    │
    ├─[frustration]─► switch_category() + trigger_reward()   [direct tools]
    │
    ├─[engagement]──► adjust_difficulty()                    [direct tool]
    │
    ├─[milestone]───► generate_quest_via_story_weaver()      [A2A tool]
    │                        │
    │                        ▼
    │                 Story Weaver (Sub-Agent — LlmAgent)
    │                        │ Generates personalised Urdu-English quest JSON
    │                        ▼
    │                 Returns Quest to Therapy Director
    │
    └─[always]──────► log_insight()                          [feeds Progress Guardian]

Progress Guardian (Independent — triggered by parent dashboard weekly)
    │  Reads log_insight() history
    └─► Generates warm parent report
```

### Why this matters for judging
ADK hackathon evaluation specifically looks for **A2A orchestration** — one agent delegating to another — not three isolated agents called by an API router. The `generate_quest_via_story_weaver` tool registered on the Therapy Director is the mechanism that achieves this. It is visible as a distinct sub-call in the ADK trace panel.

---

## 4. Core Architectural Components

### Agent 1: Therapy Director (Orchestrator)
- **Role:** Sole entry point for every session evaluation. Owns the reasoning loop.
- **Protocol:** `OBSERVE → INFER → DECIDE → ACT → LOG` (visible in Trace Panel).
- **Tools (direct):** `get_session_state`, `switch_category`, `adjust_difficulty`, `trigger_reward`, `send_break_prompt`, `log_insight`.
- **Tools (A2A):** `generate_quest_via_story_weaver` — delegates to Story Weaver and receives structured JSON back.
- **Constraint:** Max **one adaptation per 60-second window** to avoid overwhelming the child.

### Agent 2: Story Weaver (Sub-Agent)
- **Role:** Narrative generation on delegation from Therapy Director.
- **Output:** Structured JSON `{quest_title, story_text, target_category, character, urdu_hook, difficulty}`.
- **Cultural signature:** Urdu words mixed naturally (chai, mango, billi, Eid, Mubarak ho).
- **Invocation:** Via `generate_quest_via_story_weaver()` on Therapy Director **or** directly via `POST /generate-quest` at session start.

### Agent 3: Progress Guardian (Independent)
- **Role:** Synthesises multi-session `log_insight` data into parent-facing reports.
- **Trigger:** Weekly or on-demand from parent dashboard (`POST /weekly-report`).
- **Tone rules:** Never clinical. Frame as "communication journey". Evidence-backed (cites real numbers).
- **Report sections:** Warm greeting → Wins → Preferences → Gentle observations → Home activity → Next week → Encouragement close.

---

## 5. Session Persistence Strategy

> **Critical fix from review:** `InMemorySessionService` silently drops session history when Cloud Run scales to multiple instances. Flutter's 30-second heartbeat will hit different instances, causing the Therapy Director to forget its own prior adaptations — breaking the "one adaptation per 60s" rule.

| Environment | Service | Config |
|-------------|---------|--------|
| Local dev / demo | `InMemorySessionService()` | Zero setup |
| Cloud Run production | `DatabaseSessionService(db_url="sqlite:///./sitara_sessions.db")` | Add `aiosqlite` to requirements.txt |

**Switch:** In `agent.py`, comment out `InMemorySessionService` and uncomment `DatabaseSessionService` before `gcloud run deploy`.

All runners (`therapy_runner`, `story_runner`, `report_runner`) share a **single** session service instance — critical for cross-agent session visibility.

---

## 6. Architectural Layers and Dependencies

```
┌─────────────────────────────────────────────────────┐
│              Flutter App (Presentation)              │
│  GameScreen → AntigravityService → SessionTracker   │
│  ParentDashboard → AntigravityService               │
└──────────────────────┬──────────────────────────────┘
                       │ HTTP/JSON (REST)
┌──────────────────────▼──────────────────────────────┐
│        FastAPI Backend (Orchestration Layer)         │
│  /evaluate-session → therapy_runner                 │
│  /generate-quest   → story_runner (direct)          │
│  /weekly-report    → report_runner                  │
└──────────────────────┬──────────────────────────────┘
                       │ ADK SDK
┌──────────────────────▼──────────────────────────────┐
│          Google ADK Agent Layer                      │
│  LlmAgent × 3  |  Runner × 3  |  SessionService × 1│
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│              Data Layer                              │
│  SQLite (offline session history, symbol cards)     │
│  Firestore (planned: cloud sync, therapist portal)  │
└─────────────────────────────────────────────────────┘
```

---

## 7. Cross-Cutting Concerns

| Concern | Implementation |
|---------|----------------|
| **Privacy** | No camera or biometrics. Frustration inferred from tap speed + consecutive failures only. |
| **Offline resilience** | `_localFallback()` in `antigravity_service.dart` provides rule-based adaptation when API is unreachable. SQLite stores symbols and session history locally. |
| **Cultural grounding** | Urdu / Roman Urdu / English labels on every card. Story Weaver mixes language naturally. Audio uses Pakistani-accent TTS. |
| **Trace observability** | Every agent call produces a structured trace log visible in the in-app Agent Trace Panel. ADK `enable_tracing=True` exposes OBSERVE/INFER/DECIDE/ACT/LOG steps to judges. |
| **Single adaptation rule** | Therapy Director enforces max one tool call per 60-second evaluation window to prevent overwhelming the child. |

---

## 8. Technology-Specific Patterns

### ADK Patterns
- **LlmAgent** for each role (instruction + tools + model).
- **Runner** wraps each agent; all share one `session_service`.
- **A2A delegation** via a Python tool wrapper (`generate_quest_via_story_weaver`) that calls `_story_runner_internal` internally.
- **Session continuity** requires `DatabaseSessionService` in multi-instance Cloud Run deployments.

### Flutter Patterns
- **Provider** for `AntigravityService` and `SessionTracker` (injected at `MultiProvider` root).
- **Timer.periodic** drives the 30-second agent heartbeat from `GameScreen`.
- **`_applyAction()`** dispatch pattern maps agent action strings to UI mutations.

---

## 9. Testing Architecture

| Test Type | Scope | Approach |
|-----------|-------|----------|
| Unit | `_summariseEvents`, `_countConsecutiveFails` | Dart unit tests in `agent_service_test.dart` |
| Integration | Full `/evaluate-session` → agent loop | FastAPI test client with mock session state |
| Agent trace | A2A handoff visible in trace output | Verify `generate_quest_via_story_weaver` appears in trace log |
| Offline fallback | No internet → local rules fire | Mock `http.post` to throw exception, assert fallback actions returned |

---

## 10. Blueprint for New Development

### Adding a New Agent (e.g., Vocabulary Coach)
1. Define the system prompt as a constant in `agent.py`.
2. Create a `LlmAgent` instance with its tools.
3. Register a `Runner` using the shared `session_service`.
4. If it is a **sub-agent**, wrap it in a Python tool function and register that function on the orchestrating agent's tools list (A2A pattern).
5. If it is **independently triggered**, add a new FastAPI endpoint.
6. Mirror the tool schema in `antigravity_agents.md` for documentation consistency.

### Agent Design Rules
- **Orchestrators:** Follow `OBSERVE → INFER → DECIDE → ACT → LOG`. One action per window.
- **Sub-agents:** Return structured JSON only. No ambiguous prose outputs.
- **All tools:** Return `{"status": "success"|"logged", "action": "<name>", ...}` consistently.

### Common Pitfalls to Avoid
| Pitfall | Consequence | Fix |
|---------|-------------|-----|
| Multiple `session_service` instances | Cross-agent state loss | One shared instance, passed to all Runners |
| `InMemorySessionService` in Cloud Run | Adaptation state lost between instances | Use `DatabaseSessionService` for deployment |
| Three agents as isolated FastAPI calls | Judges see no A2A pattern | At least one agent must delegate to another via a tool |
| Agent tool returns unstructured text | Flutter parse failure | All tools return typed dicts; sub-agents return JSON |

---

*Generated: 2026-05-13 | Revised with ADK production session docs and A2A orchestration pattern.*
