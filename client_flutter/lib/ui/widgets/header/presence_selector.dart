import 'package:flutter/material.dart';

enum UserPresence { online, away, busy, offline }

class PresenceSelector extends StatelessWidget {
  final UserPresence current;
  final ValueChanged<UserPresence> onChange;

  const PresenceSelector({
    super.key,
    required this.current,
    required this.onChange,
  });

  String _label(UserPresence p) {
    switch (p) {
      case UserPresence.online:
        return 'Online';
      case UserPresence.away:
        return 'Away';
      case UserPresence.busy:
        return 'Busy';
      case UserPresence.offline:
      default:
        return 'Offline';
    }
  }

  Color _color(UserPresence p) {
    switch (p) {
      case UserPresence.online:
        return Colors.greenAccent;
      case UserPresence.away:
        return Colors.yellowAccent;
      case UserPresence.busy:
        return Colors.orangeAccent;
      case UserPresence.offline:
      default:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<UserPresence>(
      color: const Color(0xFF0F0F0F),
      onSelected: onChange,
      itemBuilder: (context) => UserPresence.values
          .map(
            (p) => PopupMenuItem(
              value: p,
              child: Row(
                children: [
                  Icon(Icons.circle, color: _color(p), size: 12),
                  const SizedBox(width: 8),
                  Text(
                    _label(p),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: _color(current), size: 12),
          const SizedBox(width: 8),
          Text(
            _label(current),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
        ],
      ),
    );
  }
}


