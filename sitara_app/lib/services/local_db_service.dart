import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/session_event.dart';
import '../models/game_event.dart';

/// LocalDbService — JSON persistence via shared_preferences + secure storage.
/// Child profiles (name, ID) are stored in Android Keystore via flutter_secure_storage.
/// Session events remain in SharedPreferences (volume too high for secure storage).
class LocalDbService {
  LocalDbService._();

  /// Protected constructor for test subclasses. Production code must use
  /// [instance]; only test doubles should call this.
  @visibleForTesting
  LocalDbService.forTesting();

  static final LocalDbService instance = LocalDbService._();

  SharedPreferences? _prefs;
  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences? get _p => _prefs;

  // ─── KEYS ──────────────────────────────────────────────────────────────────

  String _eventsKey(String childId) => 'events_$childId';
  String _profileKey(String childId) => 'profile_$childId';
  String _insightsKey(String childId) => 'insights_$childId';
  String _gameEventsKey(String childId) => 'game_events_$childId';
  String _playMinutesKey(String childId, String date) => 'play_minutes_${childId}_$date';

  // ─── SESSION EVENTS ────────────────────────────────────────────────────────

  Future<void> saveEvent(SessionEvent event) async {
    final key = _eventsKey(event.childId);
    final existing = _p?.getStringList(key) ?? [];
    try {
      existing.add(jsonEncode({
        'child_id': event.childId,
        'event_type': event.eventType,
        'card_id': event.cardId,
        'category': event.category,
        'timestamp': event.timestamp.toIso8601String(),
        'is_success': event.isSuccess,
        'tap_speed': event.tapSpeed,
        'tap_count': event.tapCount,
      }));
      // Keep last 500 events per child to bound storage
      if (existing.length > 500) existing.removeRange(0, existing.length - 500);
      await _p?.setStringList(key, existing);
    } catch (_) {}
  }

