#!/usr/bin/env python3
"""
demo_trace.py — Sitara Live Agentic Workflow Terminal Trace
Calls the live/local backend and renders a real-time judge-facing demo.

Usage:
    cd adk_backend
    pip install rich
    python demo_trace.py                            # local backend, frustrated scenario
    python demo_trace.py --scenario thriving        # frustrated | thriving | tired
    python demo_trace.py --all                      # run all 3 scenarios back-to-back
    python demo_trace.py --url https://sitara-backend-xxx.run.app --token YOUR_TOKEN
"""

import argparse
import json
import sys
import time
from datetime import datetime

try:
    import httpx
except ImportError:
    print("httpx not found — run: pip install httpx")
    sys.exit(1)

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.table import Table
    from rich.tree import Tree
    from rich.rule import Rule
    from rich import box
except ImportError:
    print("rich not found — run: pip install rich")
    sys.exit(1)

console = Console()

# ── Color scheme ──────────────────────────────────────────────────
TIER_COLORS = {
    "T1:Gemini":     "bright_cyan",
    "T2:OpenRouter": "bright_yellow",
    "T3:Bedrock":    "bright_magenta",
    "T4:Heuristic":  "bright_red",
}

PHASE_COLORS = {
    "TIER_ROUTE":    "bright_cyan",
    "OBSERVE":       "bright_blue",
    "INFER":         "yellow",
    "ACT":           "bright_green",
    "A2A_DELEGATE":  "bright_magenta",
    "LOG":           "dim white",
    "QC":            "cyan",
}

# ── Test Scenarios ─────────────────────────────────────────────────
SCENARIOS = {
    "frustrated": {
        "child_id": "demo_zara",
        "success_rate": 0.28,
        "consecutive_failures": 4,
        "tap_speed": 3.2,
        "category": "emotions",
        "session_duration_mins": 8.0,
        "cards_attempted": 7,
        "mode": "agentic",
        "_label": "😰 Frustrated Child",
        "_desc": "4 failures, 28% success, fast erratic taps — should reduce difficulty",
    },
    "thriving": {
        "child_id": "demo_ali",
        "success_rate": 0.82,
        "consecutive_failures": 0,
        "tap_speed": 1.4,
        "category": "animals",
        "session_duration_mins": 5.0,
        "cards_attempted": 12,
        "mode": "agentic",
        "_label": "🌟 Thriving Child",
        "_desc": "82% success, calm pace — should trigger reward or increase difficulty",
    },
    "tired": {
        "child_id": "demo_sara",
        "success_rate": 0.45,
        "consecutive_failures": 2,
        "tap_speed": 2.1,
        "category": "food",
        "session_duration_mins": 17.5,
        "cards_attempted": 20,
        "mode": "agentic",
        "_label": "😴 Tired Child",
        "_desc": "17 min session, declining success rate — should send break prompt",
    },
}


# ── Banner ─────────────────────────────────────────────────────────
def show_banner():
    console.print()
    console.print(Panel.fit(
        "[bold bright_white]🌟  SITARA  —  AAC Game for Autistic Children[/]\n"
        "[dim]Pakistan  ·  Google ADK + Gemini 2.0 Flash  ·  #AISeekho2026[/]\n\n"
        "[bright_cyan]Live Agentic Orchestration Trace[/]  "
        "[dim](Sense → Reason → Act)[/]",
        border_style="bright_cyan",
        padding=(1, 6),
    ))
    console.print()


