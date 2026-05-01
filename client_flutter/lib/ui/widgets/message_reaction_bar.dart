import 'package:flutter/material.dart';
import '../../services/chat_models.dart';

/// Displays reactions for a message with tap-to-add/remove functionality
class MessageReactionBar extends StatelessWidget {
  final List<MessageReaction> reactions;
  final String currentUserId;
  final Function(String emoji) onReactionTap;
  final Function(String emoji) onReactionRemove;

  const MessageReactionBar({
    Key? key,
    required this.reactions,
    required this.currentUserId,
    required this.onReactionTap,
    required this.onReactionRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    // Group reactions by emoji
    final Map<String, List<MessageReaction>> grouped = {};
    for (final reaction in reactions) {
      grouped.putIfAbsent(reaction.emoji, () => []).add(reaction);
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: grouped.entries.map((entry) {
        final emoji = entry.key;
        final reactionList = entry.value;
        final count = reactionList.length;
        final hasUserReacted = reactionList.any((r) => r.userId == currentUserId);

        return InkWell(
          onTap: () {
            if (hasUserReacted) {
              onReactionRemove(emoji);
            } else {
              onReactionTap(emoji);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasUserReacted 
                  ? Theme.of(context).primaryColor.withOpacity(0.2)
                  : Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: hasUserReacted
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).dividerColor,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: hasUserReacted ? FontWeight.bold : FontWeight.normal,
                    color: hasUserReacted
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
