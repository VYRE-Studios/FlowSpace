// lib/modules/module_content_interface.dart

import 'story/timeline_models.dart';

abstract class ModuleContentInterface {
  // Base interface for module content operations
}

abstract class TimelineStateModelConsumer {
  void loadTimelineModel(TimelineStateModel model);
  TimelineStateModel getTimelineModel();
}
