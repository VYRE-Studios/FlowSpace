import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Workspace landing page - Your FlowSpace hub
/// Inspired by Unreal Engine launcher: recent activity, news, quick actions
class WorkspaceScreen extends StatelessWidget {
  const WorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // Main content area (left side - 70%)
          Expanded(
            flex: 7,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32), // 8px grid alignment
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome header
                  _buildWelcomeHeader(context),
                  
                  const SizedBox(height: 32),
                  
                  // Your Workspace section
                  _buildYourWorkspace(context),
                  
                  const SizedBox(height: 32),
                  
                  // Recent activity section
                  _buildRecentActivity(context),
                  
                  const SizedBox(height: 32),
                  
                  // Active projects section
                  _buildActiveProjects(context),
                ],
              ),
            ),
          ),
          
          // Right sidebar (30%) - News/Updates feed - premium panel
          Container(
            width: MediaQuery.of(context).size.width * 0.3,
            decoration: const BoxDecoration(
              color: AppColors.sidebar,
              border: Border(
                left: BorderSide(
                  color: AppColors.borderSoft, // 6% white
                  width: 1,
                ),
              ),
            ),
            child: _buildNewsFeed(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    // TODO: Replace with actual user name from auth/profile
    const String userName = 'Joe';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,',
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          userName,
          style: textTheme.headlineMedium,
        ),
      ],
    );
  }

  Widget _buildYourWorkspace(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Workspace',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 16),
        
        // Workspace card with associated projects
        _WorkspaceCard(
          workspaceName: 'test',
          projects: [
            _WorkspaceProject(
              name: 'Brainstorming Session',
              type: 'brainstorm',
              lastModified: '2 hours ago',
            ),
          ],
          onTap: () {
            // TODO: Navigate to workspace detail/builder
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleSmall, // Pure theme - no override
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ActivityItem(
          icon: Icons.edit_outlined,
          title: 'Updated project "Mobile App Redesign"',
          timestamp: '2 hours ago',
          iconColor: AppColors.primary,
        ),
        const SizedBox(height: 12),
        _ActivityItem(
          icon: Icons.chat_bubble_outline,
          title: 'New messages in #design-team',
          timestamp: '4 hours ago',
          iconColor: const Color(0xFF4A9EFF),
        ),
        const SizedBox(height: 12),
        _ActivityItem(
          icon: Icons.upload_file_outlined,
          title: 'Uploaded 3 files to Vault',
          timestamp: 'Yesterday',
          iconColor: const Color(0xFF00B894),
        ),
      ],
    );
  }

  Widget _buildActiveProjects(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Projects',
              style: Theme.of(context).textTheme.titleSmall, // Pure theme - no override
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'See All Projects',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _ProjectCard(
              name: 'Mobile App Redesign',
              lastModified: '2 hours ago',
              progress: 0.65,
            ),
            const SizedBox(width: 16),
            _ProjectCard(
              name: 'Backend API v2',
              lastModified: '1 day ago',
              progress: 0.42,
            ),
            const SizedBox(width: 16),
            _ProjectCard(
              name: 'Marketing Campaign',
              lastModified: '3 days ago',
              progress: 0.88,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNewsFeed(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24), // 8px grid alignment
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Updates & News',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _NewsItem(
            title: 'FlowSpace v2.0.0 Released',
            description: 'New unified workspace with improved navigation and collaboration features.',
            timestamp: 'Today',
          ),
          const SizedBox(height: 16),
          _NewsItem(
            title: 'New Connect Features',
            description: 'Video and voice calls now support screen sharing and recording.',
            timestamp: '2 days ago',
          ),
          const SizedBox(height: 16),
          _NewsItem(
            title: 'Vault Storage Upgraded',
            description: 'Now with 100GB free storage and enhanced file versioning.',
            timestamp: '1 week ago',
          ),
        ],
      ),
    );
  }
}

class _WorkspaceProject {
  final String name;
  final String type;
  final String lastModified;

  _WorkspaceProject({
    required this.name,
    required this.type,
    required this.lastModified,
  });
}

class _WorkspaceCard extends StatefulWidget {
  final String workspaceName;
  final List<_WorkspaceProject> projects;
  final VoidCallback onTap;

  const _WorkspaceCard({
    required this.workspaceName,
    required this.projects,
    required this.onTap,
  });

  @override
  State<_WorkspaceCard> createState() => _WorkspaceCardState();
}

class _WorkspaceCardState extends State<_WorkspaceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered
                  ? AppColors.borderSoft
                  : AppColors.borderSofter,
              width: 1,
            ),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Workspace header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.workspaces_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.workspaceName,
                      style: textTheme.titleMedium,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textMeta,
                  ),
                ],
              ),
              
              if (widget.projects.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: AppColors.borderSofter,
                ),
                const SizedBox(height: 12),
                
                // Associated projects
                ...widget.projects.map((project) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        _getProjectIcon(project.type),
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          project.name,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        project.lastModified,
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getProjectIcon(String type) {
    switch (type) {
      case 'brainstorm':
        return Icons.lightbulb_outline;
      case 'document':
        return Icons.description_outlined;
      case 'graph':
        return Icons.account_tree_outlined;
      default:
        return Icons.folder_outlined;
    }
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String timestamp;
  final Color iconColor;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.timestamp,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card, // Machined carbon
        borderRadius: BorderRadius.circular(8),
        border: const Border.fromBorderSide(
          BorderSide(
            color: AppColors.borderSofter, // 5% white
            width: 1,
          ),
        ),
        boxShadow: AppShadows.card, // Premium shadows
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium, // Theme-driven
                ),
                const SizedBox(height: 2),
                Text(
                  timestamp,
                  style: Theme.of(context).textTheme.bodySmall, // Theme-driven
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatefulWidget {
  final String name;
  final String lastModified;
  final double progress;

  const _ProjectCard({
    required this.name,
    required this.lastModified,
    required this.progress,
  });

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues(
            0,
            _isHovered ? -2 : 0,
            0,
          ),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered
                  ? AppColors.borderSoft
                  : AppColors.borderSofter,
              width: 1,
            ),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.folder_outlined,
                color: AppColors.primary,
                size: 30,
              ),

              const SizedBox(height: 14),

              Text(
                widget.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall, // Pure theme
              ),

              const SizedBox(height: 8),

              Text(
                'Updated ${widget.lastModified}',
                style: textTheme.bodySmall, // Pure theme
              ),

              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: textTheme.labelSmall, // Pure theme
                      ),
                      Text(
                        '${(widget.progress * 100).toInt()}%',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: widget.progress,
                      minHeight: 6,
                      backgroundColor: AppColors.borderSofter,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsItem extends StatelessWidget {
  final String title;
  final String description;
  final String timestamp;

  const _NewsItem({
    required this.title,
    required this.description,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,                      // Carbon panel
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.borderSoft,              // 6 percent white
          width: 1,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              timestamp,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              fontSize: 15, // Size override only, color from theme
              letterSpacing: 0.25,
            ),
          ),

          const SizedBox(height: 6),

          // Description
          Text(
            description,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.35,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
