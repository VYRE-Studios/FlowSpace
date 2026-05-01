// lib/modules/story/story_module.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../engine/canvas_events.dart';
import '../module_content_interface.dart';
import '../module_tool_interface.dart';
import '../module_asset_interface.dart';
import '../../assets/asset_model.dart';
import 'timeline_models.dart';
import 'timeline_engine.dart';
import 'timeline_state.dart';
import 'timeline_view.dart';

class StoryModule extends StatelessWidget
    implements ModuleToolInterface, ModuleContentInterface, TimelineStateModelConsumer, ModuleAssetConsumer {
  final TimelineState state;

  StoryModule({super.key})
      : state = TimelineState(
          engine: TimelineEngine(
            state: TimelineStateModel(
              zoom: 1.0,
              tracks: [
                TimelineTrack(id: 'main', name: 'Main', events: []),
              ],
              markers: [],
            ),
          ),
        );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: state,
      child: const TimelineView(),
    );
  }

  @override
  void handleCanvasEvent(CanvasEvent event) {
    // Timeline uses pointer events embedded in TimelineView
  }

  @override
  void setTool(String toolId) {
    // Tools may later route event creation
  }

  @override
  void loadTimelineModel(TimelineStateModel model) {
    state.engine.state.zoom = model.zoom;
    state.engine.state.tracks = model.tracks;
    state.engine.state.markers = model.markers;
    state.reload();
  }

  @override
  TimelineStateModel getTimelineModel() {
    return state.engine.state;
  }

  @override
  void onAssetImported(AssetModel asset) {
    // Add asset as timeline event
    if (asset.type == AssetType.audio || asset.type == AssetType.image) {
      state.addEvent(
        'main',
        TimelineEvent(
          id: asset.id,
          title: asset.fileName,
          start: 0,
          end: 1000,
          color: Colors.blueAccent,
        ),
      );
    }
  }
}
