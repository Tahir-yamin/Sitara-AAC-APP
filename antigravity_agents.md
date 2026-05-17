# 🧠 Sitara — Google Antigravity Agent Definitions
## Full Prompts, Tool Schemas & Reasoning Flows

---

## Architecture Overview

```
User (Child taps card) → Flutter App
        ↓
  [Session Event Logger]
        ↓
  Google Antigravity Orchestrator
        ↓
  ┌─────────────────────────────────────────────┐
  │  Agent 1: Therapy Director                  │
  │  Agent 2: Story Weaver                      │
  │  Agent 3: Progress Guardian                 │
  └─────────────────────────────────────────────┘
        ↓
  Adaptation Response → Flutter App
```

---

## AGENT 1: Therapy Director
**Role:** The brain of the session. Observes child behaviour in real time, reasons about emotional/cognitive state, and adapts the game.

### System Prompt
```
You are the Therapy Director for Sitara, a gentle AI companion game for non-verbal autistic children in Pakistan.

Your role is to observe session data and adapt the game experience in real time to maximise engagement, reduce frustration, and celebrate progress.

You receive structured session events from the mobile app and must reason step-by-step before making any adaptation decision.

REASONING PROTOCOL:
1. OBSERVE: What signals am I seeing? (tap speed, success rate, category, time in session)
2. INFER: What is the child's likely emotional/cognitive state right now?
3. DECIDE: What single adaptation will best help this child right now?
4. ACT: Call the appropriate tool with clear parameters.
5. LOG: Explain your reasoning in plain language (this appears in the Antigravity trace panel).

FRUSTRATION SIGNALS:
- 3+ failed attempts on same card → HIGH frustration
- Tap speed > 3 taps/second (rapid random tapping) → frustration
- Session time > 15 mins, success rate dropping → fatigue
- No interaction for 30+ seconds → disengagement

ENGAGEMENT SIGNALS:
- Success rate > 80% for last 10 cards → ready for challenge
- Consistent 1–2 taps per card → focused engagement
- Returning to same category voluntarily → preference signal

ADAPTATION ACTIONS (use tools below):
- switch_category: Move to child's preferred/easier category
- adjust_difficulty: Increase/decrease number of cards shown, card size
- trigger_reward: Celebrate a milestone (stars, animation, Urdu praise)
- generate_quest: Ask Story Weaver to create a new mini-adventure
- send_break_prompt: Gentle suggestion to take a break
- log_insight: Record a non-obvious observation for the parent report

IMPORTANT RULES:
- Never make more than ONE adaptation per 60-second window (avoid overwhelming)
- Always prefer positive reinforcement over difficulty reduction alone
- Urdu praise phrases: "Shabash!", "Wah wah!", "Bohat acha!", "Shero!", "Kamaal!"
- Frame everything as adventure, never as test or therapy
```

### Tools Schema
```json
{
  "tools": [
    {
      "name": "get_session_state",
      "description": "Retrieve current session metrics for the active child",
      "parameters": {
        "child_id": "string",
        "window_seconds": "integer (default: 60)"
      },
      "returns": {
        "success_rate": "float (0-1)",
        "tap_speed_avg": "float (taps/second)",
        "current_category": "string",
        "cards_attempted": "integer",
        "cards_mastered": "integer",
        "session_duration_mins": "float",
        "last_action_seconds_ago": "integer",
        "consecutive_failures": "integer"
      }
    },
    {
      "name": "switch_category",
      "description": "Change the active card category to reduce frustration or match preference",
      "parameters": {
        "child_id": "string",
        "target_category": "string (animals|food|family|emotions|daily_routines|transport)",
        "reason": "string (human-readable explanation shown in trace)"
      }
    },
    {
      "name": "adjust_difficulty",
      "description": "Change number of cards shown per round or card display size",
      "parameters": {
        "child_id": "string",
        "cards_per_round": "integer (2-6)",
        "card_size": "string (small|medium|large)",
        "reason": "string"
      }
    },
    {
      "name": "trigger_reward",
      "description": "Fire a celebration animation + Urdu audio praise",
      "parameters": {
        "child_id": "string",
        "reward_type": "string (star|confetti|dance|level_up)",
        "praise_phrase": "string (Urdu)",
        "milestone_achieved": "string"
      }
    },
    {
      "name": "generate_quest",
      "description": "Request Story Weaver to create a new personalised mini-adventure",
      "parameters": {
        "child_id": "string",
        "preferred_category": "string",
        "child_name": "string",
        "difficulty": "string (easy|medium|hard)"
      }
    },
    {
      "name": "send_break_prompt",
      "description": "Display a gentle break suggestion on screen",
      "parameters": {
        "child_id": "string",
        "break_type": "string (stretch|water|hug)"
      }
    },
    {
      "name": "log_insight",
      "description": "Record a session observation for the parent Progress Guardian report",
      "parameters": {
        "child_id": "string",
        "insight_type": "string (preference|mastery|breakthrough|struggle)",
        "description": "string",
        "evidence": "string"
      }
    }
  ]
}
```

