import 'package:flutter/material.dart';

/// Bulletin panel screen - announcements and pinned messages
class BulletinPanelScreen extends StatelessWidget {
  const BulletinPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Bulletins'),
        backgroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          'Bulletin panel coming in Phase 6 Step 2',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
