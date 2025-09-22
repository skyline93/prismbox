// lib/domain/entities/unified_media_entity.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/data/models/media/media_model.dart';

part 'unified_media_entity.freezed.dart';

@freezed
class UnifiedMediaEntity with _$UnifiedMediaEntity {
  const UnifiedMediaEntity._();

  const factory UnifiedMediaEntity({
    required int id,
    String? localId,
    String? cloudUuid,
    String? thumbnailUrl,
    required SyncStatus syncStatus,
    required MediaType assetType,
    String? filePath,
    String? fileName,
    @Default(false) bool isRAW,
    int? width,
    int? height,
    int? durationSec,
    required DateTime createdAt,
    @Default(null) AssetEntity? assetEntity,
    LifecycleState? lifecycleState,
    String? trashPath,
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
      isRAW: dbAsset.isRAW,
      width: dbAsset.width,
      height: dbAsset.height,
      durationSec: dbAsset.durationSec,
      createdAt: dbAsset.createdAt,
      lifecycleState: dbAsset.lifecycleState,
      trashPath: dbAsset.trashPath,
    );
  }

  factory UnifiedMediaEntity.fromAssetEntity(AssetEntity asset) {
    // 将 photo_manager 的 AssetType 转换为我们自己的 MediaType
    final MediaType type = asset.type == AssetType.video
        ? MediaType.video
        : MediaType.image;

    return UnifiedMediaEntity(
      // 重要: 当从 AssetEntity 直接创建时，它尚未进入我们的数据库，
      // 所以我们给它一个临时的 id (例如 0 或 -1)，表示它是一个“瞬时”对象。
      // 这个 id 不应该被用于任何持久化操作。
      id: 0,

      // 这个实体只存在于本地，且尚未同步，所以状态是 localOnly
      syncStatus: SyncStatus.localOnly,

      // 填充来自 AssetEntity 的字段
      localId: asset.id,
      assetType: type,
      fileName: asset.title,
      isRAW: false,
      width: asset.width,
      height: asset.height,
      durationSec: asset.duration,
      createdAt: asset.createDateTime,

      // 关键: 将原始的 AssetEntity 附加到我们的实体上。
      // 这允许UI层在需要时直接访问它来获取缩略图或原始文件，
      // 而无需再次查询 photo_manager。
      assetEntity: asset,

      lifecycleState: LifecycleState.active,
    );
  }

  factory UnifiedMediaEntity.fromRemoteMedia(MediaResponse remoteMedia) {
    /// 一个辅助函数，用于解析后端返回的 "HH:MM:SS.ms" 格式的时长字符串。
    int _parseDuration(String? durationStr) {
      if (durationStr == null || durationStr.isEmpty) return 0;
      try {
        final parts = durationStr.split(':');
        if (parts.length != 3) return 0;

        final secondsAndMs = parts[2].split('.');
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final seconds = int.parse(secondsAndMs[0]);

        return (hours * 3600) + (minutes * 60) + seconds;
      } catch (e) {
        // debugPrint("Error parsing duration from remote: $durationStr");
        return 0;
      }
    }

    return UnifiedMediaEntity(
      // 这个实体并非来自本地数据库，因此 id 设为 0
      id: 0,
      // 它完全同步自云端
      syncStatus: SyncStatus.synced,
      // 它没有对应的本地资源
      localId: null,
      assetEntity: null,
      filePath: null,

      // 从 remoteMedia 对象映射字段
      cloudUuid: remoteMedia.uuid,
      thumbnailUrl: remoteMedia.thumbnailUrl,
      assetType: remoteMedia.itemType == 'VIDEO'
          ? MediaType.video
          : MediaType.image,
      fileName: remoteMedia.filename,
      isRAW: false,
      width: remoteMedia.width,
      height: remoteMedia.height,
      durationSec: _parseDuration("0"),
      createdAt: DateTime.parse(remoteMedia.createdAt),
      lifecycleState: LifecycleState.active,
    );
  }

  bool get isVideo => assetType == MediaType.video;

  bool get isRemote =>
      cloudUuid != null &&
      (syncStatus == SyncStatus.synced || syncStatus == SyncStatus.cloudOnly);

  DateTime get creationDate => createdAt;

  double get aspectRatio =>
      (width != null && height != null && height! > 0) ? width! / height! : 1.0;
}
