import 'package:flutter/material.dart';

class UserCursor extends StatelessWidget {
  final String userName;
  final Offset position;
  final Color color;

  const UserCursor({
    Key? key,
    required this.userName,
    required this.position,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: IgnorePointer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.arrow_upward,
              color: color,
              size: 20,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CursorTrackingService {
  static final CursorTrackingService instance = CursorTrackingService._();
  CursorTrackingService._();

  final Map<String, Offset> _userCursors = {};
  final Map<String, Color> _userColors = {};
  
  void updateCursor(String userId, Offset position) {
    _userCursors[userId] = position;
    if (!_userColors.containsKey(userId)) {
      _userColors[userId] = Colors.primaries[userId.hashCode % Colors.primaries.length];
    }
  }

  void removeCursor(String userId) {
    _userCursors.remove(userId);
  }

  Map<String, Offset> get cursors => Map.unmodifiable(_userCursors);
  Color getUserColor(String userId) => _userColors[userId] ?? Colors.blue;
}
