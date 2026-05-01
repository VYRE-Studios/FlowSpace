import 'package:flutter/material.dart';

/// Emoji picker for selecting reactions
class ReactionPickerWidget extends StatelessWidget {
  final Function(String emoji) onEmojiSelected;
  final List<String>? popularEmojis;

  const ReactionPickerWidget({
    super.key,
    required this.onEmojiSelected,
    this.popularEmojis,
  });

  // Default quick reactions
  static const List<String> defaultQuickReactions = [
    '👍', '❤️', '😂', '🎉', '👀', '🔥', '✅', '👏'
  ];

  // Full emoji picker categories
  static const Map<String, List<String>> emojiCategories = {
    'Smileys': [
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
      '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩',
      '😘', '😗', '😚', '😙', '😋', '😛', '😜', '🤪',
      '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐', '🤨',
    ],
    'Gestures': [
      '👍', '👎', '👊', '✊', '🤛', '🤜', '🤞', '✌️',
      '🤟', '🤘', '👌', '🤌', '🤏', '👈', '👉', '👆',
      '👇', '☝️', '👋', '🤚', '🖐️', '✋', '🖖', '👏',
    ],
    'Hearts': [
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
      '🤎', '💔', '❣️', '💕', '💞', '💓', '💗', '💖',
      '💘', '💝', '💟', '❤️‍🔥', '❤️‍🩹', '💌', '💋', '💏',
    ],
    'Objects': [
      '🎉', '🎊', '🎈', '🎁', '🏆', '🥇', '🥈', '🥉',
      '⭐', '🌟', '✨', '💫', '⚡', '🔥', '💥', '💢',
      '✅', '✔️', '❌', '❎', '⭕', '💯', '🔴', '🟢',
    ],
    'Symbols': [
      '👀', '👁️', '🗨️', '💬', '💭', '🗯️', '💤', '💨',
      '🚀', '🎯', '💡', '⚠️', '🚨', '🔔', '🔕', '📢',
      '📣', '🎵', '🎶', '🎤', '🎧', '🎬', '🎨', '🎭',
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: Container(
        width: 320,
        height: 400,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick reactions (popular or default)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Quick Reactions',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: (popularEmojis ?? defaultQuickReactions)
                  .map((emoji) => _buildEmojiButton(emoji, isQuick: true))
                  .toList(),
            ),
            const Divider(height: 16),
            // Full emoji picker with categories
            Expanded(
              child: DefaultTabController(
                length: emojiCategories.length,
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      tabs: emojiCategories.keys
                          .map((cat) => Tab(text: cat))
                          .toList(),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: emojiCategories.values
                            .map((emojis) => _buildEmojiGrid(emojis))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiGrid(List<String> emojis) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        return _buildEmojiButton(emojis[index]);
      },
    );
  }

  Widget _buildEmojiButton(String emoji, {bool isQuick = false}) {
    return InkWell(
      onTap: () => onEmojiSelected(emoji),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(isQuick ? 8 : 4),
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(fontSize: isQuick ? 24 : 20),
          ),
        ),
      ),
    );
  }
}

/// Compact reaction picker button that shows picker on press
class ReactionPickerButton extends StatelessWidget {
  final Function(String emoji) onEmojiSelected;
  final List<String>? popularEmojis;

  const ReactionPickerButton({
    super.key,
    required this.onEmojiSelected,
    this.popularEmojis,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.add_reaction_outlined),
      tooltip: 'Add reaction',
      onPressed: () {
        _showReactionPicker(context);
      },
    );
  }

  void _showReactionPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ReactionPickerWidget(
          onEmojiSelected: (emoji) {
            Navigator.of(context).pop();
            onEmojiSelected(emoji);
          },
          popularEmojis: popularEmojis,
        ),
      ),
    );
  }
}
