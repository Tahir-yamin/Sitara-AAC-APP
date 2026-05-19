import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sitara/screens/parent_dashboard.dart';
import 'package:sitara/services/session_tracker.dart';
import 'package:sitara/services/antigravity_service.dart';
import 'package:sitara/services/local_db_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalDbService.instance.init();
  });

  testWidgets('ParentDashboard Parental Gate blocks content initially and displays puzzle', (WidgetTester tester) async {
    final db = LocalDbService.instance;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SessionTracker()),
          ChangeNotifierProvider(create: (_) => AntigravityService()),
          Provider.value(value: db),
        ],
        child: const MaterialApp(
          home: ParentDashboard(),
        ),
      ),
    );

    // Verify Parental Gate elements are rendered
    expect(find.text('Parent Verification'), findsOneWidget);
    expect(find.text('والدین کی تصدیق'), findsOneWidget);
    expect(find.byIcon(Icons.security_rounded), findsOneWidget);

    // Verify keypad buttons exist (1 to 9, 0, C, ⌫)
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('⌫'), findsOneWidget);

    // Verify main parent dashboard elements are NOT yet visible
    expect(find.text('Daily Screen Time'), findsNothing);
  });
}
