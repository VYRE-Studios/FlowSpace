/// Workspace Configuration
/// This file defines the default workspace that all clients should connect to.
/// Update these values to match your production workspace.

class WorkspaceConfig {
  /// The default workspace slug to automatically join
  /// Set this to your primary workspace slug (e.g., 'company-hq', 'main-team')
  /// If null, will use the first available workspace (current behavior)
  static const String? defaultWorkspaceSlug = 'vyrevault';
  
  /// Alternative: specify workspace by ID
  /// If both slug and ID are set, slug takes precedence
  static const String? defaultWorkspaceId = null;
  
  /// Fallback behavior when default workspace is not found
  /// - true: Use first available workspace (safer)
  /// - false: Show error and require manual selection
  static const bool fallbackToFirstWorkspace = true;
  
  /// Auto-join first channel in workspace
  static const bool autoJoinFirstChannel = true;
  
  /// Specific channel slug to auto-join (e.g., 'general')
  /// If null, will use first available channel
  static const String? defaultChannelSlug = 'general';
}

/// Helper methods for workspace selection
extension WorkspaceConfigHelper on WorkspaceConfig {
  /// Select workspace from list based on configuration
  static Map<String, dynamic>? selectWorkspace(List<Map<String, dynamic>> workspaces) {
    if (workspaces.isEmpty) return null;
    
    // Try to find by slug first
    if (WorkspaceConfig.defaultWorkspaceSlug != null) {
      try {
        return workspaces.firstWhere(
          (ws) => ws['slug'] == WorkspaceConfig.defaultWorkspaceSlug,
        );
      } catch (e) {
        print('WorkspaceConfig: Default workspace slug "${WorkspaceConfig.defaultWorkspaceSlug}" not found');
      }
    }
    
    // Try to find by ID
    if (WorkspaceConfig.defaultWorkspaceId != null) {
      try {
        return workspaces.firstWhere(
          (ws) => ws['id'] == WorkspaceConfig.defaultWorkspaceId,
        );
      } catch (e) {
        print('WorkspaceConfig: Default workspace ID "${WorkspaceConfig.defaultWorkspaceId}" not found');
      }
    }
    
    // Fallback behavior
    if (WorkspaceConfig.fallbackToFirstWorkspace) {
      print('WorkspaceConfig: Using first available workspace: ${workspaces.first['name']}');
      return workspaces.first;
    }
    
    return null;
  }
}
