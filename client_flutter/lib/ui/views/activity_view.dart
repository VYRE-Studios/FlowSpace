import 'package:flutter/material.dart';

import '../../services/activity_service.dart';
import '../../services/auth_service.dart';

class ActivityView extends StatefulWidget {
  const ActivityView({super.key});

  @override
  State<ActivityView> createState() => _ActivityViewState();
}

enum _ActivityMode { idle, loading, active, error }

class _ActivityViewState extends State<ActivityView> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Activity feed is currently empty - would load from database
      final result = await ActivityService.getEvents();
      if (!mounted) return;
      setState(() {
        _events = result.events;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load activity feed';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchEvents,
              color: const Color(0xFF0066FF),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildContent() {
    final mode = _resolveMode();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: switch (mode) {
        _ActivityMode.loading => _buildGhostList(
            icon: Icons.timeline,
            subtle: true,
          ),
        _ActivityMode.error => _buildGhostList(
            icon: Icons.error_outline,
            subtle: false,
            onRetry: _fetchEvents,
          ),
        _ActivityMode.idle => _buildGhostList(
            icon: Icons.timeline,
            subtle: false,
          ),
        _ActivityMode.active => _buildActivityList(),
      },
    );
  }

  Widget _buildActivityList() {
    return AnimatedOpacity(
      key: const ValueKey('activity-list'),
      opacity: _events.isEmpty ? 0 : 1,
      duration: const Duration(milliseconds: 200),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _events.length,
        separatorBuilder: (_, __) =>
            const Divider(color: Color.fromRGBO(255, 255, 255, 0.08)),
        itemBuilder: (context, index) {
          final event = _events[index];
          final label = event['label'] as String? ?? 'Activity';
          final timestamp = event['timestamp'] as String? ?? '';
          final detail = event['detail'] as String? ?? '';

          return ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0066FF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.timeline, color: Color(0xFF10B981)),
            ),
            title: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                if (timestamp.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      timestamp,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGhostList({
    required IconData icon,
    bool subtle = false,
    Future<void> Function()? onRetry,
  }) {
    return ListView(
      key: ValueKey('ghost-$icon'),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 420,
          child: Center(
            child: Opacity(
              opacity: subtle ? 0.25 : 0.35,
              child: Icon(icon, size: 64, color: Colors.white),
            ),
          ),
        ),
        if (onRetry != null)
          Center(
            child: TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ),
      ],
    );
  }

  _ActivityMode _resolveMode() {
    if (_loading) return _ActivityMode.loading;
    if (_error != null) return _ActivityMode.error;
    if (_events.isEmpty) return _ActivityMode.idle;
    return _ActivityMode.active;
  }

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    return '${local.month}/${local.day}/${local.year} ${TimeOfDay.fromDateTime(local).format(context)}';
  }
}
