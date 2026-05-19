import httpx
import json

import httpx
import json

import httpx
import json

import httpx
import json

def test_openrouter():
    import os
    api_key = os.environ.get("OPENROUTER_API_KEY", "")
    if not api_key:
        print("OPENROUTER_API_KEY env variable not set!")
        return
    url = "https://openrouter.ai/api/v1/chat/completions"
    
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://sitara.app",
        "X-Title": "Sitara App"
    }
    
    candidate_models = [
        "meta-llama/llama-3.3-70b-instruct:free",
        "deepseek/deepseek-v4-flash:free",
        "google/gemma-4-31b-it:free",
        "openrouter/free"
    ]
    
    for model in candidate_models:
        payload = {
            "model": model,
            "messages": [
                {
                    "role": "user",
                    "content": "Hello! Reply with exactly 'Hello from model_name' replacing model_name with the model name."
                }
            ]
        }
        
        print(f"Testing model {model}...")
        try:
            response = httpx.post(url, headers=headers, json=payload, timeout=20.0)
            print("Status Code:", response.status_code)
            if response.status_code == 200:
                print("SUCCESS with model:", model)
                print("Response:", response.json()["choices"][0]["message"]["content"])
                return
            else:
                print("Failed with:", response.text)
        except Exception as e:
            print("Error:", e)

if __name__ == "__main__":
    test_openrouter()

if __name__ == "__main__":
    test_openrouter()
