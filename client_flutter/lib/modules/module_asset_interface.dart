// lib/modules/module_asset_interface.dart

import '../assets/asset_model.dart';

abstract class ModuleAssetConsumer {
  void onAssetImported(AssetModel asset);
}
