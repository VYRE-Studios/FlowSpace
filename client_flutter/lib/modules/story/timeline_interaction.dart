// lib/modules/story/timeline_interaction.dart

import 'dart:ui';
import 'timeline_models.dart';
import 'timeline_painter.dart';

enum HitType {
  none,
  eventBody,
  eventLeftEdge,
  eventRightEdge,
  marker,
}

class TimelineHit {
  final HitType type;
  final String? id;
  final int? trackIndex;

  TimelineHit({
    required this.type,
    this.id,
    this.trackIndex,
  });
}

class TimelineInteraction {
  static TimelineHit hitTest({
    required Offset pos,
    required TimelineStateModel model,
    required double baseScale,
  }) {
    // Ruler height offset
    if (pos.dy < TimelinePainter.rulerHeight) {
      return TimelineHit(type: HitType.none);
    }

    final trackIndex =
        ((pos.dy - TimelinePainter.rulerHeight) ~/ TimelinePainter.trackHeight)
            .toInt();

    if (trackIndex < 0 || trackIndex >= model.tracks.length) {
      return TimelineHit(type: HitType.none);
    }

    // Check markers first
    for (final marker in model.markers) {
      final markerX = marker.position * baseScale * model.zoom;
      if ((pos.dx - markerX).abs() < 5) {
        return TimelineHit(
          type: HitType.marker,
          id: marker.id,
        );
      }
    }

    // Check events
    final track = model.tracks[trackIndex];
    for (final event in track.events) {
      final x = event.start * baseScale * model.zoom;
      final width = (event.end - event.start) * baseScale * model.zoom;
      final rect = Rect.fromLTWH(
        x,
        TimelinePainter.rulerHeight + trackIndex * TimelinePainter.trackHeight + 16,
        width,
        TimelinePainter.eventHeight,
      );

      // Left resize region
      if (Rect.fromLTWH(rect.left - 4, rect.top, 8, rect.height)
          .contains(pos)) {
        return TimelineHit(
          type: HitType.eventLeftEdge,
          id: event.id,
          trackIndex: trackIndex,
        );
      }

      // Right resize region
      if (Rect.fromLTWH(rect.right - 4, rect.top, 8, rect.height)
          .contains(pos)) {
        return TimelineHit(
          type: HitType.eventRightEdge,
          id: event.id,
          trackIndex: trackIndex,
        );
      }

      // Body
      if (rect.contains(pos)) {
        return TimelineHit(
          type: HitType.eventBody,
          id: event.id,
          trackIndex: trackIndex,
        );
      }
    }

    return TimelineHit(type: HitType.none);
  }
}
