import 'package:flutter/foundation.dart';
import '../models/bulletin.dart';
import '../services/message_stream_service.dart';

/// Provider for managing workspace bulletins with real-time updates
class BulletinProvider with ChangeNotifier {
  final MessageStreamService _streamService;

  // workspaceId -> list of bulletins (sorted by priority and date)
  final Map<String, List<Bulletin>> _bulletins = {};

  // Track viewed bulletins per user
  final Set<String> _viewedBulletins = {};

  BulletinProvider(this._streamService) {
    _streamService.bulletinStream.listen(_handleBulletinEvent);
  }

  /// Get all bulletins for a workspace
  List<Bulletin> getBulletins(String workspaceId) {
    return _bulletins[workspaceId] ?? [];
  }

  /// Get active (non-expired) bulletins
  List<Bulletin> getActiveBulletins(String workspaceId) {
    final bulletins = _bulletins[workspaceId] ?? [];
    return bulletins.where((b) => b.isActive).toList();
  }

  /// Get pinned bulletins
  List<Bulletin> getPinnedBulletins(String workspaceId) {
    final bulletins = _bulletins[workspaceId] ?? [];
    return bulletins.where((b) => b.isPinned && b.isActive).toList();
  }

  /// Get bulletins by type
  List<Bulletin> getBulletinsByType(String workspaceId, BulletinType type) {
    final bulletins = _bulletins[workspaceId] ?? [];
    return bulletins.where((b) => b.type == type && b.isActive).toList();
  }

  /// Get bulletins by priority
  List<Bulletin> getBulletinsByPriority(
    String workspaceId,
    BulletinPriority priority,
  ) {
    final bulletins = _bulletins[workspaceId] ?? [];
    return bulletins.where((b) => b.priority == priority && b.isActive).toList();
  }

  /// Get bulletins by tag
  List<Bulletin> getBulletinsByTag(String workspaceId, String tag) {
    final bulletins = _bulletins[workspaceId] ?? [];
    return bulletins.where((b) => b.tags.contains(tag) && b.isActive).toList();
  }

  /// Get a specific bulletin
  Bulletin? getBulletin(String workspaceId, String bulletinId) {
    final bulletins = _bulletins[workspaceId] ?? [];
    try {
      return bulletins.firstWhere((b) => b.id == bulletinId);
    } catch (e) {
      return null;
    }
  }

  /// Get unread bulletins for current user
  List<Bulletin> getUnreadBulletins(String workspaceId) {
    final bulletins = getActiveBulletins(workspaceId);
    return bulletins.where((b) => !_viewedBulletins.contains(b.id)).toList();
  }

  /// Get unread count
  int getUnreadCount(String workspaceId) {
    return getUnreadBulletins(workspaceId).length;
  }

  /// Mark bulletin as viewed
  void markAsViewed(String bulletinId) {
    _viewedBulletins.add(bulletinId);
    notifyListeners();
  }

  /// Check if bulletin is viewed
  bool isViewed(String bulletinId) {
    return _viewedBulletins.contains(bulletinId);
  }

  /// Create a bulletin
  Future<void> createBulletin(BulletinRequest request) async {
    await _streamService.createBulletin(request);
  }

  /// Update a bulletin
  Future<void> updateBulletin(BulletinRequest request) async {
    if (request.id == null) {
      throw ArgumentError('Bulletin ID is required for update');
    }
    await _streamService.updateBulletin(request);
  }

  /// Delete a bulletin
  Future<void> deleteBulletin(String workspaceId, String bulletinId) async {
    await _streamService.deleteBulletin(workspaceId, bulletinId);
  }

  /// Pin a bulletin
  Future<void> pinBulletin(String workspaceId, String bulletinId) async {
    await _streamService.pinBulletin(workspaceId, bulletinId);
  }

  /// Unpin a bulletin
  Future<void> unpinBulletin(String workspaceId, String bulletinId) async {
    await _streamService.unpinBulletin(workspaceId, bulletinId);
  }

  /// Load bulletins for a workspace (from server/cache)
  void setBulletins(String workspaceId, List<Bulletin> bulletins) {
    _bulletins[workspaceId] = _sortBulletins(bulletins);
    notifyListeners();
  }

  /// Clear bulletins for a workspace
  void clearWorkspaceBulletins(String workspaceId) {
    _bulletins.remove(workspaceId);
    notifyListeners();
  }

