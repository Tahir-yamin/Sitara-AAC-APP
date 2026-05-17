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

  String get key => switch (this) {
        GameEventType.cardTapped => 'card_tapped',
        GameEventType.rewardTriggered => 'reward_triggered',
        GameEventType.difficultyAdjusted => 'difficulty_adjusted',
        GameEventType.breakShown => 'break_shown',
        GameEventType.questStarted => 'quest_started',
        GameEventType.questCompleted => 'quest_completed',
        GameEventType.agentSessionEval => 'agent_session_eval',
        GameEventType.interactionCapHit => 'interaction_cap_hit',
        GameEventType.sessionCapHit => 'session_cap_hit',
        GameEventType.dailyLimitApproached => 'daily_limit_approached',
        GameEventType.unknown => 'unknown',
      };

  static GameEventType fromString(String key) {
    return GameEventType.values.firstWhere(
      (e) => e.key == key,
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
        timestamp: DateTime.parse(json['timestamp'] as String),
        properties: (json['properties'] as Map<String, dynamic>?) ?? {},
      );

}
