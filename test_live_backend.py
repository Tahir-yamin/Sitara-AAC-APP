import requests
import json

BASE_URL = "https://sitara-backend-178558547254.asia-south1.run.app"

def test_evaluate_session():
    print(f"Testing {BASE_URL}/evaluate-session...")
    payload = {
        "child_id": "test_child_123",
        "success_rate": 0.2,
        "consecutive_failures": 3,
        "tap_speed": 0.5,
        "category": "animals",
        "session_duration_mins": 5,
        "cards_attempted": 10
    }
    try:
        response = requests.post(
            f"{BASE_URL}/evaluate-session",
            json=payload,
            headers={"X-Sitara-Token": "dev-token-sitara"}
        )
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_evaluate_session()
