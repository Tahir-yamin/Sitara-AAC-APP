Project: Sitara — Antigravity AI-Orchestrated AAC (Augmentative & Alternative Communication) Platform
Status: Google Antigravity Hackathon Submission (Challenge 4 — #AISeekho2026)
Technology Stack: Flutter (Android), FastAPI (Python), Google ADK + Gemini 2.0 Flash, SQLite, shared_preferences
Date Analyzed: 2026-05-16

1. PROJECT STRUCTURE & DIRECTORY TREE
Root Level
D:\my-dev-knowledge-base\sitara/
├── CLAUDE.md                           # Developer guidance
├── README.md                            # Project overview
├── Project_Architecture_Blueprint.md    # Architecture documentation
├── antigravity_agents.md               # Agent prompts & schemas
├── demo_script_readme.md               # 3-min demo video script
├── flutter_structure.md                # Flutter organization notes
├── architecture_blueprint.md           # Backup architecture doc
├── .claude/                            # Claude Code settings
├── .github/workflows/firebase-deploy.yml  # CI/CD pipeline
├── .vscode/extensions.json
├── adk_backend/                        # Python FastAPI backend
│   ├── agent.py                       # MAIN: All agents, tools, endpoints
│   ├── requirements.txt                # Python dependencies
│   ├── Dockerfile                      # Cloud Run container
│   ├── deploy_cloud_run.sh            # Linux deployment script
│   ├── deploy_cloud_run.ps1           # Windows PowerShell script
│   ├── sitara_sessions.db              # SQLite session storage
│   ├── sitara_sessions_test.db         # Test database
│   ├── scratch/                        # Development scripts
│   │   ├── check_imports.py
│   │   └── final_integration_test.py
│   ├── test_*.py (8 files)            # Testing scripts
│   ├── check_*.py (4 files)           # Diagnostic scripts
│   └── venv/                           # Python virtual environment
└── sitara_app/                         # Flutter Android app
    ├── pubspec.yaml                   # Flutter dependencies
    ├── lib/
    │   ├── main.dart                  # App entry point
    │   ├── app.dart                   # Root widget
    │   ├── services/
    │   │   ├── antigravity_service.dart    # Backend API bridge
    │   │   ├── session_tracker.dart        # Event collection
    │   │   ├── tts_service.dart            # Text-to-speech
    │   │   └── local_db_service.dart       # Offline persistence
    │   ├── screens/
    │   │   ├── game_screen.dart            # Main gameplay (30s timer)
    │   │   ├── quest_screen.dart           # Quest narrative display
    │   │   ├── parent_dashboard.dart       # Weekly reports
    │   │   ├── home_screen.dart
    │   │   ├── splash_screen.dart
    │   │   └── onboarding_screen.dart
    │   ├── widgets/
    │   │   ├── symbol_card_widget.dart     # Single card UI
    │   │   └── agent_trace_widget.dart     # Judge-facing trace panel
    │   ├── models/
    │   │   ├── session_event.dart          # Event data model
    │   │   └── symbol_card.dart
    │   └── data/
    │       └── symbols_data.dart           # Hardcoded 50 symbol cards
    ├── test/
    │   └── agent_service_test.dart
    ├── analysis_options.yaml            # Dart linting config
    └── .dart_tool/                      # Build artifacts
2. CRITICAL FILES ANALYSIS
adk_backend/agent.py (769 lines)
Core Backend Implementation

Architecture:

Three LLM agents: Therapy Director (orchestrator), Story Weaver (sub-agent), Progress Guardian (independent)
True A2A (Agent-to-Agent) delegation: Therapy Director calls generate_quest_via_story_weaver() tool which internally runs Story Weaver
Session service: DatabaseSessionService (SQLite) for production, InMemorySessionService fallback for local testing
Three FastAPI endpoints: /evaluate-session, /generate-quest, /weekly-report, plus /health
Tools (Direct & A2A):

get_session_state() — retrieves session metrics from Firestore (fallback to mock data)
switch_category() — changes active card category
adjust_difficulty() — modifies cards per round and card size
trigger_reward() — celebration animation + Urdu praise
send_break_prompt() — suggests break to child
log_insight() — records session observation for parent report
generate_quest_via_story_weaver() — A2A delegation to Story Weaver
Key Features:

Quality Control (QC) gate on Story Weaver output via _validate_quest()
Quota cooldown mechanism (60s) on 429 errors with fallback to FixedRuleEngine
Baseline (heuristic) mode comparison for hackathon judging
CORS middleware configured
Global exception handler detects 429/503 and routes gracefully
SECURITY & ERROR HANDLING ISSUES IDENTIFIED:
CRITICAL: API Key Hardcoding Risk
GOOGLE_API_KEY = os.environ.get("GOOGLE_API_KEY", os.environ.get("GEMINI_API_KEY", ""))
if not GOOGLE_API_KEY:
    print("[CRITICAL] No API key available...")
No explicit error exit if API key is missing — app starts but will crash on first agent call
Fallback to GEMINI_API_KEY env var is not documented in CLAUDE.md
Fix: Explicitly fail at startup if GOOGLE_API_KEY is not set before creating LlmAgent instances
ISSUE: Firestore Client Initialization Without Error Handling
try:
    db = firestore.Client()
except Exception as e:
    print(f"[WARN] Firestore could not be initialized...")
    db = None
Silent failure; get_session_state() will always return mock data if Firestore fails
No logging to track which deployments are using fallback vs. real data
Fix: Log to Cloud Logging and include fallback status in /health endpoint
ISSUE: Race Condition in Session Creation
async def _get_or_create_session(user_id: str, session_id: str):
    try:
        existing = await session_service.get_session(...)
        if existing:
            return existing
    except Exception:
        pass
    
    try:
        return await session_service.create_session(...)
    except AlreadyExistsError:
        return await session_service.get_session(...)
Between get_session and create_session, another request could create the same session (unlikely but possible)
Final fallback assumes get_session will succeed after AlreadyExistsError — if it fails, exception bubbles unhandled
Fix: Add max retries and exponential backoff
ISSUE: Unvalidated JSON Parsing in /generate-quest
try:
    clean = response_text.strip()
    if clean.startswith("```"):
        clean = clean.split("```")[1]  # ← No bounds check
        if clean.startswith("json"):
            clean = clean[4:]  # ← May IndexError if "```json" exactly
    parsed = json.loads(clean.strip())
except (json.JSONDecodeError, IndexError):
    return {**fallback_quest, "qc_status": "parse_error"}
String slicing is fragile; if response is exactly ```json with no closing ```` ```, split returns 1 element (IndexError)
Silent fallback hides model output quality issues
Fix: Use regex r'```(?:json)?\s*(.*?)\s*```' and log raw response on parse failure for debugging
ISSUE: Session Storage Not Cleared on App Crash
InMemorySessionService loses all state if backend crashes (no persistence)
DatabaseSessionService requires proper async context; no docs on migration strategy
Fix: Document InMemorySessionService as dev-only; require DatabaseSessionService for Cloud Run
ISSUE: No Rate Limiting on Endpoints
30-second heartbeat from Flutter can hammer /evaluate-session on poor connection retries
No request throttling; quota cooldown only triggers after 429
Fix: Add rate limiter per child_id with sliding window (e.g., max 3 requests per 10s)
ISSUE: Hardcoded Model Name
therapy_director = LlmAgent(..., model="gemini-2.0-flash", ...)
No way to toggle model version without code change
No fallback if model becomes unavailable
Fix: Read model from env var with default
sitara_app/lib/services/antigravity_service.dart (376 lines)
Flutter Backend Bridge

Key Features:

Benchmark toggle: _useHeuristic flag switches between agentic AI and baseline heuristic
Fallback mechanism: _localFallback() provides rule-based adaptation when API unreachable
Trace logging: All agent calls recorded in traceLog for judge panel
Session summary: _summariseEvents() aggregates tap events into metrics
SECURITY & ERROR HANDLING ISSUES:
ISSUE: No HTTP Timeout on API Calls
Future<Map<String, dynamic>> _post({...}) async {
    try {
        final res = await http.post(Uri.parse(...), ...);
        if (res.statusCode == 200) { ... }
        else {
            return _localFallback(endpoint);
        }
    } catch (e) {
        return _localFallback(endpoint);
    }
}
http.post() has no timeout parameter; hangs indefinitely on poor connection
Child waits up to session timeout for API response
Fix: Add .timeout(Duration(seconds: 10)) to all POST calls
Impact: Low (fallback is safe), but user experience poor on slow connections
ISSUE: Unhandled Cast Exception in _parseActions()
List<AdaptationAction> _parseActions(dynamic actionsJson) {
    if (actionsJson == null) return [];
    return (actionsJson as List)  // ← May throw if not List
        .map((a) => AdaptationAction.fromJson(a as Map<String, dynamic>))
        .toList();
}
No validation that actionsJson is actually a List; if backend returns object instead, crashes
No try/catch; error propagates to GameScreen and crashes session
Fix: Add type check and return empty list on mismatch
ISSUE: Tap Speed Calculation Division by Zero
Map<String, dynamic> _summariseEvents(List<SessionEvent> events) {
    if (events.isEmpty) return {};
    final avgTapSpeed = events.map((e) => e.tapSpeed)
        .reduce((a, b) => a + b) / events.length;  // ← Safe (checked isEmpty)
Actually safe due to isEmpty check, but pattern is error-prone
Fix: Use .fold(0.0, (a, b) => a + b) / events.length for clarity
ISSUE: Hardcoded Backend URL
static const String _baseUrl = 'https://sitara-backend-178558547254.asia-south1.run.app';
No way to point to local backend during testing
Exposes GCP project number in client code
Fix: Read from environment or config file; provide localhost default for debug builds
sitara_app/lib/screens/game_screen.dart (335 lines)
Main Gameplay Loop

Key Features:

30-second timer calls evaluateSession() on AntigravityService
_applyAction() dispatch pattern maps agent actions to UI mutations
Handles A2A delegation: when generate_quest_via_story_weaver action arrives with quest data, routes to QuestScreen
Animation controllers for rewards and card shake
SECURITY & ERROR HANDLING ISSUES:
ISSUE: No Error Handling on Timer Callback
void _startAgentCheck() {
    _agentCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
        final recentEvents = _tracker.getRecentEvents(seconds: 60);
        if (recentEvents.isEmpty) return;

        final actions = await _agentService.evaluateSession(...);  // ← May throw

        for (final action in actions) {
            _applyAction(action);
        }
        setState(() {});
    });
}
evaluateSession() is awaited but no try/catch
If service throws, timer callback crashes without UI feedback
Child sees frozen screen, no error message
Fix: Wrap in try/catch and show SnackBar on error
ISSUE: Unchecked Cast in _applyAction()
case 'adjust_difficulty':
    final rawCount = action.data['cards_per_round'] ?? 4;
    final count = (rawCount is double) ? rawCount.toInt() : (rawCount as int);
