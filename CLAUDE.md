# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**Sitara** is a Google Antigravity Hackathon submission (#AISeekho2026). It is an agentic mobile game for non-verbal autistic children in Pakistan, powered by Google ADK (Agent Development Kit) + Gemini 2.0 Flash. The app adapts in real time to child behaviour using multi-agent orchestration.

Two codebases live here:
- `adk_backend/` — Python FastAPI backend with Google ADK agents
- `sitara_app/` — Flutter Android app

---

## Backend: adk_backend/

### Run locally
```bash
cd adk_backend
pip install -r requirements.txt        # or activate venv first
uvicorn agent:app --reload --port 8000
# Docs: http://localhost:8000/docs
```

### Test endpoints manually
```bash
curl -X POST http://localhost:8000/evaluate-session \
  -H "Content-Type: application/json" \
  -d '{"child_id":"zara_001","success_rate":0.28,"consecutive_failures":4,"tap_speed":3.1,"category":"emotions","session_duration_mins":8}'

curl -X POST http://localhost:8000/generate-quest \
  -H "Content-Type: application/json" \
  -d '{"child_id":"zara_001","child_name":"Zara","preferred_category":"animals","difficulty":"easy"}'

curl http://localhost:8000/health
```

### Test scripts
```bash
python test_local.py          # local full flow
python test_endpoints.py      # endpoint-level tests
python verify_backend.py      # backend verification
python test_adk_quota.py      # quota/429 handling
```

### Deploy to Cloud Run
```bash
# Linux/Mac
./deploy_cloud_run.sh

# Windows PowerShell
./deploy_cloud_run.ps1
```

### Environment variables
Create `.env` in `adk_backend/`:
```
GOOGLE_API_KEY=your_key_here       # from aistudio.google.com
ALLOWED_ORIGINS=*                  # or specific domain for prod
ENV=development                    # set to "production" for Cloud Run
PORT=8000                          # Cloud Run injects this automatically
```

---

## Flutter App: sitara_app/

### Run
```bash
cd sitara_app
flutter pub get
flutter run                         # connects to local backend by default
flutter build apk --debug           # APK for demo/submission
```

### Test & lint
```bash
flutter test test/agent_service_test.dart   # single test
flutter test                                # all tests
flutter analyze                             # static analysis (flutter_lints)
```

### State management
Uses **Provider** (`provider: ^6.1.1`). No BLoC or Riverpod.

---

## Architecture

### Sense → Reason → Act loop

1. Flutter's `SessionTracker` collects tap events and sends a `POST /evaluate-session` to the backend every 30 seconds.
2. The **Therapy Director** (orchestrating `LlmAgent`) runs `OBSERVE → INFER → DECIDE → ACT → LOG` and calls tools.
3. Adaptation actions are returned as a list; `game_screen.dart` dispatches them via `_applyAction()`.

### Agent hierarchy (critical for judges)

```
POST /evaluate-session
    └── Therapy Director (Orchestrator)
            ├── get_session_state, switch_category, adjust_difficulty,
            │   trigger_reward, send_break_prompt, log_insight  [direct tools]
            └── generate_quest_via_story_weaver()               [A2A delegation]
                        └── Story Weaver (Sub-Agent)
                                └── returns Quest JSON to Therapy Director

POST /generate-quest → Story Weaver (called directly at session start)
POST /weekly-report  → Progress Guardian (independent, called from parent dashboard)
```

The A2A handoff via `generate_quest_via_story_weaver` is the key differentiator for judges — it makes this a true multi-agent system, not three isolated API calls.

### Session IDs
- Therapy sessions: `therapy_{child_id}`
- Story sessions: `story_{child_id}`
- Report sessions: `report_{child_id}`

All three runners share **one** `session_service` instance (defined in `agent.py`). Never create separate session services.

### Session service — when to switch
| Environment | Service | Why |
|-------------|---------|-----|
| Local / demo | `InMemorySessionService` | Zero setup |
| Cloud Run | `DatabaseSessionService(db_url="sqlite+aiosqlite:///./sitara_sessions.db")` | Survives instance restarts; Flutter's 30s heartbeat can hit different instances |

`agent.py` defaults to `DatabaseSessionService` with fallback to `InMemorySessionService` if init fails.

### Flutter core wiring
- `AntigravityService` (`services/antigravity_service.dart`) — all agent API calls + local fallback
- `SessionTracker` — collects `SessionEvent` objects, provides them to `AntigravityService`
- `GameScreen` — runs `Timer.periodic(30s)` to call `evaluateSession()`, then dispatches actions via `_applyAction()`
- `AgentTraceWidget` — judge-facing overlay toggled by the brain icon in the AppBar

### Offline fallback
`_localFallback()` in `AntigravityService` returns rule-based adaptations when the API is unreachable. This is critical for Pakistan connectivity.

---

## Implementing Changes

### Adding a tool to Therapy Director
1. Define a Python function with a typed signature and docstring in `agent.py`.
2. Add it to the `tools=[...]` list on the `therapy_director` `LlmAgent`.
3. All tools must return `{"status": "success"|"logged", "action": "<name>", ...}`.
4. Add a matching case in `_applyAction()` in `game_screen.dart`.
5. Mirror the schema in `antigravity_agents.md`.

