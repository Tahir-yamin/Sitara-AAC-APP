#!/usr/bin/env python3
"""
Quick backend health ping — verifies the live Cloud Run backend is reachable.
For a full judge-facing demo with rich terminal output, use demo_trace.py instead:

    python demo_trace.py --prod --all
"""

import httpx, json, sys

PROD_URL = "https://sitara-backend-178558547254.asia-south1.run.app"
TOKEN    = "dev-token-sitara"

print(f"Pinging {PROD_URL} ...")

try:
    r = httpx.get(f"{PROD_URL}/health",
                  headers={"X-Sitara-Token": TOKEN}, timeout=10)
    print(f"Status : {r.status_code}")
    print(json.dumps(r.json(), indent=2))
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