If backend sends string or null, cast fails
Fix: Use safer coercion: (rawCount as num?)?.toInt() ?? 4
ISSUE: Category Load on setState Inside _loadCards()
void _loadCards() {
    if (!mounted) return;
    final allCards = SymbolsData.getCardsByCategory(_currentCategory);
    setState(() {
        _displayCards = (allCards..shuffle()).take(4).toList();
        _targetCard = _displayCards.first;
    });
}
Called from _applyAction() (switch_category case) which is already in timer callback
If _applyAction() is called during Frame 1 and _loadCards() calls setState(), and another timer fires during Frame 2, race condition possible
Fix: Make _loadCards() synchronous (no async operations); use WidgetsBinding.instance.addPostFrameCallback() if needed
sitara_app/lib/services/session_tracker.dart (150 lines)
Event Aggregation

Architecture:

Records every card tap as SessionEvent
Maintains rolling window of events for 60-second agent evaluation
Tracks retention metrics: isChurnRisk, hasDifficultySpikeAbandonment
ISSUES:
MINOR: No Bounds on Event List
final List<SessionEvent> _events = [];

void recordEvent({...}) {
    _sessionStart ??= DateTime.now();
    _events.add(...);  // ← Unbounded growth
    notifyListeners();
}
If session runs for hours, _events grows indefinitely (no memory pressure on mobile, but inefficient)
Fix: Keep only last 500 events (matches LocalDbService limit)
ISSUE: DateTime Parsing Could Fail
List<SessionEvent> getRecentEvents({int seconds = 60}) {
    final cutoff = DateTime.now().subtract(Duration(seconds: seconds));
    return _events.where((e) => e.timestamp.isAfter(cutoff)).toList();
}
Safe (no parsing), but if child's device clock is wrong, cutoff logic breaks
Fix: Add device time sync check on app startup
sitara_app/lib/services/local_db_service.dart (165 lines)
Offline Persistence

