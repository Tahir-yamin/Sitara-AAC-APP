import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sitara/screens/storybook_screen.dart';
import 'package:sitara/services/local_db_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalDbService.instance.init();
  });

  group('StorybookScreen Widget Tests', () {
    testWidgets('Renders story selector initially when no cooldown is active',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StorybookScreen(),
        ),
      );

      // Wait for ticker animations
      await tester.pump();

      // Verify the header is displayed
      expect(find.text('Sitara Stories'), findsOneWidget);

      // Verify page displays the soothing stories instruction
      expect(find.text('Select a Soothing Story'), findsOneWidget);

      // Verify all 3 stories are present
      expect(find.text('The Shiny Little Star'), findsOneWidget);
      expect(find.text('Coco the Kind Cat'), findsOneWidget);
      expect(find.text('The Forest Train Adventure'), findsOneWidget);
    });

    testWidgets('Shows sleeping screen if 12-hour cooldown is active',
        (WidgetTester tester) async {
      // Set cooldown play time to current moment
      await LocalDbService.instance.saveLastStoryPlayTime(DateTime.now());

      await tester.pumpWidget(
        const MaterialApp(
          home: StorybookScreen(),
        ),
      );

      // Wait for timers/animation tickers to kick off
      await tester.pump(const Duration(milliseconds: 100));

      // Verify that sleeping screen displays cooldown text
      expect(find.text('Sitara is Sleeping...'), findsOneWidget);
      expect(find.text('Next Story Unlocks In:'), findsOneWidget);
    });
  });
}
