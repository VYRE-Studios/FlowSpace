// lib/assets/thumbnail_service.dart

import 'dart:io';
import 'dart:ui' as ui;

class ThumbnailService {
  /// Generate thumbnail from image file
  static Future<ui.Image?> generateImageThumbnail(
    String filePath, {
    int size = 128,
  }) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;

      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: size,
        targetHeight: size,
      );

      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      print('Failed to generate thumbnail for $filePath: $e');
      return null;
    }
  }

  /// Load image as full resolution (for canvas placement)
  static Future<ui.Image?> loadFullImage(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;

      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      print('Failed to load image $filePath: $e');
      return null;
    }
  }

  /// Generate placeholder icon based on asset type
  static ui.Image? getPlaceholderIcon(String assetType) {
    // Return null for now - could generate simple icons later
    return null;
  }
}
