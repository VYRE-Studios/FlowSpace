import 'package:flutter/material.dart';
import 'flo_theme.dart';

/// FLŌ Brand Assets
/// Logo, icons, and brand constants
class FloBrand {
  // Brand name with macron
  static const String name = 'FLŌ';
  static const String nameAscii = 'FLO'; // For contexts that don't support macron
  
  // Taglines
  static const String tagline = 'Teams. Unified.';
  static const String taglineExtended = 'The unified collaboration platform for modern teams';
  
  // Version
  static const String version = '1.0.0';
  
  // Logo widget with gradient
  static Widget logo({double size = 48}) {
    return ShaderMask(
      shaderCallback: (bounds) => FloTheme.floGradient.createShader(bounds),
      child: Text(
        name,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 2,
        ),
      ),
    );
  }
  
  // Logo with text
  static Widget logoWithTagline({double logoSize = 48, double taglineSize = 14}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        logo(size: logoSize),
        const SizedBox(height: 8),
        Text(
          tagline,
          style: TextStyle(
            fontSize: taglineSize,
            fontWeight: FontWeight.w500,
            color: FloTheme.textSecondary,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
  
  // Small logo for app bar
  static Widget logoSmall() => logo(size: 24);
  
  // Medium logo for cards
  static Widget logoMedium() => logo(size: 36);
  
  // Large logo for onboarding
  static Widget logoLarge() => logo(size: 64);
}

/// FLŌ Icon System
/// Consistent icons using Material rounded variants
class FloIcons {
  // Navigation
  static const IconData dashboard = Icons.dashboard_rounded;
  static const IconData projects = Icons.view_kanban_rounded;
  static const IconData chat = Icons.chat_bubble_rounded;
  static const IconData meet = Icons.videocam_rounded;
  static const IconData vault = Icons.folder_rounded;
  static const IconData activity = Icons.notifications_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData profile = Icons.person_rounded;
  
  // Workspace types
  static const IconData whiteboard = Icons.draw_rounded;
  static const IconData document = Icons.description_rounded;
  static const IconData brainstorm = Icons.lightbulb_rounded;
  static const IconData design = Icons.palette_rounded;
  
  // Actions
  static const IconData add = Icons.add_rounded;
  static const IconData remove = Icons.remove_rounded;
  static const IconData edit = Icons.edit_rounded;
  static const IconData delete = Icons.delete_rounded;
  static const IconData save = Icons.save_rounded;
  static const IconData cancel = Icons.close_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData filter = Icons.filter_list_rounded;
  static const IconData sort = Icons.sort_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData share = Icons.share_rounded;
  static const IconData download = Icons.download_rounded;
  static const IconData upload = Icons.upload_rounded;
  
  // UI elements
  static const IconData menu = Icons.menu_rounded;
  static const IconData more = Icons.more_vert_rounded;
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData forward = Icons.arrow_forward_rounded;
  static const IconData expand = Icons.expand_more_rounded;
  static const IconData collapse = Icons.expand_less_rounded;
  static const IconData maximize = Icons.fullscreen_rounded;
  static const IconData minimize = Icons.fullscreen_exit_rounded;
  
  // Communication
  static const IconData send = Icons.send_rounded;
  static const IconData attach = Icons.attach_file_rounded;
  static const IconData emoji = Icons.emoji_emotions_rounded;
  static const IconData mention = Icons.alternate_email_rounded;
  
  // Files
  static const IconData file = Icons.insert_drive_file_rounded;
  static const IconData folder = Icons.folder_rounded;
  static const IconData image = Icons.image_rounded;
  static const IconData video = Icons.video_library_rounded;
  static const IconData audio = Icons.audio_file_rounded;
  static const IconData code = Icons.code_rounded;
  
  // Status
  static const IconData success = Icons.check_circle_rounded;
  static const IconData warning = Icons.warning_rounded;
  static const IconData error = Icons.error_rounded;
  static const IconData info = Icons.info_rounded;
  
  // Misc
  static const IconData lock = Icons.lock_rounded;
  static const IconData unlock = Icons.lock_open_rounded;
  static const IconData star = Icons.star_rounded;
  static const IconData starOutline = Icons.star_border_rounded;
  static const IconData pin = Icons.push_pin_rounded;
  static const IconData link = Icons.link_rounded;
  static const IconData calendar = Icons.calendar_today_rounded;
  static const IconData time = Icons.access_time_rounded;
  static const IconData location = Icons.location_on_rounded;
}

/// Workspace Type Metadata
class WorkspaceTypeMeta {
  final String type;
  final String label;
  final IconData icon;
  final String description;
  final Color color;
  
  const WorkspaceTypeMeta({
    required this.type,
    required this.label,
    required this.icon,
    required this.description,
    required this.color,
  });
  
  static const project = WorkspaceTypeMeta(
    type: 'project',
    label: 'Project',
    icon: FloIcons.projects,
    description: 'Kanban boards for task management',
    color: FloTheme.floPrimary,
  );
  
  static const whiteboard = WorkspaceTypeMeta(
    type: 'whiteboard',
    label: 'Whiteboard',
    icon: FloIcons.whiteboard,
    description: 'Visual collaboration canvas',
    color: FloTheme.floSecondary,
  );
  
  static const document = WorkspaceTypeMeta(
    type: 'document',
    label: 'Document',
    icon: FloIcons.document,
    description: 'Rich text documents and wikis',
    color: FloTheme.success,
  );
  
  static const brainstorm = WorkspaceTypeMeta(
    type: 'brainstorm',
    label: 'Brainstorm',
    icon: FloIcons.brainstorm,
    description: 'Idea generation and voting',
    color: FloTheme.warning,
  );
  
  static const design = WorkspaceTypeMeta(
    type: 'design',
    label: 'Design',
    icon: FloIcons.design,
    description: 'Design collaboration and feedback',
    color: Color(0xFFFF6B9D),
  );
  
  static WorkspaceTypeMeta fromType(String type) {
    switch (type) {
      case 'whiteboard':
        return whiteboard;
      case 'document':
        return document;
      case 'brainstorm':
        return brainstorm;
      case 'design':
        return design;
      case 'project':
      default:
        return project;
    }
  }
  
  static List<WorkspaceTypeMeta> get all => [
    project,
    whiteboard,
    document,
    brainstorm,
    design,
  ];
}
