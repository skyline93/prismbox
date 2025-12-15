// lib/data/database/daos/remote_asset_dao.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/tables/remote_asset_entity.dart';

part 'remote_asset_dao.g.dart';

/// 远程资产数据访问对象
/// 提供远程资产的查询和操作接口
@DriftAccessor(tables: [RemoteAssetEntity])
class RemoteAssetDao extends DatabaseAccessor<AppDatabase>
    with _$RemoteAssetDaoMixin {
  RemoteAssetDao(AppDatabase db) : super(db);

  /// 获取用户的所有资产（排除已删除）
  Future<List<RemoteAssetEntityData>> getUserAssets(String userId) {
    return (select(remoteAssetEntity)
          ..where((t) => 
              t.ownerId.equals(userId) & 
              t.deletedAt.isNull()))
        .get();
  }

  /// 根据 ID 获取资产
  Future<RemoteAssetEntityData?> getAssetById(String id) {
    return (select(remoteAssetEntity)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 根据 checksum 和用户 ID 获取资产
  Future<RemoteAssetEntityData?> getAssetByChecksumAndUser(
    String checksum,
    String userId,
  ) {
    return (select(remoteAssetEntity)
          ..where((t) => 
              t.checksum.equals(checksum) & 
              t.ownerId.equals(userId) &
              t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// 根据 checksum 获取资产（不限制用户，用于关联本地资产）
  /// 返回第一个匹配的资产（通常 checksum 应该是唯一的）
  Future<RemoteAssetEntityData?> getAssetByChecksum(String checksum) {
    return (select(remoteAssetEntity)
          ..where((t) => 
              t.checksum.equals(checksum) & 
              t.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
  }

  /// 插入资产
  Future<void> insertAsset(RemoteAssetEntityData asset) {
    return into(remoteAssetEntity).insert(asset);
  }

  /// 批量插入资产
  Future<void> insertAssets(List<RemoteAssetEntityData> assets) {
    return batch((batch) {
      batch.insertAll(remoteAssetEntity, assets);
    });
  }

  /// 更新资产
  Future<bool> updateAsset(RemoteAssetEntityData asset) {
    return update(remoteAssetEntity).replace(asset);
  }

  /// 插入或更新资产（Upsert）
  /// 如果记录已存在则更新，不存在则插入
  Future<void> insertOrUpdateAsset(RemoteAssetEntityData asset) {
    return into(remoteAssetEntity).insertOnConflictUpdate(asset.toCompanion(false));
  }

  /// 软删除资产
  Future<bool> softDeleteAsset(String id) async {
    final count = await (update(remoteAssetEntity)
          ..where((t) => t.id.equals(id)))
        .write(RemoteAssetEntityCompanion(
          deletedAt: Value(DateTime.now()),
        ));
    return count > 0;
  }

  /// 恢复软删除的资产
  Future<bool> restoreAsset(String id) async {
    final count = await (update(remoteAssetEntity)
          ..where((t) => t.id.equals(id)))
        .write(RemoteAssetEntityCompanion(
          deletedAt: const Value.absent(),
        ));
    return count > 0;
  }

  /// 流式查询：监听用户资产变化
  Stream<List<RemoteAssetEntityData>> watchUserAssets(String userId) {
    return (select(remoteAssetEntity)
          ..where((t) => 
              t.ownerId.equals(userId) & 
              t.deletedAt.isNull()))
        .watch();
  }

  /// 批量更新资产
  Future<void> updateAssets(List<RemoteAssetEntityData> assets) {
    return batch((batch) {
      for (final asset in assets) {
        batch.update(remoteAssetEntity, asset);
      }
    });
  }

  /// 分页查询资产
  Future<List<RemoteAssetEntityData>> getAssetsPaged(
    String userId,
    int limit,
    int offset,
  ) {
    return (select(remoteAssetEntity)
          ..where((t) => 
              t.ownerId.equals(userId) & 
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit, offset: offset))
        .get();
  }
}

