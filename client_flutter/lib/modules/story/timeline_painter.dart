// lib/modules/story/timeline_painter.dart

import 'package:flutter/material.dart';

import 'timeline_models.dart';

class TimelinePainter extends CustomPainter {
  final TimelineStateModel model;
  final double baseScale;

  TimelinePainter({
    required this.model,
    required this.baseScale,
  });

  static const double trackHeight = 80.0;
  static const double eventHeight = 48.0;
  static const double rulerHeight = 50.0;

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawRuler(canvas, size);
    _drawTracks(canvas, size);
    _drawEvents(canvas, size);
    _drawMarkers(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawRuler(Canvas canvas, Size size) {
    final rulerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    for (int t = 0; t < 20000; t += 1000) {
      final x = t * baseScale * model.zoom;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, rulerHeight),
        rulerPaint,
      );

      textPainter.text = TextSpan(
        text: '$t',
        style: const TextStyle(color: Colors.white, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + 4, 4));
    }
  }

  void _drawTracks(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    double y = rulerHeight;

    for (final _ in model.tracks) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, trackHeight),
        trackPaint,
      );
      y += trackHeight;
    }
  }

  void _drawEvents(Canvas canvas, Size size) {
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < model.tracks.length; i++) {
      final track = model.tracks[i];
      final trackTop = rulerHeight + trackHeight * i;

      for (final event in track.events) {
        final x = event.start * baseScale * model.zoom;
        final width = (event.end - event.start) * baseScale * model.zoom;

        final rect = Rect.fromLTWH(
          x,
          trackTop + 16,
          width,
          eventHeight,
        );

        final fill = Paint()
          ..color = event.color
          ..style = PaintingStyle.fill;

        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, border);

        _drawEventTitle(canvas, rect, event.title);
      }
    }
  }

  void _drawEventTitle(Canvas canvas, Rect rect, String title) {
    final text = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );
    text.layout(maxWidth: rect.width - 8);
    text.paint(canvas, Offset(rect.left + 4, rect.top + 4));
  }

  void _drawMarkers(Canvas canvas, Size size) {
    for (final marker in model.markers) {
      final x = marker.position * baseScale * model.zoom;

      final paint = Paint()
        ..color = marker.color
        ..strokeWidth = 2;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(TimelinePainter oldDelegate) {
    return oldDelegate.model != model ||
        oldDelegate.baseScale != baseScale;
  }
}
