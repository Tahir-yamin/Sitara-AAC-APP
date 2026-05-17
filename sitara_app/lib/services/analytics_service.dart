import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/game_event.dart';
import 'local_db_service.dart';

class AnalyticsService {
  final String childId;
  final LocalDbService _db;

  AnalyticsService({
    required this.childId,
    LocalDbService? db,
  }) : _db = db ?? LocalDbService.instance;

  /// Named constructor for tests: accepts an explicit [db] instance,
  /// bypassing the [LocalDbService.instance] singleton.
  @visibleForTesting
  AnalyticsService.withDb({required this.childId, required LocalDbService db})
      : _db = db;

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
    return _db.getTodayPlayMinutes(childId);
  }

  Future<void> addMinutes(int minutes) {
    return _db.addPlayMinutes(childId, minutes);
  }

  Future<String> exportEventsAsJson({int? limitDays}) async {
    final events = await getEvents(limitDays: limitDays);
    final list = events.map((e) => e.toJson()).toList();
    return jsonEncode(list);
  }
}
