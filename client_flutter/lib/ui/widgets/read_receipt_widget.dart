import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/read_receipt_provider.dart';
import '../../models/read_receipt_event.dart';

/// Widget to display read receipts for a message
class ReadReceiptWidget extends StatelessWidget {
  final String channelId;
  final String messageId;
  final bool showText;
  final TextStyle? textStyle;
  final Color? iconColor;
  final double iconSize;

  const ReadReceiptWidget({
    Key? key,
    required this.channelId,
    required this.messageId,
    this.showText = true,
    this.textStyle,
    this.iconColor,
    this.iconSize = 14,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ReadReceiptProvider>(
      builder: (context, provider, _) {
        final readCount = provider.getReadCount(channelId, messageId);
        
        if (readCount == 0) {
          return const SizedBox.shrink();
        }

        if (showText) {
          final readText = provider.getReadReceiptText(channelId, messageId);
          
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.done_all,
                size: iconSize,
                color: iconColor ?? Colors.blue,
              ),
              const SizedBox(width: 4),
              Text(
                readText,
                style: textStyle ??
                    TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
              ),
            ],
          );
        } else {
          // Icon only with count badge
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.done_all,
                size: iconSize,
                color: iconColor ?? Colors.blue,
              ),
              if (readCount > 1)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      readCount > 9 ? '9+' : '$readCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        }
      },
    );
  }
}

/// Compact read receipt indicator (checkmarks only)
class CompactReadReceiptIndicator extends StatelessWidget {
  final String channelId;
  final String messageId;
  final String? senderId;
  final Color? sentColor;
  final Color? readColor;
  final double size;

  const CompactReadReceiptIndicator({
    Key? key,
    required this.channelId,
    required this.messageId,
    this.senderId,
    this.sentColor,
    this.readColor,
    this.size = 14,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ReadReceiptProvider>(
      builder: (context, provider, _) {
        final hasBeenRead = provider.hasBeenRead(channelId, messageId, senderId: senderId);
        
        return Icon(
          hasBeenRead ? Icons.done_all : Icons.done,
          size: size,
          color: hasBeenRead 
              ? (readColor ?? Colors.blue) 
              : (sentColor ?? Colors.grey),
        );
      },
    );
  }
}

/// Avatar stack showing users who read the message
class ReadReceiptAvatarStack extends StatelessWidget {
  final String channelId;
  final String messageId;
  final int maxAvatars;
  final double avatarSize;

  const ReadReceiptAvatarStack({
    Key? key,
    required this.channelId,
    required this.messageId,
    this.maxAvatars = 3,
    this.avatarSize = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ReadReceiptProvider>(
      builder: (context, provider, _) {
        final receipts = provider.getReadReceipts(channelId, messageId);
        
        if (receipts.isEmpty) {
          return const SizedBox.shrink();
        }

        final displayReceipts = receipts.take(maxAvatars).toList();
        final remainingCount = receipts.length - displayReceipts.length;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar stack
            SizedBox(
              height: avatarSize,
              width: (avatarSize * 0.7 * displayReceipts.length) + (avatarSize * 0.3),
              child: Stack(
                children: [
                  for (int i = 0; i < displayReceipts.length; i++)
                    Positioned(
                      left: i * avatarSize * 0.7,
                      child: _buildAvatar(displayReceipts[i]),
                    ),
                ],
              ),
            ),
            // Remaining count badge
            if (remainingCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+$remainingCount',
                  style: TextStyle(
                    fontSize: avatarSize * 0.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAvatar(ReadReceiptEvent receipt) {
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue[100],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: receipt.avatarUrl != null
          ? ClipOval(
              child: Image.network(
                receipt.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildInitial(receipt),
              ),
            )
          : _buildInitial(receipt),
    );
  }

  Widget _buildInitial(ReadReceiptEvent receipt) {
    final initial = (receipt.displayName ?? 'U')[0].toUpperCase();
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: avatarSize * 0.5,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }
}

/// Detailed read receipt list (for bottom sheet/dialog)
class ReadReceiptList extends StatelessWidget {
  final String channelId;
  final String messageId;

  const ReadReceiptList({
    Key? key,
    required this.channelId,
    required this.messageId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ReadReceiptProvider>(
      builder: (context, provider, _) {
        final receipts = provider.getReadReceipts(channelId, messageId);
        
        if (receipts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No read receipts yet',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        // Sort by timestamp (most recent first)
        final sortedReceipts = List<ReadReceiptEvent>.from(receipts)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return ListView.builder(
          shrinkWrap: true,
          itemCount: sortedReceipts.length,
          itemBuilder: (context, index) {
            final receipt = sortedReceipts[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                backgroundImage: receipt.avatarUrl != null
                    ? NetworkImage(receipt.avatarUrl!)
                    : null,
                child: receipt.avatarUrl == null
                    ? Text(
                        (receipt.displayName ?? 'U')[0].toUpperCase(),
                        style: TextStyle(color: Colors.blue[700]),
                      )
                    : null,
              ),
              title: Text(receipt.displayName ?? 'Unknown User'),
              subtitle: Text(
                _formatTimestamp(receipt.timestamp),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              trailing: const Icon(Icons.done_all, color: Colors.blue, size: 16),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
}

/// Show read receipts in a bottom sheet
void showReadReceiptsBottomSheet(
  BuildContext context,
  String channelId,
  String messageId,
) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Read by',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Flexible(
            child: ReadReceiptList(
              channelId: channelId,
              messageId: messageId,
            ),
          ),
        ],
      ),
    ),
  );
}
