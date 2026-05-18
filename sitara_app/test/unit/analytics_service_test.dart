import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/models/game_event.dart';
import 'package:sitara/services/analytics_service.dart';
import 'package:sitara/services/local_db_service.dart';

/// In-memory stub for LocalDbService — no SharedPreferences or secure storage.
class _FakeLocalDb extends LocalDbService {
  _FakeLocalDb() : super.forTesting();

  final List<GameEvent> _events = [];
  final Map<String, int> _minutes = {};

  @override
  Future<void> saveGameEvent(GameEvent event) async => _events.add(event);

  @override
  Future<List<GameEvent>> getGameEvents(String childId, {int? limitDays}) async {
    final cutoff = limitDays != null
        ? DateTime.now().subtract(Duration(days: limitDays))
        : null;
    return _events
        .where((e) => e.childId == childId)
        .where((e) => cutoff == null || e.timestamp.isAfter(cutoff))
        .toList()
        .reversed
        .toList();
  }

  @override
  Future<int> getTodayPlayMinutes(String childId) async =>
      _minutes[childId] ?? 0;

  @override
  Future<void> addPlayMinutes(String childId, int minutes) async {
    _minutes[childId] = (_minutes[childId] ?? 0) + minutes;
  }
}

AnalyticsService _makeSvc(String childId) =>
    AnalyticsService.withDb(childId: childId, db: _FakeLocalDb());

void main() {
  group('AnalyticsService', () {
    test('buildEvent returns event with correct type and childId', () {
      final svc = _makeSvc('child_001');
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
      final svc = _makeSvc('child_002');
      final event = svc.buildEvent(
        type: GameEventType.questStarted,
        properties: {},
      );
      final after = DateTime.now().add(const Duration(seconds: 1));

      expect(event.timestamp.isAfter(before), isTrue);
      expect(event.timestamp.isBefore(after), isTrue);
    });

    test('exportEventsAsJson round-trips to valid JSON list', () async {
      final svc = _makeSvc('child_003');

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

    test('GameEventType.fromString returns unknown for unrecognised key', () {
      expect(GameEventType.fromString('no_such_event'), GameEventType.unknown);
    });

    test('all GameEventType keys are distinct and non-empty', () {
      final keys = GameEventType.values.map((e) => e.key).toList();
      expect(keys.toSet().length, keys.length); // all unique
      for (final k in keys) {
        expect(k.isNotEmpty, isTrue);
      }
    });

    test('addMinutes accumulates per-child daily play time', () async {
      final svc = _makeSvc('child_004');

      await svc.addMinutes(10);
      await svc.addMinutes(5);

      expect(await svc.getTodayMinutes(), 15);
    });
  });
}
