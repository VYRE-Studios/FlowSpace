class RegistryEntry {
  final String projectId;
  final String workspaceId;
  final String name;
  final String templateId;
  final String lastOpened;
  final String localPath;

  RegistryEntry({
    required this.projectId,
    required this.workspaceId,
    required this.name,
    required this.templateId,
    required this.lastOpened,
    required this.localPath,
  });

  factory RegistryEntry.fromJson(Map<String, dynamic> json) {
    return RegistryEntry(
      projectId: json['projectId'] as String,
      workspaceId: json['workspaceId'] as String,
      name: json['name'] as String,
      templateId: json['templateId'] as String,
      lastOpened: json['lastOpened'] as String,
      localPath: json['localPath'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'workspaceId': workspaceId,
      'name': name,
      'templateId': templateId,
      'lastOpened': lastOpened,
      'localPath': localPath,
    };
  }

  RegistryEntry copyWith({
    String? projectId,
    String? workspaceId,
    String? name,
    String? templateId,
    String? lastOpened,
    String? localPath,
  }) {
    return RegistryEntry(
      projectId: projectId ?? this.projectId,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      templateId: templateId ?? this.templateId,
      lastOpened: lastOpened ?? this.lastOpened,
      localPath: localPath ?? this.localPath,
    );
  }
}

class ProjectRegistry {
  final String version;
  final String lastUpdated;
  final List<RegistryEntry> projects;

  ProjectRegistry({
    this.version = '1.0.0',
    required this.lastUpdated,
    required this.projects,
  });

  factory ProjectRegistry.fromJson(Map<String, dynamic> json) {
    return ProjectRegistry(
      version: json['version'] as String? ?? '1.0.0',
      lastUpdated: json['lastUpdated'] as String,
      projects: (json['projects'] as List)
          .map((p) => RegistryEntry.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'lastUpdated': lastUpdated,
      'projects': projects.map((p) => p.toJson()).toList(),
    };
  }

  ProjectRegistry copyWith({
    String? version,
    String? lastUpdated,
    List<RegistryEntry>? projects,
  }) {
    return ProjectRegistry(
      version: version ?? this.version,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      projects: projects ?? this.projects,
    );
  }
}
