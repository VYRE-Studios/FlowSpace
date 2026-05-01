// lib/modules/story/timeline_state.dart

import 'package:flutter/material.dart';

import 'timeline_engine.dart';
import 'timeline_models.dart';

class TimelineState extends ChangeNotifier {
  final TimelineEngine engine;

  TimelineState({
    required this.engine,
  });

  TimelineStateModel get model => engine.state;

  void moveEvent(String id, int delta) {
    engine.moveEvent(id, delta);
    notifyListeners();
  }

  void resizeLeft(String id, int delta) {
    engine.resizeEventLeft(id, delta);
    notifyListeners();
  }

  void resizeRight(String id, int delta) {
    engine.resizeEventRight(id, delta);
    notifyListeners();
  }

  void addEvent(String trackId, TimelineEvent event) {
    engine.addEvent(trackId, event);
    notifyListeners();
  }

  void addMarker(TimelineMarker marker) {
    engine.addMarker(marker);
    notifyListeners();
  }

  void moveMarker(String id, int delta) {
    engine.moveMarker(id, delta);
    notifyListeners();
  }

  void zoom(double factor) {
    engine.zoomBy(factor);
    notifyListeners();
  }

  void reload() {
    notifyListeners();
  }
}
