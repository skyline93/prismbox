import 'dart:async';

import 'package:drift/drift.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:mobile/data/models/media/media_model.dart';
import 'package:mobile/data/datasources/app_database.dart';
import 'package:pool/pool.dart'; // 1. 导入 pool 包

/// 本地媒体数据源 (使用 Pool 优化并发稳定性)
class LocalMediaDataSource {
  final MediaAssetDao _mediaAssetDao;

  LocalMediaDataSource(AppDatabase db) : _mediaAssetDao = db.mediaAssetDao;

  Future<void> scanAndIndexLocalMedia() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      print("权限被拒绝，无法扫描本地媒体。");
      return;
    }

    print("开始扫描本地媒体...");

    final Map<String, AssetEntity> allDeviceEntitiesMap = {};
    final List<AssetPathEntity> assetPaths =
        await PhotoManager.getAssetPathList(type: RequestType.common);

    for (final path in assetPaths) {
      final count = await path.assetCountAsync;
      if (count <= 0) continue;
      final List<AssetEntity> assets = await path.getAssetListRange(
        start: 0,
        end: count,
      );
      for (final asset in assets) {
        allDeviceEntitiesMap[asset.id] = asset;
      }
    }

    final Set<String> deviceAssetIds = allDeviceEntitiesMap.keys.toSet();

    final query = _mediaAssetDao.selectOnly(_mediaAssetDao.mediaAssets)
      ..addColumns([_mediaAssetDao.mediaAssets.localId])
      ..where(_mediaAssetDao.mediaAssets.localId.isNotNull());
    final List<String> idList = await query
        .map((row) => row.read(_mediaAssetDao.mediaAssets.localId)!)
        .get();
    final Set<String> dbAssetIds = idList.toSet();

    final Set<String> newAssetIds = deviceAssetIds.difference(dbAssetIds);
    print("发现 ${newAssetIds.length} 个新媒体文件需要索引...");

    if (newAssetIds.isNotEmpty) {
      // --- 【并发池优化】 ---
      // 2. 创建一个 Pool。这里的数字 10 表示“最多允许10个任务同时运行”。
      // 这是一个安全启动值，你可以根据测试结果调整（例如 15 或 20）。
      // 这个值远比500安全得多。
      final pool = Pool(5);
      int totalAddedCount = 0;

      // 我们仍然可以分批次来组织和插入数据库，但并发获取由Pool控制。
      final List<String> newAssetIdsList = newAssetIds.toList();
      const int dbBatchSize = 50; // 用于数据库批量插入的大小

      for (int i = 0; i < newAssetIdsList.length; i += dbBatchSize) {
        final int end = (i + dbBatchSize > newAssetIdsList.length)
            ? newAssetIdsList.length
            : i + dbBatchSize;
        final List<String> batchIds = newAssetIdsList.sublist(i, end);

        print("正在准备处理批次: ${i ~/ dbBatchSize + 1}...");

        // 3. 将任务提交给 Pool，并等待批次中所有任务完成
        final List<MediaAssetsCompanion?> results = await Future.wait(
          batchIds.map((assetId) {
            // pool.withResource 会获取一个“并发许可”
            // 当池中的并发任务达到上限时，它会等待，直到有任务完成并释放许可
            return pool.withResource<MediaAssetsCompanion?>(() async {
              final asset = allDeviceEntitiesMap[assetId];
              if (asset == null) return null;

              try {
                final file = await asset.file;
                if (file == null) {
                  print("警告: 无法获取资源文件路径: ${asset.id}");
                  return null;
                }

                return MediaAssetsCompanion.insert(
                  localId: Value(asset.id),
                  syncStatus: SyncStatus.localOnlyNotSelected,
                  assetType: asset.type == AssetType.video
                      ? MediaType.video
                      : MediaType.image,
                  filePath: Value(file.path),
                  width: Value(asset.width),
                  height: Value(asset.height),
                  durationSec: Value(asset.duration),
                  createdAt: asset.createDateTime,
                  updatedAt: DateTime.now(),
                );
              } catch (e, s) {
                // 增加精细的错误捕获，以防某个文件处理失败
                print('处理 asset ${asset.id} 时发生错误: $e');
                print(s);
                return null;
              }
            });
          }),
        );

        final List<MediaAssetsCompanion> newEntries = results
            .whereType<MediaAssetsCompanion>()
            .toList();

        if (newEntries.isNotEmpty) {
          await _mediaAssetDao.batch((batch) {
            batch.insertAll(_mediaAssetDao.mediaAssets, newEntries);
          });
          totalAddedCount += newEntries.length;
          print("批次处理完成：已添加 ${newEntries.length} 条记录。当前总数: $totalAddedCount");
        }
      }
      print("索引完成：成功添加了 $totalAddedCount 个新媒体记录。");
    }

    final Set<String> deletedAssetIds = dbAssetIds.difference(deviceAssetIds);
    print("发现 ${deletedAssetIds.length} 个媒体文件已在本地被删除...");
    if (deletedAssetIds.isNotEmpty) {
      final deleteQuery = _mediaAssetDao.delete(_mediaAssetDao.mediaAssets)
        ..where(
          (tbl) =>
              tbl.localId.isIn(deletedAssetIds) &
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
