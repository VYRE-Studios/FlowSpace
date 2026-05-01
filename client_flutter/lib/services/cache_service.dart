/// Simple in-memory cache service for legacy code compatibility
class CacheService {
  static final Map<String, dynamic> _cache = {};

  /// Get a value from cache with type safety
  static T? get<T>(String key) {
    final value = _cache[key];
    if (value is T) return value;
    return null;
  }

  /// Set a value in cache
  static void set(String key, dynamic value) {
    _cache[key] = value;
  }

  /// Remove a specific key from cache
  static void remove(String key) {
    _cache.remove(key);
  }

  /// Clear all cached data
  static void clear() {
    _cache.clear();
  }

  /// Check if a key exists in cache
  static bool contains(String key) {
    return _cache.containsKey(key);
  }

  /// Get all keys in cache
  static Iterable<String> get keys => _cache.keys;

  /// Get number of items in cache
  static int get length => _cache.length;

  /// Legacy read method - returns a wrapper with payload
  static CacheEntry? read(String key) {
    final value = _cache[key];
    if (value != null) {
      return CacheEntry(payload: value);
    }
    return null;
  }

  /// Legacy write method - stores the value directly
  static Future<void> write(String key, dynamic value) async {
    _cache[key] = value;
  }
}

/// Wrapper class for cache entries (legacy compatibility)
class CacheEntry {
  final dynamic payload;

  CacheEntry({required this.payload});
}
