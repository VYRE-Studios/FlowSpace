import 'dart:ui';
import 'package:flutter/material.dart';

class Stroke {
  final List<Offset> points;
  final double width;
  final Color color;

  Stroke({required this.points, this.width = 3.0, this.color = const Color(0xFFFFFFFF)});

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
        'width': width,
        'color': color.value,
      };

  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
        points: (json['points'] as List<dynamic>)
            .map((e) => Offset((e['x'] as num).toDouble(), (e['y'] as num).toDouble()))
            .toList(),
        width: (json['width'] as num?)?.toDouble() ?? 3.0,
        color: Color(json['color'] as int? ?? 0xFFFFFFFF),
      );
}
