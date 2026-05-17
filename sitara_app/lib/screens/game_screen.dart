import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import 'dart:math';
import '../services/antigravity_service.dart';
import '../services/session_tracker.dart';
import '../services/analytics_service.dart';
import '../models/game_event.dart';
import '../widgets/symbol_card_widget.dart';
import '../widgets/agent_trace_widget.dart';
import '../data/symbols_data.dart';
import '../models/symbol_card.dart';
import '../models/phrase_pool.dart';
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
  bool _showTracePanel = false;  // Toggle for judges
  Timer? _agentCheckTimer;

  // Session score & streak — shown in real-time (Gameplay Engagement criterion)
  int _sessionScore = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;

  // Animation controllers
  late AnimationController _rewardController;
  late AnimationController _cardShakeController;
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
    _agentService = context.read<AntigravityService>();
    _tracker = context.read<SessionTracker>();
    _analytics = AnalyticsService(childId: _tracker.childId);

    _rewardController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500));
    _cardShakeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
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
    if (_targetCard == null) return;
    await _tts.speakCard(
      _targetCard!.nameUrdu,
      _targetCard!.nameEnglish,
      nameRomanUrdu: _targetCard!.nameRomanUrdu,
    );
  }

  /// Agent evaluation every 30 seconds
  void _startAgentCheck() {
    _agentCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final recentEvents = _tracker.getRecentEvents(seconds: 60);
      if (recentEvents.isEmpty) return;

      try {
        final actions = await _agentService.evaluateSession(
          childId: _tracker.childId,
          recentEvents: recentEvents,
        );

        _analytics.log(
          type: GameEventType.agentSessionEval,
          properties: {'actions_count': actions.length, 'mode': _agentService.useHeuristic ? 'heuristic' : 'agentic'},
        );
        for (final action in actions) {
          _applyAction(action);
        }

        if (mounted) setState(() {});
      } catch (e) {
        if (mounted) {
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
              .take(count.clamp(2, 6)).toList();
          _targetCard = _displayCards[Random().nextInt(_displayCards.length)];
        });
        _speakTarget();
        _analytics.log(
          type: GameEventType.difficultyAdjusted,
          properties: {'cards_per_round': _displayCards.length, 'category': _currentCategory},
        );
        break;
      case 'trigger_reward':
        _showReward(action.data['praise_phrase'] ?? 'Shabash!');
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

  void _onCardTapped(SymbolCard card) {
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

    setState(() {
      _feedbackCardId = card.id;
      _lastCorrect = isCorrect;
      if (isCorrect) {
        _sessionScore += 10 + _currentStreak * 2; // bonus for streak
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
      _speakPraiseUrdu(phrase);
      _showReward(phrase.displayText);
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) setState(() => _feedbackCardId = null);
      });
      Future.delayed(const Duration(seconds: 2), _loadCards);
    } else {
      _cardShakeController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _feedbackCardId = null);
      });
    }
  }

  Future<void> _speakPraiseUrdu(Phrase phrase) async {
    try {
      await _tts.speakPraise(phrase.ttsText, phrase.romanUrdu);
    } catch (_) {
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
                        style: GoogleFonts.notoNastaliqUrdu(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF6C63FF),
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
                child: AgentTraceWidget(traces: _agentService.traceLog),
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
        title: Row(
          children: [
            const Text('⭐ Sitara', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
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
                  style: GoogleFonts.notoNastaliqUrdu(
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
    _rewardController.dispose();
    _cardShakeController.dispose();
    _confettiController.dispose();
    _tts.stop(); // Stop any in-progress utterance when leaving screen
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
              style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
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