# ── Agent hierarchy ────────────────────────────────────────────────
def show_agent_hierarchy():
    console.print(Rule("[bold bright_white]Agent Architecture[/]", style="bright_cyan"))
    console.print()

    tree = Tree("🎮 [bold]Flutter Mobile App[/]  [dim](Android · Provider)[/]")

    t1 = tree.add("📡 [bold bright_cyan]POST /evaluate-session[/]  [dim]every 30 s[/]")
    dir_node = t1.add(
        "🧠 [bold orange1]Therapy Director[/]  "
        "[dim](Orchestrator · LlmAgent · gemini-2.0-flash)[/]"
    )
    dir_node.add("👁️   OBSERVE  → get_session_state()")
    dir_node.add("⚡   ACT      → adjust_difficulty() / switch_category()")
    dir_node.add("🎁   ACT      → trigger_reward() / send_break_prompt()")
    dir_node.add("📝   LOG      → log_insight()")
    a2a = dir_node.add(
        "🔄  [bold bright_magenta]generate_quest_via_story_weaver()[/]  "
        "[dim](A2A delegation)[/]"
    )
    a2a.add("📖  [bold green]Story Weaver[/]  [dim](Sub-Agent · gemini-2.0-flash)[/]")
    a2a.add("🛡️   QC Gate  → _validate_quest()")

    t2 = tree.add("📋 [bold bright_cyan]POST /generate-quest[/]  [dim]session start[/]")
    t2.add("📖  [bold green]Story Weaver[/]  [dim](direct call)[/]")

    t3 = tree.add("📊 [bold bright_cyan]POST /weekly-report[/]  [dim]parent dashboard[/]")
    t3.add("📊  [bold purple]Progress Guardian[/]  [dim](CBT + SLP reports)[/]")

    console.print(tree)
    console.print()


# ── Tier health table ──────────────────────────────────────────────
def show_tier_health(url: str, headers: dict) -> str:
    console.print(Rule("[bold bright_white]AI Tier Health  (live probe)[/]", style="bright_cyan"))
    console.print()

    try:
        resp = httpx.get(f"{url}/health", headers=headers, timeout=6.0)
        data = resp.json()
    except Exception as e:
        console.print(f"[red]✗ Cannot reach backend at {url}[/]")
        console.print(f"  [dim]{e}[/]")
        console.print(
            "\n[yellow]Tip:[/] start the backend first:\n"
            "  [dim]cd adk_backend && uvicorn agent:app --reload --port 8000[/]"
        )
        sys.exit(1)

    th = data.get("tier_health", {})
    active = data.get("active_tier", "?")

    tbl = Table(box=box.ROUNDED, border_style="bright_cyan",
                show_header=True, header_style="bold bright_white")
    tbl.add_column("Tier",          width=20)
    tbl.add_column("Status",        width=12)
    tbl.add_column("Model / Detail",width=40)
    tbl.add_column("Routing",       width=12)

    rows = [
        ("T1: Gemini 2.0 Flash", th.get("gemini"),
         "google/gemini-2.0-flash  (Google ADK)", "T1:Gemini"),
        ("T2: OpenRouter",       th.get("openrouter"),
         th.get("openrouter_model") or "— key not set", "T2:OpenRouter"),
        ("T3: Amazon Bedrock",   th.get("bedrock"),
         "anthropic.claude-haiku-4-5  (Bearer auth)", "T3:Bedrock"),
        ("T4: Heuristic",        True,
         "FixedRuleEngine  (always live)", "T4:Heuristic"),
    ]

    for name, live, note, key in rows:
        is_active = (active == key)
        if live is True:
            status = "[bold green]✅  LIVE[/]"
        elif live is False:
            status = "[bold red]❌  DOWN[/]"
        else:
            status = "[dim yellow]⏳  UNKNOWN[/]"
        routing = "[bold bright_cyan]◀ ACTIVE[/]" if is_active else ""
        tbl.add_row(f"[bold]{name}[/]", status, note, routing)

    console.print(tbl)
    last = th.get("last_probed") or "not probed yet"
    console.print(f"  Last probed: [dim]{last}[/]   Active: [bold bright_cyan]{active}[/]")
    console.print()
    return active


