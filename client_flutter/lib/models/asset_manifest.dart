// lib/models/asset_manifest.dart

class AssetManifest {
  final String assetId;
  final String fileName;
  final String fileType;
  final int fileSize;
  final DateTime uploadedAt;

  AssetManifest({
    required this.assetId,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
  });

  factory AssetManifest.fromJson(Map<String, dynamic> json) {
    return AssetManifest(
      assetId: json['assetId'],
      fileName: json['fileName'],
      fileType: json['fileType'],
      fileSize: json['fileSize'],
      uploadedAt: DateTime.parse(json['uploadedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'assetId': assetId,
        'fileName': fileName,
        'fileType': fileType,
        'fileSize': fileSize,
        'uploadedAt': uploadedAt.toIso8601String(),
      };
}
