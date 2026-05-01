import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../../state/channel_context.dart';
import '../../../services/auth_service.dart';

/// Left sidebar showing user profile and channel list
class ChannelListPanel extends StatelessWidget {
  const ChannelListPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // User profile card
          _buildUserProfile(),
          
          const Divider(height: 1, color: Colors.white10),
          
          // New Channel button
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Channel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 36),
              ),
            ),
          ),
          
          // Channel list
          Expanded(
            child: Consumer<ChannelContext>(
              builder: (context, channelContext, _) {
                final channels = channelContext.channels;
                
                if (channels.isEmpty) {
                  return const Center(
                    child: Text(
                      'No channels',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    final isActive = channelContext.activeChannelId == channel.channelId;
                    
                    return _buildChannelItem(
                      context,
                      channel.name,
                      channel.channelId,
                      isActive,
                      channelContext,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserProfile() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: AuthService.getCurrentUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final displayName = user?['displayName'] ?? user?['email'] ?? 'User';
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  displayName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Online',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildChannelItem(
    BuildContext context,
    String name,
    String channelId,
    bool isActive,
    ChannelContext channelContext,
  ) {
    return Material(
      color: isActive ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
      child: InkWell(
        onTap: () => channelContext.setActiveChannel(channelId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.tag,
                size: 18,
                color: isActive ? AppColors.primary : Colors.white54,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
