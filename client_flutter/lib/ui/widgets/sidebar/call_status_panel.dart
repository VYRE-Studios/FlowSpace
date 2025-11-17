import 'package:flutter/material.dart';

import 'right_sidebar.dart';

class CallStatusPanel extends StatelessWidget {
  final CallStatus status;

  const CallStatusPanel({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (!status.active) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.videocam, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'In call with ${status.participants} participants',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Placeholder: hook into meet_service to join the current call.
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B93FF),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}


