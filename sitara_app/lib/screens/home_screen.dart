import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../data/symbols_data.dart';
import '../services/tts_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  String _selectedCategory = 'animals';
  final bool _loadingStory = false;

  @override
  void initState() {
    super.initState();
    // First load: stop any stale audio and start welcoming music.
    TtsService().stop();
    TtsService().playIntroMusic();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      sitaraRouteObserver.subscribe(this, route as ModalRoute<void>);
    }
  }

  /// Called when the user pops back to this screen from any child route.
  @override
  void didPopNext() {
    // Stop any in-flight card TTS from the previous screen immediately.
    TtsService().stop();
    // Resume welcoming music for the home context.
    TtsService().playIntroMusic();
  }

  @override
  void dispose() {
    sitaraRouteObserver.unsubscribe(this);
    super.dispose();
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
                        const Icon(Icons.star_rounded, size: 36, color: Colors.amberAccent),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Salaam, $childName!',
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
                    style: TextStyle(fontFamily: 'NotoNastaliqUrdu', 
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
                              icon: Icons.sports_esports_rounded,
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
                                  icon: Icons.book_rounded,
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
                                  icon: Icons.analytics_rounded,
                                  title: 'Progress',
                                  color: const Color(0xFFFA824C),
                                  onTap: () => Navigator.pushNamed(
                                      context, '/parent',
                                      arguments: {'initialTab': 1}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _FuturePlanCard(
                            onTap: () => _showFuturePlanDialog(context),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── FOOTER ────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Powered by Google ADK  ·  Built with ',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 11),
                          ),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Icon(
                              Icons.favorite_rounded,
                              color: const Color(0xFFFF6584).withValues(alpha: 0.6),
                              size: 13,
                            ),
                          ),
                          TextSpan(
                            text: ' for Pakistan',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 11),
                          ),
                        ],
                      ),
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
                          style: TextStyle(fontFamily: 'NotoNastaliqUrdu', 
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

  void _showFuturePlanDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF150E3A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.rocket_launch_rounded, color: Colors.amberAccent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '𝐒𝐈𝐓𝐀𝐑𝐀 𝐒𝐓𝐑𝐀𝐓𝐄𝐆𝐈𝐂 𝐑𝐎𝐀𝐃𝐌𝐀𝐏',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Sovereign Vision for Scaling & Local Communities',
                            style: TextStyle(
                              color: Colors.amberAccent.withValues(alpha: 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildRoadmapItem(
                          icon: Icons.language_rounded,
                          title: '1. Regional Language Scaling',
                          description: 'Expanding native voice support beyond Urdu & English to provincial languages (Punjabi, Pashto, Sindhi, and Balochi). This ensures native-tongue therapy accessibility in rural and local Pakistani communities.',
                          color: const Color(0xFF43C59E),
                        ),
                        _buildRoadmapItem(
                          icon: Icons.record_voice_over_rounded,
                          title: '2. Multimodal Interactive AAC Assistant',
                          description: 'Transforming Sitara into a complete Assistive and Alternative Communication (AAC) platform. Non-verbal children can tap rich interactive action and need icons to express daily needs (e.g. food, sleep, emotions, pain), with high-quality instant speech output.',
                          color: const Color(0xFF6C63FF),
                        ),
                        _buildRoadmapItem(
                          icon: Icons.psychology_rounded,
                          title: '3. Generative Child-Likeness Adaptation AI',
                          description: 'Developing local, on-device AI generators that tailor storybook scenarios, learning cards, and gamified therapeutic sessions completely based on the unique likes, interests, and developmental profile of each individual child.',
                          color: Colors.pinkAccent,
                        ),
                        _buildRoadmapItem(
                          icon: Icons.volume_up_rounded,
                          title: '4. Cloud Neural TTS & Narration',
                          description: 'Integrating premium cloud neural speech engines (Google Cloud TTS APIs) to deliver ultra-premium, emotionally expressive female narration for stories and target words, maximizing child phonetic mimicry.',
                          color: Colors.orangeAccent,
                        ),
                        _buildRoadmapItem(
                          icon: Icons.fingerprint_rounded,
                          title: '5. Parent Authentication & Cloud Sync',
                          description: 'Establishing a secure local-first cloud-synced account platform allowing clinical progress, success records, learning streaks, and daily behavior patterns to be synchronized securely across parent and caregiver devices.',
                          color: Colors.cyanAccent,
                        ),
                        _buildRoadmapItem(
                          icon: Icons.local_hospital_rounded,
                          title: '6. Therapist Integration Gateway',
                          description: 'Building a dedicated therapist portal for speech-language pathologists (SLPs) to configure custom vocabulary sets, monitor progress metrics remotely, and push personalized homework schedules.',
                          color: Colors.redAccent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoadmapItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFFC0BBDD),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
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
              child: Icon(Icons.star_rounded, size: 84, color: Colors.amberAccent),
            ),
          ),
        ),
      );
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
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
            Icon(icon, size: 48, color: Colors.white),
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
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _SmallCard({
    required this.icon,
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
            Icon(icon, size: 36, color: color),
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

class _FuturePlanCard extends StatelessWidget {
  final VoidCallback onTap;
  const _FuturePlanCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E144B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.amberAccent.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 28, color: Colors.amberAccent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '𝐒𝐎𝐕𝐄𝐑𝐄𝐈𝐆𝐍 𝐑𝐎𝐀𝐃𝐌𝐀𝐏 𝟐𝟎𝟐𝟔-𝟐𝟎𝟑𝟎',
                    style: GoogleFonts.outfit(
                      color: Colors.amberAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Tap to view our future expansion plans for Pakistan & AAC Assistive Tech.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.amberAccent, size: 16),
          ],
        ),
      ),
    );
  }
}
