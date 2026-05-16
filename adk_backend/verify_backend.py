
import asyncio
import os
import json
import traceback

try:
    from google.adk.sessions import DatabaseSessionService
    from google.adk.agents import LlmAgent
    from google.adk.runners import Runner
except ImportError as e:
    print(f"ImportError: {e}")
    exit(1)

# Test database URL
DB_PATH = "sqlite+aiosqlite:///./sitara_sessions_test.db"

async def test_session_service():
    print(f"Testing DatabaseSessionService with {DB_PATH}")
    try:
        session_service = DatabaseSessionService(db_url=DB_PATH)
        print("DatabaseSessionService initialized successfully")
        
        # Step 2: Create a session (idempotent)
        try:
            session = await session_service.create_session(
                app_name="sitara",
                user_id="child_123",
                session_id="test_session"
            )
            print("DatabaseSessionService: Session created")
        except Exception as e:
            if "already exists" in str(e).lower():
                print("DatabaseSessionService: Session already exists (reusing)")
                session = await session_service.get_session(
                    app_name="sitara",
                    user_id="child_123",
                    session_id="test_session"
                )
            else:
                raise e
        print(f"Session: {session}")
        
        return session_service
    except Exception as e:
        print(f"DatabaseSessionService failed: {e}")
        traceback.print_exc()
        return None

async def test_a2a_structure():
    print("\nTesting A2A Structure (Code Level)")
    
    # 1. Sub-agent
    sub_agent = LlmAgent(name="sub", model="gemini-1.5-flash", instruction="test")
    
    # 2. Tool that calls sub-agent (mocked)
    async def sub_agent_tool(input: str) -> str:
        return f"Processed: {input}"
    
    # 3. Main agent with tool
    main_agent = LlmAgent(
        name="main",
        model="gemini-1.5-flash",
        instruction="Use sub_agent_tool",
        tools=[sub_agent_tool]
    )
    
    print(f"Main agent tools: {[t.__name__ for t in main_agent.tools]}")
    if "sub_agent_tool" in [t.__name__ for t in main_agent.tools]:
        print("A2A tool registered in main agent")
    else:
        print("A2A tool NOT registered")

async def main():
    await test_session_service()
    await test_a2a_structure()

if __name__ == "__main__":
    asyncio.run(main())
