
try:
    from google.adk.models.google_llm import _ResourceExhaustedError, ClientError
    print("SUCCESS: Found errors in google.adk.models.google_llm")
except ImportError as e:
    print(f"FAILED: {e}")
except Exception as e:
    print(f"ERROR: {e}")
