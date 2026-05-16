
import os
from google import genai
from google.genai import types

api_key = os.environ.get("GOOGLE_API_KEY", "YOUR_API_KEY_HERE")
client = genai.Client(api_key=api_key)

models = ["gemini-1.5-flash", "gemini-2.0-flash", "gemini-flash-latest"]

for model_id in models:
    print(f"Testing model: {model_id}")
    try:
        response = client.models.generate_content(
            model=model_id,
            contents="Hello, say 'Test successful'"
        )
        print(f"  SUCCESS: {response.text}")
    except Exception as e:
        print(f"  FAILED: {e}")
