import 'package:flutter/material.dart';
import '../../services/chat_models.dart';
import '../../services/chat_service.dart';
import '../../models/legacy/legacy_message.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';
import '../constants/text_styles.dart';

class PinnedMessagesPanel extends StatefulWidget {
  final String workspaceId;
  final String channelId;
  final VoidCallback onClose;

  const PinnedMessagesPanel({
    Key? key,
    required this.workspaceId,
    required this.channelId,
    required this.onClose,
  }) : super(key: key);

  @override
  State<PinnedMessagesPanel> createState() => _PinnedMessagesPanelState();
}

class _PinnedMessagesPanelState extends State<PinnedMessagesPanel> {
  List<LegacyMessage> _pinnedMessages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPinnedMessages();
  }

  Future<void> _loadPinnedMessages() async {
    try {
      final messages = await ChatService.getPinnedMessages(
        workspaceId: widget.workspaceId,
        channelId: widget.channelId,
      );
      if (mounted) {
        setState(() {
          _pinnedMessages = messages.map((m) => LegacyMessage(m)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading pinned messages: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          left: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: AppSpacing.paddingLG,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.push_pin, color: Colors.white70, size: 20),
                AppSpacing.spaceHorizontalSM,
                Text(
                  'Pinned Messages',
                  style: AppTextStyles.headingMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: widget.onClose,
                  iconSize: 20,
                ),
              ],
            ),
          ),

          // Pinned messages list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _pinnedMessages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.push_pin_outlined,
                                size: 48, color: Colors.white24),
                            SizedBox(height: 16),
                            Text(
                              'No pinned messages',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: AppSpacing.paddingMD,
                        itemCount: _pinnedMessages.length,
                        itemBuilder: (context, index) {
                          final message = _pinnedMessages[index];
                          return _PinnedMessageCard(
                            message: message,
                            onUnpin: () async {
                              await ChatService.unpinMessage(
                                workspaceId: widget.workspaceId,
                                channelId: widget.channelId,
                                messageId: message.id,
                              );
                              _loadPinnedMessages();
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _PinnedMessageCard extends StatelessWidget {
  final LegacyMessage message;
  final VoidCallback onUnpin;

  const _PinnedMessageCard({
    required this.message,
    required this.onUnpin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  message.authorName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.push_pin, size: 16),
                color: Colors.white54,
                onPressed: onUnpin,
                tooltip: 'Unpin',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.text,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            _formatTimestamp(message.pinnedAt ?? message.createdAt),
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
