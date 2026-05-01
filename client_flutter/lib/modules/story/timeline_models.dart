// lib/modules/story/timeline_models.dart

import 'package:flutter/material.dart';

/// Unit = 1 millisecond, but timeline UI will use conversions.
typedef TimeUnit = int;

class TimelineEvent {
  final String id;
  final String title;
  TimeUnit start;
  TimeUnit end;
  Color color;

  TimelineEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.color,
  });

  TimelineEvent copy() {
    return TimelineEvent(
      id: id,
      title: title,
      start: start,
      end: end,
      color: color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start': start,
      'end': end,
      'color': color.toARGB32(),
    };
  }

  static TimelineEvent fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'],
      title: json['title'],
      start: json['start'],
      end: json['end'],
      color: Color(json['color']),
    );
  }
}

class TimelineMarker {
  final String id;
  TimeUnit position;
  final Color color;

  TimelineMarker({
    required this.id,
    required this.position,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': position,
      'color': color.toARGB32(),
    };
  }

  static TimelineMarker fromJson(Map<String, dynamic> json) {
    return TimelineMarker(
      id: json['id'],
      position: json['position'],
      color: Color(json['color']),
    );
  }
}

class TimelineTrack {
  final String id;
  final String name;
  List<TimelineEvent> events;

  TimelineTrack({
    required this.id,
    required this.name,
    required this.events,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'events': events.map((e) => e.toJson()).toList(),
    };
  }

  static TimelineTrack fromJson(Map<String, dynamic> json) {
    return TimelineTrack(
      id: json['id'],
      name: json['name'],
      events: (json['events'] as List)
          .map((item) => TimelineEvent.fromJson(item))
          .toList(),
    );
  }
}

class TimelineStateModel {
  double zoom;
  List<TimelineTrack> tracks;
  List<TimelineMarker> markers;

  TimelineStateModel({
    required this.zoom,
    required this.tracks,
    required this.markers,
  });

  Map<String, dynamic> toJson() {
    return {
      'zoom': zoom,
      'tracks': tracks.map((t) => t.toJson()).toList(),
      'markers': markers.map((m) => m.toJson()).toList(),
    };
  }

  static TimelineStateModel fromJson(Map<String, dynamic> json) {
    return TimelineStateModel(
      zoom: json['zoom'],
      tracks: (json['tracks'] as List)
          .map((item) => TimelineTrack.fromJson(item))
          .toList(),
      markers: (json['markers'] as List)
          .map((item) => TimelineMarker.fromJson(item))
          .toList(),
    );
  }
}
