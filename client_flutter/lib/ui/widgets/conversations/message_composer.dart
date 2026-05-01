import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/channel_context.dart';
import '../../../services/chat_service.dart';

class MessageComposer extends StatefulWidget {
  final Function(String message)? onMessageSent;

  const MessageComposer({
    Key? key,
    this.onMessageSent,
  }) : super(key: key);

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ChatService _chatService = ChatService();
  bool _isSending = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      setState(() {
        _isTyping = hasText;
      });
      // TODO: Emit typing indicator via WebSocket
      // if (hasText) emit('typing.start') else emit('typing.stop')
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    final channelContext = context.read<ChannelContext>();
    final activeChannel = channelContext.activeChannel;

    if (activeChannel == null) {
      _showError('No channel selected');
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _chatService.sendMessage(
        channelId: activeChannel.id,
        content: text,
      );

      _controller.clear();
      widget.onMessageSent?.call(text);

      // TODO: Emit typing.stop via WebSocket
    } catch (e) {
      _showError('Failed to send message: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final channelContext = context.watch<ChannelContext>();
    final activeChannel = channelContext.activeChannel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: activeChannel != null ? _onAttachFile : null,
            tooltip: 'Attach file',
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),

          // Emoji picker button
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined),
            onPressed: activeChannel != null ? _onPickEmoji : null,
            tooltip: 'Add emoji',
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),

          const SizedBox(width: 8),

          // Text input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 40,
                maxHeight: 120,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: activeChannel != null && !_isSending,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: activeChannel != null
                      ? 'Message #${activeChannel.name}'
                      : 'Select a channel',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _controller.text.trim().isNotEmpty && !_isSending
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Icon(
                      Icons.send,
                      size: 20,
                      color: _controller.text.trim().isNotEmpty && !_isSending
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
              onPressed: _controller.text.trim().isNotEmpty && !_isSending
                  ? _sendMessage
                  : null,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  void _onAttachFile() {
    // TODO: Implement file picker
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attach File'),
        content: const Text('File attachment coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onPickEmoji() {
    // TODO: Implement emoji picker
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emoji Picker'),
        content: const Text('Emoji picker coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
