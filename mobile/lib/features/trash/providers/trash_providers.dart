// lib/features/trash/providers/trash_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/data/database/connection.dart';
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
import 'package:prismbox/data/database/daos/remote_asset_dao.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/domain/entities/remote_asset.dart';
import 'package:prismbox/features/local_sync/models/timeline_section.dart';
import 'package:prismbox/features/local_sync/services/timeline_grouping_service.dart';

part 'trash_providers.g.dart';

/// 回收站过滤模式枚举
enum TrashFilterModeEnum {
  /// 显示所有已删除的资源（本地和远程）
  all,

  /// 仅显示本地已删除的资源
  localOnly,

  /// 仅显示远程已删除的资源
  remoteOnly,
}

/// 回收站过滤模式 Provider
@riverpod
class TrashFilterMode extends _$TrashFilterMode {
  @override
  TrashFilterModeEnum build() => TrashFilterModeEnum.all;

  void setMode(TrashFilterModeEnum mode) {
    state = mode;
  }

  void cycle() {
    switch (state) {
      case TrashFilterModeEnum.all:
        state = TrashFilterModeEnum.localOnly;
        break;
      case TrashFilterModeEnum.localOnly:
        state = TrashFilterModeEnum.remoteOnly;
        break;
      case TrashFilterModeEnum.remoteOnly:
        state = TrashFilterModeEnum.all;
        break;
    }
  }

  String get displayText {
    switch (state) {
      case TrashFilterModeEnum.all:
        return '全部';
      case TrashFilterModeEnum.localOnly:
        return '仅本地';
      case TrashFilterModeEnum.remoteOnly:
        return '仅远程';
    }
  }
}

/// 回收站数据 Provider
/// 提供已删除的本地和远程资产数据
@riverpod
Future<List<BaseAsset>> trashAssets(TrashAssetsRef ref) async {
  final database = await DatabaseConnection.getInstance();
  final localDao = LocalAssetDao(database);
  final remoteDao = RemoteAssetDao(database);

  // 获取已删除的本地和远程资产
  final deletedLocalAssets = await localDao.getDeletedAssets();
  final deletedRemoteAssets = await remoteDao.getDeletedAssets();

  // 转换为 BaseAsset 列表
  final assets = <BaseAsset>[];

  // 添加本地资产
  for (final entity in deletedLocalAssets) {
    assets.add(
      LocalAsset.fromData(
        id: entity.id,
        name: entity.name,
        checksum: null,
        type: entity.type,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
        width: entity.width,
        height: entity.height,
        durationInSeconds: entity.durationInSeconds,
        isUploaded: entity.isUploaded,
        orientation: entity.orientation,
        trashPath: entity.trashPath,
        fileSize: entity.fileSize,
        latitude: entity.latitude,
        longitude: entity.longitude,
        deviceMake: entity.deviceMake,
        deviceModel: entity.deviceModel,
        exifExposureTime: entity.exifExposureTime,
        exifFNumber: entity.exifFNumber,
        exifIso: entity.exifIso,
        exifFocalLength: entity.exifFocalLength,
      ),
    );
  }

  // 添加远程资产
  for (final entity in deletedRemoteAssets) {
    assets.add(
      RemoteAsset.fromData(
        id: entity.id,
        name: entity.name,
        checksum: entity.checksum,
        ownerId: entity.ownerId,
        type: entity.type,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
        width: entity.width,
        height: entity.height,
        durationInSeconds: entity.durationInSeconds,
        isFavorite: entity.isFavorite,
        thumbHash: entity.thumbHash,
        visibility: entity.visibility,
        livePhotoVideoId: entity.livePhotoVideoId,
        stackId: entity.stackId,
        fileSize: entity.fileSize,
        latitude: entity.latitude,
        longitude: entity.longitude,
        deviceMake: entity.deviceMake,
        deviceModel: entity.deviceModel,
        exifExposureTime: entity.exifExposureTime,
        exifFNumber: entity.exifFNumber,
        exifIso: entity.exifIso,
        exifFocalLength: entity.exifFocalLength,
      ),
    );
  }

  // 按删除时间降序排序（已删除的资产在 DAO 中已排序）
  return assets;
}

/// 回收站分组数据 Provider
/// 将回收站数据转换为按时间分组的 TimelineSection 列表
@riverpod
Future<List<TimelineSection>> trashSections(TrashSectionsRef ref) async {
  // 1. 获取过滤模式
  final filterMode = ref.watch(trashFilterModeProvider);

  // 2. 获取原始数据
  final assets = await ref.watch(trashAssetsProvider.future);

  // 3. 根据过滤模式过滤数据
  final filteredAssets = _filterTrashAssets(assets, filterMode);

  // 4. 如果过滤后没有数据，直接返回空列表
  if (filteredAssets.isEmpty) {
    return [];
  }

  // 5. 执行分组转换
  final groupingService = TimelineGroupingService();
  final sections = groupingService.groupByTime(filteredAssets);

  // 6. 移除空分组
  return sections.where((section) => section.assets.isNotEmpty).toList();
}

/// 根据过滤模式过滤回收站资产列表
List<BaseAsset> _filterTrashAssets(
  List<BaseAsset> assets,
  TrashFilterModeEnum filterMode,
) {
  switch (filterMode) {
    case TrashFilterModeEnum.all:
      return assets;
    case TrashFilterModeEnum.localOnly:
      return assets.whereType<LocalAsset>().toList();
    case TrashFilterModeEnum.remoteOnly:
      return assets.whereType<RemoteAsset>().toList();
  }
}
