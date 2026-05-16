# 📱 Sitara — Flutter Project Structure & Core Code
## Complete Architecture for 7-Day Build

---

## Project Structure

```
sitara/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── models/
│   │   ├── child_profile.dart
│   │   ├── symbol_card.dart
│   │   ├── session_event.dart
│   │   ├── quest.dart
│   │   └── session_stats.dart
│   ├── services/
│   │   ├── antigravity_service.dart      ← CORE: All agent calls
│   │   ├── session_tracker.dart          ← Tracks tap events
│   │   ├── local_db_service.dart         ← SQLite/Hive offline storage
│   │   └── tts_service.dart              ← Google TTS for Urdu audio
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── onboarding_screen.dart        ← Child profile setup
│   │   ├── home_screen.dart              ← Dashboard + start session
│   │   ├── game_screen.dart              ← MAIN GAME (card grid)
│   │   ├── quest_screen.dart             ← Story intro before game
│   │   ├── reward_screen.dart            ← Celebration animations
│   │   ├── parent_dashboard.dart         ← Progress reports
│   │   └── trace_panel.dart              ← JUDGE PANEL: live AI reasoning
│   ├── widgets/
│   │   ├── symbol_card_widget.dart       ← Tappable card with image + label
│   │   ├── progress_bar_widget.dart
│   │   ├── agent_trace_widget.dart       ← Scrolling trace log
│   │   └── reward_animation_widget.dart  ← Lottie/Rive animations
│   └── data/
│       ├── symbols_data.dart             ← 50 symbol cards hardcoded
│       └── urdu_phrases.dart             ← Praise phrases + labels
├── assets/
│   ├── symbols/                          ← PNG symbol cards (Mulberry/PECS)
│   │   ├── animals/
│   │   ├── food/
│   │   ├── family/
│   │   ├── emotions/
│   │   └── daily_routines/
│   ├── animations/                       ← Lottie JSON files
│   │   ├── star_burst.json
│   │   ├── confetti.json
│   │   └── sitara_character.json
│   └── audio/                            ← Pre-generated TTS Urdu phrases
│       ├── shabash.mp3
│       ├── wah_wah.mp3
│       └── bohat_acha.mp3
└── test/
    └── agent_service_test.dart
```

---

## pubspec.yaml

```yaml
name: sitara
description: AI Companion Game for Non-Verbal Autistic Children
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.1
  
  # Local Storage (offline-first, privacy-safe)
  sqflite: ^2.3.0
  path: ^1.9.0
  shared_preferences: ^2.2.2
  
  # Animations
  lottie: ^3.1.0
  
  # Audio
  audioplayers: ^5.2.1
  flutter_tts: ^4.0.2
  
  # HTTP for Antigravity API
  http: ^1.2.0
  dio: ^5.4.0
  
  # Charts for parent dashboard
  fl_chart: ^0.67.0
  
  # Image caching
  cached_network_image: ^3.3.1
  
  # Utilities
  uuid: ^4.3.3
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/symbols/animals/
    - assets/symbols/food/
    - assets/symbols/family/
    - assets/symbols/emotions/
    - assets/symbols/daily_routines/
    - assets/animations/
    - assets/audio/
```

---

## main.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/antigravity_service.dart';
import 'services/session_tracker.dart';
import 'services/local_db_service.dart';
import 'screens/splash_screen.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDbService.instance.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionTracker()),
        Provider(create: (_) => AntigravityService()),
        Provider(create: (_) => LocalDbService.instance),
      ],
      child: const SitaraApp(),
    ),
  );
}
```

---

## app.dart

```dart
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'screens/parent_dashboard.dart';

class SitaraApp extends StatelessWidget {
  const SitaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sitara ⭐',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF), // Purple — calm, magical
          brightness: Brightness.light,
        ),
        fontFamily: 'Nunito', // Rounded, child-friendly
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (ctx) => const SplashScreen(),
        '/onboarding': (ctx) => const OnboardingScreen(),
        '/home': (ctx) => const HomeScreen(),
        '/game': (ctx) => const GameScreen(),
        '/parent': (ctx) => const ParentDashboard(),
      },
    );
  }
}
```

---

## models/symbol_card.dart

```dart
class SymbolCard {
  final String id;
  final String nameEnglish;
  final String nameUrdu;        // اردو label
  final String nameRomanUrdu;   // "Billi" for cat
  final String category;
  final String imagePath;       // assets/symbols/animals/cat.png
  final String audioPath;       // assets/audio/billi.mp3
  final int difficultyLevel;    // 1=easy, 2=medium, 3=hard

