import 'dart:convert';
import '../ui/modules/module_registry.dart';

class ProjectManifest {
  final String projectId;
  final String workspaceId;
  final String templateId;
  final String name;
  final String lastOpened;
  final String createdAt;
  final List<BoardManifest> boards;
  final String localPath;
  final String manifestVersion;
  final String backgroundModule;
  final List<String> tools;

  ProjectManifest({
    required this.projectId,
    required this.workspaceId,
    required this.templateId,
    required this.name,
    required this.lastOpened,
    required this.createdAt,
    required this.boards,
    required this.localPath,
    this.manifestVersion = '1.0.0',
    this.backgroundModule = 'standard',
    this.tools = const [],
  });

  factory ProjectManifest.fromJson(Map<String, dynamic> json) {
    return ProjectManifest(
      projectId: json['projectId'] as String,
      workspaceId: json['workspaceId'] as String,
      templateId: json['templateId'] as String,
      name: json['name'] as String,
      lastOpened: json['lastOpened'] as String,
      createdAt: json['createdAt'] as String,
      boards: (json['boards'] as List)
          .map((b) => BoardManifest.fromJson(b as Map<String, dynamic>))
          .toList(),
      localPath: json['localPath'] as String,
      manifestVersion: json['manifestVersion'] as String? ?? '1.0.0',
      backgroundModule: json['backgroundModule'] as String? ?? 'standard',
      tools: (json['tools'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Parse manifest from JSON string
  factory ProjectManifest.fromJsonString(String jsonString) {
    return ProjectManifest.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'workspaceId': workspaceId,
      'templateId': templateId,
      'name': name,
      'lastOpened': lastOpened,
      'createdAt': createdAt,
      'boards': boards.map((b) => b.toJson()).toList(),
      'localPath': localPath,
      'manifestVersion': manifestVersion,
      'backgroundModule': backgroundModule,
      'tools': tools,
    };
  }

  /// Convert to JSON string for file storage
  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  ProjectManifest copyWith({
    String? projectId,
    String? workspaceId,
    String? templateId,
    String? name,
    String? lastOpened,
    String? createdAt,
    List<BoardManifest>? boards,
    String? localPath,
    String? manifestVersion,
    String? backgroundModule,
    List<String>? tools,
  }) {
    return ProjectManifest(
      projectId: projectId ?? this.projectId,
      workspaceId: workspaceId ?? this.workspaceId,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      lastOpened: lastOpened ?? this.lastOpened,
      createdAt: createdAt ?? this.createdAt,
      boards: boards ?? this.boards,
      localPath: localPath ?? this.localPath,
      manifestVersion: manifestVersion ?? this.manifestVersion,
      backgroundModule: backgroundModule ?? this.backgroundModule,
      tools: tools ?? this.tools,
    );
  }
}

class BoardManifest {
  final String id;
  final String name;
  final String type;
  final int order;
  final String? module;

  BoardManifest({
    required this.id,
    required this.name,
    required this.type,
    required this.order,
    this.module,
  });

  /// Get module ID enum for routing
  ModuleId? get moduleId => ModuleRegistry.fromString(module);

  factory BoardManifest.fromJson(Map<String, dynamic> json) {
    return BoardManifest(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      order: json['order'] as int,
      module: json['module'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'order': order,
      'module': module,
    };
  }
}
