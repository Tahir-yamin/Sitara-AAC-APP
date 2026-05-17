import os
from google.genai import Client

api_key = os.environ.get("GOOGLE_API_KEY", "YOUR_API_KEY_HERE")
client = Client(api_key=api_key)

try:
    print("Testing gemini-1.5-flash...")
    response = client.models.generate_content(
        model="gemini-1.5-flash",
        contents="Hello, respond with 'SUCCESS' if you see this."
    )
    print(f"Response: {response.text}")
except Exception as e:
    print(f"Error with 1.5-flash: {e}")

try:
    print("\nTesting gemini-2.0-flash...")
    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents="Hello, respond with 'SUCCESS' if you see this."
    )
    print(f"Response: {response.text}")
except Exception as e:
    print(f"Error with 2.0-flash: {e}")
