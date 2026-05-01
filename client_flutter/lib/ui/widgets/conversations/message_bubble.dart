import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/chat_models.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isOwnMessage;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(String emoji)? onReact;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isOwnMessage,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onReact,
  }) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: _isHovered ? theme.colorScheme.surfaceVariant.withOpacity(0.3) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                _getInitials(widget.message.senderName ?? widget.message.senderId),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: sender name + timestamp
                  Row(
                    children: [
                      Text(
                        widget.message.senderName ?? widget.message.senderId,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTimestamp(widget.message.timestamp ?? widget.message.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      if (widget.message.edited == true) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(edited)',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Message content
                  Text(
                    widget.message.content,
                    style: theme.textTheme.bodyMedium,
                  ),

                  // Attachments
                  if (widget.message.attachments != null && 
                      widget.message.attachments!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.message.attachments!.map((attachment) {
                          return _buildAttachment(context, attachment);
                        }).toList(),
                      ),
                    ),

                  // Thread indicator
                  if (widget.message.threadCount != null && 
                      widget.message.threadCount! > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: InkWell(
                        onTap: () {
                          // TODO: Open thread view
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.forum_outlined,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.message.threadCount} ${widget.message.threadCount == 1 ? "reply" : "replies"}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Reactions
                  if (widget.message.reactions != null && 
                      widget.message.reactions!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: widget.message.reactions!.entries.map((entry) {
                          return _buildReaction(context, entry.key, entry.value);
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),

            // Action buttons (visible on hover with smooth fade-in)
            AnimatedOpacity(
              opacity: _isHovered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              child: _isHovered ? Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_reaction_outlined, size: 18),
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      onPressed: () {
                        _showReactionPicker(context);
                      },
                      tooltip: 'Add reaction',
                    ),
                    IconButton(
                      icon: const Icon(Icons.reply_outlined, size: 18),
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      onPressed: widget.onReply,
                      tooltip: 'Reply in thread',
                    ),
                    if (widget.isOwnMessage) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: widget.onEdit,
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: widget.onDelete,
                        tooltip: 'Delete',
                      ),
                    ],
                  ],
                ),
              ) : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachment(BuildContext context, MessageAttachment attachment) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFileIcon(attachment.type),
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            attachment.name,
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildReaction(BuildContext context, String emoji, List<String> userIds) {
    final theme = Theme.of(context);
    final currentUserId = 'current_user'; // TODO: Get from auth
    final isReactedByUser = userIds.contains(currentUserId);

    return InkWell(
      onTap: () => widget.onReact?.call(emoji),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isReactedByUser
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isReactedByUser
                ? theme.colorScheme.primary
                : theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              '${userIds.length}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    // Common emoji reactions
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '🎉', '🚀', '👀'];
    
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: emojis.map((emoji) {
        return PopupMenuItem(
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
          onTap: () => widget.onReact?.call(emoji),
        );
      }).toList(),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) {
      return DateFormat('h:mm a').format(timestamp);
    } else if (diff.inDays == 1) {
      return 'Yesterday ${DateFormat('h:mm a').format(timestamp)}';
    } else if (diff.inDays < 7) {
      return DateFormat('EEE h:mm a').format(timestamp);
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }

  IconData _getFileIcon(String type) {
    switch (type) {
      case 'image':
        return Icons.image_outlined;
      case 'video':
        return Icons.video_file_outlined;
      case 'audio':
        return Icons.audio_file_outlined;
      case 'document':
        return Icons.description_outlined;
      default:
        return Icons.attach_file_outlined;
    }
  }
}