  Future<List<SessionEvent>> getEventsForChild(String childId,
      {int? limitDays}) async {
    final key = _eventsKey(childId);
    final raw = _p?.getStringList(key) ?? [];
    final cutoff = limitDays != null
        ? DateTime.now().subtract(Duration(days: limitDays))
        : null;

    return raw
        .map((s) {
          try {
            return jsonDecode(s) as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        })
        .where((m) => m != null)
        .cast<Map<String, dynamic>>()
        .where((m) {
          if (cutoff == null) return true;
          return DateTime.parse(m['timestamp'] as String).isAfter(cutoff);
        })
        .map((m) => SessionEvent(
              childId: m['child_id'] as String,
              eventType: m['event_type'] as String,
              cardId: m['card_id'] as String,
              category: m['category'] as String,
              timestamp: DateTime.parse(m['timestamp'] as String),
              isSuccess: m['is_success'] as bool,
              tapSpeed: (m['tap_speed'] as num).toDouble(),
              tapCount: m['tap_count'] as int,
            ))
        .toList()
        .reversed
        .toList();
  }

  // ─── CHILD PROFILES (encrypted via Android Keystore) ──────────────────────

  Future<void> saveChildProfile({
    required String childId,
    required String childName,
    String preferredCategory = 'animals',
  }) async {
    if (kIsWeb) return;
    final key = _profileKey(childId);
    final existing = await _secure.read(key: key);
    final profile = existing != null
        ? jsonDecode(existing) as Map<String, dynamic>
        : <String, dynamic>{};

    profile['child_id'] = childId;
    profile['child_name'] = childName;
    profile['preferred_category'] = preferredCategory;
    profile['total_sessions'] = ((profile['total_sessions'] as int?) ?? 0) + 1;
    profile['created_at'] ??= DateTime.now().toIso8601String();

    await _secure.write(key: key, value: jsonEncode(profile));
  }

  Future<Map<String, dynamic>?> getChildProfile(String childId) async {
    if (kIsWeb) return null;
    final key = _profileKey(childId);
    final raw = await _secure.read(key: key);
    return raw != null ? jsonDecode(raw) as Map<String, dynamic> : null;
  }

  // ─── AGENT INSIGHTS ────────────────────────────────────────────────────────

  Future<void> saveInsight({
    required String childId,
    required String agent,
    required String insightType,
    required String description,
  }) async {
    final key = _insightsKey(childId);
    final existing = _p?.getStringList(key) ?? [];
    try {
      existing.add(jsonEncode({
        'child_id': childId,
        'agent': agent,
        'insight_type': insightType,
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
      }));
      if (existing.length > 200) existing.removeRange(0, existing.length - 200);
      await _p?.setStringList(key, existing);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getInsights(String childId,
      {int limit = 20}) async {
    final key = _insightsKey(childId);
    final raw = _p?.getStringList(key) ?? [];
    final all = raw
        .map((s) {
          try {
            return jsonDecode(s) as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        })
        .where((m) => m != null)
        .cast<Map<String, dynamic>>()
        .toList()
        .reversed
        .toList();
    return all.take(limit).toList();
  }

  // ─── GAME EVENTS ───────────────────────────────────────────────────────────

  Future<void> saveGameEvent(GameEvent event) async {
    final key = _gameEventsKey(event.childId);
    final existing = _p?.getStringList(key) ?? [];
    try {
      existing.add(jsonEncode(event.toJson()));
      if (existing.length > 1000) existing.removeRange(0, existing.length - 1000);
      await _p?.setStringList(key, existing);
    } catch (_) {}
  }

  Future<List<GameEvent>> getGameEvents(String childId, {int? limitDays}) async {
    final key = _gameEventsKey(childId);
    final raw = _p?.getStringList(key) ?? [];
    final cutoff = limitDays != null
        ? DateTime.now().subtract(Duration(days: limitDays))
        : null;

    final events = raw
        .map((s) {
          try {
            return GameEvent.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .where((e) => e != null)
        .cast<GameEvent>()
        .where((e) => cutoff == null || e.timestamp.isAfter(cutoff))
        .toList()
        .reversed
        .toList();
    return events;
  }

  String _todayDateString() {
    final today = DateTime.now();
    return '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
  }

  Future<int> getTodayPlayMinutes(String childId) async {
    return _p?.getInt(_playMinutesKey(childId, _todayDateString())) ?? 0;
  }

  Future<void> addPlayMinutes(String childId, int minutes) async {
    final key = _playMinutesKey(childId, _todayDateString());
    final current = _p?.getInt(key) ?? 0;
    await _p?.setInt(key, current + minutes);
  }

  // ─── SETTINGS ──────────────────────────────────────────────────────────────

  static const String _ttsLanguageModeKey = 'setting_tts_language_mode';

  Future<void> saveTtsLanguageMode(String mode) async {
    await _p?.setString(_ttsLanguageModeKey, mode);
  }

  String getTtsLanguageMode() {
    return _p?.getString(_ttsLanguageModeKey) ?? 'bilingual';
  }

  // ─── STATS ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getWeekStats(String childId) async {
    final events = await getEventsForChild(childId, limitDays: 7);
    if (events.isEmpty) {
      return {
        'total_attempts': 0,
        'total_successes': 0,
        'categories_explored': 0,
        'avg_tap_speed': 0.0,
        'success_rate': 0.0,
      };
    }

    final successes = events.where((e) => e.isSuccess).length;
    final categories = events.map((e) => e.category).toSet().length;
    final avgSpeed = events.map((e) => e.tapSpeed).reduce((a, b) => a + b) / events.length;

    return {
      'total_attempts': events.length,
      'total_successes': successes,
      'categories_explored': categories,
      'avg_tap_speed': avgSpeed,
      'success_rate': successes / events.length,
    };
  }

  // ─── STORYBOOK COOLDOWN ───────────────────────────────────────────────────

  static const String _lastStoryPlayTimeKey = 'setting_last_story_play_time';

  Future<void> saveLastStoryPlayTime(DateTime timestamp) async {
    await _p?.setString(_lastStoryPlayTimeKey, timestamp.toIso8601String());
  }

  DateTime? getLastStoryPlayTime() {
    final raw = _p?.getString(_lastStoryPlayTimeKey);
    return raw != null ? DateTime.parse(raw) : null;
  }

  // ─── ACTIVE CHILD PERSISTENCE (WORKS EVERYWHERE INCLUDING WEB) ──────────────

  Future<void> saveActiveChild({required String childId, required String childName}) async {
    await _p?.setString('active_child_id', childId);
    await _p?.setString('active_child_name', childName);
  }

  Map<String, String>? getActiveChild() {
    final id = _p?.getString('active_child_id');
    final name = _p?.getString('active_child_name');
    if (id != null && name != null) {
      return {'childId': id, 'childName': name};
    }
    return null;
  }
}
