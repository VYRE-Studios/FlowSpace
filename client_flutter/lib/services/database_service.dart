import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'secure_storage_service.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    // Initialize FFI for desktop platforms that use the local/offline store.
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Local SQLite database is only used for caching
    // All workspace/channel/message data comes from backend API
    final appDir = await getApplicationSupportDirectory();
    final dbPath = join(appDir.path, 'flowspace.db');
    print('FlowSpace: Using local database (cache only) at: $dbPath');

    return await openDatabase(
      dbPath,
      version: 5,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE teams (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (owner_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT,
        avatar_url TEXT,
        status TEXT DEFAULT 'offline',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE workspaces (
        id TEXT PRIMARY KEY,
        team_id TEXT NOT NULL,
        name TEXT NOT NULL,
        slug TEXT NOT NULL,
        description TEXT,
        workspace_type TEXT DEFAULT 'project',
        owner_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (team_id) REFERENCES teams (id) ON DELETE CASCADE,
        FOREIGN KEY (owner_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE workspace_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workspace_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        role TEXT DEFAULT 'member',
        joined_at TEXT NOT NULL,
        FOREIGN KEY (workspace_id) REFERENCES workspaces (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(workspace_id, user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE channels (
        id TEXT PRIMARY KEY,
        workspace_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        is_private INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (workspace_id) REFERENCES workspaces (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        channel_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        sender_name TEXT NOT NULL,
        content TEXT NOT NULL,
        parent_id TEXT,
        encrypted_content TEXT,
        encrypted_nonce TEXT,
        encrypted_mac TEXT,
        encryption_version INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (channel_id) REFERENCES channels (id) ON DELETE CASCADE,
        FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (parent_id) REFERENCES messages (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE vault_files (
        id TEXT PRIMARY KEY,
        workspace_id TEXT NOT NULL,
        name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        size INTEGER NOT NULL,
        mime_type TEXT,
        folder TEXT DEFAULT 'shared',
        uploaded_by TEXT NOT NULL,
        uploaded_at TEXT NOT NULL,
        is_encrypted INTEGER DEFAULT 0,
        encrypted_nonce TEXT,
        encrypted_mac TEXT,
        encryption_version INTEGER DEFAULT 0,
        FOREIGN KEY (workspace_id) REFERENCES workspaces (id) ON DELETE CASCADE,
        FOREIGN KEY (uploaded_by) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');

    // Indexes for performance
    await db.execute(
      'CREATE INDEX idx_workspace_members_workspace ON workspace_members(workspace_id)',
    );
    await db.execute(
      'CREATE INDEX idx_workspace_members_user ON workspace_members(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_channels_workspace ON channels(workspace_id)',
    );
    await db.execute(
      'CREATE INDEX idx_messages_channel ON messages(channel_id)',
    );
    await db.execute(
      'CREATE INDEX idx_messages_created ON messages(created_at)',
    );
    await db.execute(
      'CREATE INDEX idx_vault_files_workspace ON vault_files(workspace_id)',
    );
    await db.execute(
      'CREATE INDEX idx_vault_files_folder ON vault_files(folder)',
    );

    // Project management tables
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        workspace_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        project_type TEXT,
        template_id TEXT,
        status TEXT DEFAULT 'active',
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (workspace_id) REFERENCES workspaces (id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        workspace_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT DEFAULT 'backlog',
        priority TEXT DEFAULT 'medium',
        assigned_to TEXT,
        created_by TEXT NOT NULL,
        due_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE,
        FOREIGN KEY (workspace_id) REFERENCES workspaces (id) ON DELETE CASCADE,
        FOREIGN KEY (assigned_to) REFERENCES users (id) ON DELETE SET NULL,
        FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE task_comments (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_projects_workspace ON projects(workspace_id)',
    );
    await db.execute('CREATE INDEX idx_tasks_project ON tasks(project_id)');
    await db.execute('CREATE INDEX idx_tasks_workspace ON tasks(workspace_id)');
    await db.execute('CREATE INDEX idx_tasks_status ON tasks(status)');
    await db.execute('CREATE INDEX idx_tasks_assigned ON tasks(assigned_to)');
    await db.execute(
      'CREATE INDEX idx_task_comments_task ON task_comments(task_id)',
    );

    // Meetings table
    await db.execute('''
      CREATE TABLE meetings (
        id TEXT PRIMARY KEY,
        workspace_id TEXT NOT NULL,
        room_name TEXT NOT NULL,
        title TEXT NOT NULL,
        started_by TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        status TEXT DEFAULT 'active',
        FOREIGN KEY (workspace_id) REFERENCES workspaces (id) ON DELETE CASCADE,
        FOREIGN KEY (started_by) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_meetings_workspace ON meetings(workspace_id)',
    );
    await db.execute('CREATE INDEX idx_meetings_status ON meetings(status)');

    // Whiteboard tables
    await db.execute('''
      CREATE TABLE whiteboard_elements (
        id TEXT PRIMARY KEY,
        workspace_id TEXT NOT NULL,
        element_type TEXT NOT NULL,
        data TEXT NOT NULL,
        x REAL NOT NULL,
        y REAL NOT NULL,
        z_index INTEGER DEFAULT 0,
        color TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (workspace_id) REFERENCES workspaces (id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_whiteboard_workspace ON whiteboard_elements(workspace_id)',
    );
    await db.execute(
      'CREATE INDEX idx_whiteboard_zindex ON whiteboard_elements(z_index)',
    );

    // Document tables
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        workspace_id TEXT NOT NULL,
        title TEXT NOT NULL,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (workspace_id) REFERENCES workspaces (id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE document_blocks (
        id TEXT PRIMARY KEY,
        document_id TEXT NOT NULL,
        block_type TEXT NOT NULL,
        content TEXT NOT NULL,
        block_order INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_documents_workspace ON documents(workspace_id)',
    );
    await db.execute(
      'CREATE INDEX idx_document_blocks_document ON document_blocks(document_id)',
    );
    await db.execute(
      'CREATE INDEX idx_document_blocks_order ON document_blocks(block_order)',
    );

    print('FlowSpace: Database tables created successfully');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    print('FlowSpace: Database upgrade from $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Add encryption fields to messages table
      await db.execute(
        'ALTER TABLE messages ADD COLUMN encrypted_content TEXT',
      );
      await db.execute('ALTER TABLE messages ADD COLUMN encrypted_nonce TEXT');
      await db.execute('ALTER TABLE messages ADD COLUMN encrypted_mac TEXT');
      await db.execute(
        'ALTER TABLE messages ADD COLUMN encryption_version INTEGER DEFAULT 0',
      );

      // Add encryption fields to vault_files table
      await db.execute(
        'ALTER TABLE vault_files ADD COLUMN is_encrypted INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE vault_files ADD COLUMN encrypted_nonce TEXT',
      );
      await db.execute('ALTER TABLE vault_files ADD COLUMN encrypted_mac TEXT');
      await db.execute(
        'ALTER TABLE vault_files ADD COLUMN encryption_version INTEGER DEFAULT 0',
      );

      print(
        'FlowSpace: Added encryption fields to messages and vault_files tables',
      );
    }

    if (oldVersion < 4) {
      // Add parent_id column for threaded conversations
      await db.execute('ALTER TABLE messages ADD COLUMN parent_id TEXT');
      print(
        'FlowSpace: Added parent_id column to messages table for threading support',
      );
    }

    if (oldVersion < 5) {
      // Add project_type and template_id columns to projects table
      try {
        await db.execute('ALTER TABLE projects ADD COLUMN project_type TEXT');
        await db.execute('ALTER TABLE projects ADD COLUMN template_id TEXT');
        print(
          'FlowSpace: Added project_type and template_id columns to projects table',
        );
      } catch (e) {
        print(
          'FlowSpace: Error adding project columns (may already exist): $e',
        );
      }
    }
  }

  // User operations
  static Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert(
      'users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('FlowSpace: User inserted: ${user['email']}');
  }

  static Future<Map<String, dynamic>?> getUser(String userId) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return results.isNotEmpty ? results.first : null;
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    // Get current user ID from secure storage (actual logged-in user)
    final userId = await SecureStorageService.getCurrentUserId();
    if (userId == null) {
      // Fallback: get most recent user (for backward compatibility)
      final db = await database;
      final results = await db.query(
        'users',
        limit: 1,
        orderBy: 'created_at DESC',
      );
      return results.isNotEmpty ? results.first : null;
    }

    // Get user by ID from secure storage
    final db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Team operations
  static Future<void> insertTeam(Map<String, dynamic> team) async {
    final db = await database;
    await db.insert(
      'teams',
      team,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('FlowSpace: Team inserted: ${team['name']}');
  }

  static Future<Map<String, dynamic>?> getUserTeam(String userId) async {
    final db = await database;
    final results = await db.query(
      'teams',
      where: 'owner_id = ?',
      whereArgs: [userId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Workspace operations
  static Future<void> insertWorkspace(Map<String, dynamic> workspace) async {
    final db = await database;
    await db.insert(
      'workspaces',
      workspace,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('FlowSpace: Workspace inserted: ${workspace['name']}');
  }

  static Future<Map<String, dynamic>?> getWorkspace(String workspaceId) async {
    final db = await database;
    final results = await db.query(
      'workspaces',
      where: 'id = ?',
      whereArgs: [workspaceId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  static Future<void> deleteWorkspace(String workspaceId) async {
    final db = await database;
    // Delete vault files first (they don't have CASCADE)
    await db.delete(
      'vault_files',
      where: 'workspace_id = ?',
      whereArgs: [workspaceId],
    );
    // CASCADE will handle related data (members, channels, messages, projects, tasks, etc.)
    await db.delete('workspaces', where: 'id = ?', whereArgs: [workspaceId]);
    print('FlowSpace: Workspace deleted: $workspaceId');
  }

  static Future<List<Map<String, dynamic>>> getUserWorkspaces(
    String userId,
  ) async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT w.* FROM workspaces w
      INNER JOIN workspace_members wm ON w.id = wm.workspace_id
      WHERE wm.user_id = ?
      ORDER BY w.created_at DESC
    ''',
      [userId],
    );
    return results;
  }

  // Workspace member operations
  static Future<void> addWorkspaceMember(Map<String, dynamic> member) async {
    final db = await database;
    await db.insert(
      'workspace_members',
      member,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getWorkspaceMembers(
    String workspaceId,
  ) async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT u.*, wm.role, wm.joined_at FROM users u
      INNER JOIN workspace_members wm ON u.id = wm.user_id
      WHERE wm.workspace_id = ?
      ORDER BY wm.joined_at ASC
    ''',
      [workspaceId],
    );
    return results;
  }

  // Channel operations
  static Future<void> insertChannel(Map<String, dynamic> channel) async {
    final db = await database;
    await db.insert(
      'channels',
      channel,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('FlowSpace: Channel inserted: ${channel['name']}');
  }

  static Future<List<Map<String, dynamic>>> getWorkspaceChannels(
    String workspaceId,
  ) async {
    final db = await database;
    final results = await db.query(
      'channels',
      where: 'workspace_id = ?',
      whereArgs: [workspaceId],
      orderBy: 'created_at ASC',
    );
    return results;
  }

  // Message operations
  static Future<void> insertMessage(Map<String, dynamic> message) async {
    final db = await database;
    await db.insert(
      'messages',
      message,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getChannelMessages(
    String channelId, {
    int limit = 100,
  }) async {
    final db = await database;
    final results = await db.query(
      'messages',
      where: 'channel_id = ?',
      whereArgs: [channelId],
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return results;
  }

  // Vault file operations
  static Future<void> insertVaultFile(Map<String, dynamic> file) async {
    final db = await database;
    await db.insert(
      'vault_files',
      file,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('FlowSpace: Vault file inserted: ${file['name']}');
  }

  static Future<List<Map<String, dynamic>>> getWorkspaceVaultFiles(
    String workspaceId, {
    String? folder,
  }) async {
    final db = await database;
    if (folder != null) {
      final results = await db.query(
        'vault_files',
        where: 'workspace_id = ? AND folder = ?',
        whereArgs: [workspaceId, folder],
        orderBy: 'uploaded_at DESC',
      );
      return results;
    } else {
      final results = await db.query(
        'vault_files',
        where: 'workspace_id = ?',
        whereArgs: [workspaceId],
        orderBy: 'uploaded_at DESC',
      );
      return results;
    }
  }

  // Project operations
  static Future<void> insertProject(Map<String, dynamic> project) async {
    final db = await database;
    await db.insert(
      'projects',
      project,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('FlowSpace: Project inserted: ${project['name']}');
  }

  static Future<List<Map<String, dynamic>>> getWorkspaceProjects(
    String workspaceId,
  ) async {
    final db = await database;
    final results = await db.query(
      'projects',
      where: 'workspace_id = ?',
      whereArgs: [workspaceId],
      orderBy: 'created_at DESC',
    );
    return results;
  }

  static Future<Map<String, dynamic>?> getProject(String projectId) async {
    final db = await database;
    final results = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [projectId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Task operations
  static Future<void> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    await db.insert(
      'tasks',
      task,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('FlowSpace: Task inserted: ${task['title']}');
  }

  static Future<void> updateTask(
    String taskId,
    Map<String, dynamic> updates,
  ) async {
    final db = await database;
    await db.update('tasks', updates, where: 'id = ?', whereArgs: [taskId]);
  }

  static Future<List<Map<String, dynamic>>> getProjectTasks(
    String projectId,
  ) async {
    final db = await database;
    final results = await db.query(
      'tasks',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'created_at ASC',
    );
    return results;
  }

  static Future<List<Map<String, dynamic>>> getTasksByStatus(
    String projectId,
    String status,
  ) async {
    final db = await database;
    final results = await db.query(
      'tasks',
      where: 'project_id = ? AND status = ?',
      whereArgs: [projectId, status],
      orderBy: 'created_at ASC',
    );
    return results;
  }

  static Future<void> deleteTask(String taskId) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  // Task comment operations
  static Future<void> insertTaskComment(Map<String, dynamic> comment) async {
    final db = await database;
    await db.insert('task_comments', comment);
  }

  static Future<List<Map<String, dynamic>>> getTaskComments(
    String taskId,
  ) async {
    final db = await database;
    final results = await db.query(
      'task_comments',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'created_at ASC',
    );
    return results;
  }

  // Meeting operations
  static Future<void> insertMeeting(Map<String, dynamic> meeting) async {
    final db = await database;
    await db.insert(
      'meetings',
      meeting,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('FlowSpace: Meeting inserted: ${meeting['title']}');
  }

  static Future<List<Map<String, dynamic>>> getWorkspaceMeetings(
    String workspaceId, {
    String status = 'active',
  }) async {
    final db = await database;
    final results = await db.query(
      'meetings',
      where: 'workspace_id = ? AND status = ?',
      whereArgs: [workspaceId, status],
      orderBy: 'started_at DESC',
    );
    return results;
  }

  static Future<void> endMeeting(String meetingId) async {
    final db = await database;
    await db.update(
      'meetings',
      {'ended_at': DateTime.now().toIso8601String(), 'status': 'ended'},
      where: 'id = ?',
      whereArgs: [meetingId],
    );
  }

  // Whiteboard operations
  static Future<void> insertWhiteboardElement(
    Map<String, dynamic> element,
  ) async {
    final db = await database;
    await db.insert(
      'whiteboard_elements',
      element,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getWorkspaceWhiteboardElements(
    String workspaceId,
  ) async {
    final db = await database;
    final results = await db.query(
      'whiteboard_elements',
      where: 'workspace_id = ?',
      whereArgs: [workspaceId],
      orderBy: 'z_index ASC',
    );
    return results;
  }

  static Future<void> updateWhiteboardElement(
    String elementId,
    Map<String, dynamic> updates,
  ) async {
    final db = await database;
    await db.update(
      'whiteboard_elements',
      updates,
      where: 'id = ?',
      whereArgs: [elementId],
    );
  }

  static Future<void> deleteWhiteboardElement(String elementId) async {
    final db = await database;
    await db.delete(
      'whiteboard_elements',
      where: 'id = ?',
      whereArgs: [elementId],
    );
  }

  // Document operations
  static Future<void> insertDocument(Map<String, dynamic> document) async {
    final db = await database;
    await db.insert(
      'documents',
      document,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('FlowSpace: Document inserted: ${document['title']}');
  }

  static Future<List<Map<String, dynamic>>> getWorkspaceDocuments(
    String workspaceId,
  ) async {
    final db = await database;
    final results = await db.query(
      'documents',
      where: 'workspace_id = ?',
      whereArgs: [workspaceId],
      orderBy: 'updated_at DESC',
    );
    return results;
  }

  static Future<Map<String, dynamic>?> getDocument(String documentId) async {
    final db = await database;
    final results = await db.query(
      'documents',
      where: 'id = ?',
      whereArgs: [documentId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  static Future<void> updateDocument(
    String documentId,
    Map<String, dynamic> updates,
  ) async {
    final db = await database;
    await db.update(
      'documents',
      updates,
      where: 'id = ?',
      whereArgs: [documentId],
    );
  }

  static Future<void> insertDocumentBlock(Map<String, dynamic> block) async {
    final db = await database;
    await db.insert(
      'document_blocks',
      block,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getDocumentBlocks(
    String documentId,
  ) async {
    final db = await database;
    final results = await db.query(
      'document_blocks',
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'block_order ASC',
    );
    return results;
  }

  static Future<void> updateDocumentBlock(
    String blockId,
    Map<String, dynamic> updates,
  ) async {
    final db = await database;
    await db.update(
      'document_blocks',
      updates,
      where: 'id = ?',
      whereArgs: [blockId],
    );
  }

  static Future<void> deleteDocumentBlock(String blockId) async {
    final db = await database;
    await db.delete('document_blocks', where: 'id = ?', whereArgs: [blockId]);
  }

  // Utility operations
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete('vault_files');
    await db.delete('messages');
    await db.delete('channels');
    await db.delete('workspace_members');
    await db.delete('workspaces');
    await db.delete('users');
    print('FlowSpace: All data cleared');
  }

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
