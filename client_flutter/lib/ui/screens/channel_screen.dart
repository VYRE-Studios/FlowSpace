import 'package:flutter/material.dart';
import '../shell/workspace_shell.dart';
/// Channel screen - chat/messaging view
class ChannelScreen extends StatelessWidget {
  const ChannelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkspaceShell(
      channelName: 'general',
    );
  }
}
