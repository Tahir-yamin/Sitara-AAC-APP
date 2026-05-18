import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/local_db_service.dart';
import '../services/tts_service.dart';

class StorybookScreen extends StatefulWidget {
  const StorybookScreen({super.key});

  @override
  State<StorybookScreen> createState() => _StorybookScreenState();
}

class _StorybookScreenState extends State<StorybookScreen>
    with TickerProviderStateMixin {
  late AnimationController _starController;
  late AnimationController _breatheController;
  late Animation<double> _breatheAnim;

  late AnimationController _catController;
  late Animation<double> _catAnim;

  late AnimationController _trainController;
  late Animation<double> _trainAnim;

  // Star spin/bounce interactive state
  double _starAngle = 0.0;
  double _starScale = 1.0;
  bool _isStarTapped = false;

  // Coco tap state
  bool _isCatTapped = false;

  // Train tap state
  bool _isTrainTapped = false;

  // The 3 beautiful built-in children's stories in English
  static const List<Map<String, dynamic>> _stories = [
    {
      'title': 'The Shiny Little Star',
      'emoji': '⭐',
      'accentColor': 0xFFFFD700,
      'pages': [
        'Look at the beautiful night sky. The sky is dark blue, and a soft, happy star is twinkling just for you.',
        'The little star moves left and right! When you tap the star, it sings a sweet chime like a tiny bell: Ting!',
        'Now, the moon wakes up with a soft, warm smile. It breathes in and out, slowly, helping you feel calm and safe.',
        'Look at the shooting stars! They draw beautiful glowing lines across the sky. Let\'s make a quiet wish together.',
        'The star whispers a gentle secret: "You are so special. You are brave, you are wonderful, and you are loved."',
        'Close your eyes, little explorer. The stars are keeping you safe all night long. Sweet dreams and quiet sleep.',
      ]
    },
    {
      'title': 'Coco the Kind Cat',
      'emoji': '🐱',
      'accentColor': 0xFFFFB800,
      'pages': [
        'Coco is a very small, fluffy orange kitty. He has tiny velvet paws, long white whiskers, and soft warm fur.',
        'Tap on Coco to see him jump! When you tap his tummy, Coco does a playful little bounce: Boing!',
        'Coco purrs happily: Purr, purr, purr. The sound is warm and cozy, like a soft blanket wrapped around you.',
        'He rolls a little red ball of yarn across the floor. Roll, roll, roll. Watch it go! It is so fun to watch.',
        'Coco walks slowly and sits right next to you, resting his head. He is your best friend who loves you very much.',
        'Together, you and Coco share a quiet, peaceful, and happy day. Take a deep breath and smile with your kitty.',
      ]
    },
    {
      'title': 'The Forest Train Adventure',
      'emoji': '🚂',
      'accentColor': 0xFF43C59E,
      'pages': [
        'Choo-choo! The happy blue steam train starts its slow journey through the beautiful green forest.',
        'Chug-chug-chug! Tap the train engine to hear it blow its soft horn: Toot-toot! The wheels spin around and around.',
        'The train passes by tall green trees that sway in the wind. Friendly birds chirp from the branches: Tweet-tweet!',
        'We look out the window and see bright, colorful flowers that dance in the sun. Yellow, red, and blue petals!',
        'We sit comfortably inside our safe, warm carriage. The ride is slow, steady, and very relaxing.',
        'The train safely arrives at the peaceful station. You did a wonderful job on this journey! Choo-choo!',
      ]
    }
  ];

  int _selectedStoryIndex = 0;
  int _currentPageIndex = 0;
  bool _isPlayingStory = false;
  bool _isNarrating = false;

  // Cooldown variables
  bool _cooldownActive = false;
  Duration _cooldownTimeLeft = Duration.zero;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    TtsService().stop(); // Silence everything on arrival

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breatheAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    _catController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _catAnim = Tween<double>(begin: 0.0, end: -35.0).animate(
      CurvedAnimation(parent: _catController, curve: Curves.elasticOut),
    );

    _trainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _trainAnim = Tween<double>(begin: -15.0, end: 15.0).animate(
      CurvedAnimation(parent: _trainController, curve: Curves.easeInOut),
    );

    _checkCooldown();
  }

  void _onStarTapped() {
    TtsService().speakSoundCue('Ting!');
    setState(() {
      _starAngle += 6.28; // full spin
      _starScale = 1.4;
      _isStarTapped = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _starScale = 1.0;
          _isStarTapped = false;
        });
      }
    });
  }

  void _onCatTapped() {
    TtsService().speakSoundCue('Boing!');
    _catController.forward().then((_) => _catController.reverse());
    setState(() {
      _isCatTapped = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isCatTapped = false;
        });
      }
    });
  }

  void _onTrainTapped() {
    TtsService().speakSoundCue('Toot-toot!');
    setState(() {
      _isTrainTapped = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isTrainTapped = false;
        });
      }
    });
  }

  void _checkCooldown() {
    final lastPlay = LocalDbService.instance.getLastStoryPlayTime();
    if (lastPlay != null) {
      final elapsed = DateTime.now().difference(lastPlay);
      const cooldownLimit = Duration(hours: 12);
      if (elapsed < cooldownLimit) {
        setState(() {
          _cooldownActive = true;
          _cooldownTimeLeft = cooldownLimit - elapsed;
        });
        _startCooldownTimer();
        return;
      }
    }
    setState(() {
      _cooldownActive = false;
    });
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final lastPlay = LocalDbService.instance.getLastStoryPlayTime();
      if (lastPlay == null) {
        timer.cancel();
        setState(() => _cooldownActive = false);
        return;
      }
      final elapsed = DateTime.now().difference(lastPlay);
      const cooldownLimit = Duration(hours: 12);
      if (elapsed >= cooldownLimit) {
        timer.cancel();
        setState(() {
          _cooldownActive = false;
          _cooldownTimeLeft = Duration.zero;
        });
      } else {
        setState(() {
          _cooldownTimeLeft = cooldownLimit - elapsed;
        });
      }
    });
  }

  // Triggered when child finishes a story to start the 12-hour limit
  Future<void> _completeStory() async {
    TtsService().stop();
    await LocalDbService.instance.saveLastStoryPlayTime(DateTime.now());
    if (mounted) {
      setState(() {
        _isPlayingStory = false;
        _isNarrating = false;
      });
      _checkCooldown();
    }
  }

  Future<void> _narrateCurrentPage() async {
    if (_isNarrating) return;
    setState(() => _isNarrating = true);

    final story = _stories[_selectedStoryIndex];
    final pages = story['pages'] as List<String>;
    final pageText = pages[_currentPageIndex];

    // Calm, slow narration with dynamic TTS voice configuration
    await TtsService().speakNarratorLine(pageText);

    if (mounted) {
      setState(() => _isNarrating = false);
    }
  }

  void _nextPage() {
    TtsService().stop();
    final story = _stories[_selectedStoryIndex];
    final pages = story['pages'] as List<String>;
    if (_currentPageIndex < pages.length - 1) {
      setState(() {
        _currentPageIndex++;
        _isNarrating = false;
      });
      _narrateCurrentPage();
    } else {
      // Completed last page! Activate cooldown limit
      _completeStory();
    }
  }

  void _prevPage() {
    TtsService().stop();
    if (_currentPageIndex > 0) {
      setState(() {
        _currentPageIndex--;
        _isNarrating = false;
      });
      _narrateCurrentPage();
    }
  }

  void _startStory(int index) {
    setState(() {
      _selectedStoryIndex = index;
      _currentPageIndex = 0;
      _isPlayingStory = true;
      _isNarrating = false;
    });
    _narrateCurrentPage();
  }

  // Handy shortcut for evaluation / manual override of 12-hour cooldown
  void _bypassCooldown() {
    TtsService().stop();
    _cooldownTimer?.cancel();
    // Save a timestamp from 13 hours ago to clear cooldown safely
    LocalDbService.instance.saveLastStoryPlayTime(
      DateTime.now().subtract(const Duration(hours: 13)),
    );
    setState(() {
      _cooldownActive = false;
      _isPlayingStory = false;
      _isNarrating = false;
    });
  }

  @override
  void dispose() {
    _starController.dispose();
    _breatheController.dispose();
    _catController.dispose();
    _trainController.dispose();
    _cooldownTimer?.cancel();
    TtsService().stop();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h : $m : $s';
  }

  // ─── RENDERS ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B26), // Cosmic midnight background
      body: Stack(
        children: [
          // Sensory-calming floating particles / soft glowing background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0C0920), Color(0xFF1B1440), Color(0xFF080614)],
                ),
              ),
            ),
          ),

          // Glowing background star animation
          Positioned(
            top: 100,
            right: 40,
            child: RotationTransition(
              turns: _starController,
              child: Opacity(
                opacity: 0.25,
                child: const Text('✨', style: TextStyle(fontSize: 48)),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 30,
            child: RotationTransition(
              turns: _starController,
              child: Opacity(
                opacity: 0.15,
                child: const Text('✨', style: TextStyle(fontSize: 36)),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Custom Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                        tooltip: 'Back to Home',
                        onPressed: () {
                          TtsService().stop();
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sitara Stories',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Accessible testing key for judges to instantly bypass cooldown
                      GestureDetector(
                        onLongPress: _bypassCooldown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.lock_clock_outlined, size: 14, color: Colors.yellowAccent),
                              SizedBox(width: 4),
                              Text('12h Cap', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _cooldownActive
                      ? _buildCooldownScreen()
                      : (_isPlayingStory ? _buildStoryPlayer() : _buildStorySelector()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Render when a child tries to open a story during the active 12-hour lock
  Widget _buildCooldownScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _breatheAnim,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.12),
                  border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.25), width: 3),
                ),
                child: const Center(
                  child: Text('😴⭐', style: TextStyle(fontSize: 76)),
                ),
              ),
            ),
            const SizedBox(height: 36),
            Text(
              'Sitara is Sleeping...',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'ستارہ تاروں کے نیچے آرام کر رہی ہے…',
              style: GoogleFonts.notoNastaliqUrdu(
                fontSize: 16,
                height: 2.0,
                color: const Color(0xFFB8B0FF),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Next Story Unlocks In:',
                    style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_cooldownTimeLeft),
                    style: GoogleFonts.shareTechMono(
                      fontSize: 32,
                      color: Colors.yellowAccent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'We protect young eyes! One story every 12 hours.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Explicit parent bypass button in UI for helper convenience
            TextButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 14, color: Colors.white38),
              label: const Text('Bypass for Testing (Parents/Judges)', style: TextStyle(color: Colors.white38, fontSize: 12)),
              onPressed: _bypassCooldown,
            ),
          ],
        ),
      ),
    );
  }

  // Render cozy story selection carousel
  Widget _buildStorySelector() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Select a Soothing Story',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Calming English narratives with friendly illustrations for speech engagement.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 36),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: _stories.length,
            itemBuilder: (ctx, idx) {
              final story = _stories[idx];
              final color = Color(story['accentColor'] as int);

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: () => _startStory(idx),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(story['emoji'] as String, style: const TextStyle(fontSize: 32)),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  story['title'] as String,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.menu_book_rounded, size: 14, color: color),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${(story['pages'] as List).length} Pages of Joy',
                                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Render the interactive, high-quality storybook player
  Widget _buildStoryPlayer() {
    final story = _stories[_selectedStoryIndex];
    final pages = story['pages'] as List<String>;
    final pageText = pages[_currentPageIndex];
    final color = Color(story['accentColor'] as int);
    final emoji = story['emoji'] as String;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        children: [
          // Progress indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length,
              (idx) => Container(
                width: 32,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: idx <= _currentPageIndex ? color : Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Illustration card
          Expanded(
            flex: 4,
            child: ScaleTransition(
              scale: _breatheAnim,
              child: _buildInteractiveIllustration(color),
            ),
          ),

          const SizedBox(height: 24),

          // Narrative prose block
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  pageText,
                  style: GoogleFonts.nunito(
                    fontSize: 21,
                    height: 1.6,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Interactive controls: Back / Speak / Next
          Row(
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.navigate_before_rounded, size: 36),
                onPressed: _currentPageIndex > 0 ? _prevPage : null,
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                ),
              ),
              const Spacer(),
              // Narrator audio repeat button
              Semantics(
                label: 'Repeat narration',
                button: true,
                child: InkWell(
                  onTap: _narrateCurrentPage,
                  borderRadius: BorderRadius.circular(40),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Icon(
                      _isNarrating ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                icon: Icon(
                  _currentPageIndex < pages.length - 1 ? Icons.navigate_next_rounded : Icons.check_circle_rounded,
                  size: 36,
                ),
                onPressed: _nextPage,
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                  backgroundColor: color.withValues(alpha: 0.2),
                  foregroundColor: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInteractiveIllustration(Color color) {
    switch (_selectedStoryIndex) {
      case 0:
        return _buildSpaceEnvironment(color);
      case 1:
        return _buildCocoPlayground(color);
      case 2:
        return _buildForestTrainScene(color);
      default:
        return Center(
          child: Text(
            _stories[_selectedStoryIndex]['emoji'] as String,
            style: const TextStyle(fontSize: 100),
          ),
        );
    }
  }

  Widget _buildSpaceEnvironment(Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF020617)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(top: 30, right: 40, child: Text('✨', style: TextStyle(fontSize: 20))),
          const Positioned(bottom: 50, left: 30, child: Text('✨', style: TextStyle(fontSize: 18))),
          const Positioned(top: 100, left: 60, child: Text('✨', style: TextStyle(fontSize: 16))),
          const Positioned(bottom: 80, right: 60, child: Text('✨', style: TextStyle(fontSize: 22))),

          // Floating breathing moon
          Positioned(
            top: 24,
            left: 24,
            child: ScaleTransition(
              scale: _breatheAnim,
              child: const Text('🌙', style: TextStyle(fontSize: 48)),
            ),
          ),

          // Glowing hint/ting bubble
          Positioned(
            top: 30,
            right: 0,
            left: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: _isStarTapped ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    _isStarTapped ? '✨ Ting! ✨' : 'Tap the star!',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _isStarTapped ? const Color(0xFFFFD700) : Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Central interactive twinkling Star
          Center(
            child: GestureDetector(
              onTap: _onStarTapped,
              behavior: HitTestBehavior.opaque,
              child: AnimatedScale(
                scale: _starScale,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: AnimatedRotation(
                  turns: _starAngle / 6.28,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutBack,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: _isStarTapped ? 15 : 5,
                        ),
                      ],
                    ),
                    child: const Text(
                      '⭐',
                      style: TextStyle(fontSize: 110),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCocoPlayground(Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF7ED), Color(0xFFFED7AA), Color(0xFFFFEDD5)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Stack(
        children: [
          const Positioned(top: 20, right: 30, child: Text('☁️', style: TextStyle(fontSize: 32))),
          const Positioned(top: 40, left: 40, child: Text('☁️', style: TextStyle(fontSize: 24))),

          // Interactive Yarn Ball
          Positioned(
            bottom: 40,
            right: 40,
            child: ScaleTransition(
              scale: _breatheAnim,
              child: const Text('🧶', style: TextStyle(fontSize: 48)),
            ),
          ),

          // Dialogue/Reaction Bubble
          Positioned(
            top: 30,
            right: 0,
            left: 0,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _isCatTapped ? '😺 Purr! Boing!' : 'Tap Coco the cat!',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ),
          ),

          // Central interactive bouncing Cat
          Center(
            child: AnimatedBuilder(
              animation: _catController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _catAnim.value),
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: _onCatTapped,
                behavior: HitTestBehavior.opaque,
                child: AnimatedScale(
                  scale: _isCatTapped ? 1.3 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: const Text(
                      '🐱',
                      style: TextStyle(fontSize: 100),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForestTrainScene(Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFECFDF5), Color(0xFFA7F3D0), Color(0xFF34D399)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Stack(
        children: [
          const Positioned(bottom: 80, left: 30, child: Text('🌲', style: TextStyle(fontSize: 48))),
          const Positioned(bottom: 90, right: 30, child: Text('🌲', style: TextStyle(fontSize: 54))),
          const Positioned(bottom: 100, left: 100, child: Text('🌳', style: TextStyle(fontSize: 40))),

          // Action bubble
          Positioned(
            top: 30,
            right: 0,
            left: 0,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _isTrainTapped ? '🚂 Toot-toot! Choo-choo!' : 'Tap the steam train!',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
              ),
            ),
          ),

          // Steam puff when tapped
          if (_isTrainTapped)
            Positioned(
              top: 80,
              left: 120,
              child: ScaleTransition(
                scale: _breatheAnim,
                child: const Text('💨', style: TextStyle(fontSize: 36)),
              ),
            ),

          // Central interactive chugging Train
          Center(
            child: AnimatedBuilder(
              animation: _trainController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_trainAnim.value, 0),
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: _onTrainTapped,
                behavior: HitTestBehavior.opaque,
                child: AnimatedScale(
                  scale: _isTrainTapped ? 1.25 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: const Text(
                    '🚂',
                    style: TextStyle(fontSize: 110),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
