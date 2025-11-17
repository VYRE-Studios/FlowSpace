import 'package:flutter/material.dart';

import 'right_sidebar.dart';

class MembersPanel extends StatelessWidget {
  final List<MemberInfo> members;

  const MembersPanel({super.key, required this.members});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Members',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        for (final m in members)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage:
                      m.avatarUrl.isNotEmpty ? NetworkImage(m.avatarUrl) : null,
                  child: m.avatarUrl.isEmpty
                      ? Text(
                          m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  m.name,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const Spacer(),
                Icon(
                  Icons.circle,
                  size: 10,
                  color: m.online ? Colors.greenAccent : Colors.redAccent,
                ),
              ],
            ),
          ),
      ],
    );
  }
}


