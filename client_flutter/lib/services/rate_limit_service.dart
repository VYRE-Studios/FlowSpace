import 'dart:async';

class RateLimitEntry {
  final int maxRequests;
  final Duration window;
  final List<DateTime> timestamps = [];

  RateLimitEntry(this.maxRequests, this.window);

  bool canMakeRequest() {
    final now = DateTime.now();
    final cutoff = now.subtract(window);
    
    timestamps.removeWhere((t) => t.isBefore(cutoff));
    
    return timestamps.length < maxRequests;
  }

  void recordRequest() {
    timestamps.add(DateTime.now());
  }

  Duration? getRetryAfter() {
    if (timestamps.isEmpty) return null;
    
    final now = DateTime.now();
    final cutoff = now.subtract(window);
    timestamps.removeWhere((t) => t.isBefore(cutoff));
    
    if (timestamps.length < maxRequests) return null;
    
    final oldestRequest = timestamps.first;
    final resetTime = oldestRequest.add(window);
    return resetTime.difference(now);
  }
}

class RateLimitService {
  static final RateLimitService instance = RateLimitService._();
  RateLimitService._();

  final Map<String, RateLimitEntry> _limits = {
    'message_send': RateLimitEntry(30, const Duration(seconds: 60)),
    'reaction_add': RateLimitEntry(60, const Duration(seconds: 60)),
    'file_upload': RateLimitEntry(10, const Duration(minutes: 5)),
    'channel_create': RateLimitEntry(5, const Duration(minutes: 10)),
    'search': RateLimitEntry(20, const Duration(seconds: 60)),
  };

  bool canMakeRequest(String action) {
    final limit = _limits[action];
    if (limit == null) return true;
    
    return limit.canMakeRequest();
  }

  void recordRequest(String action) {
    final limit = _limits[action];
    if (limit == null) return;
    
    limit.recordRequest();
  }

  Duration? getRetryAfter(String action) {
    final limit = _limits[action];
    if (limit == null) return null;
    
    return limit.getRetryAfter();
  }

  Future<T> throttle<T>(
    String action,
    Future<T> Function() fn, {
    bool throwOnLimit = false,
  }) async {
    if (!canMakeRequest(action)) {
      final retryAfter = getRetryAfter(action);
      if (throwOnLimit) {
        throw Exception(
          'Rate limit exceeded for $action. Retry after ${retryAfter?.inSeconds ?? 0}s',
        );
      }
      
      if (retryAfter != null) {
        await Future.delayed(retryAfter);
      }
    }
    
    recordRequest(action);
    return await fn();
  }
}
