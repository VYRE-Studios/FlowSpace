import 'dart:async';
import 'package:flutter/foundation.dart';

class ConnectionRetryService {
  static final ConnectionRetryService instance = ConnectionRetryService._();
  ConnectionRetryService._();

  Timer? _retryTimer;
  int _retryCount = 0;
  final int _maxRetries = 10;
  final List<int> _backoffSeconds = [1, 2, 5, 10, 30, 60];

  final ValueNotifier<bool> isRetrying = ValueNotifier<bool>(false);
  final ValueNotifier<String?> retryMessage = ValueNotifier<String?>(null);

  Future<T> withRetry<T>({
    required Future<T> Function() operation,
    String? operationName,
  }) async {
    _retryCount = 0;
    
    while (_retryCount < _maxRetries) {
      try {
        final result = await operation();
        _reset();
        return result;
      } catch (e) {
        _retryCount++;
        
        if (_retryCount >= _maxRetries) {
          _reset();
          rethrow;
        }

        final backoffIndex = _retryCount < _backoffSeconds.length 
            ? _retryCount 
            : _backoffSeconds.length - 1;
        final waitSeconds = _backoffSeconds[backoffIndex];

        isRetrying.value = true;
        retryMessage.value = operationName != null
            ? 'Retrying $operationName in $waitSeconds seconds...'
            : 'Retrying in $waitSeconds seconds...';

        await Future.delayed(Duration(seconds: waitSeconds));
      }
    }

    throw Exception('Max retries exceeded');
  }

  void _reset() {
    _retryCount = 0;
    isRetrying.value = false;
    retryMessage.value = null;
    _retryTimer?.cancel();
  }

  void cancel() {
    _reset();
  }
}
