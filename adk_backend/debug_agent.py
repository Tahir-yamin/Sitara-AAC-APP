"""
Run this directly to get the real traceback from the ADK runner.
Usage: python debug_agent.py
"""
import asyncio
import os
import sys

os.environ.setdefault("GOOGLE_API_KEY", os.environ.get("GOOGLE_API_KEY", ""))

async def main():
    # Import after env is set
    from google.adk.agents import LlmAgent
    from google.adk.runners import Runner
    from google.adk.sessions import InMemorySessionService
    from google.genai import types

    print("ADK imported OK")

    # Minimal tool
    def switch_category(child_id: str, target_category: str, reason: str) -> dict:
        print(f"  [TOOL CALLED] switch_category -> {target_category}")
        return {"action": "switch_category", "new_category": target_category}

    def get_session_state(child_id: str, window_seconds: int = 60) -> dict:
        return {
            "child_id": child_id, "success_rate": 0.28,
            "consecutive_failures": 4, "tap_speed_avg": 3.1,
            "current_category": "emotions", "cards_attempted": 7,
            "session_duration_mins": 8.0,
        }

    def log_insight(child_id: str, insight_type: str, description: str, evidence: str = "") -> dict:
        print(f"  [TOOL CALLED] log_insight: {insight_type}")
        return {"status": "logged"}

    session_service = InMemorySessionService()

    # Try the model strings in order until one works
    # gemini-1.5-flash first: separate quota bucket from 2.0-flash
    for model in ["gemini-1.5-flash", "gemini-2.0-flash-lite", "gemini-2.0-flash"]:
        print(f"\nTrying model: {model}")
        try:
            agent = LlmAgent(
                name="test_director",
                model=model,
                instruction="You help autistic children. When frustration is detected (consecutive_failures>=3), call switch_category to move to 'animals'.",
                tools=[get_session_state, switch_category, log_insight],
            )
            runner = Runner(agent=agent, app_name="test", session_service=session_service)

            session_id = f"test_session_{model.replace('.', '_').replace('-', '_')}"
            # Always create a fresh session for the test
            await session_service.create_session(app_name="test", user_id="child_001", session_id=session_id)

            content = types.Content(
                role="user",
                parts=[types.Part(text=(
                    "Child has 4 consecutive failures, 28% success rate, "
                    "tap speed 3.1/sec in emotions category. Please evaluate and adapt."
                ))]
            )

            response_text = ""
            tool_calls = []
            event_count = 0

            async for event in runner.run_async(
                user_id="child_001",
                session_id=session_id,
                new_message=content
            ):
                event_count += 1
                print(f"  Event #{event_count}: type={type(event).__name__}, "
                      f"has_content={event.content is not None}")
                if event.content and event.content.parts:
                    for i, part in enumerate(event.content.parts):
                        has_fc = hasattr(part, "function_call") and part.function_call is not None
                        has_fr = hasattr(part, "function_response") and part.function_response is not None
                        has_txt = hasattr(part, "text") and bool(part.text)
                        print(f"    Part[{i}]: function_call={has_fc}, function_response={has_fr}, text={has_txt}")
                        if has_fc:
                            fc = part.function_call
                            tool_calls.append({"tool": fc.name, "args": dict(fc.args) if fc.args else {}})
                        elif has_txt:
                            response_text = part.text

            print(f"\n=== RESULT for {model} ===")
            print(f"Reasoning (first 300 chars): {response_text[:300]}")
            print(f"Tool calls: {tool_calls}")
            print("SUCCESS!")
            break  # Stop at first working model

        except Exception as e:
            print(f"  ERROR: {type(e).__name__}: {e}")
            import traceback
            traceback.print_exc()

asyncio.run(main())
