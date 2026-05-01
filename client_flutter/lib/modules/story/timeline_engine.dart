// lib/modules/story/timeline_engine.dart

import 'dart:math';
import 'timeline_models.dart';

class TimelineEngine {
  TimelineStateModel state;

  TimelineEngine({
    required this.state,
  });

  /// Move an event by delta time Units
  void moveEvent(String eventId, TimeUnit delta) {
    for (final track in state.tracks) {
      for (final event in track.events) {
        if (event.id == eventId) {
          event.start = max(0, event.start + delta);
          event.end = max(event.start + 1, event.end + delta);
          return;
        }
      }
    }
  }

  /// Resize an event from left edge
  void resizeEventLeft(String eventId, TimeUnit delta) {
    for (final track in state.tracks) {
      for (final event in track.events) {
        if (event.id == eventId) {
          final newStart = max(0, event.start + delta);
          if (newStart < event.end) {
            event.start = newStart;
          }
          return;
        }
      }
    }
  }

  /// Resize an event from right edge
  void resizeEventRight(String eventId, TimeUnit delta) {
    for (final track in state.tracks) {
      for (final event in track.events) {
        if (event.id == eventId) {
          event.end = max(event.start + 1, event.end + delta);
          return;
        }
      }
    }
  }

  /// Add new event to track
  void addEvent(String trackId, TimelineEvent event) {
    for (final track in state.tracks) {
      if (track.id == trackId) {
        track.events.add(event);
        return;
      }
    }
  }

  /// Add new marker
  void addMarker(TimelineMarker marker) {
    state.markers.add(marker);
  }

  /// Move marker
  void moveMarker(String markerId, TimeUnit delta) {
    for (final marker in state.markers) {
      if (marker.id == markerId) {
        marker.position = max(0, marker.position + delta);
        return;
      }
    }
  }

  /// Zoom is multiplicative, clamp it between sensible range
  void zoomBy(double factor) {
    state.zoom = state.zoom * factor;
    state.zoom = state.zoom.clamp(0.1, 20.0);
  }

  /// Convert timeline time Units to pixel position
  double timeToPx(TimeUnit t, double baseScale) {
    return t * baseScale * state.zoom;
  }

  /// Convert pixel to time Units
  TimeUnit pxToTime(double px, double baseScale) {
    return (px / (baseScale * state.zoom)).round();
  }
}
