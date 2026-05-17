import 'dart:convert';
import '../models/game_event.dart';
import 'local_db_service.dart';

class AnalyticsService {
  final String childId;
  final LocalDbService _db;

  AnalyticsService({
    required this.childId,
    LocalDbService? db,
  }) : _db = db ?? LocalDbService.instance;

  GameEvent buildEvent({
    required GameEventType type,
    required Map<String, dynamic> properties,
  }) {
    return GameEvent(
      type: type,
      childId: childId,
      properties: properties,
    );
  }

  Future<void> log({
    required GameEventType type,
    required Map<String, dynamic> properties,
  }) async {
    final event = buildEvent(type: type, properties: properties);
    await _db.saveGameEvent(event);
  }

  Future<List<GameEvent>> getEvents({int? limitDays}) {
    return _db.getGameEvents(childId, limitDays: limitDays);
  }

  Future<int> getTodayMinutes() {
    return _db.getTodayPlayMinutes();
  }

  Future<void> addMinutes(int minutes) {
    return _db.addPlayMinutes(minutes);
  }

  Future<String> exportEventsAsJson({int? limitDays}) async {
    final events = await getEvents(limitDays: limitDays);
    final list = events.map((e) => e.toJson()).toList();
    return jsonEncode(list);
  }
}
