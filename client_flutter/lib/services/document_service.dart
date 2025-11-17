import 'database_service.dart';
import 'auth_service.dart';

/// Document service for FlowSpace wiki-style documents
/// Manages documents with rich text blocks (headings, paragraphs, lists, code)
class DocumentService {
  /// Create a new document in workspace
  static Future<String> createDocument({
    required String workspaceId,
    required String title,
  }) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) throw Exception('No user found');

    final documentId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().toIso8601String();

    await DatabaseService.insertDocument({
      'id': documentId,
      'workspace_id': workspaceId,
      'title': title,
      'created_by': user['id'],
      'created_at': now,
      'updated_at': now,
    });

    // Create initial empty paragraph block
    await addBlock(
      documentId: documentId,
      blockType: 'paragraph',
      content: '',
      order: 0,
    );

    print('FlowSpace: Document created: $title');
    return documentId;
  }

  /// Get all documents in a workspace
  static Future<List<Map<String, dynamic>>> getWorkspaceDocuments(String workspaceId) async {
    return await DatabaseService.getWorkspaceDocuments(workspaceId);
  }

  /// Get a specific document
  static Future<Map<String, dynamic>?> getDocument(String documentId) async {
    return await DatabaseService.getDocument(documentId);
  }

  /// Update document title
  static Future<void> updateDocumentTitle({
    required String documentId,
    required String title,
  }) async {
    await DatabaseService.updateDocument(documentId, {
      'title': title,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Add a block to document
  static Future<String> addBlock({
    required String documentId,
    required String blockType,
    required String content,
    required int order,
  }) async {
    final blockId = '${DateTime.now().millisecondsSinceEpoch}_${order}';
    final now = DateTime.now().toIso8601String();

    await DatabaseService.insertDocumentBlock({
      'id': blockId,
      'document_id': documentId,
      'block_type': blockType,
      'content': content,
      'block_order': order,
      'created_at': now,
      'updated_at': now,
    });

    await _touchDocument(documentId);
    return blockId;
  }

  /// Get all blocks in a document
  static Future<List<Map<String, dynamic>>> getDocumentBlocks(String documentId) async {
    return await DatabaseService.getDocumentBlocks(documentId);
  }

  /// Update block content
  static Future<void> updateBlockContent({
    required String blockId,
    required String content,
  }) async {
    await DatabaseService.updateDocumentBlock(blockId, {
      'content': content,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Update block type (e.g., paragraph -> heading)
  static Future<void> updateBlockType({
    required String blockId,
    required String blockType,
  }) async {
    await DatabaseService.updateDocumentBlock(blockId, {
      'block_type': blockType,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Reorder blocks
  static Future<void> reorderBlocks({
    required String documentId,
    required List<String> blockIds,
  }) async {
    for (int i = 0; i < blockIds.length; i++) {
      await DatabaseService.updateDocumentBlock(blockIds[i], {
        'block_order': i,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
    await _touchDocument(documentId);
  }

  /// Delete a block
  static Future<void> deleteBlock(String blockId) async {
    await DatabaseService.deleteDocumentBlock(blockId);
  }

  /// Delete entire document
  static Future<void> deleteDocument(String documentId) async {
    // Delete all blocks first
    final blocks = await getDocumentBlocks(documentId);
    for (final block in blocks) {
      await DatabaseService.deleteDocumentBlock(block['id'] as String);
    }
    
    // Delete document (will cascade in DB anyway)
    final db = await DatabaseService.database;
    await db.delete('documents', where: 'id = ?', whereArgs: [documentId]);
  }

  /// Update document's updated_at timestamp
  static Future<void> _touchDocument(String documentId) async {
    await DatabaseService.updateDocument(documentId, {
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
