// lib/data/database/daos/local_asset_dao.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/tables/local_asset_entity.dart';
import 'package:prismbox/data/database/enums/asset_type.dart';

part 'local_asset_dao.g.dart';

/// 本地资产数据访问对象
/// 提供本地资产的查询和操作接口
@DriftAccessor(tables: [LocalAssetEntity])
class LocalAssetDao extends DatabaseAccessor<AppDatabase>
    with _$LocalAssetDaoMixin {
  LocalAssetDao(AppDatabase db) : super(db);

  /// 获取所有本地资产
  Future<List<LocalAssetEntityData>> getAllAssets() {
    return select(localAssetEntity).get();
  }

  /// 根据 ID 获取资产
  Future<LocalAssetEntityData?> getAssetById(String id) {
    return (select(localAssetEntity)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 根据 checksum 获取资产
  Future<LocalAssetEntityData?> getAssetByChecksum(String checksum) {
    return (select(localAssetEntity)
          ..where((t) => t.checksum.equals(checksum)))
        .getSingleOrNull();
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
    return into(localAssetEntity).insertOnConflictUpdate(asset.toCompanion(false));
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
    final count = await (delete(localAssetEntity)
          ..where((t) => t.id.equals(id)))
        .go();
    return count > 0;
  }

  /// 流式查询：监听资产变化
  Stream<List<LocalAssetEntityData>> watchAssets() {
    return select(localAssetEntity).watch();
  }

  /// 按类型筛选资产
  Future<List<LocalAssetEntityData>> getAssetsByType(AssetType type) {
    return (select(localAssetEntity)
          ..where((t) => t.type.equalsValue(type)))
        .get();
  }

  /// 按时间范围查询资产
  Future<List<LocalAssetEntityData>> getAssetsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(localAssetEntity)
          ..where((t) => t.createdAt.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }
}

