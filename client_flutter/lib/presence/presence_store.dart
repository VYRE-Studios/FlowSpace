// lib/presence/presence_store.dart

import 'package:flutter/material.dart';
import 'presence_model.dart';

class PresenceStore extends ChangeNotifier {
  final Map<String, PresenceModel> _users = {};

  void updatePresence({
    required String userId,
    required Offset cursor,
  }) {
    final now = DateTime.now();

    if (_users.containsKey(userId)) {
      _users[userId]!.cursor = cursor;
      _users[userId]!.lastSeen = now;
    } else {
      _users[userId] = PresenceModel(
        userId: userId,
        cursor: cursor,
        lastSeen: now,
        color: _assignColor(userId),
      );
    }

    notifyListeners();
  }

  Iterable<PresenceModel> get activeUsers =>
      _users.values.where((u) => u.isActive);

  Color _assignColor(String id) {
    final hash = id.codeUnits.fold(0, (a, b) => a + b);
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.55, 0.55).toColor();
  }
}
