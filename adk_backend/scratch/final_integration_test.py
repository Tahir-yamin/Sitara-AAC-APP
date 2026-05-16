import os
import json
import asyncio
import sys
from fastapi.testclient import TestClient
from agent import app

# Ensure UTF-8 output for Sovereign characters
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# Mock API Key for local testing
os.environ["GOOGLE_API_KEY"] = "AIzaSy_MOCK_KEY_FOR_TESTING"

client = TestClient(app, raise_server_exceptions=False)

def print_result(title, response):
    print(f"\n{'='*20} {title} {'='*20}")
    print(f"Status Code: {response.status_code}")
    try:
        body = response.json()
        print(f"Response Body:\n{json.dumps(body, indent=2, ensure_ascii=False)}")
        
        # Benchmarking Verification
        if "mode" in body:
            print(f"✅ BENCHMARKING: Mode '{body['mode']}' detected.")
        else:
            # Check nested quest object if present
            if isinstance(body, dict) and "qc_status" in body:
                 print(f"✅ BENCHMARKING: QC Status '{body['qc_status']}' detected.")
            else:
                print("❌ BENCHMARKING: No mode/qc_status field found in response!")
                
        # Aesthetic Verification
        reasoning = body.get("reasoning", "") or body.get("report", "") or body.get("quest_title", "")
        if any(char in reasoning for char in "𝐒𝐎𝐕𝐄𝐑𝐄𝐈𝐆𝐍"):
            print("✅ AESTHETIC: Sovereign Unicode bolding detected.")
        else:
            print("⚠️ AESTHETIC: No Sovereign branding found in reasoning text.")
            
    except Exception as e:
        print(f"Error parsing response: {e}")
        print(f"Raw Response: {response.text}")

def run_tests():
    # 1. Test Baseline Evaluation
    print("\n[TEST 1] Forced Baseline Evaluation")
    baseline_data = {
        "child_id": "test_001",
        "success_rate": 0.2,
        "consecutive_failures": 4,
        "tap_speed": 0.5,
        "category": "fruits",
        "mode": "baseline"
    }
    response = client.post("/evaluate-session", json=baseline_data)
    print_result("Evaluation (Baseline)", response)

    # 2. Test Quest Generation (Mocked for rate limits)
    print("\n[TEST 2] Quest Generation")
    quest_data = {
        "child_id": "test_001",
        "child_name": "Zayan",
        "preferred_category": "vehicles",
        "difficulty": "medium"
    }
    response = client.post("/generate-quest", json=quest_data)
    print_result("Quest Generation", response)

    # 3. Test Weekly Report
    print("\n[TEST 3] Weekly Report Generation")
    report_data = {
        "child_id": "test_001",
        "child_name": "Zayan",
        "session_summary": "Completed 20 cards with 85% success rate.",
        "therapist_insights": "Improved attention span during animal categories."
    }
    response = client.post("/weekly-report", json=report_data)
    print_result("Weekly Report", response)

if __name__ == "__main__":
    run_tests()