Architecture:

Uses shared_preferences (no native dependencies, works on web/mobile/desktop)
Stores JSON-serialized events, profiles, insights with automatic bounds (500 events, 200 insights per child)
SECURITY ISSUES:
CRITICAL: No Encryption of Stored Data
existing.add(jsonEncode({
    'child_id': event.childId,
    'event_type': event.eventType,
    'card_id': event.cardId,
    ...
}));
await _p.setStringList(key, existing);  // ← Plaintext in shared_preferences
Child profile, session events stored unencrypted in SharedPreferences
On rooted Android, any app can read /data/data/com.example.sitara/shared_prefs/
IMPACT: High — session data exposes child's learning patterns and personal information
Fix: Use flutter_secure_storage for sensitive fields; encrypt events before storage
ISSUE: No Backup/Sync Logic
Events stored locally only; if child switches devices, all history lost
No cloud sync mechanism documented
Fix: Add optional Firebase sync (opt-in) for therapist portal
sitara_app/pubspec.yaml
Dependencies (Safe)

provider, shared_preferences, http, fl_chart, google_fonts, uuid, intl, flutter_tts — all standard, well-maintained
No suspicious transitive dependencies detected
adk_backend/requirements.txt
Python Dependencies

google-adk>=1.0.0
fastapi>=0.110.0
uvicorn>=0.27.0
google-cloud-firestore>=2.16.0
pydantic>=2.0.0
aiosqlite>=0.20.0
google-genai>=0.1.0
python-dotenv>=1.0.0
google-cloud-logging>=3.10.0
Issues:

google-genai>=0.1.0 is very permissive (any 0.1.x or higher); pin to specific version
No google-auth explicit dependency; relies on transitive from google-cloud-firestore
Fix: Pin versions: google-genai==0.3.0 (or latest stable); google-adk==1.2.0 (replace with actual)
3. ARCHITECTURE REVIEW
A2A Orchestration Pattern (Correct Implementation)
✅ Therapy Director (orchestrator) → calls generate_quest_via_story_weaver() tool → Story Weaver (sub-agent) returns quest JSON

This is true multi-agent orchestration. The A2A handoff is visible in ADK trace logs.

Session Persistence Strategy
⚠️ Current Design Mismatch:

Code defaults to DatabaseSessionService but documentation emphasizes InMemorySessionService
InMemorySessionService loses state on instance restart (critical flaw for Cloud Run with auto-scaling)
No explicit migration instructions
✅ Fix in Place: Code has try/except fallback to InMemorySessionService if DatabaseSessionService fails

Quota/429 Handling
✅ Well-Implemented:

quota_cooldowns dict tracks 60-second cooldowns per child
Fallback to FixedRuleEngine during cooldown
Both backend and app implement baseline mode for comparison
⚠️ Gap: No proactive quota prediction or request batching to avoid 429 in the first place

4. KEY SECURITY FINDINGS
Severity	Issue	Location	Recommendation
CRITICAL	No HTTP timeout on Flutter API calls	antigravity_service.dart	Add .timeout(Duration(seconds: 10)) to all POST
CRITICAL	Session events stored unencrypted	local_db_service.dart	Use flutter_secure_storage for sensitive fields
HIGH	No error handling on 30s timer callback	game_screen.dart	Add try/catch around evaluateSession() await
HIGH	Hardcoded backend URL exposes GCP project	antigravity_service.dart	Read from environment config
HIGH	API key missing causes silent startup failure	agent.py	Fail loudly at startup if GOOGLE_API_KEY not set
MEDIUM	JSON parsing fragile (string slicing on LLM output)	agent.py line 659-662	Use regex for robust JSON extraction
MEDIUM	Unvalidated type casts in _parseActions()	antigravity_service.dart	Add type guards; return empty list on mismatch
MEDIUM	No rate limiting on /evaluate-session endpoint	agent.py	Add sliding-window rate limit per child_id
MEDIUM	Permissive google-genai>=0.1.0 version	requirements.txt	Pin to specific version (e.g., ==0.3.0)
LOW	Unbounded event list in SessionTracker	session_tracker.dart	Keep last 500 events only
5. PERFORMANCE & SCALABILITY NOTES
Strengths:

Async/await throughout FastAPI (uvicorn handles concurrency well)
DatabaseSessionService can handle multiple Cloud Run instances
Local fallback ensures app works offline
Bottlenecks:

Firestore client creation on every request (should cache/reuse connection)
JSON parsing of LLM output (no streaming; full response buffered in memory)
No pagination on session events (all 500 events loaded into memory on query)
Recommendations:

Cache Firestore client in module-level singleton
Implement streaming JSON parser for large quest responses
Add cursor-based pagination to /get-events endpoint if implemented
6. TEST COVERAGE & DEBUGGING
Test Files Present:

adk_backend/test_adk_quota.py, test_adk_quota_v2.py, test_adk_quota_v3.py — quota handling
adk_backend/test_local.py, test_endpoints.py — full flow and endpoint tests
sitara_app/test/agent_service_test.dart — Dart unit tests
Coverage Gaps:

No integration tests for A2A delegation (Story Weaver called from Therapy Director)
No tests for offline fallback scenario
No load tests for concurrent child sessions
Missing tests for Firestore failure scenarios
7. COMPLIANCE WITH HACKATHON REQUIREMENTS (Challenge 4)
Checklist Status:

✅ Antigravity integration (25%): Therapy Director orchestrates; A2A delegation visible
✅ Engagement and retention (25%): 5 frustration signals, difficulty adaptation, rewards
✅ Agentic innovation (20%): Multi-agent swarm, real-time reasoning
✅ Technical polish (15%): Offline fallback, quota handling, error recovery
✅ Originality (10%): Cultural grounding (Urdu/Roman Urdu/English), Pakistan-specific design
✅ Baseline comparison (Bonus +5%): Sovereign Benchmarking toggle implemented
⚠️ Missing: Explicit cost/latency benchmarks in code comments
8. SUMMARY OF CRITICAL ACTION ITEMS
Before Cloud Run Deployment:
MUST: Set GOOGLE_API_KEY in Cloud Run Secret Manager; add startup validation
MUST: Verify DatabaseSessionService with aiosqlite works in async context
SHOULD: Add HTTP timeout to Flutter API calls
SHOULD: Encrypt sensitive session data in SharedPreferences
SHOULD: Add error handling to 30s timer callback in GameScreen
Before Hackathon Submission:
Pin Python dependency versions in requirements.txt
Document API key setup in deploy_cloud_run.sh
Add cost estimate to demo video / submission notes
Test offline fallback on real device with network disabled
Verify A2A trace appears in Agent Trace Panel widget
9. CODEBASE QUALITY ASSESSMENT
Metric	Rating	Notes
Code Organization	⭐⭐⭐⭐	Clear separation of concerns; good file naming
Documentation	⭐⭐⭐⭐	CLAUDE.md, Project_Architecture_Blueprint.md comprehensive
Error Handling	⭐⭐⭐	Basic fallbacks present; missing timeout/type guards
Testing	⭐⭐⭐	Good unit tests; missing integration/load tests
Security	⭐⭐	Data unencrypted; hardcoded URLs; missing input validation
Performance	⭐⭐⭐⭐	Async/await good; some inefficiencies (unbounded lists)
Accessibility	⭐⭐⭐⭐	Bilingual TTS, high-contrast UI, RTL support for Urdu
This concludes the comprehensive exploration of the Sitara codebase. The project demonstrates strong architectural understanding of multi-agent orchestration and thoughtful cultural design for Pakistani users. Main focus areas for production readiness: error handling robustness, data encryption, and explicit failure mode documentation.