# ── Session input summary ──────────────────────────────────────────
def show_session_input(scenario: dict):
    console.print(Rule("[bold bright_white]Incoming Session Signal  (Flutter → Backend)[/]",
                       style="yellow"))
    console.print()

    s = scenario
    rate = s["success_rate"]
    bar_len = 24
    filled = round(rate * bar_len)
    bar_color = "green" if rate > 0.6 else "yellow" if rate > 0.4 else "red"
    bar = f"[{bar_color}]{'█' * filled}{'░' * (bar_len - filled)}[/]"

    tap_warn = "  [bold red]⚠ HIGH — frustration signal[/]" if s["tap_speed"] > 3.0 else ""
    fail_warn = "  [bold red]⚠ frustration threshold[/]" if s["consecutive_failures"] >= 3 else ""
    dur_warn  = "  [bold yellow]⚠ fatigue risk[/]" if s["session_duration_mins"] > 15 else ""

    lines = [
        f"  [dim]Child ID    :[/] [bold]{s['child_id']}[/]",
        f"  [dim]Category    :[/] [bold cyan]{s['category']}[/]",
        f"  [dim]Success Rate:[/] {bar} [bold]{rate:.0%}[/]",
        f"  [dim]Failures    :[/] [bold]{'[red]' if s['consecutive_failures'] >= 3 else ''}"
        f"{s['consecutive_failures']}{'[/red]' if s['consecutive_failures'] >= 3 else ''}[/]{fail_warn}",
        f"  [dim]Tap Speed   :[/] {s['tap_speed']:.1f} /s{tap_warn}",
        f"  [dim]Duration    :[/] {s['session_duration_mins']:.1f} min{dur_warn}",
        f"  [dim]Cards Tried :[/] {s['cards_attempted']}",
    ]

    console.print(Panel(
        "\n".join(lines),
        title=f"[bold bright_white]{s.get('_label', 'Session Data')}[/]",
        subtitle=f"[dim]{s.get('_desc', '')}[/]",
        border_style="yellow",
        padding=(0, 1),
    ))
    console.print()


# ── Main trace ─────────────────────────────────────────────────────
def show_agentic_trace(url: str, headers: dict, scenario: dict):
    console.print(Rule(
        "[bold bright_white]Therapy Director  →  Sense-Reason-Act Loop[/]",
        style="bright_green"
    ))
    console.print()

    payload = {k: v for k, v in scenario.items() if not k.startswith("_")}

    console.print("  [dim]→ POST /evaluate-session ...[/]", end="")
    t0 = time.time()
    try:
        resp = httpx.post(
            f"{url}/evaluate-session",
            json=payload, headers=headers, timeout=35.0
        )
        elapsed = time.time() - t0
        data = resp.json()
    except Exception as e:
        console.print(f"\n  [red]Request failed: {e}[/]")
        return None

    console.print(f"  [bold green]✓[/] [dim]HTTP {resp.status_code}  ({elapsed:.2f}s)[/]")
    console.print()

    active_tier = data.get("active_tier", "?")
    tier_color  = TIER_COLORS.get(active_tier, "white")

    # ── Tier badge ─────────────────────────────────────────────────
    console.print(
        f"  Active Tier: [{tier_color}][bold]{active_tier}[/][/]"
        f"   Mode: [bold]{data.get('mode', '?')}[/]"
        f"   Agent: [bold]{data.get('agent', '—')}[/]"
    )
    console.print()

    # ── Trace steps ────────────────────────────────────────────────
    trace_steps = data.get("trace_steps") or _build_synthetic_trace(active_tier, data)

    console.print("  [bold dim]Step  Phase           Detail[/]")
    console.print("  " + "─" * 72)

    for step in trace_steps:
        phase  = step.get("phase", "?")
        icon   = step.get("icon", "•")
        detail = step.get("detail", "")
        color  = PHASE_COLORS.get(phase, "white")
        num    = step.get("step", "?")

        time.sleep(0.08)   # slight animation for live demo feel
        console.print(
            f"  [{color}][{num:>2}] {icon}  [bold]{phase:<16}[/][/{color}]"
            f"  {detail}"
        )

    console.print()

    # ── Reasoning excerpt ──────────────────────────────────────────
    reasoning = (data.get("reasoning") or "").strip()
    if reasoning and len(reasoning) > 8:
        snippet = reasoning[:220] + ("…" if len(reasoning) > 220 else "")
        console.print(Panel(
            f"[italic]{snippet}[/]",
            title="[dim]🧠 Agent Reasoning  (excerpt)[/]",
            border_style="dim",
            padding=(0, 2),
        ))
        console.print()

    # ── Actions table ──────────────────────────────────────────────
    actions = data.get("actions", [])
    console.print(Rule("[bold bright_white]Adaptation Actions  →  Flutter[/]", style="bright_green"))
    console.print()

    if actions:
        tbl = Table(box=box.SIMPLE, show_header=True, header_style="bold",
                    padding=(0, 1))
        tbl.add_column("#",        width=3)
        tbl.add_column("Tool",     style="bold bright_green", width=26)
        tbl.add_column("Arguments (Flutter will execute these)", width=52)

        for i, action in enumerate(actions, 1):
            tool     = action.get("tool", "?")
            args     = action.get("args", {})
            args_str = json.dumps(args, ensure_ascii=False)
            if len(args_str) > 52:
                args_str = args_str[:49] + "…"
            tbl.add_row(str(i), tool, args_str)

        console.print(tbl)
    else:
        console.print(
            "  [dim]No adaptation needed this cycle "
            "(child performing well — heuristic threshold not triggered)[/]"
        )

    console.print()

    # ── Summary ────────────────────────────────────────────────────
    console.print(Panel(
        f"  Tier:    [{tier_color}][bold]{active_tier}[/][/]\n"
        f"  Actions: [bold]{len(actions)}[/]  dispatched to Flutter\n"
        f"  Latency: [bold]{elapsed:.2f}s[/]  end-to-end\n"
        f"  Mode:    [bold]{data.get('mode', '?')}[/]",
        title="[bold bright_white]✅  Session Evaluated[/]",
        border_style=tier_color,
        padding=(0, 2),
    ))
    console.print()
    return data


