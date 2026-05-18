import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/symbols_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'animals';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final childName = args?['childName'] as String? ?? 'Star';

    return Scaffold(
      body: Container(
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
                    // Parent portal button
                    Semantics(
                      label: 'Open parent dashboard',
                      button: true,
                      child: IconButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/parent'),
                        icon: const Icon(Icons.bar_chart_rounded,
                            color: Color(0xFFB8B0FF), size: 28),
                        tooltip: 'Parent Dashboard',
                      ),
                    ),
                  ],
                ),
              ),

              // ─── STAR MASCOT ───────────────────────────────────────
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
                      const SizedBox(height: 16),
                      
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
                              onTap: () => Navigator.pushNamed(
                                  context, '/game',
                                  arguments: {
                                    'childName': childName,
                                    'mode': 'story',
                                    'initial_category': _selectedCategory
                                  }),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SmallCard(
                              emoji: '📊',
                              title: 'Progress',
                              color: const Color(0xFFFF6584),
                              onTap: () =>
                                  Navigator.pushNamed(context, '/parent'),
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
