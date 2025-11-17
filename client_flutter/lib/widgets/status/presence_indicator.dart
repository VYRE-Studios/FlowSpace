import 'package:flutter/material.dart';

/// Simple presence dot used to indicate the current user's status.
///
/// This is UI‑only for now; it will be wired to real presence data
/// when the live status layer is implemented.
class PresenceIndicator extends StatelessWidget {
  final PresenceState state;
  final double size;

  const PresenceIndicator({
    super.key,
    required this.state,
    this.size = 12,
  });

  Color _resolveColor() {
    switch (state) {
      case PresenceState.online:
        return Colors.greenAccent;
      case PresenceState.away:
        return Colors.yellowAccent;
      case PresenceState.busy:
        return Colors.orangeAccent;
      case PresenceState.offline:
        return Colors.redAccent;
      case PresenceState.unknown:
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _resolveColor(),
        shape: BoxShape.circle,
      ),
    );
  }
}

enum PresenceState {
  online,
  away,
  busy,
  offline,
  unknown,
}


