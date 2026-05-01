// lib/presence/cursor_overlay.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'presence_store.dart';
import 'presence_model.dart';

class CursorOverlay extends StatelessWidget {
  final Widget child;

  const CursorOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Consumer<PresenceStore>(
            builder: (context, store, _) {
              return CustomPaint(
                painter: _CursorPainter(store.activeUsers.toList()),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CursorPainter extends CustomPainter {
  final List<PresenceModel> users;

  _CursorPainter(this.users);

  @override
  void paint(Canvas canvas, Size size) {
    for (final u in users) {
      final paint = Paint()
        ..color = u.color
        ..style = PaintingStyle.fill;

      final pos = u.cursor;

      canvas.drawCircle(pos, 6, paint);

      final tp = TextPainter(
        text: TextSpan(
          text: u.userId,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );

      tp.layout();
      tp.paint(canvas, pos + const Offset(10, -10));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
