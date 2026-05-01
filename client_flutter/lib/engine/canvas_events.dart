// lib/engine/canvas_events.dart

import 'package:flutter/material.dart';

abstract class CanvasEvent {}

class CanvasPointerDown extends CanvasEvent {
  final Offset position;
  final double pressure;

  CanvasPointerDown(this.position, this.pressure);
}

class CanvasPointerMove extends CanvasEvent {
  final Offset position;
  final double pressure;

  CanvasPointerMove(this.position, this.pressure);
}

class CanvasPointerUp extends CanvasEvent {
  final Offset position;

  CanvasPointerUp(this.position);
}

class CanvasToolChange extends CanvasEvent {
  final String toolId;

  CanvasToolChange(this.toolId);
}
