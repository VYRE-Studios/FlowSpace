import 'package:flutter/material.dart';
import '../../models/reaction.dart';

/// Displays reactions on a message with counts and user lists
class MessageReactionsWidget extends StatelessWidget {
  final MessageReactions reactions;
  final String currentUserId;
  final Function(String emoji) onReactionTap;
  final Function()? onAddReaction;

  const MessageReactionsWidget({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.onReactionTap,
    this.onAddReaction,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.totalCount == 0 && onAddReaction == null) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        // Existing reactions
        ...reactions.emojis.map((emoji) {
          final count = reactions.getEmojiCount(emoji);
          final hasReacted = reactions.hasUserReacted(currentUserId, emoji);
          return _ReactionChip(
            emoji: emoji,
            count: count,
            hasReacted: hasReacted,
            onTap: () => onReactionTap(emoji),
            onLongPress: () => _showReactionDetails(context, emoji),
          );
        }),
        // Add reaction button
        if (onAddReaction != null)
          _AddReactionButton(onTap: onAddReaction!),
      ],
    );
  }

  void _showReactionDetails(BuildContext context, String emoji) {
    final emojiReactions = reactions.getEmojiReactions(emoji);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$emoji ${emojiReactions.length}'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: emojiReactions.length,
            itemBuilder: (context, index) {
              final reaction = emojiReactions[index];
              return ListTile(
                leading: Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(reaction.displayName),
                subtitle: Text(
                  _formatTimestamp(reaction.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final int count;
  final bool hasReacted;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.hasReacted,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = hasReacted
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final borderColor = hasReacted
        ? theme.colorScheme.primary
        : Colors.transparent;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: hasReacted ? 1.5 : 0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: hasReacted ? FontWeight.bold : FontWeight.normal,
                color: hasReacted
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddReactionButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddReactionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: Icon(
          Icons.add_reaction_outlined,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Compact version for message lists
class CompactMessageReactions extends StatelessWidget {
  final MessageReactions reactions;
  final String currentUserId;
  final Function(String emoji) onReactionTap;

  const CompactMessageReactions({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.totalCount == 0) {
      return const SizedBox.shrink();
    }

    // Show only top 3 reactions in compact mode
    final topEmojis = reactions.emojis.take(3).toList();
    final hasMore = reactions.emojis.length > 3;

    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: [
        ...topEmojis.map((emoji) {
          final count = reactions.getEmojiCount(emoji);
          final hasReacted = reactions.hasUserReacted(currentUserId, emoji);
          return _CompactReactionChip(
            emoji: emoji,
            count: count,
            hasReacted: hasReacted,
            onTap: () => onReactionTap(emoji),
          );
        }),
        if (hasMore)
          _CompactReactionChip(
            emoji: '+${reactions.emojis.length - 3}',
            count: 0,
            hasReacted: false,
            onTap: () {},
            isMore: true,
          ),
      ],
    );
  }
}

class _CompactReactionChip extends StatelessWidget {
  final String emoji;
  final int count;
  final bool hasReacted;
  final VoidCallback onTap;
  final bool isMore;

  const _CompactReactionChip({
    required this.emoji,
    required this.count,
    required this.hasReacted,
    required this.onTap,
    this.isMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: hasReacted
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: isMore ? 10 : 12),
            ),
            if (!isMore) ...[
              const SizedBox(width: 2),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: hasReacted ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
