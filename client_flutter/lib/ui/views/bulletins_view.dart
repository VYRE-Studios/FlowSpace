import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/project_state.dart';

/// Bulletins view - shows project announcements and pinned messages
class BulletinsView extends StatelessWidget {
  const BulletinsView({super.key});

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

    // TODO: Get bulletins from project manifest
    final bulletins = <Map<String, String>>[];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bulletins - ${project.name}',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: bulletins.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.campaign,
                            size: 64,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No bulletins yet',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pin important messages here',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: bulletins.length,
                      itemBuilder: (context, index) {
                        final bulletin = bulletins[index];
                        return Card(
                          color: Colors.white.withOpacity(0.05),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.push_pin,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      bulletin['title'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  bulletin['content'] ?? '',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Create bulletin
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
