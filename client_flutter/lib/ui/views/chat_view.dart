import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/chat_core.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/chat_models.dart';
import '../../services/chat_service.dart';
import '../../services/workspace_service.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key, this.bootstrapEmail = 'ava@vyrevault.studio'});

  final String bootstrapEmail;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  static const _bootstrapPassword = 'flowspace123';

  final TextEditingController _composerController = TextEditingController();
  final ScrollController _messageScrollController = ScrollController();

  ChatCore? _chatCore;

  bool _bootstrapLoading = true;
  bool _channelsLoading = false;
  bool _messagesLoading = false;
  bool _sending = false;
  bool _isTyping = false;


  String? _sessionToken;
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _workspaces = const [];
  Map<String, dynamic>? _workspace;
  List<ChannelSummary> _channels = const [];
  ChannelSummary? _selectedChannel;
  List<ChatMessage> _messages = const [];
  Map<String, String> _presence = const {};
  String? _presenceSummary;
  String? _typingUser;
  String? _error;
  String? _replyingToMessageId;
  Set<String> _collapsedThreads = {};

  Timer? _typingResetTimer;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _composerController.addListener(_handleComposerChanged);
  }

  @override
  void dispose() {
    _typingResetTimer?.cancel();
    _composerController.removeListener(_handleComposerChanged);
    _composerController.dispose();
    _messageScrollController.dispose();
    _chatCore?.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _bootstrapLoading = true;
      _error = null;
    });

    try {
      // Load from local storage
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _error = 'No user found. Please register first.';
          _bootstrapLoading = false;
        });
        return;
      }

      final userId = user['id'] as String;
      final workspaces = await DatabaseService.getUserWorkspaces(userId);

      if (!mounted) return;

      setState(() {
        _sessionToken = null;
        _user = user;
        _workspaces = workspaces;
        _workspace = workspaces.isNotEmpty ? workspaces.first : null;
        _bootstrapLoading = false;
      });

      if (_workspace != null) {
        await _loadChannels(_workspace!['id'] as String);
        if (_channels.isNotEmpty) {
          await _selectChannel(_channels.first);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load: ${e.toString()}';
        _bootstrapLoading = false;
      });
    }
  }

  Future<void> _loadChannels(String workspaceId) async {
    setState(() {
      _channelsLoading = true;
      _channels = const [];
      _selectedChannel = null;
    });

    try {
      // Load channels from SQLite
      final channelsData = await DatabaseService.getWorkspaceChannels(workspaceId);
      final channelsList = channelsData.map((c) {
        return ChannelSummary(
          id: c['id'] as String,
          name: c['name'] as String,
          description: c['description'] as String?,
          lastMessage: null,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _channels = channelsList;
        _channelsLoading = false;
      });
    } catch (e) {
      print('Chat: Error loading channels: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load channels';
        _channelsLoading = false;
      });
    }
  }

  Future<void> _selectChannel(ChannelSummary channel) async {
    final workspaceId = _workspace?['id'] as String?;
    final userId = _user?['id'] as String?;
    if (workspaceId == null || userId == null) {
      return;
    }

    setState(() {
      _selectedChannel = channel;
      _messagesLoading = true;
      _messages = const [];
      _typingUser = null;
      _presenceSummary = null;
    });

    try {
      final result = await ChatService.getChannelDetail(workspaceId, channel.id);
      if (!mounted) return;
      setState(() {
        _messages = result.detail.messages;
        _messagesLoading = false;
      });

      if (_chatCore == null) {
        _chatCore = ChatCore(
          workspaceId: workspaceId,
          userId: userId,
          sessionToken: _sessionToken ?? '',
          onMessage: _handleIncomingMessage,
          onPresence: _handlePresence,
          onTyping: _handleTyping,
        );
        _chatCore!.connect(channel.id);
      } else {
        _chatCore!.switchChannel(channel.id);
      }

      unawaited(_scrollToBottom());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messagesLoading = false;
        _error = 'Unable to load messages';
      });
    }
  }

  Future<void> _sendMessage() async {
    final workspaceId = _workspace?['id'] as String?;
    final channel = _selectedChannel;
    final content = _composerController.text.trim();

    if (workspaceId == null || channel == null) {
      return;
    }

    if (content.isEmpty || _sending) {
      return;
    }

    setState(() => _sending = true);

    try {
      final created = await ChatService.sendMessage(
        workspaceId: workspaceId,
        channelId: channel.id,
        content: content,
        parentId: _replyingToMessageId,
      );
      if (!mounted) return;
      setState(() {
        _composerController.clear();
        _isTyping = false;
        _typingResetTimer?.cancel();
        _replyingToMessageId = null;
        _messages = [..._messages, created];
      });
      _chatCore?.emitTyping(false);
      unawaited(_scrollToBottom());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Failed to send message'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _handleComposerChanged() {
    final hasText = _composerController.text.isNotEmpty;
    if (hasText != _isTyping) {
      _isTyping = hasText;
      _chatCore?.emitTyping(_isTyping);
    }

    _typingResetTimer?.cancel();
    if (hasText) {
      _typingResetTimer = Timer(const Duration(seconds: 4), () {
        if (_isTyping) {
          _isTyping = false;
          _chatCore?.emitTyping(false);
        }
      });
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> payload) {
    final channelId = payload['channelId'] as String?;
    final selected = _selectedChannel;
    if (channelId == null || selected == null || channelId != selected.id) {
      return;
    }

    final message = ChatMessage.fromJson(
      Map<String, dynamic>.from(payload),
    );

    setState(() {
      _messages = [..._messages, message];
    });

    unawaited(_scrollToBottom());
  }

  void _handlePresence(Map<String, String> presence) {
    setState(() {
      _presence = presence;
      if (presence.isEmpty) {
        _presenceSummary = 'No other members online';
      } else {
        final active = presence.entries
            .where((entry) => entry.value == 'online')
            .map((entry) => entry.key)
            .toList();
        _presenceSummary =
            active.isEmpty ? 'Everyone is away' : 'Online: ${active.join(', ')}';
      }
    });
  }

  void _handleTyping(Map<String, dynamic> payload) {
    final channelId = payload['channelId'] as String?;
    final typing = payload['typing'] as bool? ?? false;
    final userId = payload['userId'] as String?;

    if (channelId == null ||
        _selectedChannel == null ||
        channelId != _selectedChannel!.id) {
      return;
    }

    if (userId == null || userId == _user?['id']) {
      return;
    }

    setState(() {
      _typingUser = typing ? userId : null;
    });
  }

  Future<void> _scrollToBottom() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!_messageScrollController.hasClients) return;
    _messageScrollController.animateTo(
      _messageScrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_bootstrapLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _bootstrap,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_workspace == null || _user == null) {
      return const Center(
        child: Text(
          'No workspace assigned to this user yet.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 280,
                child: _buildChannelSidebar(),
              ),
              const VerticalDivider(width: 1, color: Color(0x11FFFFFF)),
              Expanded(child: _buildConversationPane()),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildChannelSidebar() {
    final workspaceName = _workspace?['name'] as String? ?? 'Workspace';

    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            workspaceName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _presenceSummary ?? 'No presence data yet',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showCreateChannelDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Channel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _channelsLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _channels.length,
                    itemBuilder: (context, index) {
                      final channel = _channels[index];
                      final selected = _selectedChannel?.id == channel.id;
                      return ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: selected
                            ? const Color(0xFF1E1E1E)
                            : Colors.transparent,
                        title: Text(
                          '# ${channel.name}',
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.white70,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        subtitle: channel.lastMessage != null
                            ? Text(
                                channel.lastMessage!.content,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              )
                            : null,
                        onTap: () => _selectChannel(channel),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationPane() {
    final channel = _selectedChannel;
    if (channel == null) {
      return const Center(
        child: Text(
          'Select a channel to begin chatting.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          color: Colors.black.withOpacity(0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '# ${channel.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                channel.description ?? 'Stay in sync with your team',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: _messagesLoading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No messages yet — be the first to send one.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : _buildThreadedMessageList(),
        ),
        if (_typingUser != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Text(
              '$_typingUser is typing…',
              style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
            ),
          ),
        _buildComposer(),
      ],
    );
  }

  Widget _buildComposer() {
    final replyingTo = _replyingToMessageId != null
        ? _messages.firstWhere(
            (m) => m.id == _replyingToMessageId,
            orElse: () => _messages.first,
          )
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (replyingTo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            color: Colors.black.withOpacity(0.3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Replying to ${replyingTo.senderName ?? replyingTo.senderId}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.white70,
                  onPressed: () {
                    setState(() {
                      _replyingToMessageId = null;
                    });
                  },
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: Colors.black.withOpacity(0.25),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _composerController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: replyingTo != null
                        ? 'Reply to ${replyingTo.senderName ?? replyingTo.senderId}…'
                        : 'Message the channel…',
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _sending ? null : _sendMessage,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _sending
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_sending ? 'Sending…' : 'Send'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final now = DateTime.now();
    final sameDay =
        local.year == now.year && local.month == now.month && local.day == now.day;
    final time = TimeOfDay.fromDateTime(local).format(context);
    if (sameDay) {
      return time;
    }
    return '${local.month}/${local.day} $time';
  }

  String _formatCacheTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    return '${local.month}/${local.day}/${local.year} ${TimeOfDay.fromDateTime(local).format(context)}';
  }

  // Organize messages into threads
  Map<String, List<ChatMessage>> _organizeMessagesIntoThreads() {
    final threads = <String, List<ChatMessage>>{};
    final rootMessages = <ChatMessage>[];

    for (final message in _messages) {
      if (message.parentId == null) {
        rootMessages.add(message);
        threads[message.id] = [];
      } else {
        if (!threads.containsKey(message.parentId)) {
          threads[message.parentId!] = [];
        }
        threads[message.parentId!]!.add(message);
      }
    }

    // Sort root messages by creation time
    rootMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Sort replies within each thread
    for (final threadId in threads.keys) {
      threads[threadId]!.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return threads;
  }

  Widget _buildThreadedMessageList() {
    final threads = _organizeMessagesIntoThreads();
    final rootMessages = _messages.where((m) => m.parentId == null).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return ListView.builder(
      controller: _messageScrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24,
      ),
      itemCount: rootMessages.length,
      itemBuilder: (context, index) {
        final message = rootMessages[index];
        final replies = threads[message.id] ?? [];
        final isCollapsed = _collapsedThreads.contains(message.id);

        return _buildMessageWithThread(
          message: message,
          replies: replies,
          isCollapsed: isCollapsed,
        );
      },
    );
  }

  Widget _buildMessageWithThread({
    required ChatMessage message,
    required List<ChatMessage> replies,
    required bool isCollapsed,
  }) {
    final isSelf = message.senderId == _user?['id'];
    final alignment =
        isSelf ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isSelf
        ? const Color(0xFF0066FF)
        : const Color(0xFF1E1E1E);
    final textColor = Colors.white;
    final hasReplies = replies.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: alignment,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            constraints: const BoxConstraints(maxWidth: 520),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: isSelf
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  message.senderName ?? message.senderId,
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message.content,
                  style: TextStyle(
                    color: textColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTimestamp(message.createdAt),
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                    if (hasReplies) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isCollapsed) {
                              _collapsedThreads.remove(message.id);
                            } else {
                              _collapsedThreads.add(message.id);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: textColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCollapsed
                                    ? Icons.expand_more
                                    : Icons.expand_less,
                                size: 14,
                                color: textColor.withOpacity(0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.8),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _replyingToMessageId = message.id;
                        });
                      },
                      child: Icon(
                        Icons.reply,
                        size: 14,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (hasReplies && !isCollapsed)
          Padding(
            padding: EdgeInsets.only(
              left: isSelf ? 0 : 48,
              right: isSelf ? 48 : 0,
            ),
            child: Column(
              children: replies.map((reply) {
                return _buildReplyMessage(reply);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildReplyMessage(ChatMessage message) {
    final isSelf = message.senderId == _user?['id'];
    final alignment =
        isSelf ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isSelf
        ? const Color(0xFF0066FF).withOpacity(0.7)
        : const Color(0xFF1E1E1E).withOpacity(0.7);
    final textColor = Colors.white;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: isSelf
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.senderName ?? message.senderId,
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.content,
              style: TextStyle(
                color: textColor,
                height: 1.4,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTimestamp(message.createdAt),
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _replyingToMessageId = message.id;
                    });
                  },
                  child: Icon(
                    Icons.reply,
                    size: 12,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateChannelDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Create Channel',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Channel Name',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'e.g., design-team',
                hintStyle: TextStyle(color: Colors.white30),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name is required')),
                );
                return;
              }
              Navigator.pop(context);
              
              final workspaceId = _workspace?['id'] as String?;
              if (workspaceId == null) return;
              
              try {
                await WorkspaceService.createChannel(
                  workspaceId: workspaceId,
                  name: name,
                  description: descController.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Channel created!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  await _loadChannels(workspaceId);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