### Example Reasoning Trace (What Judges See)
```
[THERAPY DIRECTOR - 14:32:07]
OBSERVE: Child ID zara_001 | Last 60s: 7 attempts, 2 successes (29% rate)
         Consecutive failures: 4 | Category: emotions | Tap speed: 2.8/sec
INFER:   Low success rate + rising tap speed = frustration building.
         Emotion cards are cognitively demanding. Child needs relief.
DECIDE:  Switch to 'animals' (highest historical success: 87%) + trigger reward
         to reset emotional state positively before difficulty returns.
ACT:     → switch_category(target="animals", reason="frustration detected, switching to preferred high-success category")
         → trigger_reward(type="star", praise="Shabash! Chalo naya adventure!", milestone="resilience")
LOG:     "Zara showed frustration with emotion recognition cards. Animals category
          historically her strongest. Switching to rebuild confidence before retry."
```

---

## AGENT 2: Story Weaver
**Role:** Generates short, personalised mini-adventure narratives that give the card game context and purpose. Makes therapy feel like play.

### System Prompt
```
You are the Story Weaver for Sitara. You create short, joyful, culturally relevant mini-adventures for non-verbal autistic children in Pakistan.

Your stories are:
- 3-5 sentences maximum (short, clear, engaging)
- Centred on a friendly character (Sitara the glowing star, or a local animal the child loves)
- Culturally grounded (mention mango, chai, desi food, Eid, family, cricket, cats)
- Structured as a simple quest: CHARACTER needs SOMETHING → child helps by identifying cards
- Bilingual-friendly: Mix simple English with Urdu words naturally
- Always positive, never scary, never time-pressured

QUEST STRUCTURE:
"Sitara needs to [goal]. Help her find the right [category]! 
[2-3 sentence setup]. 
Can you help Sitara? Tap the card to show her!"

CATEGORIES MAP TO QUESTS:
- animals → "Sitara's friend [animal] is lost! Help find him."
- food → "Sitara is cooking for Eid! She needs to find [food]."
- family → "Sitara's dadi is calling! Show her who is coming."
- emotions → "Sitara's friend feels something. Can you tell how?"
- daily_routines → "Time for [routine]! Help Sitara get ready."

PERSONALISATION:
- Use child's name in the story
- Reference their favourite category/animal if known
- If child just mastered something → celebrate it in the next story

OUTPUT FORMAT (JSON):
{
  "quest_title": "short title",
  "story_text": "full story (English + Urdu words mixed)",
  "target_category": "category name",
  "character": "Sitara|cat|dog|elephant",
  "urdu_hook": "one short Urdu phrase to open",
  "difficulty": "easy|medium|hard"
}
```

### Example Output
```json
{
  "quest_title": "Sitara's Eid Feast",
  "story_text": "Mubarak ho! It's Eid and Sitara wants to make a special feast for her family. She needs to find all the yummy khana! There are mangoes, samosas, and kheer — but they're all mixed up. Zara, can you help Sitara find the right food? Tap the card to show her!",
  "target_category": "food",
  "character": "Sitara",
  "urdu_hook": "Mubarak ho, Zara!",
  "difficulty": "easy"
}
```

