
import requests
import json
import time

def test_generate_quest():
    url = "http://127.0.0.1:8000/generate-quest"
    data = {
        "child_id": "test_child_123",
        "child_name": "Zara",
        "preferred_category": "animals",
        "difficulty": "easy"
    }
    
    print(f"Testing {url}...")
    try:
        response = requests.post(url, json=data, timeout=30)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    # Wait for server to be ready
    time.sleep(5)
    test_generate_quest()
