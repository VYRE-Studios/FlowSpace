import '../models/project_manifest.dart';
import 'project_template_service.dart';

/// Validates and repairs project manifests
class ManifestValidator {
  /// Validate manifest integrity
  static bool validate(ProjectManifest manifest) {
    // Check required fields
    if (manifest.name.isEmpty) {
      print('[ManifestValidator] Invalid: empty name');
      return false;
    }
    
    if (manifest.templateId.isEmpty) {
      print('[ManifestValidator] Invalid: empty template');
      return false;
    }
    
    if (manifest.projectId.isEmpty) {
      print('[ManifestValidator] Invalid: empty projectId');
      return false;
    }

    // Check template exists
    if (!ProjectTemplateService.hasTemplate(manifest.templateId)) {
      print('[ManifestValidator] Invalid: unknown template ${manifest.templateId}');
      return false;
    }

    // Check boards list is valid
    if (manifest.boards.isEmpty) {
      print('[ManifestValidator] Warning: no boards defined');
    }

    return true;
  }

  /// Repair broken manifest by applying fallbacks
  static ProjectManifest repair(ProjectManifest manifest) {
    var fixed = manifest;

    // Fix empty name
    if (fixed.name.isEmpty) {
      fixed = fixed.copyWith(name: 'Untitled Project');
    }

    // Fix unknown template
    if (!ProjectTemplateService.hasTemplate(fixed.templateId)) {
      print('[ManifestValidator] Repairing: unknown template ${fixed.templateId} -> blank');
      fixed = fixed.copyWith(templateId: 'blank');
    }

    // Fix missing background module
    if (fixed.backgroundModule.isEmpty) {
      final template = ProjectTemplateService.getTemplate(fixed.templateId);
      fixed = fixed.copyWith(backgroundModule: template.backgroundModule);
    }

    // Fix missing tools
    if (fixed.tools.isEmpty) {
      final template = ProjectTemplateService.getTemplate(fixed.templateId);
      fixed = fixed.copyWith(tools: template.tools);
    }

    // Fix empty boards - add default from template
    if (fixed.boards.isEmpty) {
      final template = ProjectTemplateService.getTemplate(fixed.templateId);
      final boards = template.defaultBoards.asMap().entries.map((entry) {
        return BoardManifest(
          id: 'board_${entry.key}',
          name: entry.value,
          type: 'kanban',
          order: entry.key,
        );
      }).toList();
      
      fixed = fixed.copyWith(boards: boards);
    }

    return fixed;
  }

  /// Check if manifest needs repair
  static bool needsRepair(ProjectManifest manifest) {
    return !validate(manifest);
  }
}
