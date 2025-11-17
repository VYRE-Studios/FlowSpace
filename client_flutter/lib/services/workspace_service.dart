import 'database_service.dart';
import 'auth_service.dart';
import 'vault_storage_service.dart';

class WorkspaceService {
  static Future<Map<String, dynamic>> getWorkspaceBootstrap() async {
    // Load from SQLite
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      return {'user': {}, 'workspaces': []};
    }
    
    final workspaces = await DatabaseService.getUserWorkspaces(user['id'] as String);
    
    return {
      'user': user,
      'workspaces': workspaces,
    };
  }

  static Future<Map<String, dynamic>> createWorkspace({
    required String name,
    String? description,
    String workspaceType = 'project',
  }) async {
    // Create workspace locally in SQLite
    final user = await AuthService.getCurrentUser();
    if (user == null) throw Exception('No user found');
    
    final userId = user['id'] as String;
    
    // Get user's team, or create one if it doesn't exist
    var team = await DatabaseService.getUserTeam(userId);
    String teamId;
    
    if (team == null) {
      // Auto-create a team for the user
      print('FlowSpace: No team found, creating default team...');
      teamId = '${DateTime.now().millisecondsSinceEpoch}_team';
      final now = DateTime.now().toIso8601String();
      
      await DatabaseService.insertTeam({
        'id': teamId,
        'name': "${user['name'] ?? 'User'}'s Team",
        'owner_id': userId,
        'created_at': now,
        'updated_at': now,
      });
      
      print('FlowSpace: Created default team: $teamId');
    } else {
      teamId = team['id'] as String;
    }
    final workspaceId = '${DateTime.now().millisecondsSinceEpoch}_ws';
    final now = DateTime.now().toIso8601String();
    
    // Create workspace
    await DatabaseService.insertWorkspace({
      'id': workspaceId,
      'team_id': teamId,
      'name': name,
      'slug': name.toLowerCase().replaceAll(' ', '-'),
      'description': description ?? 'Workspace for $name',
      'workspace_type': workspaceType,
      'owner_id': userId,
      'created_at': now,
      'updated_at': now,
    });
    
    // Add user as owner
    await DatabaseService.addWorkspaceMember({
      'workspace_id': workspaceId,
      'user_id': userId,
      'role': 'owner',
      'joined_at': now,
    });
    
    // Create default channels
    await DatabaseService.insertChannel({
      'id': '${workspaceId}_general',
      'workspace_id': workspaceId,
      'name': 'general',
      'description': 'General discussion',
      'is_private': 0,
      'created_at': now,
      'updated_at': now,
    });
    
    await DatabaseService.insertChannel({
      'id': '${workspaceId}_random',
      'workspace_id': workspaceId,
      'name': 'random',
      'description': 'Random chat',
      'is_private': 0,
      'created_at': now,
      'updated_at': now,
    });
    
    // Initialize vault directories
    await VaultStorageService.getVaultPath(workspaceId, folder: 'shared');
    await VaultStorageService.getVaultPath(workspaceId, folder: 'personal');
    
    print('FlowSpace: Workspace created: $name');
    
    return await DatabaseService.getWorkspace(workspaceId) ?? {};
  }

  static Future<Map<String, dynamic>> createChannel({
    required String workspaceId,
    required String name,
    String? description,
  }) async {
    // Create channel locally in SQLite
    final channelId = '${workspaceId}_${name.toLowerCase()}';
    final now = DateTime.now().toIso8601String();
    
    await DatabaseService.insertChannel({
      'id': channelId,
      'workspace_id': workspaceId,
      'name': name,
      'description': description ?? '',
      'is_private': 0,
      'created_at': now,
      'updated_at': now,
    });
    
    print('FlowSpace: Channel created: $name');
    
    return {
      'id': channelId,
      'workspace_id': workspaceId,
      'name': name,
      'description': description,
      'created_at': now,
    };
  }

  /// Convenience helper to select a workspace by its display name.
  ///
  /// Returns the matching workspace row, or null if not found.
  static Future<Map<String, dynamic>?> selectWorkspaceByName(String name) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return null;

    final userId = user['id'] as String;
    final workspaces = await DatabaseService.getUserWorkspaces(userId);
    try {
      return workspaces.firstWhere(
        (w) => (w['name'] as String?) == name,
      );
    } catch (_) {
      return null;
    }
  }

  /// Delete a workspace and all its associated data.
  static Future<void> deleteWorkspace(String workspaceId) async {
    // Delete workspace from database (cascade will handle members, channels, etc.)
    await DatabaseService.deleteWorkspace(workspaceId);
    
    // Delete vault directories
    try {
      final sharedPath = await VaultStorageService.getVaultPath(workspaceId, folder: 'shared');
      final personalPath = await VaultStorageService.getVaultPath(workspaceId, folder: 'personal');
      // Note: Actual file deletion would need to be implemented in VaultStorageService
      // For now, we just delete from database
    } catch (e) {
      print('WorkspaceService: Error cleaning up vault for workspace $workspaceId: $e');
    }
    
    print('FlowSpace: Workspace deleted: $workspaceId');
  }
}
