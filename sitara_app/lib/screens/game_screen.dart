import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import 'dart:math';
import '../services/antigravity_service.dart';
import '../services/session_tracker.dart';
import '../services/analytics_service.dart';
import '../models/game_event.dart';
import '../models/session_event.dart';
import '../widgets/symbol_card_widget.dart';
import '../widgets/agent_trace_widget.dart';
import '../data/symbols_data.dart';
import '../models/symbol_card.dart';
import '../models/phrase_pool.dart';
import '../services/local_db_service.dart';
import '../services/tts_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AntigravityService _agentService;
  late SessionTracker _tracker;
  late AnalyticsService _analytics;
  final _tts = TtsService();

  String _currentCategory = 'animals';
  List<SymbolCard> _displayCards = [];
  SymbolCard? _targetCard;       // Card the child should find
  String? _feedbackCardId;       // ID of most-recently tapped card (for visual feedback)
  bool _lastCorrect = false;     // Whether that tap was correct
  bool _processingTap = false;   // Guard: prevents concurrent tap handlers
  bool _showTracePanel = false;  // Toggle for judges
  Timer? _agentCheckTimer;

  // ── Agent banner (visible on game screen so judges see AI working live) ──
  String? _agentBannerText;
  Color _agentBannerColor = const Color(0xFFFFD700);
  bool _agentBannerVisible = false;
  bool _agentBannerLoading = false; // true = spinner, false = checkmark
  Timer? _agentBannerTimer;

  // Session score & streak — shown in real-time (Gameplay Engagement criterion)
  int _sessionScore = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;

  // Animation controllers
  late ConfettiController _confettiController;
  String? _rewardText;

  // Round & session caps
  Timer? _roundTimer;
  Timer? _sessionMinuteTimer;
  int _todayMinutes = 0;
  static const int _maxDailyMinutes = 15;
  static const int _roundTimeoutSeconds = 60;
  bool _sessionCapped = false;

  @override
  void initState() {
    super.initState();
    TtsService().stopIntroMusic();
    _agentService = context.read<AntigravityService>();
    _tracker = context.read<SessionTracker>();
    _analytics = context.read<AnalyticsService>();

    _confettiController = ConfettiController(duration: const Duration(milliseconds: 1500));

    // Read initial_category from route args before first load to avoid double-load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final cat = args?['initial_category'] as String?;
      if (cat != null) _currentCategory = cat;
      _loadCards();
      _startAgentCheck();
      _initSessionCaps();
    });
  }

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
        _roundTimer?.cancel();
        _analytics.log(
          type: GameEventType.sessionCapHit,
          properties: {'minutes_played': _todayMinutes},
        );
        setState(() => _sessionCapped = true);
      }
    });
  }

  void _resetRoundTimer() {
    _roundTimer?.cancel();
    _roundTimer = Timer(const Duration(seconds: _roundTimeoutSeconds), () {
      _analytics.log(
        type: GameEventType.interactionCapHit,
        properties: {'category': _currentCategory, 'target': _targetCard?.id ?? ''},
      );
      _loadCards();
    });
  }

  void _loadCards() {
    if (!mounted) return;
    var allCards = SymbolsData.getCardsByCategory(_currentCategory);
    if (allCards.isEmpty) {
      _currentCategory = 'animals';
      allCards = SymbolsData.getCardsByCategory(_currentCategory);
    }
    final picks = (List.of(allCards)..shuffle()).take(4).toList();
    setState(() {
      _displayCards = picks;
      _targetCard = picks[Random().nextInt(picks.length)];
    });
    _speakTarget();
    _resetRoundTimer();
  }

  /// Announce the target card: "بلی … Billi … Cat"
  Future<void> _speakTarget() async {
    if (!mounted || _targetCard == null) return;
    await _tts.speakCard(
      _targetCard!.nameUrdu,
      _targetCard!.nameEnglish,
      nameRomanUrdu: _targetCard!.nameRomanUrdu,
      audioPath: _targetCard!.audioPath,
    );
  }

  // Show the agent banner at the top of the game screen.
  // [loading] = true → spinner (thinking), false → checkmark (done).
  // Auto-dismisses after [durationMs] milliseconds.
  void _showAgentBanner(String text, Color color,
      {int durationMs = 3500, bool loading = false}) {
    _agentBannerTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _agentBannerText = text;
      _agentBannerColor = color;
      _agentBannerVisible = true;
      _agentBannerLoading = loading;
    });
    _agentBannerTimer = Timer(Duration(milliseconds: durationMs), () {
      if (mounted) setState(() => _agentBannerVisible = false);
    });
  }

  /// Agent evaluation every 30 seconds
  void _startAgentCheck() {
    _agentCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final recentEvents = _tracker.getRecentEvents(seconds: 60);
      if (recentEvents.isEmpty) return;

      final tierLabel = _agentService.useHeuristic ? 'Rules' : 'T1:Gemini';
      _showAgentBanner(
        '🧠 Therapy Director · $tierLabel',
        const Color(0xFFFFD700),
        durationMs: 8000,
        loading: true,
      );

      try {
        final actions = await _agentService.evaluateSession(
          childId: _tracker.childId,
          recentEvents: recentEvents,
        );

        _analytics.log(
          type: GameEventType.agentSessionEval,
          properties: {'actions_count': actions.length, 'mode': _agentService.useHeuristic ? 'heuristic' : 'agentic'},
        );

        // Show what the agent decided
        if (actions.isNotEmpty && mounted) {
          final label = actions.first.type.replaceAll('_', ' ');
          _showAgentBanner('✅ $label', const Color(0xFF00C853), durationMs: 2500);
        } else if (mounted) {
          setState(() => _agentBannerVisible = false);
        }

        for (final action in actions) {
          _applyAction(action);
        }

        if (mounted) setState(() {});
      } catch (e) {
        if (mounted) {
          setState(() => _agentBannerVisible = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Agent check failed — continuing in offline mode'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  void _applyAction(AdaptationAction action) {
    switch (action.type) {
      case 'switch_category':
        // Set category first, then load cards — never call _loadCards inside setState
        _currentCategory = action.data['new_category'] ?? action.data['target'] ?? 'animals';
        _loadCards(); // _loadCards calls setState internally
        break;
      case 'adjust_difficulty':
        final count = (action.data['cards_per_round'] as num?)?.toInt() ?? 4;
        if (count > _displayCards.length) {
          _tracker.recordDifficultyIncrease();
        }
        setState(() {
          _displayCards = (SymbolsData.getCardsByCategory(_currentCategory)..shuffle())
              .take(count.clamp(3, 6)).toList();
          _targetCard = _displayCards[Random().nextInt(_displayCards.length)];
        });
        _speakTarget();
        _analytics.log(
          type: GameEventType.difficultyAdjusted,
          properties: {'cards_per_round': _displayCards.length, 'category': _currentCategory},
        );
        break;
      case 'trigger_reward':
        final phraseStr = action.data['praise_phrase'] ?? 'Shabash!';
        final phrase = PhrasePool.findPhrase(phraseStr) ?? PhrasePool.shabash;
        _speakPraiseUrdu(phrase);
        _showReward(phrase.displayText);
        break;
      case 'send_break_prompt':
        _showBreakOverlay();
        break;
      // A2A delegation: Therapy Director called Story Weaver internally.
      // The quest data is already in action.data — route it to the quest screen.
      case 'generate_quest_via_story_weaver':
        if (action.data.containsKey('quest_title') && mounted) {
          Navigator.pushReplacementNamed(context, '/quest', arguments: action.data);
        }
        break;
    }
  }

  Future<void> _handleSimulation(String type) async {
    switch (type) {
      case 'success':
        final mockEventsSuccess = List<SessionEvent>.generate(5, (_) => SessionEvent(
          childId: _tracker.childId,
          eventType: 'card_success',
          timestamp: DateTime.now(),
          cardId: 'mock_success',
          category: _currentCategory,
          isSuccess: true,
          tapSpeed: 1.2,
        ));
        setState(() {
          _sessionScore += 50;
          _currentStreak = 5;
          if (_currentStreak > _bestStreak) _bestStreak = _currentStreak;
        });
        _showAgentBanner('🧠 Therapy Director · simulating success', const Color(0xFFFFD700), durationMs: 6000, loading: true);
        final actionsSuccess = await _agentService.evaluateSession(
          childId: _tracker.childId,
          recentEvents: mockEventsSuccess,
        );
        if (actionsSuccess.isNotEmpty && mounted) {
          _showAgentBanner('✅ ${actionsSuccess.first.type.replaceAll('_', ' ')}', const Color(0xFF00C853), durationMs: 2500);
        }
        for (final action in actionsSuccess) { _applyAction(action); }
        break;

      case 'frustration':
        final mockEventsFail = List<SessionEvent>.generate(3, (_) => SessionEvent(
          childId: _tracker.childId,
          eventType: 'card_fail',
          timestamp: DateTime.now(),
          cardId: 'mock_fail',
          category: _currentCategory,
          isSuccess: false,
          tapSpeed: 4.5,
        ));
        setState(() => _currentStreak = 0);
        _showAgentBanner('🧠 Therapy Director · frustration detected', const Color(0xFFFF6B35), durationMs: 6000, loading: true);
        final actionsFail = await _agentService.evaluateSession(
          childId: _tracker.childId,
          recentEvents: mockEventsFail,
        );
        if (actionsFail.isNotEmpty && mounted) {
          _showAgentBanner('✅ ${actionsFail.first.type.replaceAll('_', ' ')}', const Color(0xFF00C853), durationMs: 2500);
        }
        for (final action in actionsFail) { _applyAction(action); }
        break;

      case 'quest':
        _showAgentBanner('🧠 → 📖  A2A: Story Weaver generating quest', const Color(0xFF00BFFF), durationMs: 8000, loading: true);
        final questData = await _agentService.generateQuest(
          childId: _tracker.childId,
          preferredCategory: _currentCategory,
          childName: _tracker.childName,
          difficulty: 'adaptive',
        );
        if (mounted) {
          _showAgentBanner('✅ Quest ready · Story Weaver', const Color(0xFF00C853), durationMs: 2000);
          Navigator.pushNamed(context, '/quest', arguments: questData);
        }
        break;

      case 'evaluate':
        final recentEvents = _tracker.getRecentEvents(seconds: 60);
        if (recentEvents.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No active interactions yet. Tap some cards first!'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }
        _showAgentBanner('🧠 Therapy Director · evaluating session', const Color(0xFFFFD700), durationMs: 8000, loading: true);
        final actionsEval = await _agentService.evaluateSession(
          childId: _tracker.childId,
          recentEvents: recentEvents,
        );
        if (actionsEval.isNotEmpty && mounted) {
          _showAgentBanner('✅ ${actionsEval.first.type.replaceAll('_', ' ')}', const Color(0xFF00C853), durationMs: 2500);
        }
        for (final action in actionsEval) { _applyAction(action); }
        break;
    }
    if (mounted) setState(() {});
  }

  Future<void> _onCardTapped(SymbolCard card) async {
    // Guard: prevent concurrent taps from interfering with feedback state.
    if (_processingTap) return;
    _processingTap = true;

    final isCorrect = card.id == _targetCard?.id;

    _tracker.recordEvent(
      cardId: card.id,
      category: _currentCategory,
      isSuccess: isCorrect,
    );
    _analytics.log(
      type: GameEventType.cardTapped,
      properties: {'card_id': card.id, 'category': _currentCategory, 'correct': isCorrect},
    );

    // Force a null→id transition so didUpdateWidget always sees false→true,
    // even when the same wrong card is tapped twice in a row.
    setState(() => _feedbackCardId = null);
    await Future.microtask(() {});

    setState(() {
      _feedbackCardId = card.id;
      _lastCorrect = isCorrect;
      if (isCorrect) {
        _sessionScore += 10 + _currentStreak * 2;
        _currentStreak++;
        if (_currentStreak > _bestStreak) _bestStreak = _currentStreak;
      } else {
        _currentStreak = 0;
      }
    });
    _tracker.recordScore(
      score: _sessionScore,
      streak: _currentStreak,
      best: _bestStreak,
    );
    _resetRoundTimer();

    if (isCorrect) {
      final phrase = PhrasePool.pickPraise(streak: _currentStreak);
      _showReward(phrase.displayText);

      // Await praise so speakCard() in _loadCards() doesn't kill it mid-play.
      // 3-second timeout ensures the game never hangs if TTS/audio stalls.
      await _speakPraiseUrdu(phrase)
          .timeout(const Duration(seconds: 3), onTimeout: () {});

      if (mounted) {
        setState(() => _feedbackCardId = null);
        _loadCards();
        _processingTap = false;
      }
    } else {
      // Wrong tap — play gentle sound cue then clear feedback quickly
      _speakPraiseUrdu(PhrasePool.tryAgain);
      
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() => _feedbackCardId = null);
        _processingTap = false;
      }
    }
  }

  Future<void> _speakPraiseUrdu(Phrase phrase) async {
    if (!mounted) return;
    try {
      await _tts.speakPraise(phrase);
    } catch (_) {
      if (!mounted) return;
      await _tts.speak(phrase.romanUrdu);
    }
  }

  void _showReward(String displayText) {
    _analytics.log(
      type: GameEventType.rewardTriggered,
      properties: {'text': displayText, 'streak': _currentStreak},
    );
    _confettiController.play();
    setState(() => _rewardText = displayText);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _rewardText = null);
    });
  }

  void _showBreakOverlay() {
    _analytics.log(
      type: GameEventType.breakShown,
      properties: {'session_minutes': _todayMinutes, 'score': _sessionScore},
    );
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      pageBuilder: (ctx, anim1, anim2) => const _BreakOverlay(),
    );
  }


  Widget _buildGameBody() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: [
            // Score & streak bar — real-time feedback (Gameplay Engagement)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Category
                  Row(children: [
                    const Text('📂 ', style: TextStyle(fontSize: 14)),
                    Text(
                      _currentCategory.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                  ]),
                  // Score
                  Row(children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '$_sessionScore',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF333333),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ]),
                  // Streak
                  Row(children: [
                    Text(
                      _currentStreak >= 3 ? '🔥' : '⚡',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '×$_currentStreak',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _currentStreak >= 3
                            ? const Color(0xFFFF6B35)
                            : const Color(0xFF6C63FF),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ]),
                ],
              ),
            ),

            // ── Target prompt ─────────────────────────────────────────
            if (_targetCard != null)
              GestureDetector(
                // Tap the prompt banner to repeat the voiceover
                onTap: _speakTarget,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Speaker icon — tappable hint
                      const Icon(Icons.volume_up_rounded, color: Color(0xFF6C63FF), size: 24),
                      const SizedBox(width: 10),

                      // Urdu name (RTL) — Noto Nastaliq Urdu for correct script rendering
                      Text(
                        _targetCard!.nameUrdu,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(fontFamily: 'NotoNastaliqUrdu', 
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF6C63FF),
                          height: 1.3,
                        ),
                      ),

                      // Divider dot
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('·', style: TextStyle(fontSize: 22, color: Colors.grey)),
                      ),

                      // English name
                      Text(
                        _targetCard!.nameEnglish,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ],
                  ),
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
                itemBuilder: (ctx, i) {
                  final card = _displayCards[i];
                  return SymbolCardWidget(
                    card: card,
                    // TTS is handled manually via _speakPraiseUrdu / _speakTarget.
                    speakOnTap: false,
                    showCorrect: _feedbackCardId == card.id && _lastCorrect,
                    showIncorrect: _feedbackCardId == card.id && !_lastCorrect,
                    onTap: () => _onCardTapped(card),
                  );
                },
              ),
            ),

            // Antigravity trace panel (for judges)
            if (_showTracePanel)
              Semantics(
                excludeSemantics: true,
                child: AgentTraceWidget(
                  traces: _agentService.traceLog,
                  onSimulate: _handleSimulation,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EEFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          tooltip: 'Back to Home',
          onPressed: () {
            _agentBannerTimer?.cancel();
            _tts.stopSync(); // synchronous — ensures audio stops before route pops
            Navigator.of(context).pop();
          },
        ),
        title: Row(
          children: [
            const Text('⭐ Sitara', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            // TTS LANGUAGE SELECTOR
            PopupMenuButton<String>(
              icon: const Icon(Icons.translate_rounded, color: Colors.white),
              tooltip: 'TTS Language Preference',
              onSelected: (String choice) {
                LocalDbService.instance.saveTtsLanguageMode(choice);
                setState(() {});
                // Proactively speak target to confirm language setting immediately
                _speakTarget();
              },
              itemBuilder: (BuildContext context) {
                final currentMode = LocalDbService.instance.getTtsLanguageMode();
                return [
                  PopupMenuItem<String>(
                    value: 'bilingual',
                    child: Row(
                      children: [
                        const Text('🔊 '),
                        const Text('Bilingual (Urdu + English)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (currentMode == 'bilingual') const Icon(Icons.check_rounded, color: Color(0xFF6C63FF)),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'urdu',
                    child: Row(
                      children: [
                        const Text('🇵🇰 '),
                        const Text('Urdu Only', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (currentMode == 'urdu') const Icon(Icons.check_rounded, color: Color(0xFF6C63FF)),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'english',
                    child: Row(
                      children: [
                        const Text('🇬🇧 '),
                        const Text('English Only', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (currentMode == 'english') const Icon(Icons.check_rounded, color: Color(0xFF6C63FF)),
                      ],
                    ),
                  ),
                ];
              },
            ),
            const SizedBox(width: 4),
            // BENCHMARK TOGGLE: Switch between agentic AI and fixed-rule heuristic
            GestureDetector(
              onTap: () => setState(() {
                _agentService.useHeuristic = !_agentService.useHeuristic;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: _agentService.useHeuristic
                      ? Colors.grey.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                ),
                child: Text(
                  _agentService.useHeuristic ? '📏 Rules' : '🤖 AI',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
            // JUDGE TOGGLE: Show AI reasoning panel
            IconButton(
              icon: Icon(_showTracePanel ? Icons.psychology : Icons.psychology_outlined),
              onPressed: () => setState(() => _showTracePanel = !_showTracePanel),
              tooltip: 'Show AI Reasoning',
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _buildGameBody(),

          // ── Agent live banner — slides down from top when AI is working ──
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            top: _agentBannerVisible ? 8 : -64,
            left: 12,
            right: 12,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _agentBannerVisible ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: _agentBannerColor.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _agentBannerColor.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_agentBannerLoading)
                      const SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        _agentBannerText ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              colors: const [
                Color(0xFF6C63FF), Color(0xFF43C59E),
                Color(0xFFFFB800), Color(0xFFFF6584),
              ],
              shouldLoop: false,
            ),
          ),
          if (_rewardText != null)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  _rewardText!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'NotoNastaliqUrdu', 
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          if (_sessionCapped)
            Positioned.fill(
              child: Container(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.95),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🌙', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 20),
                      const Text(
                        'آج کے لیے بس!',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "That's enough for today!",
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_todayMinutes minutes played today',
                        style: const TextStyle(fontSize: 14, color: Colors.white60),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6C63FF),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Go Home', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _agentCheckTimer?.cancel();
    _roundTimer?.cancel();
    _sessionMinuteTimer?.cancel();
    _agentBannerTimer?.cancel();
    _confettiController.dispose();
    // Cancel both audio player and TTS immediately on exit —
    // prevents card-name speech leaking into the HomeScreen.
    _tts.stopSync();
    super.dispose();
  }
}

class _BreakOverlay extends StatefulWidget {
  const _BreakOverlay();
  @override
  State<_BreakOverlay> createState() => _BreakOverlayState();
}

class _BreakOverlayState extends State<_BreakOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _breatheController;
  late Animation<double> _breatheAnim;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _breatheAnim = Tween<double>(begin: 0.75, end: 1.15).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
    // Auto-dismiss after 3 breath cycles (24 seconds)
    Future.delayed(const Duration(seconds: 24), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.97),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _breatheAnim,
              builder: (ctx, _) => Transform.scale(
                scale: _breatheAnim.value,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.25),
                    border: Border.all(color: Colors.white54, width: 3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'وقفہ کریں',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Time for a little break',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            GestureDetector(
              onDoubleTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white38),
                ),
                child: const Text(
                  'Double-tap to continue',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
