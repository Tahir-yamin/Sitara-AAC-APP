# Sitara — Live Agentic Workflow Demo Trace Guide
**For Judges · Google Antigravity Hackathon · Challenge 4 · May 2026**

This guide covers `adk_backend/demo_trace.py` — a terminal tool that calls the live backend
and renders the full multi-agent orchestration in real time. It is the fastest way to verify
that the system is working and to understand what each agent is doing.

---

## What It Shows

The trace renders five sections in sequence:

| Section | What Judges See |
|---------|----------------|
| **Agent Architecture** | Full tree: Flutter → Therapy Director → Story Weaver (A2A) → QC Gate → Progress Guardian |
| **Tier Health** | Live status of T1 Gemini / T2 OpenRouter / T3 Bedrock / T4 Heuristic with active marker |
| **Session Signal** | Colour-coded bars, frustration warnings — the exact data Flutter sends every 30 s |
| **Sense-Reason-Act Trace** | Step-by-step: `TIER_ROUTE → OBSERVE → INFER → ACT → A2A_DELEGATE → LOG` |
| **Adaptation Actions** | Table of tool calls dispatched back to Flutter (`adjust_difficulty`, `switch_category`, etc.) |

---

## One-Time Setup

```bash
cd adk_backend
pip install rich        # only needed once — httpx is already installed
```

---

## Commands

### Run against the live Cloud Run backend (recommended for judges)

```bash
python demo_trace.py --prod --all
```

This runs all three child scenarios back-to-back against the deployed
`asia-south1` Cloud Run instance:

| Scenario | Child State | Expected Agent Decision |
|----------|-------------|------------------------|
| `frustrated` | 28% success, 4 failures, fast taps | `adjust_difficulty` → 2 cards, large |
| `thriving` | 82% success, 0 failures, calm pace | `trigger_reward` → star + Urdu praise |
| `tired` | 45% success, 17 min session | `send_break_prompt` → breathing break |

### Run a single scenario

```bash
python demo_trace.py --prod --scenario frustrated
python demo_trace.py --prod --scenario thriving
python demo_trace.py --prod --scenario tired
```

### Run against a local backend

```bash
# Terminal 1 — start the backend
uvicorn agent:app --reload --port 8000

# Terminal 2 — run the trace
python demo_trace.py --all
```

### All flags

| Flag | Default | Purpose |
|------|---------|---------|
| `--prod` | off | Use live Cloud Run URL instead of localhost |
| `--url URL` | `http://localhost:8000` | Custom backend URL (overridden by `--prod`) |
| `--token TOKEN` | `dev-token-sitara` | `X-Sitara-Token` header value |
| `--scenario` | `frustrated` | Which test scenario: `frustrated`, `thriving`, `tired` |
| `--all` | off | Run all 3 scenarios back-to-back |

---

## What Each Trace Step Means

```
[1] 📡  TIER_ROUTE      Routing to T1:Gemini — tier health verified
```
The startup probe ran at boot and confirmed Gemini 2.0 Flash is live.
This step is skipped instantly if Gemini is down — the next live tier is used.

```
[2] 👁️  OBSERVE         get_session_state(child_id='demo_zara')
```
Therapy Director calls `get_session_state` — the first tool in its
OBSERVE → INFER → DECIDE → ACT → LOG protocol.

```
[3] 🧠  INFER           Child shows frustration signals: 4 failures, 28%...
```
Extracted from the agent's reasoning text. Shows what conclusion the LLM drew.

```
[4] ⚡  ACT             adjust_difficulty(cards_per_round=2, card_size='large')
```
The adaptation tool call. This JSON is returned to Flutter, which executes it
via `_applyAction()` in `game_screen.dart`.

```
[5] 🔄  A2A_DELEGATE    → Story Weaver: child=Zara, cat=animals, diff=easy
```
Therapy Director delegates to Story Weaver via `generate_quest_via_story_weaver()`.
This is the key A2A (Agent-to-Agent) handoff — Story Weaver runs as a sub-agent
and returns a culturally relevant Urdu-English quest.

```
[6] 📝  LOG             Detected frustration on emotions; switching category
```
`log_insight()` call — recorded in the session for Progress Guardian's weekly report.

---

## Tier Health Colour Code

| Colour | Meaning |
|--------|---------|
| `✅ LIVE` (green) | Tier responding — will receive requests |
| `❌ DOWN` (red) | Tier failed health probe — requests skip straight to next tier |
| `⏳ UNKNOWN` (yellow) | Not yet probed (probe runs at startup and every 3 min) |
| `◀ ACTIVE` (cyan) | Current tier being used for all `/evaluate-session` calls |

The fallback chain is automatic and instant:
```
T1: Gemini 2.0 Flash  →  T2: OpenRouter  →  T3: Amazon Bedrock  →  T4: FixedRuleEngine
```
T4 never fails — the app stays playable even with all cloud APIs down.

---

## Quick Sanity Ping (before the demo)

```bash
python test_live_backend_agent.py
```

Expected output:
```json
{
  "status": "running",
  "active_tier": "T1:Gemini",
  "agents": ["therapy_director", "story_weaver", "progress_guardian"],
  "tier_health": {
    "gemini": true,
    "openrouter": true,
    "bedrock": false,
    ...
  }
}
```

---

## Where This Fits in the Demo Video

The `demo_trace.py` output maps directly to **Act 2** of `DEMO_SCRIPT.md`:

- The `OBSERVE → INFER → DECIDE → ACT → LOG` text on the Agent Trace overlay (Slide 4)
  is exactly what this script prints in the terminal.
- The A2A delegation arrow in Slide 5 corresponds to the `🔄 A2A_DELEGATE` step.
- Judges watching the demo video can verify the same logic by running this script live.

---

## Files

| File | Purpose |
|------|---------|
| `adk_backend/demo_trace.py` | This script |
| `adk_backend/test_live_backend_agent.py` | Minimal health ping (run first) |
| `adk_backend/agent.py` | Backend — `_build_trace_steps()` produces the `trace_steps` field |
| `docs/demo/DEMO_SCRIPT.md` | Demo video shot list and narration script |

---

*Last updated: 2026-05-20 · Verified against agent.py commit 2f61d0e*
