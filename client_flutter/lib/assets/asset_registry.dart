// lib/assets/asset_registry.dart

import 'dart:convert';
import 'dart:io';

import 'board_asset_manifest.dart';

class AssetRegistry {
  final String workspacePath;

  AssetRegistry({required this.workspacePath});

  Future<BoardAssetManifest> loadManifest(
      String projectId, String boardId) async {
    final path = '$workspacePath/$projectId/$boardId/assets.json';
    final file = File(path);

    if (file.existsSync()) {
      final decoded = jsonDecode(await file.readAsString());
      return BoardAssetManifest.fromJson(decoded);
    }

    return BoardAssetManifest(assets: []);
  }

  Future<void> saveManifest(
      String projectId, String boardId, BoardAssetManifest manifest) async {
    final dir = Directory('$workspacePath/$projectId/$boardId');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final file = File('${dir.path}/assets.json');
    await file.writeAsString(jsonEncode(manifest.toJson()));
  }

  String getAssetDirectoryPath(String projectId, String boardId) {
    return '$workspacePath/$projectId/$boardId/files';
  }

  void ensureAssetDirectory(String projectId, String boardId) {
    final dir = Directory(getAssetDirectoryPath(projectId, boardId));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }
}
