import 'dart:async';

import 'package:drift/drift.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:mobile/data/models/media/media_model.dart';
import 'package:mobile/data/datasources/app_database.dart';
import 'package:pool/pool.dart';

/// 本地媒体数据源 (最终内存优化版)
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

    // --- 【核心内存优化：不再全量加载 AssetEntity】 ---
    // 1. 只获取设备上所有媒体的 ID，这是一个非常轻量的操作。
    print("正在获取设备所有媒体ID...");
    final List<AssetPathEntity> assetPaths =
        await PhotoManager.getAssetPathList(
          type: RequestType.common,
          onlyAll: true,
        );

    Set<String> deviceAssetIds = {};
    if (assetPaths.isNotEmpty) {
      // 通常 "Recent" 或 "所有照片" 相册在第一个
      final AssetPathEntity mainPath = assetPaths.first;
      final int totalCount = await mainPath.assetCountAsync;
      // 使用 getAssetListRange 的一个技巧，只获取id
      final List<AssetEntity> idOnlyAssets = await mainPath.getAssetListPaged(
        page: 0,
        size: totalCount,
      );
      deviceAssetIds = idOnlyAssets.map((e) => e.id).toSet();
    }
    print("获取到 ${deviceAssetIds.length} 个设备媒体ID。");

    // 2. 从数据库获取已存在的ID（这部分已优化，保持不变）
    final query = _mediaAssetDao.selectOnly(_mediaAssetDao.mediaAssets)
      ..addColumns([_mediaAssetDao.mediaAssets.localId])
      ..where(_mediaAssetDao.mediaAssets.localId.isNotNull());
    final List<String> idList = await query
        .map((row) => row.read(_mediaAssetDao.mediaAssets.localId)!)
        .get();
    final Set<String> dbAssetIds = idList.toSet();

    // 3. 计算差异 - 增量添加
    final Set<String> newAssetIds = deviceAssetIds.difference(dbAssetIds);
    print("发现 ${newAssetIds.length} 个新媒体文件需要索引...");

    if (newAssetIds.isNotEmpty) {
      // 使用 Pool 控制并发，防止资源过载
      final pool = Pool(5); // 保持一个安全的并发数
      int totalAddedCount = 0;

      final List<String> newAssetIdsList = newAssetIds.toList();
      const int dbBatchSize = 50; // 数据库批处理大小

      for (int i = 0; i < newAssetIdsList.length; i += dbBatchSize) {
        final int end = (i + dbBatchSize > newAssetIdsList.length)
            ? newAssetIdsList.length
            : i + dbBatchSize;
        final List<String> batchIds = newAssetIdsList.sublist(i, end);

        print(
          "正在处理批次: ${i ~/ dbBatchSize + 1} / ${(newAssetIdsList.length / dbBatchSize).ceil()}...",
        );

        final List<Future<MediaAssetsCompanion?>> futures = batchIds.map((
          assetId,
        ) {
          return pool.withResource<MediaAssetsCompanion?>(() async {
            try {
              // --- 【核心内存优化：按需获取 AssetEntity】 ---
              // 4. 只在需要时，根据ID获取单个 AssetEntity 对象
              final AssetEntity? asset = await AssetEntity.fromId(assetId);
              if (asset == null) {
                print("警告: 无法通过ID找到资源: $assetId");
                return null;
              }

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
              print('处理 asset $assetId 时发生错误: $e');
              print(s);
              return null;
            }
          });
        }).toList();

        final List<MediaAssetsCompanion?> results = await Future.wait(futures);
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

        // **实验性优化**: 在每个大批次后，手动触发一次事件循环，给GC机会运行。
        await Future.delayed(Duration.zero);
      }
      print("索引完成：成功添加了 $totalAddedCount 个新媒体记录。");
    }

    // 清理逻辑保持不变
    final Set<String> deletedAssetIds = dbAssetIds.difference(deviceAssetIds);
    if (deletedAssetIds.isNotEmpty) {
      // ... (删除逻辑代码)
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
