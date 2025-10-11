import 'package:photo_manager/photo_manager.dart';
import 'package:mobile/core/enums.dart';

extension AssetTypeExtension on AssetType {
  MediaType toMediaType() {
    switch (this) {
      case AssetType.video:
        return MediaType.video;
      case AssetType.image:
        return MediaType.image;
      default:
        throw Exception('Unsupported asset type: $this');
    }
  }
}
