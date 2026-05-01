import 'package:flutter/material.dart';

class ActivityPanel extends StatelessWidget {
  final Map<String, String> presenceMap;
  final Map<String, String> userNames;
  final VoidCallback onClose;

  const ActivityPanel({
    Key? key,
    required this.presenceMap,
    required this.userNames,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final onlineUsers = presenceMap.entries
        .where((e) => e.value == 'online')
        .map((e) => e.key)
        .toList();
    
    final awayUsers = presenceMap.entries
        .where((e) => e.value == 'away')
        .map((e) => e.key)
        .toList();

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(
          left: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: onClose,
                  iconSize: 20,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (onlineUsers.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.circle,
                    iconColor: Colors.green,
                    title: 'Online (${onlineUsers.length})',
                  ),
                  ...onlineUsers.map((userId) => _UserTile(
                        userName: userNames[userId] ?? userId,
                        status: 'online',
                      )),
                  const SizedBox(height: 16),
                ],
                if (awayUsers.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.circle,
                    iconColor: Colors.orange,
                    title: 'Away (${awayUsers.length})',
                  ),
                  ...awayUsers.map((userId) => _UserTile(
                        userName: userNames[userId] ?? userId,
                        status: 'away',
                      )),
                ],
                if (onlineUsers.isEmpty && awayUsers.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No users online',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 12),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final String userName;
  final String status;

  const _UserTile({
    required this.userName,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor:
                Colors.primaries[userName.hashCode % Colors.primaries.length],
            child: Text(
              userName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          Icon(
            Icons.circle,
            size: 8,
            color: status == 'online' ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }
}
