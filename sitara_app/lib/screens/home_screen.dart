import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/symbols_data.dart';
import '../services/tts_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'animals';
  final bool _loadingStory = false;

  @override
  void initState() {
    super.initState();
    TtsService().stop(); // Ensure all speech is killed when home screen is loaded or returned to
  }



  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final childName = args?['childName'] as String? ?? 'Star';

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1040), Color(0xFF2D2060)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // ─── TOP BAR ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Salaam, $childName! 👋',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Nunito'),
                            ),
                            const Text(
                              'Ready for an adventure?',
                              style: TextStyle(
                                  color: Color(0xFFB8B0FF), fontSize: 13),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Semantics(
                          label: 'Open parent dashboard',
                          button: true,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.settings, color: Colors.white),
                              onPressed: () => Navigator.pushNamed(context, '/parent'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ─── HERO MASCORT ──────────────────────────────────────
                  const SizedBox(height: 10),
                  const _PulsingStar(),
                  const SizedBox(height: 8),
                  Text(
                    'ستارہ آپ کا انتظار کر رہی ہے!',
                    style: GoogleFonts.notoNastaliqUrdu(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        height: 1.5),
                  ),
                  const SizedBox(height: 20),

                  // ─── ACTION CARDS ──────────────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Selector
                          Text(
                            'Select Category:',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Nunito'),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF2D2060),
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Nunito', fontWeight: FontWeight.bold),
                                items: SymbolsData.allCategories.map((cat) {
                                  return DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat.replaceAll('_', ' ').toUpperCase()),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedCategory = val);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Semantics(
                            label: 'Start game session',
                            button: true,
                            child: _ActionCard(
                              emoji: '🎮',
                              title: 'Play Now!',
                              subtitle: 'Tap & learn with Sitara',
                              color: const Color(0xFF6C63FF),
                              onTap: () => Navigator.pushNamed(context, '/game',
                                  arguments: {
                                    'childName': childName,
                                    'initial_category': _selectedCategory
                                  }),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _SmallCard(
                                  emoji: '📖',
                                  title: 'Stories',
                                  color: const Color(0xFF43C59E),
                                  onTap: () {
                                    TtsService().stop();
                                    Navigator.pushNamed(context, '/storybook');
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _SmallCard(
                                  emoji: '📊',
                                  title: 'Progress',
                                  color: const Color(0xFFFA824C),
                                  onTap: () => Navigator.pushNamed(
                                      context, '/parent',
                                      arguments: {'initialTab': 1}),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── FOOTER ────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Powered by Google ADK  ·  Built with ❤️ for Pakistan',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loadingStory)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Card(
                  color: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            strokeWidth: 5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Sitara is weaving a story...',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E2E2E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ستارہ آپ کے لیے ایک خوبصورت کہانی بنا رہی ہے…',
                          style: GoogleFonts.notoNastaliqUrdu(
                            fontSize: 16,
                            height: 2.0,
                            color: const Color(0xFF6C63FF),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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

class _PulsingStar extends StatefulWidget {
  const _PulsingStar();
  @override
  State<_PulsingStar> createState() => _PulsingStarState();
}

class _PulsingStarState extends State<_PulsingStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _scale,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF6C63FF).withValues(alpha: 0.3),
                Colors.transparent,
              ]),
            ),
            child: const Center(
              child: Text('⭐', style: TextStyle(fontSize: 80)),
            ),
          ),
        ),
      );
}

class _ActionCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Nunito')),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14)),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.7), size: 20),
          ],
        ),
      ),
    );
  }
}

class _SmallCard extends StatelessWidget {
  final String emoji, title;
  final Color color;
  final VoidCallback onTap;

  const _SmallCard({
    required this.emoji,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    fontFamily: 'Nunito')),
          ],
        ),
      ),
    );
  }
}
