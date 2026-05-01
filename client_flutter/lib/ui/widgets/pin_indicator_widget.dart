import 'package:flutter/material.dart';
import '../../models/pinned_message.dart';

/// Indicator showing a message is pinned
class PinIndicatorWidget extends StatelessWidget {
  final bool isPinned;
  final PinnedMessage? pinnedMessage;
  final VoidCallback? onTap;

  const PinIndicatorWidget({
    super.key,
    required this.isPinned,
    this.pinnedMessage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isPinned) return const SizedBox.shrink();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.push_pin,
              size: 12,
              color: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
            if (pinnedMessage?.pinnedReason != null) ...[
              const SizedBox(width: 4),
              Text(
                pinnedMessage!.pinnedReason!,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact pin badge for message lists
class PinBadge extends StatelessWidget {
  const PinBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.push_pin,
        size: 12,
        color: Theme.of(context).colorScheme.onTertiaryContainer,
      ),
    );
  }
}

/// Banner showing pinned message details
class PinnedMessageBanner extends StatelessWidget {
  final PinnedMessage pinnedMessage;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const PinnedMessageBanner({
    super.key,
    required this.pinnedMessage,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              Icons.push_pin,
              size: 16,
              color: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pinnedMessage.authorName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                  ),
                  Text(
                    pinnedMessage.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: onDismiss,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for pinning a message with optional reason
class PinMessageDialog extends StatefulWidget {
  final Function(String? reason) onPin;

  const PinMessageDialog({
    super.key,
    required this.onPin,
  });

  @override
  State<PinMessageDialog> createState() => _PinMessageDialogState();
}

class _PinMessageDialogState extends State<PinMessageDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.push_pin, size: 20),
          SizedBox(width: 8),
          Text('Pin Message'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add an optional reason for pinning this message:'),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              hintText: 'Reason (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            maxLength: 100,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final reason = _reasonController.text.trim();
            widget.onPin(reason.isEmpty ? null : reason);
            Navigator.of(context).pop();
          },
          child: const Text('Pin'),
        ),
      ],
    );
  }
}

/// Unpin confirmation dialog
class UnpinConfirmDialog extends StatelessWidget {
  final PinnedMessage pinnedMessage;
  final VoidCallback onConfirm;

  const UnpinConfirmDialog({
    super.key,
    required this.pinnedMessage,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Unpin Message?'),
      content: Text(
        'Are you sure you want to unpin this message?\n\n"${pinnedMessage.content.length > 100 ? '${pinnedMessage.content.substring(0, 100)}...' : pinnedMessage.content}"',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            onConfirm();
            Navigator.of(context).pop();
          },
          child: const Text('Unpin'),
        ),
      ],
    );
  }
}
