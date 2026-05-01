import 'package:flutter/material.dart';

import '../screens/streams_screen.dart';

/// Compatibility route for older navigation entries that still open ChatView.
///
/// The maintained Slack-style messaging surface is StreamsScreen.
class ChatView extends StatelessWidget {
  const ChatView({super.key, this.bootstrapEmail});

  final String? bootstrapEmail;

  @override
  Widget build(BuildContext context) {
    return const StreamsScreen();
  }
}