### Adding a new agent
- Sub-agent (called by Therapy Director): create `LlmAgent` → wrap in a `Runner` using the shared `session_service` → write an `async def` tool function → register on Therapy Director's `tools` list.
- Independent agent: create `LlmAgent` + `Runner` + new FastAPI endpoint.

### Frustration signals (do not change thresholds without reason)
| Signal | Threshold |
|--------|-----------|
| `consecutive_failures` | ≥ 3 |
| `tap_speed` | > 3.0 taps/sec |
| Inactivity | > 30 seconds |
| Long session + low success | > 15 min + success_rate < 0.6 |

**Maximum one Therapy Director adaptation per 60-second window** — enforced in the prompt and by Flutter's timer.

---

## Quota / 429 Handling

`agent.py` implements a `quota_cooldowns` dict. When a 429 is caught, `trigger_cooldown(child_id)` blocks further API calls for 60 seconds and routes to `get_heuristic_adaptation()` — a rule-based fallback that keeps the game playable.

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `adk_backend/agent.py` | All agents, tools, runners, FastAPI endpoints |
| `adk_backend/requirements.txt` | Python deps |
| `adk_backend/Dockerfile` | Cloud Run container |
| `sitara_app/lib/services/antigravity_service.dart` | Flutter ↔ backend bridge |
| `sitara_app/lib/screens/game_screen.dart` | 30s timer, `_applyAction()` dispatch |
| `sitara_app/lib/widgets/agent_trace_widget.dart` | Judge-facing AI trace panel |
| `sitara_app/lib/data/symbols_data.dart` | 50 symbol cards (hardcoded) |
| `antigravity_agents.md` | Agent system prompts + tool schemas (source of truth for prompts) |
| `Project_Architecture_Blueprint.md` | Reviewed architecture doc (May 13, 2026) |

---

## Hackathon Requirements (Challenge 4 — Official FAQ, May 2026)

### Key Dates
| Date | Milestone |
|------|-----------|
| **May 15, 2026** | Challenge/idea selection deadline (PASSED) |
| **May 20, 2026** | Final project submission deadline |
| May 25–26, 2026 | Virtual Regional Pitching Rounds |
| June 7, 2026 | National Finale — Islamabad |

### Hard Rules
- APK only — PWAs are **not** acceptable.
- Project must be built from scratch in Antigravity; no pre-existing MVPs.
- Mobile app is **mandatory**; web app is optional.
- Demo video: **~3 minutes** for Challenge 4.
- Minimum team: 2 members; maximum: 5.

### What Must Be in the Submission
| Deliverable | Status |
|-------------|--------|
| Working APK | build with `flutter build apk --debug` |
| Demo video (~3 min) | see `demo_script_readme.md` |
| Antigravity traces/logs | exported from Agent Trace Panel |
| README with architecture, Antigravity role, APIs, cost/latency, scalability, baseline comparison, privacy note | `demo_script_readme.md` is complete |
| **Baseline comparison** (agentic vs fixed-rule) | **DONE** — implemented via `FixedRuleEngine` and app toggle |
| Robustness evidence (failure/edge case demo) | **DONE** — quota fallback + parse error fallback implemented |
| Cost and scalability note | **DONE** — detailed in `demo_script_readme.md` |

### Challenge 4 Evaluation Weights
| Criterion | Weight |
|-----------|--------|
| Antigravity integration | 25% |
| Gameplay engagement and retention | 25% |
| Agentic innovation | 20% |
| Technical polish | 15% |
| Originality and creativity | 10% |
| Comparative proof bonus | +5% |

### Gaps vs Current Implementation (Status: All Core Logic Integrated)
1. **Baseline comparison** — **DONE**. Implemented in `FixedRuleEngine` (backend) and `_useHeuristic` toggle (app). Comparison card in Parent Dashboard tracks win rates.
2. **Quality-control agent** — **DONE**. `_validate_quest` function in `agent.py` performs content validation before quest delivery.
3. **Retention metrics** — **DONE**. `SessionTracker` (Dart) and `log_insight` (Python) track retry rates, churn risk, and engagement spikes.
4. **Engagement adaptive signals** — **DONE**. 5 signals implemented: `consecutive_failures`, `tap_speed`, inactivity, session duration, success rate.
5. **Cost/latency note** — **DONE**. Included in `demo_script_readme.md`.

### Antigravity Integration Checklist (from FAQ §Q17 / §Q20)
- [x] Antigravity as primary orchestrator (Therapy Director)
- [x] Tool calling with clear parameters and traces
- [x] A2A delegation (Therapy Director → Story Weaver)
- [x] Visible reasoning trace in-app (Agent Trace Panel)
- [x] Fallback/recovery behavior (quota cooldown + heuristic fallback)
- [x] Quality Control validation step for agent output
- [x] Explicit failure + error recovery scenario shown in code/tests

---

## Hackathon Submission Checklist

See `Project_Architecture_Blueprint.md §10` for the ADK requirements checklist and demo video shot list.

Symbol image assets use [Mulberry Symbols](https://mulberrysymbols.org/) (CC BY-SA 4.0).
