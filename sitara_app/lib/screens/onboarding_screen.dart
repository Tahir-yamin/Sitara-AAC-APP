import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../services/local_db_service.dart';
import '../services/session_tracker.dart';
import '../services/tts_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    TtsService().stop();
  }

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      emoji: '⭐',
      title: 'Welcome to Sitara!',
      subtitle: 'ستارہ کی دنیا میں خوش آمدید',
      body: 'A magical learning companion designed for non-verbal children. '
          "Sitara adapts to your child's pace — always patient, always kind.",
      color: Color(0xFF6C63FF),
    ),
    _OnboardingPage(
      emoji: '🎮',
      title: 'Learn Through Play',
      subtitle: 'کھیل کھیل میں سیکھیں',
      body: 'Our AI watches, listens, and gently adjusts the game — '
          'easier when frustrated, more exciting when ready. '
          'No pressure, just joy!',
      color: Color(0xFF43C59E),
    ),
    _OnboardingPage(
      emoji: '📊',
      title: 'Parents Stay Informed',
      subtitle: 'ہر پیش قدمی دیکھیں',
      body: 'Weekly warm reports celebrate every milestone. '
          'See what your child loves, what they\'re mastering, '
          'and gentle suggestions for home.',
      color: Color(0xFFFF6584),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _startApp();
    }
  }

  void _startApp() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your child's name first!")),
      );
      return;
    }
    final randomHex = List.generate(8, (_) => Random().nextInt(16).toRadixString(16)).join('');
    final childId = 'child_${DateTime.now().millisecondsSinceEpoch}_$randomHex';

    context.read<SessionTracker>().startNewSession(
          childId: childId,
          childName: name,
        );
    LocalDbService.instance.saveChildProfile(
      childId: childId,
      childName: name,
    );

    Navigator.pushReplacementNamed(context, '/home',
        arguments: {'childName': name});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _pages.length,
              itemBuilder: (_, i) => _PageView(page: _pages[i]),
            ),
          ),
          // Name input on last page
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(fontSize: 20),
                decoration: InputDecoration(
                  hintText: "Your child's name (e.g. Zara)",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon:
                      const Icon(Icons.child_care, color: Color(0xFF6C63FF)),
                ),
              ),
            ),
            crossFadeState: _currentPage == _pages.length - 1
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
          const SizedBox(height: 16),
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? _pages[i].color
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: Semantics(
                label: 'Next onboarding step',
                button: true,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pages[_currentPage].color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _next,
                  child: Text(_currentPage < _pages.length - 1
                      ? 'Next →'
                      : 'Start Learning! ⭐'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final String emoji, title, subtitle, body;
  final Color color;
  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.color,
  });
}

class _PageView extends StatelessWidget {
  final _OnboardingPage page;
  const _PageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [page.color.withValues(alpha: 0.15), Colors.white],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
              Text(page.emoji, style: const TextStyle(fontSize: 80)),
              const SizedBox(height: 32),
              Text(
                page.title,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Nunito'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                page.subtitle,
                style: GoogleFonts.notoNastaliqUrdu(
                    fontSize: 16,
                    color: page.color,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                page.body,
                style: const TextStyle(
                    fontSize: 16, height: 1.6, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
