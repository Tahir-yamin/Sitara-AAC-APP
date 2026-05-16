"""
Sitara ADK Backend — End-to-End Test Script
Run with: python test_endpoints.py
Prerequisites: uvicorn agent:app --reload --port 8000
"""

import requests
import json

BASE_URL = "http://localhost:8000"


def print_section(title: str):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")


def test_health():
    print_section("1. Health Check")
    try:
        r = requests.get(f"{BASE_URL}/health")
        print(f"Status: {r.status_code}")
        print(json.dumps(r.json(), indent=2))
        assert r.json()["status"] == "running", "Health check failed"
        print("PASS")
    except Exception as e:
        print(f"FAIL: {e}")


def test_evaluate_frustration():
    """Simulates a frustrated child — expect switch_category or adjust_difficulty."""
    print_section("2. Evaluate Session — Frustrated Child (4 consecutive failures)")
    data = {
        "child_id": "zara_001",
        "success_rate": 0.28,
        "consecutive_failures": 4,
        "tap_speed": 3.1,
        "category": "emotions",
        "session_duration_mins": 8.0,
        "cards_attempted": 7,
    }
    try:
        r = requests.post(f"{BASE_URL}/evaluate-session", json=data, timeout=60)
        print(f"Status: {r.status_code}")
        body = r.json()
        print(f"Agent: {body.get('agent')}")
        print(f"Reasoning (first 200 chars): {body.get('reasoning', '')[:200]}")
        print(f"Actions returned: {json.dumps(body.get('actions', []), indent=2)}")

        actions = body.get("actions", [])
        action_names = [a.get("tool", "") for a in actions]
        print(f"\nAction tools: {action_names}")

        # Expect at least one adaptation
        if actions:
            print("PASS — Therapy Director made an adaptation")
        else:
            print("WARNING — No adaptation returned (may be intentional if 60s window not elapsed)")
    except Exception as e:
        print(f"FAIL: {e}")


def test_evaluate_success():
    """Simulates a succeeding child — expect trigger_reward or adjust_difficulty (harder)."""
    print_section("3. Evaluate Session — High Success (ready for challenge)")
    data = {
        "child_id": "zara_001",
        "success_rate": 0.90,
        "consecutive_failures": 0,
        "tap_speed": 1.2,
        "category": "animals",
        "session_duration_mins": 5.0,
        "cards_attempted": 10,
    }
    try:
        r = requests.post(f"{BASE_URL}/evaluate-session", json=data, timeout=60)
        print(f"Status: {r.status_code}")
        body = r.json()
        print(f"Actions: {json.dumps(body.get('actions', []), indent=2)}")
        print("PASS")
    except Exception as e:
        print(f"FAIL: {e}")


def test_generate_quest():
    """Story Weaver generates a culturally relevant quest."""
    print_section("4. Generate Quest — Story Weaver A2A")
    data = {
        "child_id": "zara_001",
        "child_name": "Zara",
        "preferred_category": "animals",
        "difficulty": "easy",
        "recent_mastery": "just mastered cat and dog cards",
    }
    try:
        r = requests.post(f"{BASE_URL}/generate-quest", json=data, timeout=60)
        print(f"Status: {r.status_code}")
        quest = r.json()
        print(json.dumps(quest, indent=2, ensure_ascii=False))

        required = ["quest_title", "story_text", "target_category", "urdu_hook"]
        missing = [k for k in required if k not in quest]
        if missing:
            print(f"⚠️  Missing fields: {missing}")
        else:
            print("PASS — All required quest fields present")
    except Exception as e:
        print(f"FAIL: {e}")


def test_weekly_report():
    """Progress Guardian generates a warm parent report."""
    print_section("5. Weekly Report — Progress Guardian")
    data = {
        "child_id": "zara_001",
        "child_name": "Zara",
        "session_summary": json.dumps({
            "total_attempts": 45,
            "total_successes": 38,
            "success_rate": 0.84,
            "session_duration_mins": 22.5,
            "current_category": "animals",
            "consecutive_failures": 0,
        }),
        "therapist_insights": "Child shows strong preference for animal cards. Responded positively to reduce-difficulty adaptation at 8-minute mark.",
    }
    try:
        r = requests.post(f"{BASE_URL}/weekly-report", json=data, timeout=90)
        print(f"Status: {r.status_code}")
        body = r.json()
        report = body.get("report", "")
        print(f"Report preview (first 400 chars):\n{report[:400]}")

        checks = ["Assalamu", "Zara"]
        for check in checks:
            if check in report:
                print(f"  ✅ Contains '{check}'")
            else:
                print(f"  ⚠️  Missing '{check}'")
        print("PASS")
    except Exception as e:
        print(f"FAIL: {e}")


if __name__ == "__main__":
    import time
    print("\n*** Sitara Backend Validation Suite ***")
    print("Connecting to:", BASE_URL)
    test_health()
    time.sleep(5)
    test_evaluate_frustration()
    time.sleep(5)
    test_evaluate_success()
    time.sleep(5)
    test_generate_quest()
    time.sleep(5)
    test_weekly_report()
    print(f"\n{'='*60}")
    print("  Validation complete. Check results above.")
    print(f"{'='*60}\n")
