import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/conversations/conversations_header.dart';
import '../widgets/conversations/channel_list_panel.dart';
import '../widgets/conversations/message_list_view.dart';
import '../widgets/conversations/message_composer.dart';
import '../widgets/conversations/members_panel.dart';

/// FlowSpace Streams - Real-time messaging with 3-column layout
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Column(
        children: [
          // Top navigation bar
          const ConversationsHeader(),
          
          // Main 3-column layout
          Expanded(
            child: Row(
              children: [
                // Left sidebar - Channels
                const ChannelListPanel(),
                
                // Center - Messages + Composer
                Expanded(
                  child: Column(
                    children: [
                      // Messages list
                      const Expanded(
                        child: MessageListView(),
                      ),
                      // Message composer at bottom
                      MessageComposer(
                        onMessageSent: (message) {
                          // Message sent, will be handled by WebSocket
                        },
                      ),
                    ],
                  ),
                ),
                
                // Right sidebar - Members & Activity
                const MembersPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
