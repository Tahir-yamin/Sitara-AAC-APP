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
    return GameEvent(type: type, childId: childId, properties: properties);
  }

  Future<void> log({
    required GameEventType type,
    required Map<String, dynamic> properties,
  }) async {
    final event = buildEvent(type: type, properties: properties);
    await _db.saveGameEvent(event);
  }

  Future<List<GameEvent>> getEvents({int? limitDays}) =>
      _db.getGameEvents(childId, limitDays: limitDays);

  Future<int> getTodayMinutes() => _db.getTodayPlayMinutes();

  Future<void> addMinutes(int minutes) => _db.addPlayMinutes(minutes);

  Future<String> exportEventsAsJson({int? limitDays}) async {
    final events = await getEvents(limitDays: limitDays);
    return jsonEncode(events.map((e) => e.toJson()).toList());
  }
}
