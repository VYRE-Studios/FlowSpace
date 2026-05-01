import 'dart:io';

/// Atomic file writer to prevent corruption during save operations
/// Uses temp file + rename strategy for atomic writes
class SafeWriter {
  /// Write content to file atomically
  /// 1. Write to temp file
  /// 2. Delete original if exists
  /// 3. Rename temp to original
  static Future<void> writeAtomic(File file, String content) async {
    final temp = File('${file.path}.tmp');
    
    // Write to temp file first
    await temp.writeAsString(content);
    
    // Delete original if exists
    if (file.existsSync()) {
      file.deleteSync();
    }
    
    // Rename temp to original (atomic operation)
    await temp.rename(file.path);
  }

  /// Write bytes atomically (for binary files)
  static Future<void> writeAtomicBytes(File file, List<int> bytes) async {
    final temp = File('${file.path}.tmp');
    
    await temp.writeAsBytes(bytes);
    
    if (file.existsSync()) {
      file.deleteSync();
    }
    
    await temp.rename(file.path);
  }
}
