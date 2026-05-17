import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/models/game_event.dart';
import 'package:sitara/services/analytics_service.dart';

// Minimal stub — avoids SharedPreferences entirely so no mocking needed.
class _NullDb {
  final List<GameEvent> _store = [];

  Future<void> saveGameEvent(GameEvent event) async => _store.add(event);

  Future<List<GameEvent>> getGameEvents(String childId, {int? limitDays}) async {
    final cutoff = limitDays != null
        ? DateTime.now().subtract(Duration(days: limitDays))
        : null;
    return _store
        .where((e) => e.childId == childId)
        .where((e) => cutoff == null || e.timestamp.isAfter(cutoff))
        .toList()
        .reversed
        .toList();
  }

  Future<int> getTodayPlayMinutes() async => 0;
  Future<void> addPlayMinutes(int _) async {}
}

// Thin wrapper that makes _NullDb look like LocalDbService to AnalyticsService.
// We achieve this by subclassing AnalyticsService with an overridden _db path.
class _TestAnalyticsService extends AnalyticsService {
  final _NullDb _nullDb;

  _TestAnalyticsService(String childId)
      : _nullDb = _NullDb(),
        super(childId: childId);

  @override
  GameEvent buildEvent({
    required GameEventType type,
    required Map<String, dynamic> properties,
  }) {
    return GameEvent(type: type, childId: childId, properties: properties);
  }

  @override
  Future<void> log({
    required GameEventType type,
    required Map<String, dynamic> properties,
  }) async {
    final event = buildEvent(type: type, properties: properties);
    await _nullDb.saveGameEvent(event);
  }

  @override
  Future<List<GameEvent>> getEvents({int? limitDays}) {
    return _nullDb.getGameEvents(childId, limitDays: limitDays);
  }

  @override
  Future<int> getTodayMinutes() => _nullDb.getTodayPlayMinutes();

  @override
  Future<void> addMinutes(int minutes) => _nullDb.addPlayMinutes(minutes);
}

void main() {
  group('AnalyticsService', () {
    test('buildEvent returns event with correct type and childId', () {
      final svc = _TestAnalyticsService('child_001');
      final event = svc.buildEvent(
        type: GameEventType.cardTapped,
        properties: {'card_id': 'apple'},
      );

      expect(event.type, GameEventType.cardTapped);
      expect(event.childId, 'child_001');
      expect(event.properties['card_id'], 'apple');
    });

    test('buildEvent auto-stamps a timestamp close to now', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final svc = _TestAnalyticsService('child_002');
      final event = svc.buildEvent(
        type: GameEventType.questStarted,
        properties: {},
      );
      final after = DateTime.now().add(const Duration(seconds: 1));

      expect(event.timestamp.isAfter(before), isTrue);
      expect(event.timestamp.isBefore(after), isTrue);
    });

    test('exportEventsAsJson round-trips to valid JSON list', () async {
      final svc = _TestAnalyticsService('child_003');

      await svc.log(
        type: GameEventType.rewardTriggered,
        properties: {'stars': 3},
      );
      await svc.log(
        type: GameEventType.difficultyAdjusted,
        properties: {'level': 'easy'},
      );

      final json = await svc.exportEventsAsJson();
      final decoded = jsonDecode(json) as List<dynamic>;

      expect(decoded.length, 2);

      // newest-first order — difficultyAdjusted was logged second
      expect(decoded[0]['type'], 'difficulty_adjusted');
      expect(decoded[1]['type'], 'reward_triggered');

      // verify round-trip fidelity via GameEvent.fromJson
      final reconstructed =
          decoded.map((m) => GameEvent.fromJson(m as Map<String, dynamic>)).toList();
      expect(reconstructed[0].type, GameEventType.difficultyAdjusted);
      expect(reconstructed[1].properties['stars'], 3);
    });

    test('GameEventType.fromKey returns unknown for unrecognised key', () {
      expect(GameEventType.fromKey('no_such_event'), GameEventType.unknown);
    });

    test('all GameEventType keys are distinct and non-empty', () {
      final keys = GameEventType.values.map((e) => e.key).toList();
      expect(keys.toSet().length, keys.length); // all unique
      for (final k in keys) {
        expect(k.isNotEmpty, isTrue);
      }
    });
  });
}