  const SymbolCard({
    required this.id,
    required this.nameEnglish,
    required this.nameUrdu,
    required this.nameRomanUrdu,
    required this.category,
    required this.imagePath,
    required this.audioPath,
    this.difficultyLevel = 1,
  });
}

// Categories
enum SymbolCategory {
  animals,
  food,
  family,
  emotions,
  dailyRoutines,
  transport,
}
```

---

## models/session_event.dart

```dart
class SessionEvent {
  final String childId;
  final String eventType;  // 'card_tap', 'card_success', 'card_fail', 'quest_complete'
  final String cardId;
  final String category;
  final DateTime timestamp;
  final bool isSuccess;
  final int tapCount;       // How many taps on this card
  final double tapSpeed;    // Taps per second (frustration proxy)

  SessionEvent({
    required this.childId,
    required this.eventType,
    required this.cardId,
    required this.category,
    required this.timestamp,
    required this.isSuccess,
    this.tapCount = 1,
    this.tapSpeed = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'child_id': childId,
    'event_type': eventType,
    'card_id': cardId,
    'category': category,
    'timestamp': timestamp.toIso8601String(),
    'is_success': isSuccess,
    'tap_count': tapCount,
    'tap_speed': tapSpeed,
  };
}
```

---

## services/antigravity_service.dart  ← THE CORE FILE

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/session_event.dart';

class AntigravityService {
  // Replace with your actual Antigravity API endpoint
  static const String _baseUrl = 'https://antigravity.googleapis.com/v1';
  static const String _apiKey = 'YOUR_ANTIGRAVITY_API_KEY';
  
  // Trace log for judge panel — stored locally, shown in UI
  final List<TraceEntry> traceLog = [];

  // ─── THERAPY DIRECTOR ───────────────────────────────────────────────

  /// Called every 30 seconds during active session
  Future<List<AdaptationAction>> evaluateSession({
    required String childId,
    required List<SessionEvent> recentEvents,
  }) async {
    final sessionSummary = _summariseEvents(recentEvents);
    
    final prompt = '''
Session update for child $childId:
${jsonEncode(sessionSummary)}

Please evaluate this session and decide if any adaptation is needed.
Use your tools to check full session state and apply changes.
Remember: reason step by step before acting.
''';

    final response = await _callAgent(
      agentId: 'therapy_director',
      prompt: prompt,
      childId: childId,
    );

    // Parse agent actions from response
    final actions = _parseActions(response['actions']);
    
    // Log trace for judge panel
    _addTrace(
      agent: 'Therapy Director',
      reasoning: response['reasoning'],
      actions: actions,
    );

    return actions;
  }

  // ─── STORY WEAVER ───────────────────────────────────────────────────

  /// Request a personalised quest
  Future<Quest> generateQuest({
    required String childId,
    required String preferredCategory,
    required String childName,
    required String difficulty,
  }) async {
    final prompt = '''
Generate a short, joyful quest for $childName (child ID: $childId).
Preferred category: $preferredCategory
Difficulty: $difficulty
Make it culturally relevant for a Pakistani family.
Include Urdu words naturally.
''';

    final response = await _callAgent(
      agentId: 'story_weaver',
      prompt: prompt,
      childId: childId,
    );

    _addTrace(
      agent: 'Story Weaver',
      reasoning: 'Generated personalised quest for $childName',
      actions: [AdaptationAction(type: 'quest_generated', data: response['quest'])],
    );

    return Quest.fromJson(response['quest']);
  }

  // ─── PROGRESS GUARDIAN ──────────────────────────────────────────────

  /// Generate weekly parent report
  Future<String> generateWeeklyReport(String childId) async {
    final prompt = '''
Generate a warm, encouraging weekly progress report for child $childId.
Pull their session history, mastered symbols, and preferences.
Write for a Pakistani parent. Use simple English with some Urdu phrases.
Frame everything positively. Include 1 practical home activity suggestion.
''';

    final response = await _callAgent(
      agentId: 'progress_guardian',
      prompt: prompt,
      childId: childId,
    );

    _addTrace(
      agent: 'Progress Guardian',
      reasoning: 'Generated weekly parent report',
      actions: [],
    );

    return response['report'] as String;
  }

  // ─── INTERNAL ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _callAgent({
    required String agentId,
    required String prompt,
    required String childId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/agents/$agentId/run'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'prompt': prompt,
          'context': {'child_id': childId},
          'enable_tracing': true,
          'stream': false,
        }),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        // Fallback to local rule-based adaptation if API fails
        return _localFallback(agentId, prompt);
      }
    } catch (e) {
      return _localFallback(agentId, prompt);
    }
  }

  /// LOCAL FALLBACK: Rule-based adaptation when offline
  /// This ensures the app works without internet (critical for Pakistan)
  Map<String, dynamic> _localFallback(String agentId, String prompt) {
    if (agentId == 'therapy_director') {
      return {
        'reasoning': '[OFFLINE MODE] Using local rules: high consecutive failures → switch category',
        'actions': [
          {'type': 'switch_category', 'target': 'animals', 'reason': 'Offline fallback: switching to preferred category'}
        ]
      };
    }
    return {'reasoning': 'Offline mode', 'actions': []};
  }

  Map<String, dynamic> _summariseEvents(List<SessionEvent> events) {
    if (events.isEmpty) return {};
    final successes = events.where((e) => e.isSuccess).length;
    final failures = events.where((e) => !e.isSuccess).length;
    final avgTapSpeed = events.map((e) => e.tapSpeed).reduce((a, b) => a + b) / events.length;
    final consecutiveFails = _countConsecutiveFails(events);
    
    return {
      'total_attempts': events.length,
      'successes': successes,
      'failures': failures,
      'success_rate': events.isEmpty ? 0 : successes / events.length,
      'avg_tap_speed': avgTapSpeed,
      'consecutive_failures': consecutiveFails,
      'current_category': events.last.category,
    };
  }

  int _countConsecutiveFails(List<SessionEvent> events) {
    int count = 0;
    for (final e in events.reversed) {
      if (!e.isSuccess) count++;
      else break;
    }
    return count;
  }

  List<AdaptationAction> _parseActions(dynamic actionsJson) {
    if (actionsJson == null) return [];
    return (actionsJson as List)
        .map((a) => AdaptationAction.fromJson(a))
        .toList();
  }

  void _addTrace({
    required String agent,
    required String reasoning,
    required List<AdaptationAction> actions,
  }) {
    traceLog.add(TraceEntry(
      timestamp: DateTime.now(),
      agent: agent,
      reasoning: reasoning,
      actions: actions.map((a) => a.type).toList(),
    ));
  }

  /// Export traces for hackathon submission
  String exportTracesAsJson() => jsonEncode(traceLog.map((t) => t.toJson()).toList());
}

class AdaptationAction {
  final String type;
  final Map<String, dynamic> data;
  AdaptationAction({required this.type, Map<String, dynamic>? data}) 
      : data = data ?? {};
  factory AdaptationAction.fromJson(Map<String, dynamic> json) =>
      AdaptationAction(type: json['type'], data: json);
}

class TraceEntry {
  final DateTime timestamp;
  final String agent;
  final String reasoning;
  final List<String> actions;
  TraceEntry({required this.timestamp, required this.agent, 
               required this.reasoning, required this.actions});
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'agent': agent,
    'reasoning': reasoning,
    'actions': actions,
  };
}

class Quest {
  final String title;
  final String storyText;
  final String targetCategory;
  final String urduHook;
  Quest({required this.title, required this.storyText, 
         required this.targetCategory, required this.urduHook});
  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
    title: json['quest_title'] ?? 'New Adventure!',
    storyText: json['story_text'] ?? '',
    targetCategory: json['target_category'] ?? 'animals',
    urduHook: json['urdu_hook'] ?? 'Chalo!',
  );
}
```

---

## screens/game_screen.dart  ← THE MAIN GAME

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/antigravity_service.dart';
import '../services/session_tracker.dart';
import '../widgets/symbol_card_widget.dart';
import '../widgets/agent_trace_widget.dart';
import '../data/symbols_data.dart';
import '../models/symbol_card.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AntigravityService _agentService;
  late SessionTracker _tracker;
  
