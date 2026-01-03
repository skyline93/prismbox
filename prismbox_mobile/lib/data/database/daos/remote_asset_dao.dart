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

  /// 批量根据 checksum 获取远程资产
  /// 返回 Map<checksum, RemoteAssetEntityData>
  /// 如果同一个 checksum 有多个资产，取第一个（通常应该是唯一的）
  Future<Map<String, RemoteAssetEntityData>> getAssetsByChecksums(
    List<String> checksums,
  ) {
    if (checksums.isEmpty) {
      return Future.value({});
    }

    return (select(remoteAssetEntity)
          ..where((t) => 
              t.checksum.isIn(checksums) & 
              t.deletedAt.isNull()))
        .get()
        .then((assets) {
          final map = <String, RemoteAssetEntityData>{};
          // 如果同一个 checksum 有多个资产，取第一个
          for (final asset in assets) {
            if (!map.containsKey(asset.checksum)) {
              map[asset.checksum] = asset;
            }
          }
          return map;
        });
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
          deletedAt: const Value(null), // 设置为 NULL，清空删除标记
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

  /// 流式查询：监听指定 checksum 的远程资产变化
  /// 
  /// **用途**：用于实时查询本地资产是否有对应的远程版本
  /// 当远程同步完成后，如果该 checksum 的远程资产被插入，会自动发出新值
  /// 
  /// **返回**：Stream<RemoteAssetEntityData?>，当远程资产变化时会自动发出新值
  Stream<RemoteAssetEntityData?> watchAssetByChecksum(String checksum) {
    return (select(remoteAssetEntity)
          ..where((t) => 
              t.checksum.equals(checksum) & 
              t.deletedAt.isNull())
          ..limit(1))
      .watchSingleOrNull();
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

  /// 获取所有已软删除的远程资产
  /// 按删除时间降序排序
  Future<List<RemoteAssetEntityData>> getDeletedAssets() {
    return (select(remoteAssetEntity)
          ..where((t) => t.deletedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]))
        .get();
  }

  /// 硬删除资产（永久删除）
  Future<bool> deleteAsset(String id) async {
    final count = await (delete(remoteAssetEntity)
          ..where((t) => t.id.equals(id)))
        .go();
    return count > 0;
  }
}

