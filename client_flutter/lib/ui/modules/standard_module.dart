import 'package:flutter/material.dart';

/// Standard background module - clean surface for project workspaces
/// No interactive background, just solid color
class StandardModule extends StatelessWidget {
  const StandardModule({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
    );
  }
}
