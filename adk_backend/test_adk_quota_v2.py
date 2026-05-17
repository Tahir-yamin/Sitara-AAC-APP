import os
import asyncio
from google.adk.agents import LlmAgent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types

# Set API Key for the environment
os.environ["GOOGLE_API_KEY"] = os.environ.get("GOOGLE_API_KEY", "YOUR_API_KEY_HERE")

async def test_model(model_id):
    print(f"\n--- Testing {model_id} ---")
    try:
        agent = LlmAgent(
            name="test_agent",
            model=model_id,
            instruction="You are a helpful assistant.",
            description="Testing quota"
        )
        
        session_service = InMemorySessionService()
        await session_service.create_session(app_name="test", user_id="u", session_id="s")
        
        runner = Runner(
            agent=agent,
            app_name="test",
            session_service=session_service
        )
        
        content = types.Content(role="user", parts=[types.Part(text="Hi")])
        
        response_text = ""
        async for event in runner.run_async(user_id="u", session_id="s", new_message=content):
            if event.content and event.content.parts:
                for part in event.content.parts:
                    if hasattr(part, "text") and part.text:
                        response_text += part.text
        
        if response_text:
            print(f"SUCCESS: {model_id} worked!")
            return True
        else:
            print(f"FAILED: {model_id} (Empty)")
            return False
    except Exception as e:
        print(f"FAILED: {model_id}")
        print(f"Error: {str(e)[:500]}")
        return False

async def main():
    # Test a few variants
    models = [
        "gemini-flash-latest",
        "models/gemini-flash-latest",
        "models/gemini-2.5-flash",
        "models/gemini-2.0-flash",
        "models/gemini-2.0-flash-lite"
    ]
    for m in models:
        await test_model(m)

if __name__ == "__main__":
    asyncio.run(main())
