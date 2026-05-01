import 'dart:io';
import 'dart:convert';

/// Registry for loading custom templates from workspace
/// Loads template definitions from <workspace>/VyreVault/templates/
class TemplateRegistry {
  static final Map<String, Map<String, dynamic>> _templates = {};

  /// Load all templates from workspace templates folder
  static Future<void> loadFromWorkspace(String workspacePath) async {
    print('[TemplateRegistry] Loading templates from workspace...');
    
    final dir = Directory('$workspacePath/VyreVault/templates');
    if (!dir.existsSync()) {
      print('[TemplateRegistry] Templates directory does not exist - creating it');
      dir.createSync(recursive: true);
      return;
    }

    int loaded = 0;
    for (final entry in dir.listSync()) {
      if (entry is Directory) {
        final file = File('${entry.path}/template.json');
        if (file.existsSync()) {
          try {
            final jsonString = file.readAsStringSync();
            final data = jsonDecode(jsonString) as Map<String, dynamic>;
            final name = data['id'] as String? ?? data['name'] as String;
            _templates[name] = data;
            loaded++;
            print('[TemplateRegistry]   ✓ Loaded template: $name');
          } catch (e) {
            print('[TemplateRegistry]   ✗ Failed to load ${entry.path}: $e');
          }
        }
      }
    }

    print('[TemplateRegistry] Loaded $loaded custom templates');
  }

  /// Check if template exists
  static bool exists(String templateId) => _templates.containsKey(templateId);

  /// Get template data
  static Map<String, dynamic>? get(String templateId) => _templates[templateId];

  /// Get all template IDs
  static List<String> getAllTemplateIds() => _templates.keys.toList();

  /// Get all templates
  static List<Map<String, dynamic>> getAllTemplates() => _templates.values.toList();

  /// Clear loaded templates
  static void clear() {
    _templates.clear();
  }
}
