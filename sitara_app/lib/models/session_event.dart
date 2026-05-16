class SessionEvent {
  final String childId;
  final String eventType;  // 'card_tap', 'card_success', 'card_fail', 'quest_complete'
  final String cardId;
  final String category;
  final DateTime timestamp;
  final bool isSuccess;
  final int tapCount;       // How many taps on this card
  final double tapSpeed;    // Taps per second (frustration proxy)

  SessionEvent({
    required this.childId,
    required this.eventType,
    required this.cardId,
    required this.category,
    required this.timestamp,
    required this.isSuccess,
    this.tapCount = 1,
    this.tapSpeed = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'child_id': childId,
    'event_type': eventType,
    'card_id': cardId,
    'category': category,
    'timestamp': timestamp.toIso8601String(),
    'is_success': isSuccess,
    'tap_count': tapCount,
    'tap_speed': tapSpeed,
  };
}
