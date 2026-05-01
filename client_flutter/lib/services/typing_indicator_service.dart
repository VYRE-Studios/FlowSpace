import 'dart:async';
import '../models/typing_event.dart';

/// Service to handle debounced typing indicator broadcasts
class TypingIndicatorService {
  final void Function(String channelId, bool isTyping) _emitTyping;
  
  // Debounce timers per channel
  final Map<String, Timer?> _debounceTimers = {};
  
  // Stop timers per channel (to auto-stop typing after idle)
  final Map<String, Timer?> _stopTimers = {};
  
  // Track current typing state per channel
  final Map<String, bool> _isTypingInChannel = {};
  
  // Debounce duration before sending typing indicator
  final Duration debounceDuration;
  
  // Duration after which typing indicator auto-stops if no new input
  final Duration stopDuration;
  
  TypingIndicatorService(
    this._emitTyping, {
    this.debounceDuration = const Duration(milliseconds: 300),
    this.stopDuration = const Duration(seconds: 3),
  });
  
  /// Called when user types in a channel
  /// 
  /// Debounces the typing indicator to avoid sending too many events.
  /// Automatically stops typing indicator after idle period.
  void onUserTyping(String channelId) {
    // Cancel existing debounce timer
    _debounceTimers[channelId]?.cancel();
    
    // Cancel existing stop timer
    _stopTimers[channelId]?.cancel();
    
    // Set debounce timer to start typing indicator
    _debounceTimers[channelId] = Timer(debounceDuration, () {
      _startTyping(channelId);
    });
    
    // Set stop timer to auto-stop after idle period
    _stopTimers[channelId] = Timer(stopDuration, () {
      _stopTyping(channelId);
    });
  }
  
  /// Manually stop typing indicator for a channel
  void stopTyping(String channelId) {
    _debounceTimers[channelId]?.cancel();
    _stopTimers[channelId]?.cancel();
    _stopTyping(channelId);
  }
  
  /// Called when user sends a message (stop typing immediately)
  void onMessageSent(String channelId) {
    _debounceTimers[channelId]?.cancel();
    _stopTimers[channelId]?.cancel();
    _stopTyping(channelId);
  }
  
  /// Check if user is currently typing in a channel
  bool isTypingInChannel(String channelId) {
    return _isTypingInChannel[channelId] ?? false;
  }
  
  /// Clear all typing indicators and timers
  void clearAll() {
    for (final timer in _debounceTimers.values) {
      timer?.cancel();
    }
    for (final timer in _stopTimers.values) {
      timer?.cancel();
    }
    
    // Stop all active typing indicators
    for (final channelId in _isTypingInChannel.keys.toList()) {
      if (_isTypingInChannel[channelId] == true) {
        _stopTyping(channelId);
      }
    }
    
    _debounceTimers.clear();
    _stopTimers.clear();
    _isTypingInChannel.clear();
  }
  
  /// Clear typing indicator for a specific channel
  void clearChannel(String channelId) {
    _debounceTimers[channelId]?.cancel();
    _stopTimers[channelId]?.cancel();
    _debounceTimers.remove(channelId);
    _stopTimers.remove(channelId);
    
    if (_isTypingInChannel[channelId] == true) {
      _stopTyping(channelId);
    }
    _isTypingInChannel.remove(channelId);
  }
  
  // Private methods
  
  void _startTyping(String channelId) {
    if (_isTypingInChannel[channelId] != true) {
      _isTypingInChannel[channelId] = true;
      _emitTyping(channelId, true);
    }
  }
  
  void _stopTyping(String channelId) {
    if (_isTypingInChannel[channelId] == true) {
      _isTypingInChannel[channelId] = false;
      _emitTyping(channelId, false);
    }
  }
  
  /// Dispose all resources
  void dispose() {
    clearAll();
  }
}
