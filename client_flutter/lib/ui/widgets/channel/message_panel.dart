import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../constants/spacing.dart';
import '../../../state/channel_context.dart';
import '../../../services/chat_service.dart';
import '../../../services/chat_models.dart';
import '../conversations/message_bubble.dart';
import '../conversations/message_composer.dart';

/// Functional message display panel connected to ChatService
class MessagePanel extends StatefulWidget {
  const MessagePanel({super.key});

  @override
  State<MessagePanel> createState() => _MessagePanelState();
}

class _MessagePanelState extends State<MessagePanel> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final channelContext = context.read<ChannelContext>();
    final channel = channelContext.activeChannel;
    final projectId = channelContext.activeProjectId;

    if (channel == null || projectId == null) return;

    setState(() => _loading = true);

    try {
      // Load messages from ChatService
      final result = await ChatService.getChannelDetail(
        projectId,
        channel.channelId,
        limit: 100,
      );

      if (mounted) {
        setState(() {
          _messages = result.detail.messages;
          _loading = false;
        });
      }
    } catch (e) {
      print('[MessagePanel] ERROR loading messages: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final channelContext = context.read<ChannelContext>();
    final channel = channelContext.activeChannel;
    final projectId = channelContext.activeProjectId;

    if (channel == null || projectId == null) return;

    _messageController.clear();

    try {
      final message = await ChatService.sendMessageStatic(
        workspaceId: projectId,
        channelId: channel.channelId,
        content: content,
      );

      setState(() {
        _messages.add(message);
      });

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('[MessagePanel] ERROR sending message: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChannelContext>(
      builder: (context, channelContext, _) {
        final channel = channelContext.activeChannel;

        if (channel == null) {
          return Center(
            child: Text(
              'No channel selected',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled),
            ),
          );
        }

        return Column(
          children: [
            // Channel header
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tag, size: 20, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(
                    channel.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Back to boards button (Teams-style)
                  IconButton(
                    icon: const Icon(Icons.dashboard_outlined, size: 20),
                    color: Colors.white70,
                    tooltip: 'Back to boards',
                    onPressed: () {
                      // Clear active channel to return to board view
                      channelContext.setActiveChannel('');
                    },
                  ),
                ],
              ),
            ),
            // Message list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: AppColors.textDisabled,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textDisabled,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
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
                              onEdit: () {
                                // TODO: Edit message
                              },
                              onDelete: () async {
                                // TODO: Delete message
                              },
                              onReact: (emoji) async {
                                // TODO: Add reaction
                              },
                            );
                          },
                        ),
            ),
            // Message composer with polished UI
            MessageComposer(
              onMessageSent: (message) {
                // Reload messages after send
                _loadMessages();
              },
            ),
          ],
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
