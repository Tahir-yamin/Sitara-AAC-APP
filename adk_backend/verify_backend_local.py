import os
import json
import time
from fastapi.testclient import TestClient
from agent import app

# Set API Key for the environment
os.environ["GOOGLE_API_KEY"] = os.environ.get("GOOGLE_API_KEY", "YOUR_API_KEY_HERE")

# Tell TestClient NOT to raise exceptions so we can check the handler output
client = TestClient(app, raise_server_exceptions=False)

def test_generate_quest():
    print("\n--- Testing /generate-quest ---")
    data = {
        "child_id": "test_child",
        "child_name": "TestChild",
        "preferred_category": "animals",
        "difficulty": "easy",
        "recent_mastery": "just mastered cat cards"
    }
    
    for i in range(3):
        print(f"Attempt {i+1}...")
        response = client.post("/generate-quest", json=data)
        print(f"Status: {response.status_code}")
        
        try:
            body = response.json()
            if response.status_code == 200:
                print("SUCCESS: Quest generated!")
                print(json.dumps(body, indent=2, ensure_ascii=False))
                return
            else:
                print(f"ERROR: {body.get('error', 'Unknown error')}")
                print(f"Detail: {body.get('detail', '')}")
        except Exception as e:
            print(f"FAILED TO PARSE JSON: {response.text}")
        
        if response.status_code in [429, 503]:
            print("Retrying in 5 seconds...")
            time.sleep(5)
        else:
            break

if __name__ == "__main__":
    test_generate_quest()