---

## AGENT 3: Progress Guardian
**Role:** Synthesises session data across multiple days into warm, clear, actionable parent reports. The agent that makes parents feel seen and supported.

### System Prompt
```
You are the Progress Guardian for Sitara. You support parents of non-verbal autistic children in Pakistan by turning raw session data into warm, clear, encouraging progress reports.

Your reports are:
- Written for a Pakistani parent (may be Urdu-speaking, use simple English with Urdu phrases)
- Warm and encouraging — celebrate EVERY step forward, no matter how small
- Specific and evidence-based (cite actual numbers, not vague praise)
- Actionable — give 1-2 simple suggestions per report
- Never clinical or medical — frame as "communication journey", never as diagnosis

REPORT STRUCTURE:
1. WARM GREETING (personalised, mentions child by name)
2. THIS WEEK'S WINS (3 specific achievements with evidence)
3. WHAT YOUR CHILD LOVES (preference insights)
4. GENTLE OBSERVATIONS (1-2 struggles, framed constructively)
5. SUGGESTED HOME ACTIVITY (1 simple thing parent can do offline)
6. NEXT WEEK PREVIEW (what Sitara will try next)
7. ENCOURAGEMENT CLOSE (warm, personal)

TONE EXAMPLES:
✅ "Zara recognised 'mango' 8 times this week — she's building her food vocabulary beautifully!"
✅ "We noticed Zara lights up with animal cards. Try pointing to animals on your walk together!"
❌ "Zara failed emotion recognition 14 times." (Never frame as failure)
❌ "Your child shows deficits in..." (Never clinical language)

TOOLS AVAILABLE:
- get_child_session_history(child_id, days=7)
- get_mastered_symbols(child_id)
- get_category_preferences(child_id)
- get_therapist_insights(child_id)  [from Therapy Director logs]
- generate_report(child_id, report_data)
```

### Example Report Output
```
🌟 Sitara Weekly Report — Zara's Journey

Assalamu Alaikum!

What a wonderful week for Zara! She spent 4 sessions exploring Sitara's world, 
and we're so excited to share what we saw. 💫

THIS WEEK'S WINS ✨
• Zara recognised 12 NEW symbols this week — up from 7 last week!
• She mastered the entire "Animals" category (15/15 cards). 
  Whenever she saw the cat card, she tapped it immediately — she loves cats! 🐈
• She completed her first full quest ("Sitara's Eid Feast") without any breaks. 
  That's a huge milestone for focus and persistence. Mubarak ho!

WHAT ZARA LOVES 💖
Zara's favourite category is clearly Animals — 87% success rate and the highest 
engagement. She also showed growing interest in Food cards, especially mango and 
chai. Keep this in mind when talking to her at home!

SOMETHING WE NOTICED 🤍
Emotion cards (happy, sad, angry) are still a bit challenging — that's completely 
normal and she's making progress. We've been alternating them gently with her 
favourite animal cards so she doesn't feel pressured.

TRY THIS AT HOME 🏠
When you're out for a walk, point to animals and say their name in Urdu and English. 
If Zara taps or points back — celebrate loudly! "Shabash Zara!" That connection 
between real world and symbols is magic.

NEXT WEEK 🔭
Sitara will introduce Family cards — dada, dadi, ammi, abu, bhai. 
We think Zara will love recognising her favourite people!

You are doing an amazing job, and so is Zara. 
Every tap, every try, every session is a step forward. 
We're on this journey with you. ❤️

— The Sitara Team
```

---

## Antigravity Orchestration Flow (Python Pseudocode)

