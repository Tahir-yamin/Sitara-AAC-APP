import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tts_service.dart';
import '../services/local_db_service.dart';
import '../services/session_tracker.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  bool _tapped = false;

  @override
  void initState() {
    super.initState();
    
    // Attempt auto-play on start (works on native platforms immediately)
    TtsService().playIntroMusic();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scaleAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)),
    );
    _controller.forward();
  }

  void _onTapEnter() {
    if (_tapped) return;
    setState(() {
      _tapped = true;
    });
    
    // Start music on user interaction (satisfies web autoplay policy!)
    TtsService().playIntroMusic();
    
    // Fun visual pop animation on tap
    _controller.forward(from: 0.0);
    
    final activeChild = LocalDbService.instance.getActiveChild();
    
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        if (activeChild != null) {
          context.read<SessionTracker>().startNewSession(
            childId: activeChild['childId']!,
            childName: activeChild['childName']!,
          );
          TtsService().stopIntroMusic();
          Navigator.pushReplacementNamed(context, '/home',
              arguments: {'childName': activeChild['childName']!});
        } else {
          Navigator.pushReplacementNamed(context, '/onboarding');
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTapEnter,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1040), Color(0xFF6C63FF), Color(0xFFFF6584)],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    excludeSemantics: true,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (_, __) => Transform.scale(
                        scale: _scaleAnim.value,
                        child: const Icon(
                          Icons.star_rounded,
                          size: 120,
                          color: Colors.amberAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        const Text(
                          'Sitara',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Nunito',
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ستارہ  ·  Your Learning Star',
                          style: TextStyle(
                            fontFamily: 'NotoNastaliqUrdu', 
                            fontFamilyFallback: const ['sans-serif', 'Arial', 'system-ui'],
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),
                        PulsingButton(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.touch_app_rounded, color: Colors.amberAccent, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Tap to Enter  ·  ٹیپ کریں',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

class PulsingButton extends StatefulWidget {
  final Widget child;
  const PulsingButton({super.key, required this.child});

  @override
  State<PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<PulsingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnim,
      child: widget.child,
    );
  }
}
