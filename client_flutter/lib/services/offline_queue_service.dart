import 'dart:async';
import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'chat_service.dart';

enum MessageStatus { pending, sending, sent, failed }

class PendingMessage {
  final String id;
  final String workspaceId;
  final String channelId;
  final String content;
  final DateTime createdAt;
  final int retryCount;
  final MessageStatus status;

  const PendingMessage({
    required this.id,
    required this.workspaceId,
    required this.channelId,
    required this.content,
    required this.createdAt,
    this.retryCount = 0,
    this.status = MessageStatus.pending,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'workspace_id': workspaceId,
        'channel_id': channelId,
        'content': content,
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
        'status': status.name,
      };

  factory PendingMessage.fromMap(Map<String, dynamic> map) => PendingMessage(
        id: map['id'] as String,
        workspaceId: map['workspace_id'] as String,
        channelId: map['channel_id'] as String,
        content: map['content'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        retryCount: map['retry_count'] as int? ?? 0,
        status: MessageStatus.values.firstWhere(
          (e) => e.name == (map['status'] as String),
          orElse: () => MessageStatus.pending,
        ),
      );
}

class OfflineQueueService {
  static final OfflineQueueService instance = OfflineQueueService._();
  OfflineQueueService._();

  final ValueNotifier<List<PendingMessage>> pendingMessages = ValueNotifier([]);
  Timer? _flushTimer;
  bool _isFlushing = false;

  Future<void> init() async {
    await _createPendingMessagesTable();
    await _loadPendingMessages();
    
    // Start periodic flush attempts
    _flushTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      flushQueue();
    });
  }

  Future<void> _createPendingMessagesTable() async {
    final db = await DatabaseService.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_messages (
        id TEXT PRIMARY KEY,
        workspace_id TEXT NOT NULL,
        channel_id TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pending'
      )
    ''');
  }

  Future<void> _loadPendingMessages() async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'pending_messages',
      where: 'status != ?',
      whereArgs: ['sent'],
      orderBy: 'created_at ASC',
    );
    
    pendingMessages.value = maps.map((m) => PendingMessage.fromMap(m)).toList();
  }

  Future<String> queueMessage({
    required String workspaceId,
    required String channelId,
    required String content,
  }) async {
    final message = PendingMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workspaceId: workspaceId,
      channelId: channelId,
      content: content,
      createdAt: DateTime.now(),
    );

    final db = await DatabaseService.database;
    await db.insert('pending_messages', message.toMap());
    
    await _loadPendingMessages();
    
    // Immediate flush attempt
    flushQueue();
    
    return message.id;
  }

  Future<void> flushQueue() async {
    if (_isFlushing || pendingMessages.value.isEmpty) return;
    
    _isFlushing = true;
    
    try {
      final pending = pendingMessages.value
          .where((m) => m.status == MessageStatus.pending || m.status == MessageStatus.failed)
          .toList();

      for (final message in pending) {
        await _sendPendingMessage(message);
      }
    } finally {
      _isFlushing = false;
    }
  }

  Future<void> _sendPendingMessage(PendingMessage message) async {
    if (message.retryCount >= 5) {
      // Max retries reached, mark as failed permanently
      await _updateMessageStatus(message.id, MessageStatus.failed);
      return;
    }

    await _updateMessageStatus(message.id, MessageStatus.sending);

    try {
      await ChatService.sendMessageStatic(
        workspaceId: message.workspaceId,
        channelId: message.channelId,
        content: message.content,
      );

      // Success - remove from queue
      await _removePendingMessage(message.id);
    } catch (e) {
      print('Failed to send pending message: $e');
      
      // Increment retry count
      final db = await DatabaseService.database;
      await db.update(
        'pending_messages',
        {
          'retry_count': message.retryCount + 1,
          'status': MessageStatus.failed.name,
        },
        where: 'id = ?',
        whereArgs: [message.id],
      );
      
      await _loadPendingMessages();
    }
  }

  Future<void> _updateMessageStatus(String id, MessageStatus status) async {
    final db = await DatabaseService.database;
    await db.update(
      'pending_messages',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _loadPendingMessages();
  }

  Future<void> _removePendingMessage(String id) async {
    final db = await DatabaseService.database;
    await db.delete(
      'pending_messages',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _loadPendingMessages();
  }

  Future<void> retryMessage(String id) async {
    final db = await DatabaseService.database;
    await db.update(
      'pending_messages',
      {
        'status': MessageStatus.pending.name,
        'retry_count': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await _loadPendingMessages();
    await flushQueue();
  }

  Future<void> clearQueue() async {
    final db = await DatabaseService.database;
    await db.delete('pending_messages');
    await _loadPendingMessages();
  }

  void dispose() {
    _flushTimer?.cancel();
    pendingMessages.dispose();
  }
}