```python
# antigravity_orchestrator.py
import antigravity as ag

# Initialise agents
therapy_director = ag.Agent(
    name="therapy_director",
    system_prompt=THERAPY_DIRECTOR_PROMPT,
    tools=[get_session_state, switch_category, adjust_difficulty, 
           trigger_reward, generate_quest, send_break_prompt, log_insight],
    model="gemini-2.0-flash",
    enable_tracing=True  # CRITICAL: Shows reasoning in judge panel
)

story_weaver = ag.Agent(
    name="story_weaver", 
    system_prompt=STORY_WEAVER_PROMPT,
    tools=[get_child_profile, get_session_history],
    model="gemini-2.0-flash",
    output_schema=QuestSchema
)

progress_guardian = ag.Agent(
    name="progress_guardian",
    system_prompt=PROGRESS_GUARDIAN_PROMPT,
    tools=[get_child_session_history, get_mastered_symbols, 
           get_category_preferences, get_therapist_insights, generate_report],
    model="gemini-2.0-flash"
)

# Multi-agent orchestrator
orchestrator = ag.Orchestrator(
    agents=[therapy_director, story_weaver, progress_guardian],
    routing_strategy="event_driven",
    trace_all=True  # Full Antigravity trace for submission
)

# Event handler (called from Flutter every 30 seconds)
def on_session_event(event: SessionEvent):
    if event.type == "card_interaction":
        response = therapy_director.run(
            f"Session update for {event.child_id}: {event.to_json()}"
        )
        return response.actions  # List of adaptations to apply
    
    elif event.type == "quest_request":
        quest = story_weaver.run(
            f"Generate quest for {event.child_id}, category: {event.preferred_category}"
        )
        return quest.output
    
    elif event.type == "weekly_report_request":
        report = progress_guardian.run(
            f"Generate weekly report for {event.child_id}"
        )
        return report.output

# Export traces for submission
def export_antigravity_traces():
    return orchestrator.get_traces(format="json")
```

---

## Before/After State — What Judges See

### BEFORE Adaptation
```
State: Zara | Category: Emotions | Success Rate: 28% | Consecutive Failures: 4
Cards shown: 4 (medium size) | Session time: 8 min
```

### ANTIGRAVITY TRACE (Live)
```
[THERAPY DIRECTOR 14:32:07] REASONING...
  OBSERVE → success_rate=0.28, consecutive_failures=4, category=emotions
  INFER   → frustration HIGH, cognitive demand too high for current state
  DECIDE  → switch to animals (success_rate_historical=0.87), trigger reward
  ACT     → switch_category("animals") + trigger_reward("star", "Shabash!")
  LOG     → "Detected frustration on emotions. Switching to preferred category."
```

### AFTER Adaptation
```
State: Zara | Category: Animals | Success Rate: 91% | Consecutive Failures: 0
Reward triggered: ⭐ + "Shabash Zara!" audio
New quest loading: "Sitara's Lost Kitten..."
```

**This is your money shot for the demo video.**

---

## TRACK 3 — Client-Side Analytics & Session Intelligence

> **Hackathon relevance:** Antigravity FAQ §Q17 requires "visible reasoning trace" and "retention metrics." This track wires every meaningful gameplay moment to a structured event log, feeds the two-clock session cap system, and produces dual JSON exports (agent traces + game events) that judges can audit directly.

---

### Architecture Overview

```
GameScreen (Flutter)
    │  every tap / reward / break / round change
    ▼
AnalyticsService.log(type, properties)
    │  childId-scoped call
    ▼
LocalDbService.saveGameEvent()
    │  JSON → SharedPreferences
    │  FIFO cap: 1 000 events per child
    ▼
LocalDbService.getGameEvents() / exportEventsAsJson()
    │
    ├──► ParentDashboard  → daily usage bar + dual export button
    └──► Hackathon judges → sitara_events_YYYY-MM-DD.json
```

**Why SharedPreferences, not SQLite:**
Pakistan's budget Android handsets (2–3 GB RAM) cannot reliably run `sqflite` without JNI linking issues on older API levels. SharedPreferences is zero-native-dependency, survives app restarts, and fits well under the 1 000-event FIFO cap that bounds storage to ≈ 300 KB per child.

---

### GameEvent Schema — Full Specification

**Model:** `sitara_app/lib/models/game_event.dart`

Every event is a flat JSON object:

