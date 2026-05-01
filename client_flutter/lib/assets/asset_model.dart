// lib/assets/asset_model.dart

enum AssetType {
  image,
  audio,
  pdf,
  text,
  unknown,
}

AssetType parseAssetType(String ext) {
  final lower = ext.toLowerCase();

  if (['png', 'jpg', 'jpeg', 'webp'].contains(lower)) {
    return AssetType.image;
  }
  if (['mp3', 'wav', 'ogg', 'flac'].contains(lower)) {
    return AssetType.audio;
  }
  if (lower == 'pdf') {
    return AssetType.pdf;
  }
  if (['txt', 'md', 'rtf'].contains(lower)) {
    return AssetType.text;
  }
  return AssetType.unknown;
}

class AssetModel {
  final String id;
  final String fileName;
  final String filePath;
  final AssetType type;
  final int fileSize;
  final String checksum;
  final DateTime importedAt;

  AssetModel({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.type,
    required this.fileSize,
    required this.checksum,
    required this.importedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'type': type.name,
      'fileSize': fileSize,
      'checksum': checksum,
      'importedAt': importedAt.toIso8601String(),
    };
  }

  static AssetModel fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['id'],
      fileName: json['fileName'],
      filePath: json['filePath'],
      type: AssetType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => AssetType.unknown,
      ),
      fileSize: json['fileSize'],
      checksum: json['checksum'],
      importedAt: DateTime.parse(json['importedAt']),
    );
  }
}