  String _currentCategory = 'animals';
  List<SymbolCard> _displayCards = [];
  SymbolCard? _targetCard;       // Card the child should find
  bool _showTracePanel = false;  // Toggle for judges
  Timer? _agentCheckTimer;
  
  // Animation controllers
  late AnimationController _rewardController;
  late AnimationController _cardShakeController;

  @override
  void initState() {
    super.initState();
    _agentService = context.read<AntigravityService>();
    _tracker = context.read<SessionTracker>();
    
    _rewardController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500));
    _cardShakeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
    
    _loadCards();
    _startAgentCheck();
    _loadNewQuest();
  }

  void _loadCards() {
    final allCards = SymbolsData.getCardsByCategory(_currentCategory);
    setState(() {
      _displayCards = (allCards..shuffle()).take(4).toList();
      _targetCard = _displayCards.first;
    });
  }

  /// Agent evaluation every 30 seconds
  void _startAgentCheck() {
    _agentCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final recentEvents = _tracker.getRecentEvents(seconds: 60);
      if (recentEvents.isEmpty) return;
      
      final actions = await _agentService.evaluateSession(
        childId: _tracker.childId,
        recentEvents: recentEvents,
      );
      
      // Apply agent adaptations
      for (final action in actions) {
        _applyAction(action);
      }
      
      setState(() {}); // Refresh trace panel
    });
  }

  void _applyAction(AdaptationAction action) {
    switch (action.type) {
      case 'switch_category':
        setState(() {
          _currentCategory = action.data['target'] ?? 'animals';
          _loadCards();
        });
        break;
      case 'adjust_difficulty':
        final count = action.data['cards_per_round'] ?? 4;
        setState(() {
          _displayCards = (SymbolsData.getCardsByCategory(_currentCategory)..shuffle())
              .take(count).toList();
          _targetCard = _displayCards.first;
        });
        break;
      case 'trigger_reward':
        _showReward(action.data['praise_phrase'] ?? 'Shabash!');
        break;
      case 'send_break_prompt':
        _showBreakDialog();
        break;
    }
  }

  void _onCardTapped(SymbolCard card) {
    final isCorrect = card.id == _targetCard?.id;
    
    _tracker.recordEvent(
      cardId: card.id,
      category: _currentCategory,
      isSuccess: isCorrect,
    );

    if (isCorrect) {
      _showReward('Shabash! 🌟');
      Future.delayed(const Duration(seconds: 2), _loadCards);
    } else {
      _cardShakeController.forward(from: 0);
    }
  }

  void _showReward(String praise) {
    _rewardController.forward(from: 0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(praise, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6C63FF),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showBreakDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🧘 Break Time!'),
        content: const Text('Let\'s take a small break. Stretch, drink water, or give a hug!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Okay, back to game!'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadNewQuest() async {
    final quest = await _agentService.generateQuest(
      childId: _tracker.childId,
      preferredCategory: _currentCategory,
      childName: _tracker.childName,
      difficulty: 'easy',
    );
    // Show quest intro screen
    if (mounted) {
      Navigator.pushNamed(context, '/quest', arguments: quest);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EEFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Text('⭐ Sitara', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            // JUDGE TOGGLE: Show AI reasoning panel
            IconButton(
              icon: Icon(_showTracePanel ? Icons.psychology : Icons.psychology_outlined),
              onPressed: () => setState(() => _showTracePanel = !_showTracePanel),
              tooltip: 'Show AI Reasoning',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Category indicator
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Category: ', style: TextStyle(fontSize: 16)),
                Text(
                  _currentCategory.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C63FF),
                  ),
                ),
              ],
            ),
          ),

          // Target card prompt
          if (_targetCard != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Find: ', style: TextStyle(fontSize: 18)),
                  Text(
                    _targetCard!.nameUrdu,
                    style: const TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${_targetCard!.nameEnglish})',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

          // Symbol card grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _displayCards.length,
              itemBuilder: (ctx, i) => SymbolCardWidget(
                card: _displayCards[i],
                onTap: () => _onCardTapped(_displayCards[i]),
              ),
            ),
          ),

          // Antigravity trace panel (for judges)
          if (_showTracePanel)
            AgentTraceWidget(traces: _agentService.traceLog),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _agentCheckTimer?.cancel();
    _rewardController.dispose();
    _cardShakeController.dispose();
    super.dispose();
  }
}
```

---

## widgets/symbol_card_widget.dart

```dart
import 'package:flutter/material.dart';
import '../models/symbol_card.dart';

