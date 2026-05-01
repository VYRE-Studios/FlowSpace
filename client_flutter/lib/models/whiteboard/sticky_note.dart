import 'dart:ui';
import 'package:flutter/material.dart';

class StickyNote {
  Offset position;
  Size size;
  String text;
  Color color;

  StickyNote({
    required this.position,
    required this.size,
    required this.text,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'x': position.dx,
        'y': position.dy,
        'w': size.width,
        'h': size.height,
        't': text,
        'c': color.value,
      };

  factory StickyNote.fromJson(Map<String, dynamic> json) => StickyNote(
        position: Offset((json['x'] as num).toDouble(), (json['y'] as num).toDouble()),
        size: Size((json['w'] as num).toDouble(), (json['h'] as num).toDouble()),
        text: (json['t'] as String? ?? ''),
        color: Color(json['c'] as int),
      );
}
