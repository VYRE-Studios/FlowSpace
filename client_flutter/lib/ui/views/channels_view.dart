import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/project_state.dart';

/// Channels view - shows project channels/chat rooms
class ChannelsView extends StatelessWidget {
  const ChannelsView({super.key});

  @override
  Widget build(BuildContext context) {
    final project = context.watch<ProjectState>().currentProject;
    
    if (project == null) {
      return const Center(
        child: Text(
          'Load a project to begin',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    // Channels from project (default to 'general' if none defined)
    final channels = ['general', 'team', 'random']; // TODO: Get from project manifest

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Channels - ${project.name}',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: channels.length,
                itemBuilder: (context, index) {
                  final channel = channels[index];
                  return Card(
                    color: Colors.white.withOpacity(0.05),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.tag, color: Colors.white70),
                      title: Text(
                        '#$channel',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Project channel',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                      onTap: () {
                        // TODO: Open channel chat
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
