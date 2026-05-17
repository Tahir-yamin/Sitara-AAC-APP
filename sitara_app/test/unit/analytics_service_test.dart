import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/models/game_event.dart';
import 'package:sitara/services/analytics_service.dart';

void main() {
  group('AnalyticsService', () {
    test('buildEvent creates event with correct type and child ID', () {
      final svc = AnalyticsService(childId: 'test_child');
      final event = svc.buildEvent(
        type: GameEventType.cardTapped,
        properties: {'correct': true, 'response_time_ms': 800},
      );
      expect(event.type, GameEventType.cardTapped);
      expect(event.childId, 'test_child');
      expect(event.properties['correct'], isTrue);
    });

    test('buildEvent stamps current timestamp', () {
      final svc = AnalyticsService(childId: 'test_child');
      final before = DateTime.now();
      final event = svc.buildEvent(
        type: GameEventType.sessionCapHit,
        properties: {},
      );
      final after = DateTime.now();
      expect(event.timestamp.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(event.timestamp.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });
  });
}
