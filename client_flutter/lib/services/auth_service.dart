import 'database_service.dart';
import 'vault_storage_service.dart';
import 'encryption_service.dart';
import 'secure_storage_service.dart';

class AuthService {

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String workspaceName,
  }) async {
    try {
      print('FlowSpace: Starting registration for $email');
      
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      final teamId = '${userId}_team';
      final workspaceId = '${userId}_ws';
      
      print('FlowSpace: Generated userId=$userId, teamId=$teamId, workspaceId=$workspaceId');
      
      // Create full user profile
      final user = {
        'id': userId,
        'name': name,
        'email': email,
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      final now = DateTime.now();
      
      // Create team (organization level)
      final team = {
        'id': teamId,
        'name': workspaceName,
        'ownerId': userId,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };
      
      // Create default workspace (General workspace within the team)
      final workspace = {
        'id': workspaceId,
        'name': 'General',
        'slug': 'general',
        'description': 'General workspace for team collaboration',
        'workspace_type': 'project',
        'ownerId': userId,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };
      
      // Create default channels
      final channels = [
        {
          'id': '${workspaceId}_general',
          'name': 'general',
          'workspaceId': workspaceId,
          'description': 'General discussion',
          'createdAt': DateTime.now().toIso8601String(),
        },
        {
          'id': '${workspaceId}_random',
          'name': 'random',
          'workspaceId': workspaceId,
          'description': 'Random chat',
          'createdAt': DateTime.now().toIso8601String(),
        },
      ];
      
      // Save to SQLite database
      print('FlowSpace: Saving user to database...');
      await DatabaseService.insertUser({
        'id': userId,
        'name': name,
        'email': email,
        'password_hash': null,
        'avatar_url': null,
        'status': 'online',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      
      print('FlowSpace: Creating team...');
      await DatabaseService.insertTeam({
        'id': teamId,
        'name': workspaceName,
        'owner_id': userId,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      
      print('FlowSpace: Creating default workspace (General)...');
      await DatabaseService.insertWorkspace({
        'id': workspaceId,
        'team_id': teamId,
        'name': 'General',
        'slug': 'general',
        'description': 'General workspace for team collaboration',
        'workspace_type': 'project',
        'owner_id': userId,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      
      print('FlowSpace: Adding workspace member...');
      await DatabaseService.addWorkspaceMember({
        'workspace_id': workspaceId,
        'user_id': userId,
        'role': 'owner',
        'joined_at': now.toIso8601String(),
      });
      
      print('FlowSpace: Creating default channels...');
      for (final channel in channels) {
        await DatabaseService.insertChannel({
          'id': channel['id'],
          'workspace_id': workspaceId,
          'name': channel['name'],
          'description': channel['description'],
          'is_private': 0,
          'created_at': channel['createdAt'],
          'updated_at': channel['createdAt'],
        });
      }
      
      print('FlowSpace: Creating vault directories...');
      await VaultStorageService.getVaultPath(workspaceId, folder: 'shared');
      await VaultStorageService.getVaultPath(workspaceId, folder: 'personal');
      
      // Generate master encryption key and store securely
      print('FlowSpace: Generating master encryption key...');
      final masterKey = await EncryptionService.generateMasterKey();
      
      // Encrypt master key with password-derived key
      print('FlowSpace: Encrypting master key with password...');
      final encryptedMasterKey = await EncryptionService.encryptMasterKey(
        masterKey,
        password,
      );
      
      // Store encrypted master key in secure storage
      print('FlowSpace: Storing encrypted master key in secure storage...');
      await SecureStorageService.storeEncryptedMasterKey(userId, encryptedMasterKey);
      await SecureStorageService.setCurrentUserId(userId);
      
      print('FlowSpace: Registration complete!');
      print('FlowSpace: Team: $workspaceName (organization)');
      print('FlowSpace: Default Workspace: General');
      print('FlowSpace: Owner: $name');
      print('FlowSpace: Channels: #general, #random');
      print('FlowSpace: Vault: initialized');
      print('FlowSpace: Encryption: Master key generated and secured');
      
      // Registration complete - return success
      return {
        'success': true,
        'localOnly': true,
        'user': user,
        'team': team,
        'workspace': workspace,
        'channels': channels,
      };
    } catch (e, stack) {
      print('FlowSpace: ERROR in registration: $e');
      print('FlowSpace: Stack trace: $stack');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    return await DatabaseService.getCurrentUser();
  }
}
