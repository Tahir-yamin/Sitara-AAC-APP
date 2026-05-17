import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/models/game_event.dart';

void main() {
  group('GameEvent', () {
    test('toJson includes all required fields', () {
      final event = GameEvent(
        type: GameEventType.cardTapped,
        childId: 'zara_001',
        properties: {'symbol_id': 'cat', 'correct': true, 'response_time_ms': 1200},
      );
      final json = event.toJson();
      expect(json['type'], equals('card_tapped'));
      expect(json['child_id'], equals('zara_001'));
      expect(json['timestamp'], isA<String>());
      expect(json['properties']['correct'], isTrue);
    });

    test('fromJson roundtrip preserves type and properties', () {
      final original = GameEvent(
        type: GameEventType.rewardTriggered,
        childId: 'zara_001',
        properties: {'reward_type': 'star', 'success_rate': 0.8},
      );
      final restored = GameEvent.fromJson(jsonDecode(jsonEncode(original.toJson())));
      expect(restored.type, equals(original.type));
      expect(restored.childId, equals(original.childId));
      expect(restored.properties['reward_type'], equals('star'));
    });

    test('GameEventType.fromString returns correct enum', () {
      expect(GameEventType.fromString('card_tapped'), GameEventType.cardTapped);
      expect(GameEventType.fromString('session_cap_hit'), GameEventType.sessionCapHit);
      expect(GameEventType.fromString('unknown_xyz'), GameEventType.unknown);
    });
  });
}
