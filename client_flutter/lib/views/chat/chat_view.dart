import 'package:flutter/material.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key, required this.threadId, required this.username});

  final String threadId;
  final String username;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
