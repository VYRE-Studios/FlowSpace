// lib/assets/board_asset_manifest.dart

import 'asset_model.dart';

class BoardAssetManifest {
  List<AssetModel> assets;

  BoardAssetManifest({
    required this.assets,
  });

  Map<String, dynamic> toJson() {
    return {
      'assets': assets.map((a) => a.toJson()).toList(),
    };
  }

  static BoardAssetManifest fromJson(Map<String, dynamic> json) {
    return BoardAssetManifest(
      assets: (json['assets'] as List<dynamic>)
          .map((a) => AssetModel.fromJson(a))
          .toList(),
    );
  }
}
