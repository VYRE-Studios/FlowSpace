// lib/assets/asset_importer.dart

import 'dart:io';
import 'package:path/path.dart' as p;

import 'asset_model.dart';
import 'asset_registry.dart';
import 'checksum.dart';
import '../sync/sync_manager.dart';
import '../sync/sync_op_types.dart';

class AssetImporter {
  final AssetRegistry registry;
  final String projectId;
  final String boardId;

  AssetImporter({
    required this.registry,
    required this.projectId,
    required this.boardId,
  });

  Future<AssetModel> importFile(File file) async {
    // Ensure asset directory exists
    registry.ensureAssetDirectory(projectId, boardId);

    // Generate checksum for deduplication
    final checksum = await fileChecksum(file);

    // Check if asset already exists
    final manifest = await registry.loadManifest(projectId, boardId);
    final existing = manifest.assets.where((a) => a.checksum == checksum).firstOrNull;
    if (existing != null) {
      return existing; // Already imported
    }

    // Get file extension and type
    final ext = p.extension(file.path).replaceFirst('.', '');
    final type = parseAssetType(ext);

    // Copy file to board's asset directory
    final destDir = registry.getAssetDirectoryPath(projectId, boardId);
    final fileName = p.basename(file.path);
    final destPath = '$destDir/$fileName';
    
    await file.copy(destPath);

    // Get file size
    final stat = await File(destPath).stat();

    // Create asset model
    final asset = AssetModel(
      id: checksum,
      fileName: fileName,
      filePath: 'files/$fileName', // Relative path
      type: type,
      fileSize: stat.size,
      checksum: checksum,
      importedAt: DateTime.now(),
    );

    // Add to manifest
    manifest.assets.add(asset);
    await registry.saveManifest(projectId, boardId, manifest);

    // Broadcast import to collaborators
    SyncManager.instance.send(
      boardId,
      SyncOp.assetImported,
      asset.toJson(),
    );

    return asset;
  }

  Future<List<AssetModel>> importFiles(List<File> files) async {
    final assets = <AssetModel>[];
    for (final file in files) {
      try {
        final asset = await importFile(file);
        assets.add(asset);
      } catch (e) {
        // Log error but continue with other files
        print('Failed to import ${file.path}: $e');
      }
    }
    return assets;
  }
}
