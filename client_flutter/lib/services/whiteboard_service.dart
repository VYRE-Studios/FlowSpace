import 'dart:convert';
import 'database_service.dart';
import 'auth_service.dart';

/// Whiteboard service for FlowSpace collaborative canvas
/// Manages drawing strokes, shapes, sticky notes, and text elements
class WhiteboardService {
  /// Add a drawing stroke to the whiteboard
  static Future<void> addStroke({
    required String workspaceId,
    required List<Map<String, double>> points,
    required String color,
    required double strokeWidth,
  }) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) throw Exception('No user found');

    final elementId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().toIso8601String();

    final strokeData = {
      'points': points,
      'strokeWidth': strokeWidth,
    };

    await DatabaseService.insertWhiteboardElement({
      'id': elementId,
      'workspace_id': workspaceId,
      'element_type': 'stroke',
      'data': jsonEncode(strokeData),
      'x': points.first['x'],
      'y': points.first['y'],
      'z_index': await _getNextZIndex(workspaceId),
      'color': color,
      'created_by': user['id'],
      'created_at': now,
      'updated_at': now,
    });
  }

  /// Add a sticky note to the whiteboard
  static Future<void> addStickyNote({
    required String workspaceId,
    required double x,
    required double y,
    required String content,
    required String color,
  }) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) throw Exception('No user found');

    final elementId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().toIso8601String();

    final noteData = {
      'content': content,
      'width': 200.0,
      'height': 200.0,
    };

    await DatabaseService.insertWhiteboardElement({
      'id': elementId,
      'workspace_id': workspaceId,
      'element_type': 'sticky_note',
      'data': jsonEncode(noteData),
      'x': x,
      'y': y,
      'z_index': await _getNextZIndex(workspaceId),
      'color': color,
      'created_by': user['id'],
      'created_at': now,
      'updated_at': now,
    });
  }

  /// Add a text box to the whiteboard
  static Future<void> addTextBox({
    required String workspaceId,
    required double x,
    required double y,
    required String content,
  }) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) throw Exception('No user found');

    final elementId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().toIso8601String();

    final textData = {
      'content': content,
      'fontSize': 16.0,
    };

    await DatabaseService.insertWhiteboardElement({
      'id': elementId,
      'workspace_id': workspaceId,
      'element_type': 'text',
      'data': jsonEncode(textData),
      'x': x,
      'y': y,
      'z_index': await _getNextZIndex(workspaceId),
      'color': '#000000',
      'created_by': user['id'],
      'created_at': now,
      'updated_at': now,
    });
  }

  /// Add a shape (rectangle, circle, arrow) to the whiteboard
  static Future<void> addShape({
    required String workspaceId,
    required String shapeType,
    required double x,
    required double y,
    required double width,
    required double height,
    required String color,
  }) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) throw Exception('No user found');

    final elementId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().toIso8601String();

    final shapeData = {
      'shapeType': shapeType,
      'width': width,
      'height': height,
    };

    await DatabaseService.insertWhiteboardElement({
      'id': elementId,
      'workspace_id': workspaceId,
      'element_type': 'shape',
      'data': jsonEncode(shapeData),
      'x': x,
      'y': y,
      'z_index': await _getNextZIndex(workspaceId),
      'color': color,
      'created_by': user['id'],
      'created_at': now,
      'updated_at': now,
    });
  }

  /// Get all whiteboard elements for a workspace
  static Future<List<Map<String, dynamic>>> getWorkspaceElements(String workspaceId) async {
    return await DatabaseService.getWorkspaceWhiteboardElements(workspaceId);
  }

  /// Update element position
  static Future<void> updateElementPosition({
    required String elementId,
    required double x,
    required double y,
  }) async {
    await DatabaseService.updateWhiteboardElement(elementId, {
      'x': x,
      'y': y,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Update element data (e.g., sticky note content)
  static Future<void> updateElementData({
    required String elementId,
    required Map<String, dynamic> data,
  }) async {
    await DatabaseService.updateWhiteboardElement(elementId, {
      'data': jsonEncode(data),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Delete an element
  static Future<void> deleteElement(String elementId) async {
    await DatabaseService.deleteWhiteboardElement(elementId);
  }

  /// Clear all elements from whiteboard
  static Future<void> clearWorkspace(String workspaceId) async {
    final elements = await getWorkspaceElements(workspaceId);
    for (final element in elements) {
      await DatabaseService.deleteWhiteboardElement(element['id'] as String);
    }
  }

  /// Get the next z-index for layering
  static Future<int> _getNextZIndex(String workspaceId) async {
    final elements = await DatabaseService.getWorkspaceWhiteboardElements(workspaceId);
    if (elements.isEmpty) return 0;
    final maxZ = elements.map((e) => e['z_index'] as int? ?? 0).reduce((a, b) => a > b ? a : b);
    return maxZ + 1;
  }
}
