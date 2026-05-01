import 'database_service.dart';
import 'auth_service.dart';
import 'vault_storage_service.dart';
import 'api_client.dart';

class WorkspaceService {
  /// Fetch workspaces from backend API
  static Future<List<Map<String, dynamic>>> listWorkspaces(String userId) async {
    try {
      final response = await ApiClient.get('workspaces');
      final data = response as Map<String, dynamic>;
      final workspacesData = data['workspaces'] as List;
      
      final workspaces = <Map<String, dynamic>>[];
      
      for (final wsData in workspacesData) {
        final ws = wsData as Map<String, dynamic>;
        final channels = ws['channels'] as List? ?? [];
        
        // Convert to database format
        final workspace = {
          'id': ws['id'] as String,
          'name': ws['name'] as String,
          'slug': ws['slug'] as String,
          'description': ws['description'] as String?,
          'team_id': userId, // Use userId as team_id for compatibility
          'owner_id': userId,
          'workspace_type': 'project',
          'created_at': ws['createdAt'] as String,
          'updated_at': ws['updatedAt'] as String,
        };
        
        workspaces.add(workspace);
        
        // Also save channels to database
        for (final channelData in channels) {
          final ch = channelData as Map<String, dynamic>;
          await DatabaseService.insertChannel({
            'id': ch['id'] as String,
            'workspace_id': ws['id'] as String,
            'name': ch['name'] as String,
            'description': ch['description'] as String?,
            'is_private': 0,
            'created_at': ch['createdAt'] as String,
            'updated_at': ch['updatedAt'] as String,
          });
        }
      }
      
      return workspaces;
    } catch (e) {
      print('WorkspaceService: Error fetching workspaces from API: $e');
      // Fallback to local database
      return await DatabaseService.getUserWorkspaces(userId);
    }
  }
  
  static Future<Map<String, dynamic>> getWorkspaceBootstrap() async {
    // Fetch from backend API - this handles everything including
    // automatically adding new users to the main shared workspace
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      return {'user': {}, 'workspaces': []};
    }
    
    final userId = user['id'] as String;
    
    // Fetch workspaces from backend - the backend automatically
    // ensures all users are members of the main shared workspace
    final workspaces = await listWorkspaces(userId);
    
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
    try {
      // Create channel via backend API
      final response = await ApiClient.post(
        'workspaces/$workspaceId/channels',
        body: {
          'name': name,
          'description': description,
          'private': false,
        },
      );
      
      final channelData = (response as Map<String, dynamic>)['channel'] as Map<String, dynamic>;
      
      // Sync to local database for offline support
      await DatabaseService.insertChannel({
        'id': channelData['id'] as String,
        'workspace_id': workspaceId,
        'name': channelData['name'] as String,
        'description': channelData['description'] as String? ?? '',
        'is_private': 0,
        'created_at': channelData['createdAt'] as String,
        'updated_at': channelData['updatedAt'] as String,
      });
      
      print('FlowSpace: Channel created via API: $name');
      
      return {
        'id': channelData['id'] as String,
        'workspace_id': workspaceId,
        'name': channelData['name'] as String,
        'description': channelData['description'] as String?,
        'created_at': channelData['createdAt'] as String,
      };
    } catch (e) {
      print('WorkspaceService: Error creating channel via API: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getMembers(String workspaceId) async {
    try {
      final response = await ApiClient.get('workspaces/$workspaceId/members');
      return (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (e) {
      print('WorkspaceService: Error fetching members from API: $e');
      return await DatabaseService.getWorkspaceMembers(workspaceId);
    }
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
