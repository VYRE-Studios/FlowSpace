import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/channel_context.dart';
import '../../../services/chat_service.dart';
import '../../../services/chat_models.dart';
import 'message_bubble.dart';

class MessageListView extends StatefulWidget {
  const MessageListView({Key? key}) : super(key: key);

  @override
  State<MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends State<MessageListView> {
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _error;
  Set<String> _typingUsers = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupWebSocketListeners();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final channelContext = context.read<ChannelContext>();
    final activeChannel = channelContext.activeChannel;

    if (activeChannel == null) {
      setState(() {
        _isLoading = false;
        _messages = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final messages = await _chatService.getChannelMessages(activeChannel.id);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      // Scroll to bottom after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _setupWebSocketListeners() {
    // TODO: Connect to WebSocket events
    // - message.new -> add to _messages and scroll down
    // - message.edited -> update message in _messages
    // - message.deleted -> remove from _messages
    // - typing.start -> add to _typingUsers
    // - typing.stop -> remove from _typingUsers
    // - reaction.added/removed -> update message reactions
  }

  void _onNewMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onEditMessage(String messageId) {
    // TODO: Show edit dialog
  }

  Future<void> _onDeleteMessage(String messageId) async {
    try {
      await _chatService.deleteMessage(messageId);
      setState(() {
        _messages.removeWhere((m) => m.id == messageId);
      });
    } catch (e) {
      _showError('Failed to delete message: $e');
    }
  }

  Future<void> _onReactToMessage(String messageId, String emoji) async {
    try {
      await _chatService.addReaction(messageId, emoji);
      // Update will come via WebSocket
    } catch (e) {
      _showError('Failed to add reaction: $e');
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

    if (activeChannel == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a channel to start messaging',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load messages',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Channel header
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Row(
            children: [
              Icon(
                activeChannel.isPrivate ? Icons.lock_outline : Icons.tag,
                size: 20,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                activeChannel.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (activeChannel.description != null) ...[
                const SizedBox(width: 8),
                Text(
                  '|',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activeChannel.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Messages list
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start the conversation!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: _messages.length + (_typingUsers.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Typing indicator at the end
                    if (index == _messages.length) {
                      return _buildTypingIndicator();
                    }

                    final message = _messages[index];
                    final currentUserId = 'current_user'; // TODO: Get from auth
                    final isOwnMessage = message.senderId == currentUserId;

                    return MessageBubble(
                      key: ValueKey(message.id),
                      message: message,
                      isOwnMessage: isOwnMessage,
                      onReply: () {
                        // TODO: Open thread view
                      },
                      onEdit: () => _onEditMessage(message.id),
                      onDelete: () => _onDeleteMessage(message.id),
                      onReact: (emoji) => _onReactToMessage(message.id, emoji),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    final theme = Theme.of(context);
    final typingText = _typingUsers.length == 1
        ? '${_typingUsers.first} is typing...'
        : '${_typingUsers.length} people are typing...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTypingDot(theme, 0),
                _buildTypingDot(theme, 1),
                _buildTypingDot(theme, 2),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            typingText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(ThemeData theme, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        final delay = index * 0.2;
        final adjustedValue = (value - delay).clamp(0.0, 1.0);
        return Opacity(
          opacity: 0.3 + (adjustedValue * 0.7),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
