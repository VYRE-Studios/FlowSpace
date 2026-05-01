// lib/sync/sync_message.dart

import 'dart:convert';

class SyncMessage {
  final String boardId;
  final String opType;
  final Map<String, dynamic> payload;
  final int timestamp;

  SyncMessage({
    required this.boardId,
    required this.opType,
    required this.payload,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'boardId': boardId,
      'opType': opType,
      'payload': payload,
      'timestamp': timestamp,
    };
  }

  static SyncMessage fromJson(Map<String, dynamic> json) {
    return SyncMessage(
      boardId: json['boardId'],
      opType: json['opType'],
      payload: json['payload'],
      timestamp: json['timestamp'],
    );
  }

  String encode() => jsonEncode(toJson());
  static SyncMessage decode(String data) => fromJson(jsonDecode(data));
}
