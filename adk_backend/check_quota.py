import os
import google.generativeai as genai

# Set API Key
api_key = "YOUR_API_KEY_HERE"
genai.configure(api_key=api_key)

models_to_check = [
    "gemini-1.5-flash",
    "gemini-1.5-pro",
    "gemini-2.0-flash",
    "gemini-2.5-flash",
    "gemini-3.1-flash-live-preview"
]

def check_models():
    print(f"--- Checking Quota for {len(models_to_check)} models ---")

    for model_name in models_to_check:
        print(f"\nTesting {model_name}...")
        try:
            model = genai.GenerativeModel(model_name)
            response = model.generate_content("Hi")
            print(f"SUCCESS: {model_name} is working!")
            print(f"Response snippet: {response.text[:50].strip()}...")
        except Exception as e:
            print(f"FAILED: {model_name}")
            if "429" in str(e) or "RESOURCE_EXHAUSTED" in str(e):
                print("Reason: 429 RESOURCE_EXHAUSTED")
                if "limit: 0" in str(e):
                    print("Note: Limit is 0 (Free Tier or deactivated)")
            else:
                print(f"Reason: {str(e)[:200]}")

if __name__ == "__main__":
    check_models()
