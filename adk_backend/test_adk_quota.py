import os
import asyncio
from google.adk.agents import LlmAgent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types

# Set API Key for the environment
os.environ["GOOGLE_API_KEY"] = os.environ.get("GOOGLE_API_KEY", "YOUR_API_KEY_HERE")

async def test_model(model_name):
    print(f"\n--- Testing {model_name} ---")
    try:
        agent = LlmAgent(
            name="test_agent",
            model=model_name,
            instruction="You are a helpful assistant.",
            description="Testing quota"
        )
        
        session_service = InMemorySessionService()
        
        # Create session first
        await session_service.create_session(
            app_name="test_app",
            user_id="test_user",
            session_id="test_session"
        )
        
        runner = Runner(
            agent=agent,
            app_name="test_app",
            session_service=session_service
        )
        
        content = types.Content(
            role="user",
            parts=[types.Part(text="Hello")]
        )
        
        print(f"Running {model_name}...")
        response_text = ""
        async for event in runner.run_async(
            user_id="test_user",
            session_id="test_session",
            new_message=content
        ):
            if event.content and event.content.parts:
                for part in event.content.parts:
                    if hasattr(part, "text") and part.text:
                        response_text += part.text
        
        if response_text:
            print(f"SUCCESS: {model_name} responded!")
            print(f"Response: {response_text[:50]}...")
            return True
        else:
            print(f"FAILED: {model_name} (Empty response)")
            return False
    except Exception as e:
        print(f"FAILED: {model_name}")
        print(f"Error: {str(e)}")
        return False

async def main():
    models = [
        "gemini-1.5-flash",
        "gemini-2.0-flash",
        "gemini-2.5-flash",
        "gemini-3.1-flash-live-preview"
    ]
    for m in models:
        await test_model(m)

if __name__ == "__main__":
    asyncio.run(main())
