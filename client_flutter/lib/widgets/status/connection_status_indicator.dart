import 'package:flutter/material.dart';

/// Displays a compact connection quality pill with ping and icon.
///
/// For now this can be passed mock data; it will later be driven by
/// real connectivity metrics from the backend/P2P layer.
class ConnectionStatusIndicator extends StatelessWidget {
  final Duration ping;
  final bool connected;

  const ConnectionStatusIndicator({
    super.key,
    required this.ping,
    required this.connected,
  });

  Color _resolveColor() {
    if (!connected) return Colors.redAccent;

    final ms = ping.inMilliseconds;
    if (ms < 100) return const Color(0xFF0B93FF); // FLŌ blue
    if (ms < 250) return const Color(0xFF00D9FF); // cyan
    if (ms < 500) return Colors.yellowAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '${ping.inMilliseconds}ms',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}


