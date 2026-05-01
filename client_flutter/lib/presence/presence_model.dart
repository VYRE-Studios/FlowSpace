// lib/presence/presence_model.dart

import 'package:flutter/material.dart';

class PresenceModel {
  final String userId;
  Offset cursor;
  DateTime lastSeen;
  Color color;

  PresenceModel({
    required this.userId,
    required this.cursor,
    required this.lastSeen,
    required this.color,
  });

  bool get isActive {
    final diff = DateTime.now().difference(lastSeen).inMilliseconds;
    return diff < 5000;
  }
}