# ── Synthetic trace builder (fallback for older backends) ──────────
def _build_synthetic_trace(active_tier: str, data: dict) -> list:
    """Reconstruct trace steps from the response when backend didn't include them."""
    steps   = []
    actions = data.get("actions", [])
    n       = 1

    steps.append({"step": n, "phase": "TIER_ROUTE", "icon": "📡",
                  "detail": f"Routing to {active_tier} — health probe verified"})
    n += 1

    obs = next((a for a in actions if a.get("tool") == "get_session_state"), None)
    if obs:
        cid = obs.get("args", {}).get("child_id", "child")
        steps.append({"step": n, "phase": "OBSERVE", "icon": "👁️",
                      "detail": f"get_session_state(child_id='{cid}')"})
        n += 1

    reasoning = (data.get("reasoning") or "").replace("\n", " ").strip()
    if reasoning:
        steps.append({"step": n, "phase": "INFER", "icon": "🧠",
                      "detail": reasoning[:90] + ("…" if len(reasoning) > 90 else "")})
        n += 1

    for a in actions:
        tool = a.get("tool", "?")
        if tool in ("get_session_state", "log_insight"):
            continue
        if tool == "generate_quest_via_story_weaver":
            ch = a.get("args", {}).get("child_name", "child")
            cat = a.get("args", {}).get("preferred_category", "?")
            steps.append({"step": n, "phase": "A2A_DELEGATE", "icon": "🔄",
                          "detail": f"→ Story Weaver sub-agent  (child={ch}, cat={cat})"})
        else:
            args = a.get("args", {})
            summary = ", ".join(f"{k}={v!r}" for k, v in list(args.items())[:2])
            steps.append({"step": n, "phase": "ACT", "icon": "⚡",
                          "detail": f"{tool}({summary})"})
        n += 1

    log = next((a for a in actions if a.get("tool") == "log_insight"), None)
    if log:
        desc = log.get("args", {}).get("description", "insight logged")
        steps.append({"step": n, "phase": "LOG", "icon": "📝",
                      "detail": str(desc)[:65]})

    return steps


# ── Entry point ────────────────────────────────────────────────────
def main():
    args    = parse_args()
    url     = PROD_URL if args.prod else args.url
    headers = {
        "Content-Type":  "application/json",
        "X-Sitara-Token": args.token,
    }

    show_banner()
    show_agent_hierarchy()
    show_tier_health(url, headers)

    scenarios_to_run = (
        list(SCENARIOS.values()) if args.all
        else [SCENARIOS[args.scenario]]
    )

    for i, scenario in enumerate(scenarios_to_run):
        if i > 0:
            console.print()
            console.print(Rule(style="dim"))
            console.print()
        show_session_input(scenario)
        show_agentic_trace(url, headers, scenario)

    console.print(Rule("[dim]End of Demo Trace[/]", style="dim"))
    console.print(
        f"[dim]Backend: {url}  ·  "
        f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}[/]"
    )
    console.print()


if __name__ == "__main__":
    main()
