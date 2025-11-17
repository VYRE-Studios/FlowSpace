import 'package:flutter/material.dart';

import 'members_panel.dart';
import 'activity_panel.dart';
import 'workspace_metadata_panel.dart';
import 'call_status_panel.dart';

class RightSidebar extends StatelessWidget {
  final List<MemberInfo> members;
  final List<ActivityEvent> recentActivity;
  final WorkspaceMetadata metadata;
  final CallStatus? callStatus;

  const RightSidebar({
    super.key,
    required this.members,
    required this.recentActivity,
    required this.metadata,
    this.callStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          left: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          if (callStatus != null) CallStatusPanel(status: callStatus!),
          const SizedBox(height: 16),
          WorkspaceMetadataPanel(metadata: metadata),
          const Divider(color: Colors.white24, height: 32),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MembersPanel(members: members),
                  const SizedBox(height: 24),
                  ActivityPanel(events: recentActivity),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MemberInfo {
  final String name;
  final String avatarUrl;
  final bool online;

  MemberInfo({
    required this.name,
    required this.avatarUrl,
    required this.online,
  });
}

class ActivityEvent {
  final String description;
  final DateTime timestamp;

  ActivityEvent({required this.description, required this.timestamp});
}

class WorkspaceMetadata {
  final String name;
  final String type;
  final String createdBy;
  final DateTime createdAt;

  WorkspaceMetadata({
    required this.name,
    required this.type,
    required this.createdBy,
    required this.createdAt,
  });
}

class CallStatus {
  final bool active;
  final int participants;

  CallStatus({
    required this.active,
    required this.participants,
  });
}


