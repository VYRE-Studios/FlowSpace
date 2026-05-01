import 'package:flutter/foundation.dart';

/// Tool identifiers for canvas interactions
enum ToolId {
  pan,
  draw,
  text,
  select,
  erase,
}

/// Global tool state manager
/// Tracks which tool is active across all modules
class ToolState extends ChangeNotifier {
  ToolId _activeTool = ToolId.pan;

  ToolId get activeTool => _activeTool;

  void setActiveTool(ToolId tool) {
    if (_activeTool != tool) {
      _activeTool = tool;
      notifyListeners();
    }
  }
}
