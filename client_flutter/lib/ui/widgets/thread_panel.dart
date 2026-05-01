import 'package:flutter/material.dart';
import '../../services/chat_models.dart';
import '../../services/chat_service.dart';
import '../../models/legacy/legacy_message.dart';

class ThreadPanel extends StatefulWidget {
  final String workspaceId;
  final String channelId;
  final String parentMessageId;
  final VoidCallback onClose;

  const ThreadPanel({
    Key? key,
    required this.workspaceId,
    required this.channelId,
    required this.parentMessageId,
    required this.onClose,
  }) : super(key: key);

  @override
  State<ThreadPanel> createState() => _ThreadPanelState();
}

class _ThreadPanelState extends State<ThreadPanel> {
  final TextEditingController _replyController = TextEditingController();
  LegacyMessage? _parentMessage;
  List<LegacyMessage> _replies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadThread();
  }

  Future<void> _loadThread() async {
    try {
      final response = await ChatService.getThread(
        workspaceId: widget.workspaceId,
        channelId: widget.channelId,
        messageId: widget.parentMessageId,
      );
      
      setState(() {
        _parentMessage = LegacyMessage(ChatMessage.fromJson(response['parent']));
        _replies = (response['replies'] as List)
            .map((r) => LegacyMessage(ChatMessage.fromJson(r)))
            .toList();
        _loading = false;
      });
    } catch (e) {
      print('Error loading thread: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;
    
    final content = _replyController.text.trim();
    _replyController.clear();

    try {
      await ChatService.sendMessageStatic(
        workspaceId: widget.workspaceId,
        channelId: _parentMessage!.channelId,
        content: content,
        parentId: widget.parentMessageId,
      );
      
      // Reload thread to show new reply
      await _loadThread();
    } catch (e) {
      print('Error sending reply: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          left: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Thread',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Thread content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_parentMessage != null)
                        _MessageBubble(message: _parentMessage!, isParent: true),
                      
                      if (_replies.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Replies',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ..._replies.map((reply) => _MessageBubble(message: reply)),
                      ],
                    ],
                  ),
          ),

          // Reply input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: const InputDecoration(
                      hintText: 'Reply to thread...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendReply(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendReply,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }
}

class _MessageBubble extends StatelessWidget {
  final LegacyMessage message;
  final bool isParent;

  const _MessageBubble({
    required this.message,
    this.isParent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isParent
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isParent
              ? Theme.of(context).primaryColor.withOpacity(0.3)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                message.authorName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(message.text),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
