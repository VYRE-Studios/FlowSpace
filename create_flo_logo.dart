import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';

// Run this to generate a temporary FLŌ logo
void main() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = 512.0;
  
  // Draw background circle
  final paint = Paint()
    ..shader = LinearGradient(
      colors: [Color(0xFF0B93FF), Color(0xFF0A7FDB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size, size));
  
  canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
  
  // Draw FLŌ text
  final textPainter = TextPainter(
    text: TextSpan(
      text: 'FLŌ',
      style: TextStyle(
        color: Colors.white,
        fontSize: 180,
        fontWeight: FontWeight.w700,
        fontFamily: 'Inter',
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2,
    ),
  );
  
  // Save as PNG
  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final buffer = byteData!.buffer.asUint8List();
  
  await File('assets/images/flo_logo.png').writeAsBytes(buffer);
  print('Logo created!');
}