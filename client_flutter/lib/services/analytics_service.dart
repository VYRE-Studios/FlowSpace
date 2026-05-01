import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'error_logging_service.dart';

class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> properties;
  final DateTime timestamp;

  AnalyticsEvent(this.name, this.properties)
      : timestamp = DateTime.now();

  Map<String, dynamic> toJson() => {
        'event': name,
        'properties': properties,
        'timestamp': timestamp.toIso8601String(),
      };
}

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();
  AnalyticsService._();

  final List<AnalyticsEvent> _eventQueue = [];
  Timer? _flushTimer;
  String? _userId;
  final int _maxQueueSize = 50;

  void init({required String userId}) {
    _userId = userId;
    _flushTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _flush();
    });
  }

  void track(String eventName, {Map<String, dynamic>? properties}) {
    final event = AnalyticsEvent(
      eventName,
      {
        ...?properties,
        'userId': _userId,
        'platform': 'desktop',
      },
    );

    _eventQueue.add(event);

    if (_eventQueue.length >= _maxQueueSize) {
      _flush();
    }
  }

  void trackFeatureUsage(String featureName) {
    track('feature_used', properties: {'feature': featureName});
  }

  void trackError(String errorType, String message) {
    track('error_occurred', properties: {
      'errorType': errorType,
      'message': message,
    });
  }

  void trackPerformance(String action, int durationMs) {
    track('performance', properties: {
      'action': action,
      'duration_ms': durationMs,
    });
  }

  Future<void> _flush() async {
    if (_eventQueue.isEmpty) return;

    final batch = List<AnalyticsEvent>.from(_eventQueue);
    _eventQueue.clear();

    try {
      final response = await http.post(
        Uri.parse('https://flowspace-backend.onrender.com/api/analytics/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'events': batch.map((e) => e.toJson()).toList(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        ErrorLoggingService.instance.warning(
          'Analytics batch failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      ErrorLoggingService.instance.error(
        'Analytics flush failed',
        error: e,
      );
    }
  }

  void dispose() {
    _flush();
    _flushTimer?.cancel();
  }
}
