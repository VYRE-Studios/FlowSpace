import 'dart:async';

enum NetworkQuality {
  excellent,  // < 50ms latency
  good,       // 50-150ms latency
  fair,       // 150-300ms latency
  poor,       // > 300ms latency
  offline,    // No connection
}

class NetworkQualityMetrics {
  final NetworkQuality quality;
  final int? latencyMs;
  final DateTime timestamp;
  final bool isConnected;

  NetworkQualityMetrics({
    required this.quality,
    this.latencyMs,
    required this.timestamp,
    required this.isConnected,
  });

  String get description {
    switch (quality) {
      case NetworkQuality.excellent:
        return 'Excellent connection';
      case NetworkQuality.good:
        return 'Good connection';
      case NetworkQuality.fair:
        return 'Fair connection';
      case NetworkQuality.poor:
        return 'Poor connection';
      case NetworkQuality.offline:
        return 'No connection';
    }
  }

  NetworkQualityMetrics copyWith({
    NetworkQuality? quality,
    int? latencyMs,
    DateTime? timestamp,
    bool? isConnected,
  }) {
    return NetworkQualityMetrics(
      quality: quality ?? this.quality,
      latencyMs: latencyMs ?? this.latencyMs,
      timestamp: timestamp ?? this.timestamp,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

class NetworkQualityService {
  final Duration pingInterval;
  final Duration timeout;
  
  Timer? _pingTimer;
  DateTime? _lastPingSent;
  final _metricsController = StreamController<NetworkQualityMetrics>.broadcast();
  
  NetworkQualityMetrics _currentMetrics = NetworkQualityMetrics(
    quality: NetworkQuality.offline,
    timestamp: DateTime.now(),
    isConnected: false,
  );
  
  // Latency history for smoothing
  final List<int> _latencyHistory = [];
  static const int _historySize = 5;
  
  NetworkQualityService({
    this.pingInterval = const Duration(seconds: 10),
    this.timeout = const Duration(seconds: 5),
  });
  
  Stream<NetworkQualityMetrics> get metricsStream => _metricsController.stream;
  NetworkQualityMetrics get currentMetrics => _currentMetrics;
  
  /// Start monitoring network quality
  void startMonitoring(Future<void> Function() pingCallback) {
    _pingTimer?.cancel();
    
    _pingTimer = Timer.periodic(pingInterval, (_) async {
      await _performPing(pingCallback);
    });
    
    // Perform initial ping
    _performPing(pingCallback);
  }
  
  /// Stop monitoring
  void stopMonitoring() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }
  
  /// Manually trigger a ping
  Future<void> ping(Future<void> Function() pingCallback) async {
    await _performPing(pingCallback);
  }
  
  /// Update metrics when connection state changes
  void updateConnectionState(bool isConnected) {
    if (!isConnected) {
      _updateMetrics(
        quality: NetworkQuality.offline,
        latencyMs: null,
        isConnected: false,
      );
    } else if (!_currentMetrics.isConnected) {
      // Just reconnected, perform immediate ping
      _updateMetrics(
        quality: NetworkQuality.good,
        latencyMs: null,
        isConnected: true,
      );
    }
  }
  
  /// Record successful message delivery time
  void recordMessageDelivery(Duration deliveryTime) {
    final latencyMs = deliveryTime.inMilliseconds;
    _addLatencyMeasurement(latencyMs);
    
    final quality = _calculateQuality(latencyMs);
    _updateMetrics(
      quality: quality,
      latencyMs: latencyMs,
      isConnected: true,
    );
  }
  
  Future<void> _performPing(Future<void> Function() pingCallback) async {
    _lastPingSent = DateTime.now();
    
    try {
      await pingCallback().timeout(timeout);
      
      final latency = DateTime.now().difference(_lastPingSent!);
      final latencyMs = latency.inMilliseconds;
      
      _addLatencyMeasurement(latencyMs);
      
      final quality = _calculateQuality(_getAverageLatency());
      _updateMetrics(
        quality: quality,
        latencyMs: latencyMs,
        isConnected: true,
      );
    } catch (e) {
      // Ping failed or timed out
      _updateMetrics(
        quality: NetworkQuality.offline,
        latencyMs: null,
        isConnected: false,
      );
    }
  }
  
  void _addLatencyMeasurement(int latencyMs) {
    _latencyHistory.add(latencyMs);
    
    if (_latencyHistory.length > _historySize) {
      _latencyHistory.removeAt(0);
    }
  }
  
  int _getAverageLatency() {
    if (_latencyHistory.isEmpty) return 0;
    
    final sum = _latencyHistory.reduce((a, b) => a + b);
    return sum ~/ _latencyHistory.length;
  }
  
  NetworkQuality _calculateQuality(int latencyMs) {
    if (latencyMs < 50) {
      return NetworkQuality.excellent;
    } else if (latencyMs < 150) {
      return NetworkQuality.good;
    } else if (latencyMs < 300) {
      return NetworkQuality.fair;
    } else {
      return NetworkQuality.poor;
    }
  }
  
  void _updateMetrics({
    required NetworkQuality quality,
    required int? latencyMs,
    required bool isConnected,
  }) {
    _currentMetrics = NetworkQualityMetrics(
      quality: quality,
      latencyMs: latencyMs,
      timestamp: DateTime.now(),
      isConnected: isConnected,
    );
    
    _metricsController.add(_currentMetrics);
  }
  
  void dispose() {
    _pingTimer?.cancel();
    _metricsController.close();
  }
}
