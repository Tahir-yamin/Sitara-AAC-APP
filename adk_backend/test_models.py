import asyncio
import os
os.environ['GOOGLE_API_KEY'] = os.environ.get('GOOGLE_API_KEY', 'YOUR_API_KEY_HERE')

async def main():
    from google.adk.agents import LlmAgent
    from google.adk.runners import Runner
    from google.adk.sessions import InMemorySessionService
    from google.genai import types

    session_service = InMemorySessionService()

    for model in ['gemini-2.5-flash', 'gemini-1.5-pro', 'gemini-flash-latest']:
        print(f'\nTrying model: {model}')
        try:
            agent = LlmAgent(name='test_director', model=model, instruction='Say hi.')
            runner = Runner(agent=agent, app_name='test', session_service=session_service)
            session_id = f'test_session_{model.replace(".", "_").replace("-", "_")}'
            await session_service.create_session(app_name='test', user_id='child_001', session_id=session_id)
            
            content = types.Content(role='user', parts=[types.Part(text='Hello')])
            async for event in runner.run_async(user_id='child_001', session_id=session_id, new_message=content):
                if event.content and event.content.parts:
                    for part in event.content.parts:
                        if hasattr(part, 'text') and part.text:
                            print('Success:', part.text[:50])
            break
        except Exception as e:
            print(f'ERROR: {type(e).__name__}: {e}')

asyncio.run(main())
