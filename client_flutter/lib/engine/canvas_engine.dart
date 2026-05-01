// lib/engine/canvas_engine.dart

import 'package:flutter/material.dart';
import 'canvas_events.dart';
import 'stroke_engine.dart';

class CanvasEngine {
  final StrokeEngine strokeEngine;

  String activeTool = 'pen';
  Color penColor = Colors.white;
  double penWidth = 3.0;

  CanvasEngine({required this.strokeEngine});

  void handle(CanvasEvent event) {
    if (event is CanvasToolChange) {
      activeTool = event.toolId;
      return;
    }

    if (activeTool != 'pen') {
      return;
    }

    if (event is CanvasPointerDown) {
      strokeEngine.startStroke(
        penColor,
        penWidth,
        event.position,
        event.pressure,
      );
    }

    if (event is CanvasPointerMove) {
      strokeEngine.addPoint(event.position, event.pressure);
    }

    if (event is CanvasPointerUp) {
      strokeEngine.endStroke();
    }
  }
}