```json
{
  "type":       "card_tapped",
  "child_id":   "child_001",
  "timestamp":  "2026-05-17T14:32:07.441Z",
  "properties": { ... event-specific fields ... }
}
```

#### Event Catalogue

| `type` key | Fired from | Core properties |
|---|---|---|
| `card_tapped` | `_onCardTap()` in `game_screen.dart` | `card_id`, `category`, `correct` (bool) |
| `reward_triggered` | `_showReward()` | `text` (praise phrase), `streak` (int) |
| `difficulty_adjusted` | `_applyAction()` → `switch_category` / `adjust_difficulty` | `cards_per_round`, `category` |
| `break_shown` | `_showBreakOverlay()` | `session_minutes`, `score` |
| `quest_started` | `QuestScreen.initState()` | `category`, `difficulty`, `title` |
| `quest_completed` | Quest completion handler | `category`, `completion_rate`, `time_spent_secs` |
| `agent_session_eval` | 30s heartbeat callback | `actions_count`, `mode` (`agentic`\|`heuristic`) |
| `interaction_cap_hit` | 60s round timer callback | `category`, `target` (card id) |
| `session_cap_hit` | 15-min session timer | `minutes_played` |
| `daily_limit_approached` | Parent Dashboard load | `minutes_today`, `threshold` (15) |
| `unknown` | JSON parse fallback only | — |

#### Dart Enum Mapping

```dart
// lib/models/game_event.dart
enum GameEventType {
  cardTapped,          // 'card_tapped'
  rewardTriggered,     // 'reward_triggered'
  difficultyAdjusted,  // 'difficulty_adjusted'
  breakShown,          // 'break_shown'
  questStarted,        // 'quest_started'
  questCompleted,      // 'quest_completed'
  agentSessionEval,    // 'agent_session_eval'
  interactionCapHit,   // 'interaction_cap_hit'
  sessionCapHit,       // 'session_cap_hit'
  dailyLimitApproached,// 'daily_limit_approached'
  unknown;             // parse fallback — never logged intentionally

  // exhaustive switch guarantees compile-time coverage for new event types
  String get key => switch (this) { ... };

  static GameEventType fromString(String key) =>
      GameEventType.values.firstWhere(
        (e) => e.key == key,
        orElse: () => GameEventType.unknown,
      );
}
```

---

### AnalyticsService API

**File:** `sitara_app/lib/services/analytics_service.dart`

```dart
class AnalyticsService {
  // Production: wraps LocalDbService.instance
  AnalyticsService({required String childId, LocalDbService? db});

  // Testing: explicit db injection, no singleton touch
  @visibleForTesting
  AnalyticsService.withDb({required String childId, required LocalDbService db});

  // Build an event without persisting (for inspection / preview)
  GameEvent buildEvent({required GameEventType type, required Map<String,dynamic> properties});

  // Build + persist in one call — used at every gameplay callsite
  Future<void> log({required GameEventType type, required Map<String,dynamic> properties});

  // Query
  Future<List<GameEvent>> getEvents({int? limitDays});
  Future<int>             getTodayMinutes();   // per-child, per-day counter
  Future<void>            addMinutes(int minutes);

  // Hackathon export — used by Parent Dashboard "Download" button
  Future<String>          exportEventsAsJson({int? limitDays});
}
```

**Design decisions:**
- `childId` is a required field so every event is automatically scoped — no caller can forget to set it.
- `log()` is fire-and-forget (`unawaited` in hot paths like `_onCardTap`) to avoid frame jank.
- `exportEventsAsJson()` returns a pretty-printable JSON string that pairs with the agent trace export for the dual-download judges see.

---

### LocalDbService — Game Events Persistence Layer

**File:** `sitara_app/lib/services/local_db_service.dart` — `// ─── GAME EVENTS ───` section

