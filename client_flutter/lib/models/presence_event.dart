enum PresenceState {
  online,
  offline,
  idle,
  inCall,
  inWorkspace,
}

class PresenceEvent {
  final String userId;
  final PresenceState state;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  PresenceEvent({
    required this.userId,
    required this.state,
    required this.timestamp,
    this.metadata,
  });

  factory PresenceEvent.fromJson(Map<String, dynamic> json) {
    return PresenceEvent(
      userId: json['userId'] as String,
      state: _parseState(json['state'] as String),
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'state': state.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      if (metadata != null) 'metadata': metadata,
    };
  }

  static PresenceState _parseState(String stateStr) {
    switch (stateStr.toLowerCase()) {
      case 'online':
        return PresenceState.online;
      case 'offline':
        return PresenceState.offline;
      case 'idle':
        return PresenceState.idle;
      case 'in_call':
      case 'incall':
        return PresenceState.inCall;
      case 'in_workspace':
      case 'inworkspace':
        return PresenceState.inWorkspace;
      default:
        return PresenceState.offline;
    }
  }

  bool get isOnline =>
      state == PresenceState.online ||
      state == PresenceState.inCall ||
      state == PresenceState.inWorkspace;

  PresenceEvent copyWith({
    String? userId,
    PresenceState? state,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return PresenceEvent(
      userId: userId ?? this.userId,
      state: state ?? this.state,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }
}
