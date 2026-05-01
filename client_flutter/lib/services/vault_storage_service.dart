import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'project_template_structures.dart';
import 'template_tools.dart';
import '../models/project_manifest.dart';

class VaultStorageService {
  static const String _customStoragePathKey = 'custom_vault_storage_path';

  /// Get the custom storage path from preferences, or null if not set
  static Future<String?> getCustomStoragePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customStoragePathKey);
  }

  /// Set a custom storage path
  static Future<void> setCustomStoragePath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.isEmpty) {
      await prefs.remove(_customStoragePathKey);
    } else {
      await prefs.setString(_customStoragePathKey, path);
    }
  }

  /// Get the base vault directory (either custom or default app data)
  static Future<String> getBaseVaultPath() async {
    final customPath = await getCustomStoragePath();
    if (customPath != null && customPath.isNotEmpty) {
      // Validate that the custom path exists and is accessible
      final dir = Directory(customPath);
      if (await dir.exists()) {
        return customPath;
      } else {
        // If custom path doesn't exist, try to create it
        try {
          await dir.create(recursive: true);
          return customPath;
        } catch (e) {
          print('FlowSpace: Failed to create custom storage path: $e');
          // Fall back to default
        }
      }
    }
    
    // Default: use app data directory
    final appDir = await getApplicationSupportDirectory();
    return join(appDir.path, 'Vault');
  }

  static Future<String> getVaultPath(String workspaceId, {String folder = 'shared'}) async {
    final basePath = await getBaseVaultPath();
    final vaultPath = join(basePath, workspaceId, folder);
    
    // Create directory if it doesn't exist
    final directory = Directory(vaultPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
      print('FlowSpace: Created vault directory: $vaultPath');
    }
    
    return vaultPath;
  }

  static Future<File> saveFile(String workspaceId, File sourceFile, {String folder = 'shared'}) async {
    final vaultPath = await getVaultPath(workspaceId, folder: folder);
    final fileName = basename(sourceFile.path);
    final destinationPath = join(vaultPath, fileName);
    
    // Copy file to vault
    final destinationFile = await sourceFile.copy(destinationPath);
    print('FlowSpace: File saved to vault: $destinationPath');
    
    return destinationFile;
  }

  static Future<bool> fileExists(String workspaceId, String fileName, {String folder = 'shared'}) async {
    final vaultPath = await getVaultPath(workspaceId, folder: folder);
    final filePath = join(vaultPath, fileName);
    return await File(filePath).exists();
  }

  static Future<File?> getFile(String workspaceId, String fileName, {String folder = 'shared'}) async {
    final vaultPath = await getVaultPath(workspaceId, folder: folder);
    final filePath = join(vaultPath, fileName);
    final file = File(filePath);
    
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  static Future<void> deleteFile(String workspaceId, String fileName, {String folder = 'shared'}) async {
    final vaultPath = await getVaultPath(workspaceId, folder: folder);
    final filePath = join(vaultPath, fileName);
    final file = File(filePath);
    
    if (await file.exists()) {
      await file.delete();
      print('FlowSpace: File deleted from vault: $filePath');
    }
  }

  static Future<List<File>> listFiles(String workspaceId, {String folder = 'shared'}) async {
    final vaultPath = await getVaultPath(workspaceId, folder: folder);
    final directory = Directory(vaultPath);
    
    if (!await directory.exists()) {
      return [];
    }
    
    final entities = await directory.list().toList();
    final files = entities.whereType<File>().toList();
    
    return files;
  }

  static Future<int> getFileSize(File file) async {
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  static String getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    final mimeTypes = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'zip': 'application/zip',
      '7z': 'application/x-7z-compressed',
      'rar': 'application/x-rar-compressed',
    };
    
    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  static Future<void> clearWorkspaceVault(String workspaceId) async {
    final basePath = await getBaseVaultPath();
    final vaultPath = join(basePath, workspaceId);
    final directory = Directory(vaultPath);
    
    if (await directory.exists()) {
      await directory.delete(recursive: true);
      print('FlowSpace: Cleared vault for workspace: $workspaceId');
    }
  }

  /// Create a project folder in the vault with template-specific structure
  static Future<String> createProjectFolder(
    String workspaceId,
    String projectName, {
    String? description,
    String? templateId,
  }) async {
    final basePath = await getBaseVaultPath();
    final projectPath = join(basePath, workspaceId, 'projects', projectName);
    
    final directory = Directory(projectPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
      print('FlowSpace: Created project folder: $projectPath');
      
      // Get template-specific structure
      final structure = ProjectTemplateStructure.getStructure(
        templateId ?? 'blank',
        projectName,
        description,
      );
      
      // Create folders
      for (final folder in structure.folders) {
        await Directory(join(projectPath, folder)).create(recursive: true);
      }
      
      // Create files
      for (final entry in structure.files.entries) {
        final filePath = join(projectPath, entry.key);
        final file = File(filePath);
        // Create parent directories if nested file
        await file.parent.create(recursive: true);
        await file.writeAsString(entry.value);
      }
      
      print('FlowSpace: Created project structure with ${structure.folders.length} folders and ${structure.files.length} files');
    }
    
    return projectPath;
  }

  /// List all project folders for a workspace
  static Future<List<String>> listProjectFolders(String workspaceId) async {
    final basePath = await getBaseVaultPath();
    final projectsPath = join(basePath, workspaceId, 'projects');
    
    final directory = Directory(projectsPath);
    if (!await directory.exists()) {
      return [];
    }
    
    final entities = await directory.list().toList();
    final folders = entities.whereType<Directory>().map((d) => basename(d.path)).toList();
    
    return folders;
  }

  // ===== New baseline: workspace-local project directory by IDs =====

  static Future<String> _projectDir(String workspaceId, String projectId) async {
    final base = await getBaseVaultPath();
    final dir = Directory(join(base, workspaceId, projectId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  static Future<void> ensureLocalWorkspaceFolder(String workspaceId, String projectId) async {
    await _projectDir(workspaceId, projectId);
    // Create subfolders for modules
    final wb = Directory(join(await _projectDir(workspaceId, projectId), 'whiteboard'));
    if (!await wb.exists()) {
      await wb.create(recursive: true);
    }
  }

  static Future<void> initializeProjectFiles({
    required String workspaceId,
    required String projectId,
    required Map<String, dynamic> template,
  }) async {
    final base = await _projectDir(workspaceId, projectId);
    final projectJson = File(join(base, 'project.json'));
    final boardsJson = File(join(base, 'boards.json'));
    final stateJson = File(join(base, 'state.json'));

    if (!await projectJson.exists()) {
      await projectJson.writeAsString('{"projectId":"$projectId","templateId":"${template['id']}","createdAt":"${DateTime.now().toIso8601String()}"}');
    }
    if (!await boardsJson.exists()) {
      final boards = (template['defaultBoards'] as List<dynamic>? ?? []);
      await boardsJson.writeAsString('{"boards": ${boards.map((e) => '"$e"').toList()}}');
    }
    if (!await stateJson.exists()) {
      await stateJson.writeAsString('{"version":1}');
    }

    // Initialize whiteboard files for whiteboard/infinite-canvas
    final bg = template['backgroundModule'];
    if (bg == 'whiteboard' || bg == 'infinite-canvas') {
      final wbDir = Directory(join(base, 'whiteboard'));
      if (!await wbDir.exists()) await wbDir.create(recursive: true);
      final wbFile = File(join(wbDir.path, 'whiteboard.json'));
      if (!await wbFile.exists()) {
        await wbFile.writeAsString('{"stickies":[],"strokes":[]}');
      }
    }
  }

  // Whiteboard persistence helpers
  static Future<void> saveWhiteboard(String projectId, String jsonData) async {
    // We do not know workspaceId here; scan for containing folder by convention
    final base = await getBaseVaultPath();
    final baseDir = Directory(base);
    if (!await baseDir.exists()) return;
    // best-effort write to any matching projectId directory
    await for (final entity in baseDir.list(recursive: true, followLinks: false)) {
      if (entity is Directory && basename(entity.path) == projectId) {
        final wbDir = Directory(join(entity.path, 'whiteboard'));
        if (!await wbDir.exists()) await wbDir.create(recursive: true);
        final f = File(join(wbDir.path, 'whiteboard.json'));
        await f.writeAsString(jsonData);
        break;
      }
    }
  }

  static Future<Map<String, dynamic>?> loadWhiteboard(String projectId) async {
    final base = await getBaseVaultPath();
    final baseDir = Directory(base);
    if (!await baseDir.exists()) return null;
    await for (final entity in baseDir.list(recursive: true, followLinks: false)) {
      if (entity is Directory && basename(entity.path) == projectId) {
        final f = File(join(entity.path, 'whiteboard', 'whiteboard.json'));
        if (await f.exists()) {
          try {
            final txt = await f.readAsString();
            return txt.isEmpty ? null : (txt.trim().isEmpty ? null : (txt.startsWith('{') ? _safeJson(txt) : null));
          } catch (_) {
            return null;
          }
        }
      }
    }
    return null;
  }

  static Map<String, dynamic>? _safeJson(String txt) {
    try {
      return jsonDecode(txt) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Create project vault folder with template-specific structure
  /// Returns the path to the created project folder
  static Future<String> createProjectVaultFolder({
    required String projectId,
    required String templateId,
    required String projectName,
  }) async {
    final base = await getBaseVaultPath();
    final projectPath = join(base, 'Projects', projectId);
    final projectDir = Directory(projectPath);
    
    // Create main project directory
    if (!await projectDir.exists()) {
      await projectDir.create(recursive: true);
      print('FlowSpace: Created project vault folder: $projectPath');
    }
    
    // Get folder structure from template
    final folderStructure = TemplateTools.getFolderStructure(templateId);
    
    // Create template-specific subfolders
    final folders = folderStructure['root'] ?? [];
    for (final folder in folders) {
      final subDir = Directory(join(projectPath, folder));
      if (!await subDir.exists()) {
        await subDir.create(recursive: true);
        print('FlowSpace: Created subfolder: ${join(projectPath, folder)}');
      }
    }
    
    // Create project metadata file
    final metadataFile = File(join(projectPath, 'project.json'));
    final metadata = {
      'projectId': projectId,
      'projectName': projectName,
      'templateId': templateId,
      'createdAt': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
    await metadataFile.writeAsString(jsonEncode(metadata));
    
    // Create README file
    final readmeFile = File(join(projectPath, 'README.md'));
    final templateName = TemplateTools.getTemplateName(templateId);
    final readmeContent = '''# $projectName

**Template**: $templateName
**Created**: ${DateTime.now().toLocal().toString().split('.')[0]}

## Project Structure
${folders.map((f) => '- `$f/` - ${_getFolderDescription(f, templateId)}').join('\n')}

## Getting Started
Add your files to the appropriate folders above.
''';
    await readmeFile.writeAsString(readmeContent);
    
    print('FlowSpace: Created project vault structure with ${folders.length} folders');
    return projectPath;
  }
  
  static String _getFolderDescription(String folder, String templateId) {
    final descriptions = {
      'Boards': 'Whiteboard canvases',
      'Exports': 'Exported files and images',
      'Images': 'Image assets',
      'Characters': 'Character profiles and sheets',
      'Scenes': 'Scene descriptions and notes',
      'Drafts': 'Story drafts and chapters',
      'Worldbuilding': 'World lore and details',
      'Research': 'Research materials',
      'Assets': 'Game assets and resources',
      'Builds': 'Compiled game builds',
      'Documentation': 'Project documentation',
      'Source': 'Source code and scripts',
      'Workflows': 'Automation workflows',
      'Logs': 'Execution logs',
      'Config': 'Configuration files',
      'Files': 'General files',
      'Notes': 'Project notes',
    };
    return descriptions[folder] ?? 'Project files';
  }

  // ===== Project Manifest Management =====

  /// Create a project manifest file in the project folder
  static Future<void> createProjectManifest(ProjectManifest manifest) async {
    final base = await getBaseVaultPath();
    final projectPath = join(base, 'Projects', manifest.projectId);
    final projectDir = Directory(projectPath);
    
    // Ensure project directory exists
    if (!await projectDir.exists()) {
      await projectDir.create(recursive: true);
    }
    
    // Write manifest file
    final manifestFile = File(join(projectPath, 'project.json'));
    await manifestFile.writeAsString(jsonEncode(manifest.toJson()));
    print('FlowSpace: Created project manifest: ${manifestFile.path}');
  }

  /// Load a project manifest from its folder
  static Future<ProjectManifest?> loadProjectManifest(String projectId) async {
    try {
      final base = await getBaseVaultPath();
      final manifestFile = File(join(base, 'Projects', projectId, 'project.json'));
      
      if (!await manifestFile.exists()) {
        return null;
      }
      
      final contents = await manifestFile.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;
      return ProjectManifest.fromJson(json);
    } catch (e) {
      print('FlowSpace: Error loading manifest for $projectId: $e');
      return null;
    }
  }

  /// Update an existing project manifest
  static Future<void> updateProjectManifest(String projectId, ProjectManifest manifest) async {
    final base = await getBaseVaultPath();
    final manifestFile = File(join(base, 'Projects', projectId, 'project.json'));
    
    if (await manifestFile.exists()) {
      await manifestFile.writeAsString(jsonEncode(manifest.toJson()));
      print('FlowSpace: Updated project manifest for $projectId');
    } else {
      // Create if doesn't exist
      await createProjectManifest(manifest);
    }
  }

  /// Update only the lastOpened timestamp in manifest
  static Future<void> updateManifestLastOpened(String projectId) async {
    final manifest = await loadProjectManifest(projectId);
    if (manifest != null) {
      final updated = manifest.copyWith(
        lastOpened: DateTime.now().toIso8601String(),
      );
      await updateProjectManifest(projectId, updated);
    }
  }

  /// Delete a project manifest file
  static Future<void> deleteProjectManifest(String projectId) async {
    try {
      final base = await getBaseVaultPath();
      final manifestFile = File(join(base, 'Projects', projectId, 'project.json'));
      
      if (await manifestFile.exists()) {
        await manifestFile.delete();
        print('FlowSpace: Deleted project manifest for $projectId');
      }
    } catch (e) {
      print('FlowSpace: Error deleting manifest for $projectId: $e');
    }
  }

  /// Delete entire project folder including manifest
  static Future<void> deleteProjectFolder(String projectId) async {
    try {
      final base = await getBaseVaultPath();
      final projectDir = Directory(join(base, 'Projects', projectId));
      
      if (await projectDir.exists()) {
        await projectDir.delete(recursive: true);
        print('FlowSpace: Deleted project folder for $projectId');
      }
    } catch (e) {
      print('FlowSpace: Error deleting project folder for $projectId: $e');
    }
  }
}
