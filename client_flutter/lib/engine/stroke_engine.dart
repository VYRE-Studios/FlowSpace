// lib/engine/stroke_engine.dart

import 'package:flutter/material.dart';
import 'stroke_model.dart';

class StrokeEngine {
  Stroke? _activeStroke;

  final List<Stroke> strokes = [];

  Stroke? get activeStroke => _activeStroke;

  void startStroke(Color color, double width, Offset position, double pressure) {
    final point = StrokePoint(
      position: position,
      pressure: pressure,
      timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
    );

    _activeStroke = Stroke(
      id: UniqueKey().toString(),
      color: color,
      width: width,
      points: [point],
    );
  }

  void addPoint(Offset position, double pressure) {
    if (_activeStroke == null) return;

    _activeStroke = _activeStroke!.addPoint(
      StrokePoint(
        position: position,
        pressure: pressure,
        timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
      ),
    );
  }

  Stroke? endStroke() {
    if (_activeStroke == null) return null;

    final finished = _activeStroke;
    strokes.add(finished!);
    _activeStroke = null;
    return finished;
  }
}