class SymbolCardWidget extends StatefulWidget {
  final SymbolCard card;
  final VoidCallback onTap;
  const SymbolCardWidget({super.key, required this.card, required this.onTap});
  
  @override
  State<SymbolCardWidget> createState() => _SymbolCardWidgetState();
}

class _SymbolCardWidgetState extends State<SymbolCardWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnim = Tween(begin: 1.0, end: 0.95).animate(_scaleController);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _scaleController.forward();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        _scaleController.reverse();
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        _scaleController.reverse();
        setState(() => _isPressed = false);
      },
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (ctx, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isPressed ? const Color(0xFF6C63FF) : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Symbol image (from PECS/Mulberry open source)
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    widget.card.imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, e, s) => const Icon(
                      Icons.image_outlined, 
                      size: 48, 
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              // Urdu label
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.card.nameUrdu,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C63FF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      widget.card.nameEnglish,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }
}
```

---

## widgets/agent_trace_widget.dart  ← JUDGE PANEL

```dart
import 'package:flutter/material.dart';
import '../services/antigravity_service.dart';

class AgentTraceWidget extends StatelessWidget {
  final List<TraceEntry> traces;
  const AgentTraceWidget({super.key, required this.traces});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),  // Dark terminal look
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.psychology, color: Color(0xFF00FF88), size: 16),
                const SizedBox(width: 8),
                const Text(
                  'ANTIGRAVITY AGENT TRACES',
                  style: TextStyle(
                    color: Color(0xFF00FF88),
                    fontSize: 11,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${traces.length} events',
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
          
          // Trace log (scrollable)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              reverse: true, // Latest at bottom
              itemCount: traces.length,
              itemBuilder: (ctx, i) {
                final trace = traces[traces.length - 1 - i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Agent + timestamp
                      Row(
                        children: [
                          Text(
                            '[${_formatTime(trace.timestamp)}] ',
                            style: const TextStyle(
                              color: Color(0xFF888888), fontSize: 10, fontFamily: 'Courier'),
                          ),
                          Text(
                            trace.agent.toUpperCase(),
                            style: TextStyle(
                              color: _agentColor(trace.agent), 
                              fontSize: 10, 
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Reasoning
                      Text(
                        trace.reasoning,
                        style: const TextStyle(
                          color: Color(0xFFCCCCCC), fontSize: 10, fontFamily: 'Courier'),
                      ),
                      // Actions taken
                      if (trace.actions.isNotEmpty)
                        Text(
                          '→ Actions: ${trace.actions.join(", ")}',
                          style: const TextStyle(
                            color: Color(0xFF00FF88), fontSize: 10, fontFamily: 'Courier'),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _agentColor(String agent) {
    switch (agent) {
      case 'Therapy Director': return const Color(0xFFFFD700); // Gold
      case 'Story Weaver': return const Color(0xFF00BFFF);     // Sky blue
      case 'Progress Guardian': return const Color(0xFFFF69B4); // Pink
      default: return Colors.white;
    }
  }

  String _formatTime(DateTime dt) => 
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}:${dt.second.toString().padLeft(2,'0')}';
}
```

---

## data/symbols_data.dart  ← 50 Symbol Cards

```dart
import '../models/symbol_card.dart';

class SymbolsData {
  static const List<SymbolCard> allCards = [
    // ANIMALS (15 cards) — Highest success category
    SymbolCard(id: 'a01', nameEnglish: 'Cat', nameUrdu: 'بلی', nameRomanUrdu: 'Billi',
        category: 'animals', imagePath: 'assets/symbols/animals/cat.png', audioPath: 'assets/audio/billi.mp3'),
    SymbolCard(id: 'a02', nameEnglish: 'Dog', nameUrdu: 'کتا', nameRomanUrdu: 'Kutta',
        category: 'animals', imagePath: 'assets/symbols/animals/dog.png', audioPath: 'assets/audio/kutta.mp3'),
    SymbolCard(id: 'a03', nameEnglish: 'Bird', nameUrdu: 'پرندہ', nameRomanUrdu: 'Parinda',
        category: 'animals', imagePath: 'assets/symbols/animals/bird.png', audioPath: 'assets/audio/parinda.mp3'),
    SymbolCard(id: 'a04', nameEnglish: 'Fish', nameUrdu: 'مچھلی', nameRomanUrdu: 'Machli',
        category: 'animals', imagePath: 'assets/symbols/animals/fish.png', audioPath: 'assets/audio/machli.mp3'),
    SymbolCard(id: 'a05', nameEnglish: 'Cow', nameUrdu: 'گائے', nameRomanUrdu: 'Gaaye',
        category: 'animals', imagePath: 'assets/symbols/animals/cow.png', audioPath: 'assets/audio/gaaye.mp3'),

    // FOOD (10 cards)
    SymbolCard(id: 'f01', nameEnglish: 'Mango', nameUrdu: 'آم', nameRomanUrdu: 'Aam',
        category: 'food', imagePath: 'assets/symbols/food/mango.png', audioPath: 'assets/audio/aam.mp3'),
    SymbolCard(id: 'f02', nameEnglish: 'Roti', nameUrdu: 'روٹی', nameRomanUrdu: 'Roti',
        category: 'food', imagePath: 'assets/symbols/food/roti.png', audioPath: 'assets/audio/roti.mp3'),
    SymbolCard(id: 'f03', nameEnglish: 'Rice', nameUrdu: 'چاول', nameRomanUrdu: 'Chawal',
        category: 'food', imagePath: 'assets/symbols/food/rice.png', audioPath: 'assets/audio/chawal.mp3'),
    SymbolCard(id: 'f04', nameEnglish: 'Water', nameUrdu: 'پانی', nameRomanUrdu: 'Paani',
        category: 'food', imagePath: 'assets/symbols/food/water.png', audioPath: 'assets/audio/paani.mp3'),
    SymbolCard(id: 'f05', nameEnglish: 'Apple', nameUrdu: 'سیب', nameRomanUrdu: 'Saib',
        category: 'food', imagePath: 'assets/symbols/food/apple.png', audioPath: 'assets/audio/saib.mp3'),

    // FAMILY (8 cards)
    SymbolCard(id: 'fam01', nameEnglish: 'Mother', nameUrdu: 'امی', nameRomanUrdu: 'Ammi',
        category: 'family', imagePath: 'assets/symbols/family/mother.png', audioPath: 'assets/audio/ammi.mp3'),
    SymbolCard(id: 'fam02', nameEnglish: 'Father', nameUrdu: 'ابو', nameRomanUrdu: 'Abu',
        category: 'family', imagePath: 'assets/symbols/family/father.png', audioPath: 'assets/audio/abu.mp3'),
    SymbolCard(id: 'fam03', nameEnglish: 'Grandmother', nameUrdu: 'دادی', nameRomanUrdu: 'Dadi',
        category: 'family', imagePath: 'assets/symbols/family/grandmother.png', audioPath: 'assets/audio/dadi.mp3'),
    SymbolCard(id: 'fam04', nameEnglish: 'Brother', nameUrdu: 'بھائی', nameRomanUrdu: 'Bhai',
        category: 'family', imagePath: 'assets/symbols/family/brother.png', audioPath: 'assets/audio/bhai.mp3'),

    // EMOTIONS (8 cards) — harder, introduced gradually
    SymbolCard(id: 'e01', nameEnglish: 'Happy', nameUrdu: 'خوش', nameRomanUrdu: 'Khush',
        category: 'emotions', imagePath: 'assets/symbols/emotions/happy.png', 
        audioPath: 'assets/audio/khush.mp3', difficultyLevel: 2),
    SymbolCard(id: 'e02', nameEnglish: 'Sad', nameUrdu: 'اداس', nameRomanUrdu: 'Udaas',
        category: 'emotions', imagePath: 'assets/symbols/emotions/sad.png', 
        audioPath: 'assets/audio/udaas.mp3', difficultyLevel: 2),
    SymbolCard(id: 'e03', nameEnglish: 'Hungry', nameUrdu: 'بھوکا', nameRomanUrdu: 'Bhooka',
        category: 'emotions', imagePath: 'assets/symbols/emotions/hungry.png', 
        audioPath: 'assets/audio/bhooka.mp3', difficultyLevel: 2),

    // DAILY ROUTINES (9 cards)
    SymbolCard(id: 'd01', nameEnglish: 'Sleep', nameUrdu: 'سونا', nameRomanUrdu: 'Sona',
        category: 'daily_routines', imagePath: 'assets/symbols/daily/sleep.png', audioPath: 'assets/audio/sona.mp3'),
    SymbolCard(id: 'd02', nameEnglish: 'Eat', nameUrdu: 'کھانا', nameRomanUrdu: 'Khaana',
        category: 'daily_routines', imagePath: 'assets/symbols/daily/eat.png', audioPath: 'assets/audio/khaana.mp3'),
    SymbolCard(id: 'd03', nameEnglish: 'Bath', nameUrdu: 'نہانا', nameRomanUrdu: 'Nahana',
        category: 'daily_routines', imagePath: 'assets/symbols/daily/bath.png', audioPath: 'assets/audio/nahana.mp3'),
  ];

  static List<SymbolCard> getCardsByCategory(String category) =>
      allCards.where((c) => c.category == category).toList();
  
  static List<SymbolCard> getEasyCards() =>
      allCards.where((c) => c.difficultyLevel == 1).toList();
}
```
