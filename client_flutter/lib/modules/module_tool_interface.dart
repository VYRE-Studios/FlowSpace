// lib/modules/module_tool_interface.dart

import '../engine/canvas_events.dart';

abstract class ModuleToolInterface {
  void handleCanvasEvent(CanvasEvent event);
  void setTool(String toolId);
}
