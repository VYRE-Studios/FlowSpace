import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/chat_models.dart';
import '../../services/chat_service.dart';
import 'chat_view.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final String _username = 'User-${100 + Random().nextInt(900)}';

  bool _loading = true;
  bool _error = false;
  // List<ChatThread> _threads = const []; // Legacy ChatThread model disabled
  // ChatThread? _selectedThread; // Legacy ChatThread model disabled

  @override
  void initState() {
    super.initState();
    // _loadThreads(); // Legacy method disabled
    setState(() => _loading = false);
  }

  // Legacy ChatService methods not available - disabled
  // Future<void> _loadThreads() async { ... }

  // Legacy ChatService.createThread() not available - disabled
  Future<void> _createThread() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Legacy chat feature disabled - use ChatView instead')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Legacy ChatThread model not available - show placeholder
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 64, color: Colors.white54),
          SizedBox(height: 24),
          Text(
            'Legacy Chat Screen Disabled',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'This view requires the legacy ChatThread model.\nUse the ChatView in the main navigation instead.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

