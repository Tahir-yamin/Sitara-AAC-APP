
import requests
import json

url = "https://sitara-backend-178558547254.asia-south1.run.app/evaluate-session"
payload = {
    "child_id": "test_child_123",
    "success_rate": 0.2,
    "tap_speed": 4.5,
    "category": "animals",
    "cards_attempted": 5,
    "session_duration_mins": 5.0,
    "last_action_seconds_ago": 10,
    "consecutive_failures": 3
}

print(f"Testing {url}...")
try:
    response = requests.post(url, json=payload, timeout=30)
    print(f"Status Code: {response.status_code}")
    print("Response:")
    print(json.dumps(response.json(), indent=2))
except Exception as e:
    print(f"Error: {e}")
