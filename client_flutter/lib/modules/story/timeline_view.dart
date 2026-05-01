// lib/modules/story/timeline_view.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'timeline_state.dart';
import 'timeline_models.dart';
import 'timeline_painter.dart';
import 'timeline_interaction.dart';

class TimelineView extends StatefulWidget {
  const TimelineView({super.key});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  final ScrollController _horizontal = ScrollController();
  final ScrollController _vertical = ScrollController();

  static const double baseScale = 2.0; // 1 time unit = 2px at zoom 1.0

  bool _dragging = false;
  bool _resizingLeft = false;
  bool _resizingRight = false;
  String? _draggingEventId;
  String? _draggingMarker;
  Offset? _lastPos;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TimelineState>();

    return Scrollbar(
      controller: _horizontal,
      child: SingleChildScrollView(
        controller: _horizontal,
        scrollDirection: Axis.horizontal,
        child: Scrollbar(
          controller: _vertical,
          child: SingleChildScrollView(
            controller: _vertical,
            scrollDirection: Axis.vertical,
            child: Listener(
              onPointerDown: (event) {
                _onPointerDown(event.localPosition, state);
              },
              onPointerMove: (event) {
                _onPointerMove(event.localPosition, state);
              },
              onPointerUp: (event) {
                _dragging = false;
                _resizingLeft = false;
                _resizingRight = false;
                _draggingMarker = null;
              },
              onPointerSignal: (signal) {
                if (signal is PointerScrollEvent) {
                  if (signal.scrollDelta.dy < 0) {
                    state.zoom(1.05);
                  } else {
                    state.zoom(0.95);
                  }
                }
              },
              child: CustomPaint(
                painter: TimelinePainter(
                  model: state.model,
                  baseScale: baseScale,
                ),
                size: Size(
                  _computeWidth(state.model),
                  _computeHeight(state.model),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onPointerDown(Offset pos, TimelineState state) {
    final hit = TimelineInteraction.hitTest(
      pos: pos,
      model: state.model,
      baseScale: baseScale,
    );
    _lastPos = pos;

    switch (hit.type) {
      case HitType.eventBody:
        _dragging = true;
        _draggingEventId = hit.id;
        break;

      case HitType.eventLeftEdge:
        _resizingLeft = true;
        _draggingEventId = hit.id;
        break;

      case HitType.eventRightEdge:
        _resizingRight = true;
        _draggingEventId = hit.id;
        break;

      case HitType.marker:
        _draggingMarker = hit.id;
        break;

      default:
        break;
    }
  }

  void _onPointerMove(Offset pos, TimelineState state) {
    if (_lastPos == null) return;
    final dx = pos.dx - _lastPos!.dx;
    final deltaTime = state.engine.pxToTime(dx, baseScale);

    if (_dragging && _draggingEventId != null) {
      state.moveEvent(_draggingEventId!, deltaTime);
    }

    if (_resizingLeft && _draggingEventId != null) {
      state.resizeLeft(_draggingEventId!, deltaTime);
    }

    if (_resizingRight && _draggingEventId != null) {
      state.resizeRight(_draggingEventId!, deltaTime);
    }

    if (_draggingMarker != null) {
      state.moveMarker(_draggingMarker!, deltaTime);
    }

    _lastPos = pos;
  }

  double _computeWidth(TimelineStateModel model) {
    final maxEnd = model.tracks
        .expand((t) => t.events)
        .fold<int>(0, (max, e) => e.end > max ? e.end : max);

    return maxEnd * baseScale * model.zoom + 2000;
  }

  double _computeHeight(TimelineStateModel model) {
    const trackHeight = 80.0;
    return model.tracks.length * trackHeight + 80.0;
  }
}
