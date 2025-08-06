import 'dart:async';

import 'package:drift/drift.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:mobile/data/datasources/app_database.dart'; // 你的 Drift 数据库文件

/// 本地媒体数据源
///
/// 封装了所有与设备媒体库 (`photo_manager`) 和本地数据库 (`Drift`)
/// 直接交互的底层、具体的实现逻辑。
class LocalMediaDataSource {
  final MediaAssetDao _mediaAssetDao;

  LocalMediaDataSource(AppDatabase db) : _mediaAssetDao = db.mediaAssetDao;

  /// **核心实现：扫描、索引和清理本地媒体**
  ///
  /// 此方法遵循 "本地优先" 原则，高效地将设备媒体库与本地数据库同步。
  /// 流程:
  /// 1. 从 photo_manager 获取设备上所有媒体的实体列表 (AssetEntity)。
  /// 2. 从本地数据库获取所有已索引的本地媒体的 `localId`。
  /// 3. **增量添加**: 对比两个集合，找出设备上新增的媒体，并将其元数据插入到数据库。
  /// 4. **增量清理**: 对比两个集合，找出已从设备上删除、但仍存在于数据库中的媒体记录，并将其移除（仅限未同步到云的条目）。
  Future<void> scanAndIndexLocalMedia() async {
    // 1. 检查并请求权限
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      print("权限被拒绝，无法扫描本地媒体。");
      // 在真实应用中，这里应该通过一个回调或返回状态来通知上层UI，引导用户去设置页开启权限。
      return;
    }

    print("开始扫描本地媒体...");

    // 2. 从 photo_manager 获取设备上所有媒体
    final List<AssetEntity> allDeviceEntities = [];
    final List<AssetPathEntity> assetPaths =
        await PhotoManager.getAssetPathList(
          type: RequestType.common, // 获取图片和视频
        );

    for (final path in assetPaths) {
      // 为了防止一次性加载过多资源导致内存问题，可以分页加载，但对于大多数手机，一次性加载几千个资源的元数据是可行的。
      final List<AssetEntity> assets = await path.getAssetListRange(
        start: 0,
        end: await path.assetCountAsync,
      );
      allDeviceEntities.addAll(assets);
    }

    final Set<String> deviceAssetIds = allDeviceEntities
        .map((e) => e.id)
        .toSet();

    // 3. 从本地数据库获取所有已索引的 `localId`
    final List<MediaAsset> dbAssets = await (_mediaAssetDao.select(
      _mediaAssetDao.mediaAssets,
    )..where((tbl) => tbl.localId.isNotNull())).get();
    final Set<String> dbAssetIds = dbAssets.map((e) => e.localId!).toSet();

    // 4. 计算差异 - 增量添加
    final Set<String> newAssetIds = deviceAssetIds.difference(dbAssetIds);
    print("发现 ${newAssetIds.length} 个新媒体文件需要索引...");

    if (newAssetIds.isNotEmpty) {
      final List<MediaAssetsCompanion> newEntries = [];
      final Iterable<AssetEntity> newEntities = allDeviceEntities.where(
        (e) => newAssetIds.contains(e.id),
      );

      for (final asset in newEntities) {
        final file = await asset.file;
        newEntries.add(
          MediaAssetsCompanion.insert(
            localId: Value(asset.id),
            syncStatus: SyncStatus.localOnlyNotSelected, // 初始状态
            assetType: asset.type == AssetType.video
                ? MediaType.video
                : MediaType.image,
            filePath: Value(file?.path),
            width: Value(asset.width),
            height: Value(asset.height),
            durationSec: Value(asset.duration),
            createdAt: asset.createDateTime,
            updatedAt: DateTime.now(),
            // contentHash 可以在需要上传时再计算，以避免启动时产生大量IO开销。
          ),
        );
      }
      // 使用批量插入以获得最佳性能
      await _mediaAssetDao.batch((batch) {
        batch.insertAll(_mediaAssetDao.mediaAssets, newEntries);
      });
      print("索引完成：成功添加了 ${newEntries.length} 个新媒体记录。");
    }

    // 5. 计算差异 - 增量清理
    final Set<String> deletedAssetIds = dbAssetIds.difference(deviceAssetIds);
    print("发现 ${deletedAssetIds.length} 个媒体文件已在本地被删除...");

    if (deletedAssetIds.isNotEmpty) {
      // 核心约束：只删除那些还未上传到云端的、仅存在于本地的记录。
      // 如果一个媒体已经 `synced` 或 `cloudOnly`，即使本地文件被删除了，我们也不应该删除它的数据库记录。
      final deleteQuery = _mediaAssetDao.delete(_mediaAssetDao.mediaAssets)
        ..where(
          (tbl) =>
              tbl.localId.isIn(deletedAssetIds) &
              // 只清理处于“本地独有”或“同步出错”状态的记录
              (tbl.syncStatus.equalsValue(SyncStatus.localOnlyNotSelected) |
                  tbl.syncStatus.equalsValue(SyncStatus.error)),
        );

      final int deletedCount = await deleteQuery.go();
      print("清理完成：从数据库中移除了 $deletedCount 个已在本地删除的媒体记录。");
    }

    if (newAssetIds.isEmpty && deletedAssetIds.isEmpty) {
      print("本地媒体库与数据库完全同步，无变化。");
    }
  }
}
