import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_event.dart';

class QueuedMessage {
  final String tempId;
  final String channelId;
  final String content;
  final List<String>? attachments;
  final String? threadId;
  final DateTime queuedAt;
  final int retryCount;

  QueuedMessage({
    required this.tempId,
    required this.channelId,
    required this.content,
    this.attachments,
    this.threadId,
    required this.queuedAt,
    this.retryCount = 0,
  });

  factory QueuedMessage.fromJson(Map<String, dynamic> json) {
    return QueuedMessage(
      tempId: json['tempId'] as String,
      channelId: json['channelId'] as String,
      content: json['content'] as String,
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'] as List)
          : null,
      threadId: json['threadId'] as String?,
      queuedAt: DateTime.fromMillisecondsSinceEpoch(json['queuedAt'] as int),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tempId': tempId,
      'channelId': channelId,
      'content': content,
      if (attachments != null) 'attachments': attachments,
      if (threadId != null) 'threadId': threadId,
      'queuedAt': queuedAt.millisecondsSinceEpoch,
      'retryCount': retryCount,
    };
  }

  QueuedMessage copyWith({
    String? tempId,
    String? channelId,
    String? content,
    List<String>? attachments,
    String? threadId,
    DateTime? queuedAt,
    int? retryCount,
  }) {
    return QueuedMessage(
      tempId: tempId ?? this.tempId,
      channelId: channelId ?? this.channelId,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      threadId: threadId ?? this.threadId,
      queuedAt: queuedAt ?? this.queuedAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

class OfflineMessageQueue {
  static const String _queueKey = 'offline_message_queue';
  static const int _maxQueueSize = 100;
  static const int _maxRetries = 3;
  
  final List<QueuedMessage> _queue = [];
  final _queueController = StreamController<List<QueuedMessage>>.broadcast();
  
  bool _isProcessing = false;
  
  Stream<List<QueuedMessage>> get queueStream => _queueController.stream;
  List<QueuedMessage> get queue => List.unmodifiable(_queue);
  int get queueSize => _queue.length;
  bool get hasQueuedMessages => _queue.isNotEmpty;
  
  /// Initialize and load queue from persistent storage
  Future<void> initialize() async {
    await _loadQueue();
  }
  
  /// Add a message to the offline queue
  Future<void> enqueue(QueuedMessage message) async {
    // Prevent queue from growing too large
    if (_queue.length >= _maxQueueSize) {
      print('[OfflineMessageQueue] Queue full, removing oldest message');
      _queue.removeAt(0);
    }
    
    _queue.add(message);
    await _saveQueue();
    _queueController.add(_queue);
    
    print('[OfflineMessageQueue] Enqueued message: ${message.tempId} (queue size: ${_queue.length})');
  }
  
  /// Remove a message from the queue
  Future<void> dequeue(String tempId) async {
    _queue.removeWhere((msg) => msg.tempId == tempId);
    
    if (_queue.length >= 0) {
      await _saveQueue();
      _queueController.add(_queue);
      print('[OfflineMessageQueue] Dequeued message: $tempId (queue size: ${_queue.length})');
    }
  }
  
  /// Increment retry count for a message
  Future<void> incrementRetry(String tempId) async {
    final index = _queue.indexWhere((msg) => msg.tempId == tempId);
    
    if (index != -1) {
      final message = _queue[index];
      
      if (message.retryCount >= _maxRetries) {
        // Max retries reached, remove from queue
        print('[OfflineMessageQueue] Max retries reached for $tempId, removing');
        await dequeue(tempId);
      } else {
        _queue[index] = message.copyWith(retryCount: message.retryCount + 1);
        await _saveQueue();
        _queueController.add(_queue);
        print('[OfflineMessageQueue] Incremented retry for $tempId to ${_queue[index].retryCount}');
      }
    }
  }
  
  /// Process the queue (send all queued messages)
  Future<void> processQueue(
    Future<bool> Function(QueuedMessage) sendCallback,
  ) async {
    if (_isProcessing || _queue.isEmpty) {
      return;
    }
    
    _isProcessing = true;
    print('[OfflineMessageQueue] Processing queue (${_queue.length} messages)');
    
    // Process messages in order
    final messagesToProcess = List<QueuedMessage>.from(_queue);
    
    for (final message in messagesToProcess) {
      try {
        final success = await sendCallback(message);
        
        if (success) {
          await dequeue(message.tempId);
        } else {
          await incrementRetry(message.tempId);
        }
        
        // Small delay between sends to avoid flooding
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('[OfflineMessageQueue] Error processing message ${message.tempId}: $e');
        await incrementRetry(message.tempId);
      }
    }
    
    _isProcessing = false;
    print('[OfflineMessageQueue] Queue processing complete (remaining: ${_queue.length})');
  }
  
  /// Clear the entire queue
  Future<void> clearQueue() async {
    _queue.clear();
    await _saveQueue();
    _queueController.add(_queue);
    print('[OfflineMessageQueue] Queue cleared');
  }
  
  /// Get messages for a specific channel
  List<QueuedMessage> getChannelMessages(String channelId) {
    return _queue.where((msg) => msg.channelId == channelId).toList();
  }
  
  /// Check if a specific message is queued
  bool isMessageQueued(String tempId) {
    return _queue.any((msg) => msg.tempId == tempId);
  }
  
  // Private methods
  
  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonQueue = _queue.map((msg) => msg.toJson()).toList();
      final encoded = jsonEncode(jsonQueue);
      await prefs.setString(_queueKey, encoded);
    } catch (e) {
      print('[OfflineMessageQueue] Error saving queue: $e');
    }
  }
  
  Future<void> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_queueKey);
      
      if (encoded != null) {
        final jsonQueue = jsonDecode(encoded) as List;
        _queue.clear();
        _queue.addAll(
          jsonQueue.map((json) => QueuedMessage.fromJson(json as Map<String, dynamic>)),
        );
        _queueController.add(_queue);
        print('[OfflineMessageQueue] Loaded ${_queue.length} messages from storage');
      }
    } catch (e) {
      print('[OfflineMessageQueue] Error loading queue: $e');
      _queue.clear();
    }
  }
  
  void dispose() {
    _queueController.close();
  }
}
