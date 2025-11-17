import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/chat_models.dart';
import '../../services/chat_service.dart';
import 'chat_view.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final String _username = 'User-${100 + Random().nextInt(900)}';

  bool _loading = true;
  bool _error = false;
  List<ChatThread> _threads = const [];
  ChatThread? _selectedThread;

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final data = await ChatService.getThreads();
      if (!mounted) return;

      setState(() {
        _threads = data;
        _selectedThread =
            data.isEmpty ? null : data.firstWhere((t) => t.id == _selectedThread?.id, orElse: () => data.first);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  Future<void> _createThread() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Channel'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Channel name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (title == null || title.isEmpty) return;

    try {
      await ChatService.createThread(title);
      await _loadThreads();
      if (_threads.isNotEmpty) {
        setState(() {
          _selectedThread = _threads.first;
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to create channel')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text('Unable to load channels'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadThreads,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Container(
          width: 320,
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            border: Border(right: BorderSide(color: Color(0x22FFFFFF))),
          ),
          child: Column(
            children: [
              ListTile(
                title: const Text(
                  'Channels',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: IconButton(
                  tooltip: 'New channel',
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: _createThread,
                ),
              ),
              Expanded(
                child: _threads.isEmpty
                    ? const Center(
                        child: Text(
                          'No channels yet.\nCreate one to get started.',
                          style: TextStyle(color: Colors.white54),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: _threads.length,
                        itemBuilder: (context, index) {
                          final thread = _threads[index];
                          final selected = thread.id == _selectedThread?.id;

                          return ListTile(
                            selected: selected,
                            selectedTileColor:
                                const Color(0xFF0066FF).withOpacity(0.15),
                            leading: const Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.white70,
                              size: 18,
                            ),
                            title: Text(
                              thread.title,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.85),
                                fontWeight:
                                    selected ? FontWeight.w600 : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: (thread.lastMessage ?? '').isEmpty
                                ? null
                                : Text(
                                    thread.lastMessage!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                            onTap: () {
                              setState(() => _selectedThread = thread);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _selectedThread == null
              ? const Center(
                  child: Text(
                    'Select or create a channel to start chatting.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ChatView(
                  threadId: _selectedThread!.id,
                  username: _username,
                ),
        ),
      ],
    );
  }
}

