import 'package:flutter/material.dart';
import '../../models/project_manifest.dart';

class ProjectCard extends StatelessWidget {
  final ProjectManifest manifest;
  final VoidCallback onOpen;

  const ProjectCard({
    super.key,
    required this.manifest,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getTemplateIcon(manifest.templateId),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    manifest.name,
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              _getTemplateName(manifest.templateId),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatLastOpened(manifest.lastOpened),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Icon _getTemplateIcon(String templateId) {
    final iconData = {
      'whiteboard': Icons.brush,
      'story': Icons.auto_stories,
      'workflow': Icons.account_tree,
      'game': Icons.videogame_asset,
      'brainstorm-lite': Icons.lightbulb_outline,
      'blank': Icons.note,
    }[templateId] ?? Icons.folder;

    return Icon(iconData, color: Colors.blueAccent);
  }

  String _getTemplateName(String templateId) {
    return {
      'whiteboard': 'Whiteboard',
      'story': 'Story Building',
      'workflow': 'Workflow Automation',
      'game': 'Game Project',
      'brainstorm-lite': 'Brainstorm Board',
      'blank': 'Blank Project',
    }[templateId] ?? templateId;
  }

  String _formatLastOpened(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 30) {
        return 'Opened ${difference.inDays ~/ 30} months ago';
      } else if (difference.inDays > 0) {
        return 'Opened ${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return 'Opened ${difference.inHours} hours ago';
      } else {
        return 'Opened recently';
      }
    } catch (e) {
      return 'Last opened: $isoString';
    }
  }
}
