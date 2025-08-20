import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/data/datasources/local_db/enums.dart';
import 'package:mobile/data/models/media/media_model.dart';

part 'unified_media_entity.freezed.dart';

@freezed
class UnifiedMediaEntity with _$UnifiedMediaEntity {
  const UnifiedMediaEntity._();

  const factory UnifiedMediaEntity({
    required int id,
    String? localId,
    String? cloudUuid,
    required SyncStatus syncStatus,
    required MediaType assetType,
    String? filePath,
    String? fileName,
    int? width,
    int? height,
    int? durationSec,
    required DateTime createdAt,
    @Default(null) AssetEntity? assetEntity,
  }) = _UnifiedMediaEntity;

  factory UnifiedMediaEntity.fromDbModel(MediaAsset dbAsset) {
    return UnifiedMediaEntity(
      id: dbAsset.id,
      localId: dbAsset.localId,
      cloudUuid: dbAsset.cloudUuid,
      syncStatus: dbAsset.syncStatus,
      assetType: dbAsset.assetType,
      filePath: dbAsset.filePath,
      fileName: dbAsset.fileName,
      width: dbAsset.width,
      height: dbAsset.height,
      durationSec: dbAsset.durationSec,
      createdAt: dbAsset.createdAt,
    );
  }

  bool get isVideo => assetType == MediaType.video;

  DateTime get creationDate => createdAt;

  double get aspectRatio =>
      (width != null && height != null && height! > 0) ? width! / height! : 1.0;
}
