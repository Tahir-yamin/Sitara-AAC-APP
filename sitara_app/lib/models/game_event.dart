enum GameEventType {
  cardTapped,
  rewardTriggered,
  difficultyAdjusted,
  breakShown,
  questStarted,
  questCompleted,
  agentSessionEval,
  interactionCapHit,
  sessionCapHit,
  dailyLimitApproached,
  unknown;

  String get key {
    switch (this) {
      case cardTapped:
        return 'card_tapped';
      case rewardTriggered:
        return 'reward_triggered';
      case difficultyAdjusted:
        return 'difficulty_adjusted';
      case breakShown:
        return 'break_shown';
      case questStarted:
        return 'quest_started';
      case questCompleted:
        return 'quest_completed';
      case agentSessionEval:
        return 'agent_session_eval';
      case interactionCapHit:
        return 'interaction_cap_hit';
      case sessionCapHit:
        return 'session_cap_hit';
      case dailyLimitApproached:
        return 'daily_limit_approached';
      case unknown:
        return 'unknown';
    }
  }

  static GameEventType fromString(String s) {
    return GameEventType.values.firstWhere(
      (e) => e.key == s,
      orElse: () => GameEventType.unknown,
    );
  }
}

class GameEvent {
  final GameEventType type;
  final String childId;
  final Map<String, dynamic> properties;
  final DateTime timestamp;

  GameEvent({
    required this.type,
    required this.childId,
    required this.properties,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'type': type.key,
    'child_id': childId,
    'timestamp': timestamp.toIso8601String(),
    'properties': properties,
  };

  factory GameEvent.fromJson(Map<String, dynamic> json) => GameEvent(
    type: GameEventType.fromString(json['type'] as String),
    childId: json['child_id'] as String,
    properties: Map<String, dynamic>.from(json['properties'] as Map),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}
