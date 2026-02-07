// lib/data/database/daos/local_asset_dao.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/tables/local_asset_entity.dart';
import 'package:prismbox/data/database/enums/asset_type.dart';
import 'package:prismbox/data/database/enums/migration_status.dart';

part 'local_asset_dao.g.dart';

/// 本地资产数据访问对象
/// 提供本地资产的查询和操作接口
@DriftAccessor(tables: [LocalAssetEntity])
class LocalAssetDao extends DatabaseAccessor<AppDatabase>
    with _$LocalAssetDaoMixin {
  LocalAssetDao(AppDatabase db) : super(db);

  /// 获取所有本地资产（排除已删除）
  Future<List<LocalAssetEntityData>> getAllAssets() {
    return (select(localAssetEntity)..where((t) => t.deletedAt.isNull())).get();
  }

  /// 根据 ID 获取资产
  Future<LocalAssetEntityData?> getAssetById(String id) {
    return (select(
      localAssetEntity,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 批量根据 ID 获取资产
  /// 返回 Map<assetId, LocalAssetEntityData>
  Future<Map<String, LocalAssetEntityData>> getAssetsByIds(List<String> ids) {
    if (ids.isEmpty) {
      return Future.value({});
    }

    return (select(localAssetEntity)..where((t) => t.id.isIn(ids))).get().then((
      assets,
    ) {
      final map = <String, LocalAssetEntityData>{};
      for (final asset in assets) {
        map[asset.id] = asset;
      }
      return map;
    });
  }

  /// 插入资产
  Future<void> insertAsset(LocalAssetEntityData asset) {
    return into(localAssetEntity).insert(asset);
  }

  /// 批量插入资产
  Future<void> insertAssets(List<LocalAssetEntityData> assets) {
    return batch((batch) {
      batch.insertAll(localAssetEntity, assets);
    });
  }

  /// 更新资产
  Future<bool> updateAsset(LocalAssetEntityData asset) {
    return update(localAssetEntity).replace(asset);
  }

  /// 插入或更新资产（Upsert）
  /// 如果记录已存在则更新，不存在则插入
  Future<void> insertOrUpdateAsset(LocalAssetEntityData asset) {
    return into(
      localAssetEntity,
    ).insertOnConflictUpdate(asset.toCompanion(false));
  }

  /// 批量插入或更新资产（Upsert）
  Future<void> insertOrUpdateAssets(List<LocalAssetEntityData> assets) {
    return batch((batch) {
      for (final asset in assets) {
        batch.insert(
          localAssetEntity,
          asset.toCompanion(false),
          onConflict: DoUpdate((_) => asset.toCompanion(false)),
        );
      }
    });
  }

  /// 删除资产
  Future<bool> deleteAsset(String id) async {
    final count = await (delete(
      localAssetEntity,
    )..where((t) => t.id.equals(id))).go();
    return count > 0;
  }

  /// 流式查询：监听资产变化（排除已删除）
  Stream<List<LocalAssetEntityData>> watchAssets() {
    return (select(
      localAssetEntity,
    )..where((t) => t.deletedAt.isNull())).watch();
  }

  /// 按类型筛选资产（排除已删除）
  Future<List<LocalAssetEntityData>> getAssetsByType(AssetType type) {
    return (select(
      localAssetEntity,
    )..where((t) => t.type.equalsValue(type) & t.deletedAt.isNull())).get();
  }

  /// 按时间范围查询资产（排除已删除）
  Future<List<LocalAssetEntityData>> getAssetsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(localAssetEntity)
          ..where(
            (t) =>
                t.createdAt.isBetweenValues(start, end) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 查询迁移状态为失败的资产
  Future<List<LocalAssetEntityData>> getAssetsWithFailedMigration() {
    return (select(localAssetEntity)
          ..where((t) => t.migrationStatus.equalsValue(MigrationStatus.failed)))
        .get();
  }

  /// 查询迁移状态为进行中的资产
  Future<List<LocalAssetEntityData>> getAssetsWithPendingMigration() {
    return (select(
          localAssetEntity,
        )..where((t) => t.migrationStatus.equalsValue(MigrationStatus.pending)))
        .get();
  }

  /// 获取所有已软删除的本地资产
  /// 按删除时间降序排序
  Future<List<LocalAssetEntityData>> getDeletedAssets() {
    return (select(localAssetEntity)
          ..where((t) => t.deletedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]))
        .get();
  }

  /// 软删除资产
  /// 设置 deletedAt、originalPath 和 trashPath 字段
  Future<bool> softDeleteAsset({
    required String id,
    required String originalPath,
    required String trashPath,
  }) async {
    final count =
        await (update(localAssetEntity)..where((t) => t.id.equals(id))).write(
          LocalAssetEntityCompanion(
            deletedAt: Value(DateTime.now()),
            originalPath: Value(originalPath),
            trashPath: Value(trashPath),
          ),
        );
    return count > 0;
  }

  /// 恢复软删除的资产
  /// 清空 deletedAt、originalPath 和 trashPath 字段，恢复 path 为原始路径
  Future<bool> restoreAsset({
    required String id,
    required String restoredPath,
  }) async {
    final count =
        await (update(localAssetEntity)..where((t) => t.id.equals(id))).write(
          LocalAssetEntityCompanion(
            deletedAt: const Value(null), // 设置为 NULL，清空删除标记
            originalPath: const Value(null), // 设置为 NULL，清空原始路径
            trashPath: const Value(null), // 设置为 NULL，清空回收站路径
            path: Value(restoredPath),
          ),
        );
    return count > 0;
  }

  /// 恢复软删除的资产（支持更新 assetId）
  ///
  /// **参数**：
  /// - [oldId] - 旧的资产 ID
  /// - [newId] - 新的资产 ID（文件重新添加到系统相册后生成的新 ID）
  /// - [restoredPath] - 恢复后的文件路径
  ///
  /// **行为**：
  /// 如果 oldId == newId，只更新 path 和清空软删除字段
  /// 如果 oldId != newId，先删除旧记录，再插入新记录（因为 assetId 是主键）
  Future<bool> restoreAssetWithNewId({
    required String oldId,
    required String newId,
    required String restoredPath,
  }) async {
    // 获取旧记录
    final oldAsset = await getAssetById(oldId);
    if (oldAsset == null) {
      return false;
    }

    // 如果 assetId 没有变化，使用简单的更新方法
    if (oldId == newId) {
      return await restoreAsset(id: oldId, restoredPath: restoredPath);
    }

    // assetId 发生变化，需要先删除旧记录，再插入新记录
    return await transaction(() async {
      // 1. 删除旧记录
      final deleteCount = await (delete(
        localAssetEntity,
      )..where((t) => t.id.equals(oldId))).go();

      if (deleteCount == 0) {
        return false;
      }

      // 2. 创建新记录（使用新的 assetId）
      final newAsset = LocalAssetEntityData(
        id: newId,
        name: oldAsset.name,
        type: oldAsset.type,
        createdAt: oldAsset.createdAt,
        updatedAt: DateTime.now(), // 更新时间为当前时间
        width: oldAsset.width,
        height: oldAsset.height,
        durationInSeconds: oldAsset.durationInSeconds,
        isUploaded: oldAsset.isUploaded,
        path: restoredPath,
        isFavorite: oldAsset.isFavorite,
        orientation: oldAsset.orientation,
        isInPrivateSpace: false, // 恢复后不在私有空间
        migrationStatus: MigrationStatus.none, // 恢复后无迁移状态
        deletedAt: null,
        originalPath: null,
        trashPath: null,
        fileSize: oldAsset.fileSize,
        latitude: oldAsset.latitude,
        longitude: oldAsset.longitude,
        deviceMake: oldAsset.deviceMake,
        deviceModel: oldAsset.deviceModel,
        exifExposureTime: oldAsset.exifExposureTime,
        exifFNumber: oldAsset.exifFNumber,
        exifIso: oldAsset.exifIso,
        exifFocalLength: oldAsset.exifFocalLength,
      );

      // 3. 插入新记录
      await insertAsset(newAsset);
      return true;
    });
  }
}
