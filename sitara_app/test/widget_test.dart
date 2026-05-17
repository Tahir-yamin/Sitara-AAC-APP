// This is a basic Flutter widget test for Sitara App.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sitara/app.dart';
import 'package:sitara/services/session_tracker.dart';
import 'package:sitara/services/antigravity_service.dart';
import 'package:sitara/services/local_db_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalDbService.instance.init();
  });

  testWidgets('Sitara App Splash Screen Smoke Test', (WidgetTester tester) async {
    final db = LocalDbService.instance;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SessionTracker()),
          ChangeNotifierProvider(create: (_) => AntigravityService()),
          Provider.value(value: db),
        ],
        child: const SitaraApp(),
      ),
    );

    // Verify that the Splash Screen loads and displays the app name
    expect(find.text('Sitara'), findsOneWidget);

    // Drain transition timers
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}

