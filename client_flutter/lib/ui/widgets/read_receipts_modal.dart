import 'package:flutter/material.dart';
import '../../services/chat_service.dart';

class ReadReceiptsModal extends StatefulWidget {
  final String workspaceId;
  final String channelId;
  final String messageId;

  const ReadReceiptsModal({
    Key? key,
    required this.workspaceId,
    required this.channelId,
    required this.messageId,
  }) : super(key: key);

  @override
  State<ReadReceiptsModal> createState() => _ReadReceiptsModalState();
}

class _ReadReceiptsModalState extends State<ReadReceiptsModal> {
  List<Map<String, dynamic>> _reads = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReadReceipts();
  }

  Future<void> _loadReadReceipts() async {
    try {
      final reads = await ChatService.getReadReceipts(
        workspaceId: widget.workspaceId,
        channelId: widget.channelId,
        messageId: widget.messageId,
      );
      if (mounted) {
        setState(() {
          _reads = reads;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading read receipts: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Read By',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _reads.isEmpty
                      ? const Center(
                          child: Text(
                            'No one has read this message yet',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _reads.length,
                          itemBuilder: (context, index) {
                            final read = _reads[index];
                            final userId = read['userId'] as String;
                            final readAt = DateTime.parse(read['readAt'] as String);
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.primaries[
                                    userId.hashCode % Colors.primaries.length],
                                child: Text(
                                  userId.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                userId,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                _formatTimestamp(readAt),
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inDays > 0) {
      return 'Read ${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return 'Read ${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return 'Read ${diff.inMinutes}m ago';
    } else {
      return 'Just read';
    }
  }
}
