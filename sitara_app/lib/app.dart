import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'screens/quest_screen.dart';
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
        // Nunito via google_fonts — no font files needed in assets
        textTheme: GoogleFonts.nunitoTextTheme(),
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash':      (ctx) => const SplashScreen(),
        '/onboarding':  (ctx) => const OnboardingScreen(),
        '/home':        (ctx) => const HomeScreen(),
        '/game':        (ctx) => const GameScreen(),
        '/quest':       (ctx) => const QuestScreen(),   // A2A: Story Weaver output
        '/parent':      (ctx) => const ParentDashboard(),
      },
    );
  }
}
