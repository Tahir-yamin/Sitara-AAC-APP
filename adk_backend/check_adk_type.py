
import asyncio
from google.adk.agents import LlmAgent
import inspect

async def check():
    agent = LlmAgent(model="gemini-1.5-flash", instructions="test")
    print(f"run_async is async generator: {inspect.isasyncgenfunction(agent.run_async)}")
    print(f"run_async is coroutine function: {inspect.iscoroutinefunction(agent.run_async)}")

if __name__ == "__main__":
    asyncio.run(check())