```dart
// Storage keys — per-child, never cross-pollinate between siblings
String _gameEventsKey(String childId)              => 'game_events_$childId';
String _playMinutesKey(String childId, String date) => 'play_minutes_${childId}_$date';

// Persist one event. FIFO trim keeps RAM bounded.
Future<void> saveGameEvent(GameEvent event) async {
  final key      = _gameEventsKey(event.childId);
  final existing = _p.getStringList(key) ?? [];
  existing.add(jsonEncode(event.toJson()));
  if (existing.length > 1000) existing.removeRange(0, existing.length - 1000);
  await _p.setStringList(key, existing);
}

// Retrieve newest-first, optional recency filter
Future<List<GameEvent>> getGameEvents(String childId, {int? limitDays}) async { ... }

// Daily play-minutes — per-child, per-YYYY-MM-DD
Future<int>  getTodayPlayMinutes(String childId) async { ... }
Future<void> addPlayMinutes(String childId, int minutes) async { ... }

String _todayDateString() {
  final t = DateTime.now();
  return '${t.year.toString().padLeft(4,'0')}-'
         '${t.month.toString().padLeft(2,'0')}-'
         '${t.day.toString().padLeft(2,'0')}';
}
```

**Storage bounds:**

| Store | Key pattern | Cap | Est. size at cap |
|---|---|---|---|
| Game events | `game_events_$childId` | 1 000 entries | ≈ 300 KB |
| Daily minutes | `play_minutes_$childId_YYYY-MM-DD` | unbounded (one int/day) | < 1 KB/year |
| Session events (pre-existing) | `events_$childId` | 500 entries | ≈ 150 KB |

---

### Two-Clock Session Cap System (Task 14)

**Research basis:** Children with ASD aged 8–10 have a 10–15 minute sustained attention span (Diomampo et al., 2025). WHO/AAP recommend ≤ 60 min/day screen time for ages 3–8 (Panjeti-Madan et al., 2023).

**Implementation:** `game_screen.dart` runs two independent timers simultaneously.

```
                    ┌─────────────────────────────────┐
Session Start ───► │  _sessionMinuteTimer (1 min tick)│
                   │  fires 15× before session cap    │
                   └──────────────┬──────────────────-┘
                                  │ at 15 min:
                                  ▼
                         SessionCapHit event logged
                         _sessionCapped = true
                         Full-screen "آج کے لیے بس!" overlay

                   ┌─────────────────────────────────┐
Each loadCards ──► │  _roundTimer (60s one-shot)      │
                   │  resets on every tap             │
                   └──────────────┬──────────────────-┘
                                  │ on 60s timeout:
                                  ▼
                         InteractionCapHit event logged
                         _loadCards() auto-advances round
```

**Dart implementation sketch:**

```dart
// 60-second round timeout — resets after every tap
void _resetRoundTimer() {
  _roundTimer?.cancel();
  _roundTimer = Timer(const Duration(seconds: 60), () {
    _analytics.log(
      type: GameEventType.interactionCapHit,
      properties: {'category': _currentCategory, 'target': _targetCard?.id ?? ''},
    );
    _loadCards(); // auto-advance without child interaction
  });
}

// 15-minute cumulative daily cap — per-child, persisted across sessions
Future<void> _initSessionCaps() async {
  _todayMinutes = await _analytics.getTodayMinutes();
  if (_todayMinutes >= _maxDailyMinutes) {
    setState(() => _sessionCapped = true);
    return;
  }
  _sessionMinuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
    _todayMinutes++;
    _analytics.addMinutes(1);
    if (_todayMinutes >= _maxDailyMinutes) {
      _sessionMinuteTimer?.cancel();
      _analytics.log(
        type: GameEventType.sessionCapHit,
        properties: {'minutes_played': _todayMinutes},
      );
      setState(() => _sessionCapped = true);
    }
  });
}
```

**Cap overlay (bilingual, child-safe):**
```
🌙
آج کے لیے بس!
That's enough for today!
15 minutes played today
[ Go Back ]
```
- Purple overlay (`0xFF6C63FF`, 95% opacity) — matches brand palette
- Child cannot dismiss via back button; requires explicit "Go Back" tap
- Daily counter persists via `SharedPreferences` so re-opening app respects the cap

---

### Event Logging Callsites (Task 15)

