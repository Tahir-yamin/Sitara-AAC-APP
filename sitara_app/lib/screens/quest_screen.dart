import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/tts_service.dart';

/// QuestScreen — rendered when Therapy Director triggers 'generate_quest_via_story_weaver'.
/// Receives quest JSON from game_screen via Navigator.pushNamed(context, '/quest', arguments: questData).
///
/// Quest data keys (from Story Weaver):
///   quest_title       — short title
///   urdu_hook         — opening Urdu phrase
///   story_text        — bilingual story body
///   target_category   — animals | food | family | emotions | daily_routines
///   character         — Sitara | cat | dog | elephant
///   difficulty        — easy | medium | hard
class QuestScreen extends StatefulWidget {
  const QuestScreen({super.key});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  Map<String, dynamic> _questData = {};

  // Category → emoji mascot mapping
  static const Map<String, String> _categoryEmojis = {
    'animals': '🐘',
    'food': '🥭',
    'family': '👨‍👩‍👧',
    'emotions': '😊',
    'daily_routines': '🌅',
    'transport': '🚗',
  };

  // Difficulty → display info
  static const Map<String, Map<String, dynamic>> _difficultyInfo = {
    'easy': {'label': 'Gentle', 'color': 0xFF43C59E, 'stars': 1},
    'medium': {'label': 'Adventure', 'color': 0xFF6C63FF, 'stars': 2},
    'hard': {'label': 'Champion', 'color': 0xFFFF6584, 'stars': 3},
  };

  @override
  void initState() {
    super.initState();
    TtsService().stop(); // Silence the app immediately on entering Quest screen
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic));
    _entranceController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _questData = args;
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  String get _category =>
      _questData['target_category'] as String? ?? 'animals';
  String get _difficulty =>
      _questData['difficulty'] as String? ?? 'easy';
  String get _questTitle =>
      _questData['quest_title'] as String? ?? 'New Adventure!';
  String get _urduHook =>
      _questData['urdu_hook'] as String? ?? 'چلو!';
  String get _storyText =>
      _questData['story_text'] as String? ??
      'Sitara needs your help! Tap the right card to guide her!';
  String get _character =>
      _questData['character'] as String? ?? 'Sitara';

  Color get _difficultyColor {
    final hex = _difficultyInfo[_difficulty]?['color'] as int? ?? 0xFF6C63FF;
    return Color(hex);
  }

  int get _stars => _difficultyInfo[_difficulty]?['stars'] as int? ?? 1;
  String get _difficultyLabel =>
      _difficultyInfo[_difficulty]?['label'] as String? ?? 'Adventure';

  void _startGame() {
    Navigator.pushReplacementNamed(
      context,
      '/game',
      arguments: {
        'initial_category': _category,
        'quest_active': true,
        'quest_title': _questTitle,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryEmoji = _categoryEmojis[_category] ?? '⭐';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _difficultyColor.withValues(alpha: 0.15),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
              children: [
                // ─── TOP BAR ─────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                        color: Colors.grey,
                      ),
                      const Spacer(),
                      // A2A badge — shows judges this came from Agent orchestration
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 14, color: Color(0xFF6C63FF)),
                            SizedBox(width: 4),
                            Text('Story Weaver · A2A',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6C63FF),
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── QUEST CARD ──────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Character + category emoji display
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _difficultyColor.withValues(alpha: 0.12),
                            border: Border.all(
                                color: _difficultyColor.withValues(alpha: 0.3),
                                width: 3),
                          ),
                          child: Center(
                            child: Text(categoryEmoji,
                                style: const TextStyle(fontSize: 60)),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Difficulty badge + stars
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _difficultyColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _difficultyLabel,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ...List.generate(
                              _stars,
                              (_) => const Text('⭐',
                                  style: TextStyle(fontSize: 16)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Urdu hook
                        Text(
                          _urduHook,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoNastaliqUrdu(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFFD700),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Quest title
                        Text(
                          _questTitle,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Nunito',
                            color: Color(0xFF1A1040),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Story text card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _difficultyColor.withValues(alpha: 0.12),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.menu_book_rounded,
                                      color: Color(0xFF6C63FF), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$_character\'s Quest',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6C63FF),
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Text(
                                _storyText,
                                style: const TextStyle(
                                    fontSize: 17,
                                    height: 1.7,
                                    color: Color(0xFF2D2060)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Category info chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _difficultyColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.category_outlined,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                'Category: ${_category.replaceAll('_', ' ').toUpperCase()}',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── START BUTTON ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _difficultyColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Nunito'),
                        elevation: 8,
                        shadowColor: _difficultyColor.withValues(alpha: 0.5),
                      ),
                      onPressed: _startGame,
                      child: const Text('Let\'s Go! 🚀'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}
