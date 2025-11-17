import 'dart:ui';

import 'package:flutter/material.dart';

import '../../services/meet_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

enum _MeetState { idle, loading, active }

class MeetView extends StatefulWidget {
  const MeetView({super.key});

  @override
  State<MeetView> createState() => _MeetViewState();
}

class _MeetViewState extends State<MeetView> {
  _MeetState _state = _MeetState.loading;
  List<Map<String, dynamic>> _meetings = const [];
  String? _workspaceId;

  @override
  void initState() {
    super.initState();
    _loadWorkspaceAndMeetings();
  }

  Future<void> _loadWorkspaceAndMeetings() async {
    setState(() => _state = _MeetState.loading);
    try {
      // Get current user and their workspace
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        if (!mounted) return;
        setState(() => _state = _MeetState.idle);
        return;
      }

      final workspaces = await DatabaseService.getUserWorkspaces(user['id'] as String);
      if (workspaces.isEmpty) {
        if (!mounted) return;
        setState(() => _state = _MeetState.idle);
        return;
      }

      final workspace = workspaces.first;
      final workspaceId = workspace['id'] as String;

      // Load active meetings
      final meetings = await MeetService.getWorkspaceMeetings(workspaceId);
      
      if (!mounted) return;
      setState(() {
        _workspaceId = workspaceId;
        _meetings = meetings;
        _state = meetings.isEmpty ? _MeetState.idle : _MeetState.active;
      });
    } catch (e) {
      print('Meet: Error loading meetings: $e');
      if (!mounted) return;
      setState(() => _state = _MeetState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMeetings = _state == _MeetState.active && _meetings.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: hasMeetings ? _buildMeetingGrid() : _buildIdleState(),
      ),
    );
  }

  Widget _buildMeetingGrid() {
    return RefreshIndicator(
      key: const ValueKey('meet-grid'),
      onRefresh: _loadWorkspaceAndMeetings,
      color: const Color(0xFF0066FF),
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 1.25,
        ),
        itemCount: _meetings.length,
        itemBuilder: (context, i) {
          final meeting = _meetings[i];
          final title = meeting['title'] as String? ?? 'Meeting ${i + 1}';
          final roomName = meeting['room_name'] as String? ?? '';
          final startedAt = meeting['started_at'] as String?;

          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.videocam_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (startedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Started ${startedAt.split("T").first}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: OutlinedButton(
                        onPressed: () async {
                          try {
                            final user = await AuthService.getCurrentUser();
                            await MeetService.joinMeeting(
                              roomName: roomName,
                              displayName: user?['name'] as String? ?? 'User',
                              title: title,
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to join: $e')),
                              );
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF0066FF)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Join'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIdleState() {
    final isLoading = _state == _MeetState.loading;

    return Center(
      key: const ValueKey('meet-idle'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: isLoading ? 0.25 : 0.35,
            child: Icon(
              Icons.meeting_room_outlined,
              size: 72,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isLoading ? 'Checking upcoming meetings…' : 'No meetings right now',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            FilledButton.icon(
              onPressed: _showStartMeetingDialog,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text('Start a meeting'),
            ),
          if (!isLoading)
            TextButton(
              onPressed: _loadWorkspaceAndMeetings,
              child: const Text('Refresh'),
            ),
        ],
      ),
    );
  }

  void _showStartMeetingDialog() {
    final titleController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Start a Meeting',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: titleController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Meeting Title',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white54),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title is required')),
                );
                return;
              }

              if (_workspaceId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No workspace found')),
                );
                return;
              }

              Navigator.pop(context);

              try {
                await MeetService.startMeeting(
                  workspaceId: _workspaceId!,
                  title: title,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Meeting started!')),
                  );
                  _loadWorkspaceAndMeetings();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to start: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}