Every gameplay event is instrumented in `game_screen.dart`:

| Callsite | Method | Event logged |
|---|---|---|
| Card tap | `_onCardTap()` | `card_tapped` |
| Reward shown | `_showReward()` | `reward_triggered` |
| Break overlay | `_showBreakOverlay()` | `break_shown` |
| Agent heartbeat | `_startAgentCheck()` callback | `agent_session_eval` |
| Difficulty change | `_applyAction()` → `adjust_difficulty` | `difficulty_adjusted` |
| 60s round timeout | `_resetRoundTimer()` callback | `interaction_cap_hit` |
| 15-min cap reached | `_sessionMinuteTimer` callback | `session_cap_hit` |

**Example log sequence for a real session:**

```json
[
  {"type":"card_tapped","child_id":"child_001","timestamp":"2026-05-17T14:31:10Z",
   "properties":{"card_id":"cat","category":"animals","correct":true}},

  {"type":"reward_triggered","child_id":"child_001","timestamp":"2026-05-17T14:31:10Z",
   "properties":{"text":"Shabash!","streak":3}},

  {"type":"card_tapped","child_id":"child_001","timestamp":"2026-05-17T14:31:18Z",
   "properties":{"card_id":"dog","category":"animals","correct":false}},

  {"type":"card_tapped","child_id":"child_001","timestamp":"2026-05-17T14:31:22Z",
   "properties":{"card_id":"dog","category":"animals","correct":false}},

  {"type":"card_tapped","child_id":"child_001","timestamp":"2026-05-17T14:31:26Z",
   "properties":{"card_id":"dog","category":"animals","correct":false}},

  {"type":"agent_session_eval","child_id":"child_001","timestamp":"2026-05-17T14:31:40Z",
   "properties":{"actions_count":2,"mode":"agentic"}},

  {"type":"difficulty_adjusted","child_id":"child_001","timestamp":"2026-05-17T14:31:41Z",
   "properties":{"cards_per_round":2,"category":"food"}},

  {"type":"break_shown","child_id":"child_001","timestamp":"2026-05-17T14:40:05Z",
   "properties":{"session_minutes":9,"score":420}},

  {"type":"session_cap_hit","child_id":"child_001","timestamp":"2026-05-17T14:46:10Z",
   "properties":{"minutes_played":15}}
]
```

This log sequence exactly mirrors what the Therapy Director saw — making `sitara_events.json` a ground-truth audit trail for judges verifying agentic adaptation claims.

---

### Error Handling & Offline Resilience

#### 1. Persistence failure (SharedPreferences unavailable)

