# Sitara Security Review Report

## CRITICAL — Must Fix Before Submission

### CRIT-1: Real Google API Keys Hardcoded in Committed Test Scripts
**Affected files:**
- `adk_backend/check_quota.py`
- `adk_backend/test_adk_quota.py`
- `adk_backend/test_adk_quota_v2.py`
- `adk_backend/test_adk_quota_v3.py`
- `adk_backend/test_models_simple.py`
- `adk_backend/list_models.py`
- `adk_backend/check_models_availability.py`
- `adk_backend/verify_backend_local.py`
- `adk_backend/test_models.py`

These scripts contain real `AIzaSy...` format Google API keys committed directly into source. Both unique key values appear multiple times across files. These keys were committed in the initial commit, so they are in full Git history. 

**Required action:** Rotate both keys immediately at `console.cloud.google.com`, then replace all hardcoded values with `os.environ.get("GOOGLE_API_KEY")` only. Use `git filter-repo` or BFG Repo Cleaner to purge from history before any public sharing.

---

## HIGH — Should Fix

### HIGH-1: Backend Exposes No Authentication on Any Endpoint
The Cloud Run deployment uses `--allow-unauthenticated` and there is no API key, bearer token, or authentication middleware on any FastAPI endpoint. Any person who discovers the Cloud Run URL can send unlimited requests, burning Gemini API quota.
**Recommended fix:** Add a simple shared secret header (e.g., `X-Sitara-Token`) checked in a FastAPI middleware.

### HIGH-2: `deploy_cloud_run.sh` Passes API Key as Plain Environment Variable
Environment variables in Cloud Run are visible in plaintext in the Google Cloud Console and in `gcloud run services describe` output. 
**Recommended fix:** Use `--set-secrets "GOOGLE_API_KEY=GOOGLE_API_KEY:latest"` (Secret Manager) instead of `--set-env-vars`.

### HIGH-3: Prompt Injection Risk — User-Controlled Input Injected Directly into LLM Prompts
User-supplied fields from the API request are interpolated directly into f-string prompts passed to the LLM agents without sanitization (`child_id`, `child_name`, `category`, `session_summary`, `therapist_insights`).
**Recommended fix:** Add Pydantic `Field(max_length=...)` constraints to all string inputs.

### HIGH-4: Release APK Signed with Debug Keys
An APK submitted signed with debug keys provides no authenticity guarantee.
**Recommended fix:** Generate a dedicated keystore for the release variant before submission.

---

## MEDIUM — Consider Fixing

### MED-1: Wildcard CORS in Production
The `ALLOWED_ORIGINS` env var is never set in `deploy_cloud_run.sh`, leaving it as `*`. This is a gap if a web dashboard is ever added.

### MED-2: Exception Handler Leaks Internal Error Detail to Client
The global exception handler returns `{"error": ..., "detail": str(exc), "type": exc_type}` to the client for all 500 errors, which may include file paths or internal module names.

### MED-3: Freeform JSON String injected into LLM
In `/weekly-report`, `session_summary` is a raw JSON string the client sends. If malformed, it could disrupt the prompt structure.

### MED-4: Backend URL Hardcoded in Flutter Source
The full Cloud Run URL is embedded in the APK binary (`antigravity_service.dart`), giving anyone the full address of an unauthenticated API endpoint.

### MED-5: `child_id` Generated from Child's Name
The child's name is embedded in the `child_id` (e.g., `zara_1716000000000`) and logged in plaintext. Use a UUID or random hex token instead.

### MED-6: Rate Limiter State Per-Instance
The rate limiter and quota cooldown state are Python dicts in process memory. On Cloud Run, each instance has independent state.

---

## LOW / INFO

### LOW-1: `.db` Files
Verify `adk_backend/*.db` files are not in Git history.

### LOW-2: Unreachable Code
Unreachable `print` after `return False` in `is_rate_limited` (`agent.py:95`).

### LOW-3: Placeholder API Key
Placeholder API key pattern in `flutter_structure.md`.

### LOW-4: Default Package Name
Default `com.example.sitara` package ID still set in `build.gradle.kts`.

### LOW-5: App Backup
No `android:allowBackup="false"` in `AndroidManifest.xml` — session data could transfer via Google backup.
