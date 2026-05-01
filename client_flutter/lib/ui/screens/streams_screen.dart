import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../../core/theme/flo_theme.dart';
import '../../services/chat_service.dart';
import '../../services/chat_integration_helper.dart';
import '../../services/chat_models.dart';
import '../../services/workspace_service.dart';
import '../../state/active_workspace_state.dart';

/// Streams - Team messaging interface (integrated with real backend)
class StreamsScreen extends StatefulWidget {
  const StreamsScreen({super.key});

  @override
  State<StreamsScreen> createState() => _StreamsScreenState();
}

class _StreamsScreenState extends State<StreamsScreen> {
  int _selectedChannelIndex = 0;
  final TextEditingController _messageController = TextEditingController();
  
  List<ChannelSummary> _channels = [];
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _loadError;
  String? _selectedChannelId;
  String? _workspaceId;
  String? _workspaceName;
  ChatMessage? _selectedThreadMessage; // Track active thread
  List<ChatMessage> _threadReplies = [];
  bool _threadLoading = false;
  bool _detailsLoading = false;
  int _memberCount = 0;
  int _pinnedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadChannels();
    ChatIntegrationHelper.addMessageUpdateListener(_onMessageUpdate);
    ChatIntegrationHelper.addTypingUpdateListener(_onTypingUpdate);
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    ChatIntegrationHelper.removeMessageUpdateListener(_onMessageUpdate);
    ChatIntegrationHelper.removeTypingUpdateListener(_onTypingUpdate);
    super.dispose();
  }
  
  void _onMessageUpdate() {
    if (_selectedChannelId != null) {
      _loadMessages(_selectedChannelId!);
    }
  }
  
  void _onTypingUpdate() {
    if (mounted) setState(() {});
  }
  
  Future<void> _loadChannels() async {
    try {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });

      final workspaceId = await _resolveWorkspaceId();
      if (workspaceId == null) {
        if (!mounted) return;
        setState(() {
          _channels = [];
          _messages = [];
          _selectedChannelId = null;
          _loadError = 'No workspace is available for this account yet.';
          _isLoading = false;
        });
        return;
      }

      final result = await ChatService.getChannels(workspaceId);
      if (!mounted) return;
      setState(() {
        _channels = result.channels;
        _isLoading = false;
        if (_channels.isNotEmpty) {
          _selectedChannelId = _channels[0].id;
          _loadMessages(_selectedChannelId!);
        } else {
          _selectedChannelId = null;
          _messages = [];
        }
      });
    } catch (e) {
      print('StreamsScreen: Error loading channels: $e');
      setState(() {
        _channels = [];
        _selectedChannelId = null;
        _messages = [];
        _loadError = 'Unable to load streams. Check your connection and try again.';
        _isLoading = false;
      });
    }
  }

  Future<String?> _resolveWorkspaceId() async {
    if (_workspaceId != null) return _workspaceId;

    final activeWorkspace = context.read<ActiveWorkspaceState>();
    if (activeWorkspace.activeWorkspaceId != null) {
      _workspaceId = activeWorkspace.activeWorkspaceId;
      _workspaceName = activeWorkspace.activeWorkspaceName;
      return _workspaceId;
    }

    final bootstrap = await WorkspaceService.getWorkspaceBootstrap();
    final workspaces = bootstrap['workspaces'] as List? ?? const [];
    if (workspaces.isEmpty) {
      return null;
    }

    final workspace = Map<String, dynamic>.from(workspaces.first as Map);
    _workspaceId = workspace['id'] as String?;
    _workspaceName = workspace['name'] as String?;
    activeWorkspace.setActiveWorkspace(workspace);
    return _workspaceId;
  }
  
  Future<void> _loadMessages(String channelId) async {
    try {
      final workspaceId = await _resolveWorkspaceId();
      if (workspaceId == null) return;

      _loadChannelDetails(channelId);
      final result = await ChatService.getChannelDetail(workspaceId, channelId);
      if (mounted) {
        setState(() {
          _messages = result.detail.messages;
        });
      }
    } catch (e) {
      print('StreamsScreen: Error loading messages: $e');
    }
  }

  Future<void> _loadChannelDetails(String channelId) async {
    final workspaceId = await _resolveWorkspaceId();
    if (workspaceId == null) return;

    setState(() => _detailsLoading = true);
    try {
      final members = await WorkspaceService.getMembers(workspaceId);
      final pinnedMessages = await ChatService.getPinnedMessages(
        workspaceId: workspaceId,
        channelId: channelId,
      );
      if (!mounted) return;
      setState(() {
        _memberCount = members.length;
        _pinnedCount = pinnedMessages.length;
        _detailsLoading = false;
      });
    } catch (e) {
      print('StreamsScreen: Error loading channel details: $e');
      if (!mounted) return;
      setState(() => _detailsLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedChannelId == null) return;

    final workspaceId = await _resolveWorkspaceId();
    if (workspaceId == null) return;

    final content = _messageController.text.trim();
    _messageController.clear();
    
    try {
      await ChatIntegrationHelper.sendMessageWithOfflineSupport(
        workspaceId: workspaceId,
        channelId: _selectedChannelId!,
        content: content,
        sendFunction: () => ChatService.sendMessageStatic(
          workspaceId: workspaceId,
          channelId: _selectedChannelId!,
          content: content,
        ),
      );
      
      // Reload messages after sending
      await _loadMessages(_selectedChannelId!);
    } catch (e) {
      print('StreamsScreen: Error sending message: $e');
    }
  }

  Future<void> _addReaction(ChatMessage message, String emoji) async {
    final workspaceId = await _resolveWorkspaceId();
    final channelId = _selectedChannelId;
    if (workspaceId == null || channelId == null) return;

    try {
      await ChatService.addReactionStatic(
        workspaceId: workspaceId,
        channelId: channelId,
        messageId: message.id,
        emoji: emoji,
      );
      await _loadMessages(channelId);
    } catch (e) {
      print('StreamsScreen: Error adding reaction: $e');
    }
  }

  Future<void> _openThread(ChatMessage message) async {
    setState(() {
      _selectedThreadMessage = message;
      _threadReplies = [];
      _threadLoading = true;
    });

    final workspaceId = await _resolveWorkspaceId();
    final channelId = _selectedChannelId;
    if (workspaceId == null || channelId == null) {
      if (!mounted) return;
      setState(() => _threadLoading = false);
      return;
    }

    try {
      final thread = await ChatService.getThread(
        workspaceId: workspaceId,
        channelId: channelId,
        messageId: message.id,
      );
      final replies = (thread['replies'] as List<dynamic>? ?? const [])
          .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      if (!mounted) return;
      setState(() {
        _threadReplies = replies;
        _threadLoading = false;
      });
    } catch (e) {
      print('StreamsScreen: Error loading thread: $e');
      if (!mounted) return;
      setState(() => _threadLoading = false);
    }
  }

  Future<void> _showCreateChannelDialog() async {
    final workspaceId = await _resolveWorkspaceId();
    if (workspaceId == null) return;

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Create Stream', style: FloTheme.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: FloTheme.bodyPrimary,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'engineering',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              style: FloTheme.bodyPrimary,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What this stream is for',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final name = nameController.text.trim();
    if (name.isEmpty) return;

    try {
      await WorkspaceService.createChannel(
        workspaceId: workspaceId,
        name: name,
        description: descriptionController.text.trim(),
      );
      await _loadChannels();
    } catch (e) {
      print('StreamsScreen: Error creating stream: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to create stream: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // Left sidebar - Channels list
          _buildChannelsSidebar(),

          // Center - Message thread
          Expanded(
            child: _buildMessageThread(),
          ),

          // Right sidebar - Thread details or Channel info
          _selectedThreadMessage != null 
              ? _buildThreadSidebar()
              : _buildDetailsSidebar(),
        ],
      ),
    );
  }

  Widget _buildChannelsSidebar() {
    if (_isLoading) {
      return Container(
        width: 280,
        decoration: const BoxDecoration(
          color: AppColors.sidebar,
          border: Border(
            right: BorderSide(
              color: AppColors.borderSoft,
              width: 1,
            ),
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(
          right: BorderSide(
            color: AppColors.borderSoft,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.borderSofter,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  _workspaceName == null ? 'Streams' : '$_workspaceName Streams',
                  style: FloTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Create Stream',
                  icon: const Icon(Icons.add, color: AppColors.textSecondary),
                  onPressed: _showCreateChannelDialog,
                ),
              ],
            ),
          ),

          // Channels list
          Expanded(
            child: _channels.isEmpty
                ? Center(
                    child: Text(
                      'No streams yet',
                      style: FloTheme.bodySecondary,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _channels.length,
                    itemBuilder: (context, index) {
                      final channel = _channels[index];
                      return _ChannelItem(
                        channel: channel,
                        isSelected: _selectedChannelIndex == index,
                        onTap: () {
                          setState(() {
                            _selectedChannelIndex = index;
                            _selectedChannelId = channel.id;
                          });
                          _loadMessages(channel.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageThread() {
    return Container(
      color: AppColors.bgBottom,
      child: Column(
        children: [
          // Thread header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.borderSofter,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.tag,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedChannelId != null
                      ? _channels.firstWhere(
                          (c) => c.id == _selectedChannelId!,
                          orElse: () => _channels.first,
                        ).name
                      : 'Select a channel',
                  style: FloTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.more_horiz,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: _buildMessageBody(),
          ),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return _StreamsEmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Streams unavailable',
        message: _loadError!,
        actionLabel: 'Retry',
        onAction: _loadChannels,
      );
    }

    if (_channels.isEmpty) {
      return _StreamsEmptyState(
        icon: Icons.tag_outlined,
        title: 'No streams yet',
        message: 'Create a channel to start team conversation in this workspace.',
        actionLabel: 'Refresh',
        onAction: _loadChannels,
      );
    }

    if (_messages.isEmpty) {
      return const _StreamsEmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No messages yet',
        message: 'Send the first message to get this stream moving.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _MessageBubble(
          message: message,
          onAddReaction: () => _addReaction(message, '\u{1F44D}'),
          onReply: () => _openThread(message),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(
            color: AppColors.borderSofter,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgBottom,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.borderSoft,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: FloTheme.bodyPrimary,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: FloTheme.bodySecondary.copyWith(
                    color: AppColors.textMeta,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: _sendMessage,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.send,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreadSidebar() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(
          left: BorderSide(
            color: AppColors.borderSoft,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Thread Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.borderSofter,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text('Thread', style: FloTheme.titleMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => setState(() {
                    _selectedThreadMessage = null;
                    _threadReplies = [];
                    _threadLoading = false;
                  }),
                ),
              ],
            ),
          ),
          
          // Parent Message
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.bgBottom,
            child: _MessageBubble(
              message: _selectedThreadMessage!,
              isThreadParent: true,
            ),
          ),
          
          const Divider(height: 1, color: AppColors.borderSofter),
          
          Expanded(
            child: _buildThreadReplies(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSidebar() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(
          left: BorderSide(
            color: AppColors.borderSoft,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Channel Details',
              style: FloTheme.titleSmall,
            ),
            const SizedBox(height: 20),
            _DetailSection(
              icon: Icons.people_outline,
              title: 'Members',
              subtitle: _detailsLoading ? 'Loading...' : '$_memberCount members',
            ),
            const SizedBox(height: 12),
            _DetailSection(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'All messages',
            ),
            const SizedBox(height: 12),
            _DetailSection(
              icon: Icons.push_pin_outlined,
              title: 'Pinned Messages',
              subtitle: _detailsLoading ? 'Loading...' : '$_pinnedCount pinned',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadReplies() {
    if (_threadLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_threadReplies.isEmpty) {
      return const _StreamsEmptyState(
        icon: Icons.forum_outlined,
        title: 'No replies yet',
        message: 'Reply in this thread to keep the main stream focused.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _threadReplies.length,
      itemBuilder: (context, index) {
        return _MessageBubble(
          message: _threadReplies[index],
          isThreadParent: true,
        );
      },
    );
  }

}

class _ChannelItem extends StatefulWidget {
  final ChannelSummary channel;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChannelItem({
    required this.channel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ChannelItem> createState() => _ChannelItemState();
}

class _ChannelItemState extends State<_ChannelItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.sidebarItemActive
                : _isHovered
                    ? AppColors.sidebarItemHover
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.tag,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.channel.name,
                      style: FloTheme.bodyPrimary.copyWith(
                        color: widget.isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.channel.lastMessage != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${widget.channel.lastMessage!.senderName ?? 'User'}: ${widget.channel.lastMessage!.content}',
                        style: FloTheme.caption.copyWith(
                          color: AppColors.textMeta,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isThreadParent;
  final VoidCallback? onReply;
  final VoidCallback? onAddReaction;

  const _MessageBubble({
    required this.message,
    this.isThreadParent = false,
    this.onReply,
    this.onAddReaction,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  bool _isHovered = false;

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      (widget.message.senderName ?? widget.message.senderId)[0].toUpperCase(),
                      style: FloTheme.bodyPrimary.copyWith(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Message content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.message.senderName ?? widget.message.senderId,
                            style: FloTheme.bodyPrimary.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(widget.message.createdAt),
                            style: FloTheme.caption.copyWith(
                              color: AppColors.textMeta,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.message.content,
                        style: FloTheme.bodySecondary,
                      ),
                      
                      // Reactions Display
                      if (widget.message.reactions != null && widget.message.reactions!.isNotEmpty)
                         Padding(
                           padding: const EdgeInsets.only(top: 8),
                           child: Wrap(
                             spacing: 4,
                             runSpacing: 4,
                             children: widget.message.reactions!.entries.map((entry) {
                               return Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                 decoration: BoxDecoration(
                                   color: AppColors.card,
                                   borderRadius: BorderRadius.circular(12),
                                   border: Border.all(color: AppColors.borderSoft),
                                 ),
                                 child: Text('${entry.key} ${entry.value.length}', style: const TextStyle(fontSize: 12)),
                               );
                             }).toList(),
                           ),
                         ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Hover Actions overlay
            if (_isHovered && !widget.isThreadParent)
              Positioned(
                top: -10,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderSoft),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HoverActionButton(
                        icon: Icons.add_reaction_outlined,
                        tooltip: 'Add Reaction',
                        onTap: widget.onAddReaction ?? () {},
                      ),
                      const SizedBox(width: 4),
                      _HoverActionButton(
                        icon: Icons.reply, 
                        tooltip: 'Reply in Thread',
                        onTap: widget.onReply ?? () {},
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

}

class _StreamsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StreamsEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textMeta),
            const SizedBox(height: 16),
            Text(title, style: FloTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              message,
              style: FloTheme.bodySecondary,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }

}

class _HoverActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HoverActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
             padding: const EdgeInsets.all(6),
             child: Icon(icon, size: 16, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DetailSection({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderSofter,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: FloTheme.bodyPrimary,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: FloTheme.caption.copyWith(
                    color: AppColors.textMeta,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: AppColors.textMeta,
          ),
        ],
      ),
    );
  }
}
