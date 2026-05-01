// lib/engine/stroke_model.dart

import 'package:flutter/material.dart';

class StrokePoint {
  final Offset position;
  final double pressure;
  final double timestamp;

  StrokePoint({
    required this.position,
    required this.pressure,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': position.dx,
      'y': position.dy,
      'pressure': pressure,
      'timestamp': timestamp,
    };
  }

  static StrokePoint fromJson(Map<String, dynamic> json) {
    return StrokePoint(
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      pressure: (json['pressure'] as num).toDouble(),
      timestamp: (json['timestamp'] as num).toDouble(),
    );
  }
}

class Stroke {
  final String id;
  final Color color;
  final double width;
  final List<StrokePoint> points;

  Stroke({
    required this.id,
    required this.color,
    required this.width,
    required this.points,
  });

  Stroke addPoint(StrokePoint point) {
    return Stroke(
      id: id,
      color: color,
      width: width,
      points: [...points, point],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'color': color.toARGB32(),
      'width': width,
      'points': points.map((p) => p.toJson()).toList(),
    };
  }

  static Stroke fromJson(Map<String, dynamic> json) {
    return Stroke(
      id: json['id'],
      color: Color(json['color']),
      width: (json['width'] as num).toDouble(),
      points: (json['points'] as List<dynamic>)
          .map((p) => StrokePoint.fromJson(p))
          .toList(),
    );
  }
}
