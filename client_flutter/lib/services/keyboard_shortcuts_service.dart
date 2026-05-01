import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class KeyboardShortcutsService {
  static final KeyboardShortcutsService instance = KeyboardShortcutsService._();
  KeyboardShortcutsService._();

  final Map<String, VoidCallback> _chatShortcuts = {};

  void init() {
    // Initialization placeholder
  }

  void registerChatShortcut(String key, VoidCallback callback) {
    _chatShortcuts[key] = callback;
  }

  void unregisterChatShortcut(String key) {
    _chatShortcuts.remove(key);
  }

  static Map<LogicalKeySet, VoidCallback> getGlobalShortcuts({
    VoidCallback? onSave,
    VoidCallback? onUndo,
    VoidCallback? onRedo,
    VoidCallback? onFind,
    VoidCallback? onNewChannel,
    VoidCallback? onSettings,
    VoidCallback? onToggleSidebar,
  }) {
    return {
      // Save
      if (onSave != null)
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): onSave,
      
      // Undo
      if (onUndo != null)
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ): onUndo,
      
      // Redo  
      if (onRedo != null)
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyZ): onRedo,
      
      // Find
      if (onFind != null)
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): onFind,
      
      // New Channel
      if (onNewChannel != null)
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): onNewChannel,
      
      // Settings
      if (onSettings != null)
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.comma): onSettings,
      
      // Toggle Sidebar
      if (onToggleSidebar != null)
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB): onToggleSidebar,
    };
  }

  static Map<LogicalKeySet, VoidCallback> getChatShortcuts({
    VoidCallback? onSendMessage,
    VoidCallback? onUploadFile,
    VoidCallback? onEmojiPicker,
    VoidCallback? onMention,
  }) {
    return {
      // Send message (Enter)
      if (onSendMessage != null)
        LogicalKeySet(LogicalKeyboardKey.enter): onSendMessage,
      
      // Upload file
      if (onUploadFile != null)
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyU): onUploadFile,
      
      // Emoji picker
      if (onEmojiPicker != null)
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyE): onEmojiPicker,
      
      // Mention (@)
      if (onMention != null)
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.digit2): onMention,
    };
  }
}