`LocalDbService.init()` is called once at app startup (`main.dart`). If `SharedPreferences.getInstance()` throws, the app falls back to in-memory `SessionTracker` only — gameplay continues without persistence. `AnalyticsService.log()` wraps `saveGameEvent()` in a try/catch (inherited from `LocalDbService`'s `_p` guard) so a persistence failure never crashes the UI loop.

```dart
// LocalDbService getter — throws StateError on uninitialized access,
// caught by AnalyticsService.log() so gameplay is never interrupted
SharedPreferences get _p {
  if (_prefs == null) throw StateError('LocalDbService not initialized.');
  return _prefs!;
}
```

#### 2. FIFO cap overflow

When `saveGameEvent` sees > 1 000 entries, `removeRange(0, length - 1000)` purges the oldest events atomically before the write. No crash, no silent data loss — the most recent 1 000 events are always retained.

#### 3. 60s round timer leak prevention

`_roundTimer` is always cancelled before being re-created:
```dart
void _resetRoundTimer() {
  _roundTimer?.cancel();   // ← prevents timer doubling on rapid loadCards calls
  _roundTimer = Timer(...);
}
```
Both `_roundTimer` and `_sessionMinuteTimer` are cancelled in `dispose()` to prevent setState-after-dispose crashes.

#### 4. Agent mode vs heuristic mode event parity

`agent_session_eval` records `mode: "agentic"` or `mode: "heuristic"` so the export differentiates sessions run under the Therapy Director vs the fixed-rule baseline. Judges can filter the event log to compare both modes in the same export file.

#### 5. Multi-child household isolation

All keys are scoped to `childId`:
- `game_events_child_001` vs `game_events_child_002`
- `play_minutes_child_001_2026-05-17` vs `play_minutes_child_002_2026-05-17`

Switching children in onboarding never pollutes the other child's event history or daily cap.

---

### Parent Dashboard Integration (Task 16)

**File:** `sitara_app/lib/screens/parent_dashboard.dart`

#### Daily Usage Progress Bar

Loaded on `initState()` via `_analytics.getTodayMinutes()`. Updates colour dynamically:

| Progress | Colour | Label |
|---|---|---|
| 0–69% | Teal `0xFF43C59E` | `"X min left"` |
| 70–99% | Orange | `"X min left"` |
| 100% | Red | `"Done for today"` |

```
Today: 11 / 15 min  ·  4 min left
████████████████████░░░░░░░░░░░░  (73%)
```

#### Dual Export (Hackathon Submission Artefact)

The download button now exports two payloads in a single tap:

```dart
Future<void> _exportData() async {
  final traces    = _agentService.exportTracesAsJson();   // agent reasoning
  final analytics = await _analytics.exportEventsAsJson(limitDays: 7); // game events
  debugPrint('[TRACE EXPORT]\n$traces');
  debugPrint('[ANALYTICS EXPORT]\n$analytics');
}
```

Judges open Android `adb logcat` or the Flutter DevTools console and see two clearly labelled JSON blocks:

```
[TRACE EXPORT]
[{"timestamp":"14:32:07","agent":"TherapyDirector","observe":"...","decide":"..."}...]

[ANALYTICS EXPORT]
[{"type":"card_tapped","child_id":"child_001","timestamp":"...","properties":{...}}...]
```

These two files together satisfy the hackathon requirement for "Antigravity traces/logs exported from Agent Trace Panel."

---

### Complete Data Flow — End-to-End

```
Child taps card
    │
    ├─► SessionTracker.recordEvent()        [in-memory, feeds 30s heartbeat]
    │
    ├─► AnalyticsService.log(cardTapped)    [persisted to SharedPreferences]
    │
    └─► SymbolCardWidget feedback           [bounce / shake animation]

30s heartbeat fires
    │
    ├─► AntigravityService.evaluateSession()  [POST /evaluate-session → ADK]
    │       │
    │       └─► Therapy Director reasons → returns actions
    │
    ├─► _applyAction(actions)               [UI update]
    │       │
    │       └─► AnalyticsService.log(difficultyAdjusted | breakShown | ...)
    │
    └─► AnalyticsService.log(agentSessionEval)  [mode + actions_count]

60s round timer fires (no tap in 60s)
    └─► AnalyticsService.log(interactionCapHit)
    └─► _loadCards()  [advance to next round silently]

15-min session timer fires
    └─► AnalyticsService.log(sessionCapHit)
    └─► _sessionCapped = true  [full-screen bilingual overlay]

Parent opens Dashboard
    └─► AnalyticsService.getTodayMinutes()  [daily bar]
    └─► Export button → dual JSON download
```

---

### Hackathon Checklist — Track 3 Coverage

| Requirement | Covered by | File |
|---|---|---|
| Retention metrics visible | Daily usage bar | `parent_dashboard.dart` |
| Agent reasoning traceable | `agent_session_eval` event + trace export | `game_screen.dart` |
| Baseline vs agentic comparison | `mode` field on `agent_session_eval` | `game_screen.dart` |
| Antigravity traces exportable | Dual JSON export button | `parent_dashboard.dart` |
| Session limits (research-backed) | 15-min cap + 60s round timeout | `game_screen.dart` |
| Offline-first | SharedPreferences, no network needed | `local_db_service.dart` |
| Privacy (zero PII to backend) | `child_id` is opaque UUID, no names in events | `analytics_service.dart` |
| Edge case / failure demo | FIFO trim, timer cancel-on-dispose, persist guard | `local_db_service.dart` |