  /// Clear all bulletins
  void clearAll() {
    _bulletins.clear();
    _viewedBulletins.clear();
    notifyListeners();
  }

  /// Handle incoming bulletin events from WebSocket
  void _handleBulletinEvent(BulletinEvent event) {
    switch (event.action) {
      case BulletinAction.created:
        if (event.bulletin != null) {
          _addBulletin(event.workspaceId, event.bulletin!);
        }
        break;
      case BulletinAction.updated:
        if (event.bulletin != null) {
          _updateBulletin(event.workspaceId, event.bulletin!);
        }
        break;
      case BulletinAction.deleted:
        _removeBulletin(event.workspaceId, event.bulletinId);
        break;
      case BulletinAction.pinned:
        if (event.bulletin != null) {
          _updateBulletin(event.workspaceId, event.bulletin!);
        }
        break;
      case BulletinAction.unpinned:
        if (event.bulletin != null) {
          _updateBulletin(event.workspaceId, event.bulletin!);
        }
        break;
    }
  }

  /// Add a bulletin to the list
  void _addBulletin(String workspaceId, Bulletin bulletin) {
    _bulletins.putIfAbsent(workspaceId, () => []);
    final bulletins = _bulletins[workspaceId]!;

    // Remove if already exists
    bulletins.removeWhere((b) => b.id == bulletin.id);

    // Add and sort
    bulletins.add(bulletin);
    _bulletins[workspaceId] = _sortBulletins(bulletins);
    notifyListeners();
  }

  /// Update a bulletin in the list
  void _updateBulletin(String workspaceId, Bulletin bulletin) {
    final bulletins = _bulletins[workspaceId];
    if (bulletins != null) {
      final index = bulletins.indexWhere((b) => b.id == bulletin.id);
      if (index != -1) {
        bulletins[index] = bulletin;
        _bulletins[workspaceId] = _sortBulletins(bulletins);
        notifyListeners();
      }
    }
  }

  /// Remove a bulletin from the list
  void _removeBulletin(String workspaceId, String bulletinId) {
    final bulletins = _bulletins[workspaceId];
    if (bulletins != null) {
      bulletins.removeWhere((b) => b.id == bulletinId);
      _viewedBulletins.remove(bulletinId);
      notifyListeners();
    }
  }

  /// Sort bulletins: pinned first, then by priority, then by date
  List<Bulletin> _sortBulletins(List<Bulletin> bulletins) {
    final sorted = List<Bulletin>.from(bulletins);
    sorted.sort((a, b) {
      // Pinned first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      // Then by priority (urgent first)
      final priorityOrder = {
        BulletinPriority.urgent: 0,
        BulletinPriority.high: 1,
        BulletinPriority.normal: 2,
        BulletinPriority.low: 3,
      };
      final aPriority = priorityOrder[a.priority] ?? 2;
      final bPriority = priorityOrder[b.priority] ?? 2;
      if (aPriority != bPriority) return aPriority.compareTo(bPriority);

      // Then by date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }

  /// Search bulletins by title or content
  List<Bulletin> searchBulletins(String workspaceId, String query) {
    final bulletins = getActiveBulletins(workspaceId);
    if (query.isEmpty) return bulletins;

    final lowerQuery = query.toLowerCase();
    return bulletins.where((b) {
      return b.title.toLowerCase().contains(lowerQuery) ||
          b.content.toLowerCase().contains(lowerQuery) ||
          b.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Get all unique tags used in bulletins
  List<String> getAllTags(String workspaceId) {
    final bulletins = _bulletins[workspaceId] ?? [];
    final tags = <String>{};
    for (final bulletin in bulletins) {
      tags.addAll(bulletin.tags);
    }
    return tags.toList()..sort();
  }

  /// Get bulletins expiring soon (within next 7 days)
  List<Bulletin> getExpiringSoonBulletins(String workspaceId) {
    final bulletins = getActiveBulletins(workspaceId);
    final now = DateTime.now();
    final sevenDaysFromNow = now.add(const Duration(days: 7));

    return bulletins.where((b) {
      return b.expiresAt != null &&
          b.expiresAt!.isAfter(now) &&
          b.expiresAt!.isBefore(sevenDaysFromNow);
    }).toList();
  }
}
