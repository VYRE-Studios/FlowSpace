import 'package:flutter/material.dart';

/// Small icon-only badge describing current sync state.
///
/// This is designed to sit in the header next to presence and
/// connection indicators.
class SyncStatusBadge extends StatelessWidget {
  final SyncStatus status;

  const SyncStatusBadge({
    super.key,
    required this.status,
  });

  IconData _resolveIcon() {
    switch (status) {
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.error:
        return Icons.error_outline;
      case SyncStatus.queued:
        return Icons.pending;
      case SyncStatus.idle:
      default:
        return Icons.check_circle_outline;
    }
  }

  Color _resolveColor() {
    switch (status) {
      case SyncStatus.syncing:
        return const Color(0xFF00D9FF);
      case SyncStatus.error:
        return Colors.redAccent;
      case SyncStatus.queued:
        return Colors.yellowAccent;
      case SyncStatus.idle:
      default:
        return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Icon(
      _resolveIcon(),
      size: 18,
      color: _resolveColor(),
    );
  }
}

enum SyncStatus {
  idle,
  syncing,
  queued,
  error,
}


