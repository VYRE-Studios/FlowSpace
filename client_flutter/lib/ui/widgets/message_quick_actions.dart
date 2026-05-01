import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MessageQuickActions extends StatelessWidget {
  final bool isOwnMessage;
  final VoidCallback onReply;
  final VoidCallback onReact;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final bool isPinned;
  final VoidCallback? onReadReceipts;
  final String messageContent;

  const MessageQuickActions({
    Key? key,
    required this.isOwnMessage,
    required this.onReply,
    required this.onReact,
    this.onEdit,
    this.onDelete,
    this.onPin,
    this.isPinned = false,
    this.onReadReceipts,
    required this.messageContent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionButton(
            icon: Icons.add_reaction_outlined,
            tooltip: 'React',
            onPressed: onReact,
          ),
          _ActionButton(
            icon: Icons.reply,
            tooltip: 'Reply',
            onPressed: onReply,
          ),
          if (onPin != null)
            _ActionButton(
              icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              tooltip: isPinned ? 'Unpin' : 'Pin',
              onPressed: onPin!,
              color: isPinned ? Colors.blue : null,
            ),
          if (isOwnMessage && onEdit != null)
            _ActionButton(
              icon: Icons.edit,
              tooltip: 'Edit',
              onPressed: onEdit!,
            ),
          if (onReadReceipts != null)
            _ActionButton(
              icon: Icons.visibility_outlined,
              tooltip: 'Read by',
              onPressed: onReadReceipts!,
            ),
          _ActionButton(
            icon: Icons.content_copy,
            tooltip: 'Copy',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: messageContent));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          if (isOwnMessage && onDelete != null)
            _ActionButton(
              icon: Icons.delete_outline,
              tooltip: 'Delete',
              onPressed: onDelete!,
              color: Colors.red,
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: color ?? Theme.of(context).iconTheme.color,
          ),
        ),
      ),
    );
  }
}
