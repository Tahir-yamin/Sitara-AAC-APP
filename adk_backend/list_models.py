import os
from google.genai import Client

api_key = "YOUR_API_KEY_HERE"
client = Client(api_key=api_key)

try:
    print("Listing available models via google.genai Client...")
    # The new SDK list_models returns a list of model objects
    for m in client.models.list():
        print(f"- {m.name}")
except Exception as e:
    print(f"Error: {e}")
