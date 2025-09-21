import 'package:drift/drift.dart';
import 'package:flutter_replicator/flutter_replicator.dart';
import 'package:logging/logging.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/core/service_locator.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';

final mediaTableName = 'media';

/// MediaStorageAdapter 实现了 StorageAdapter 抽象类，是云端同步引擎与本地数据库之间的桥梁。
///
/// 设计思想:
/// 1.  **服务器权威 (Server-Authoritative)**: 云端数据被视为最终的“事实来源”。
/// 2.  **职责分离**:
///     - `syncStatus`: 严格管理本地记录与云端的 **同步关系** (localOnly, synced, cloudOnly)。
///     - `lifecycleState`: 严格管理资源本身的 **生命周期** (active, trashed)。
///     这两个状态是正交的，一个 `synced` 的资源可以是 `active` 或 `trashed` 状态，
///     这种分离简化了状态管理，并避免了引入更多复杂的组合状态。
/// 3.  **幂等性**: 所有操作都设计为幂等的，重复执行不会产生副作用。
/// 4.  **本地保留策略**: 当云端资源被永久删除时，如果本地存在对应文件 (synced)，
///     则仅断开同步链接，保留本地副本，避免用户数据丢失。
class MediaStorageAdapter extends StorageAdapter {
  final AppDatabase _db;
  final _log = Logger('MediaStorageAdapter');

  // 在 UserSettings 表中存储序列ID的键名。
  static const String _sequenceIdKey = 'last_media_sync_seq_id';

  MediaStorageAdapter() : _db = getIt<AppDatabase>();

  /// 从 UserSettings 表中获取上次成功同步的序列ID。
  /// 如果从未同步过，必须返回 0。
  @override
  Future<int> getLastSyncedSequenceId() async {
    final seqIdString = await _db.userSettingDao.getSetting(_sequenceIdKey);
    if (seqIdString == null) {
      _log.info('未找到上次同步的序列ID，将从 0 开始同步。');
      return 0;
    }
    _log.info('找到上次同步的序列ID: $seqIdString。');
    return int.tryParse(seqIdString) ?? 0;
  }

  /// 将最新的序列ID持久化存储到 UserSettings 表中。
  @override
  Future<void> setLastSyncedSequenceId(int seqId) async {
    _log.info('正在将最新的同步序列ID持久化: $seqId');
    await _db.userSettingDao.upsertSetting(
      UserSettingsCompanion(
        key: const Value(_sequenceIdKey),
        value: Value(seqId.toString()),
      ),
    );
  }

  /// 在全量同步开始前，准备本地数据库。
  /// 此方法会重置所有与云端相关的媒体资源状态，为接收全新的云端数据快照做准备。
  @override
  Future<void> prepareForFullSync(List<String> tables) async {
    if (!tables.contains(mediaTableName)) {
      _log.info('MediaAssets 表不在全量同步列表中，跳过准备阶段。');
      return;
    }

    _log.info('正在为全量同步做准备：重置与云端相关的媒体资源...');

    await _db.transaction(() async {
      // 1. 对于 `cloudOnly` 的记录，它们是纯粹的云端占位符，直接删除。
      final deleteCloudOnly = _db.delete(_db.mediaAssets)
        ..where((tbl) => tbl.syncStatus.equals(SyncStatus.cloudOnly.name));
      final deletedRows = await deleteCloudOnly.go();
      if (deletedRows > 0) {
        _log.info('删除了 $deletedRows 条“仅云上”的占位记录。');
      }

      // 2. 对于 `synced` 的记录，断开它们与云端的链接，使其变回普通本地资源。
      //    这保留了用户本地的数据，但清除了云端关联。
      final updateSynced = _db.update(_db.mediaAssets)
        ..where((tbl) => tbl.syncStatus.equals(SyncStatus.synced.name));
      final updatedRows = await updateSynced.write(
        const MediaAssetsCompanion(
          syncStatus: Value(SyncStatus.localOnlyNotSelected),
          cloudUuid: Value(null),
          // 注意：lifecycleState 保持不变，因为它描述的是资源自身的状态。
        ),
      );
      if (updatedRows > 0) {
        _log.info('将 $updatedRows 条“已同步”记录的状态重置为“仅本地”。');
      }
    });

    _log.info('全量同步准备阶段完成。');
  }

  /// 应用一页全量同步的数据。
  /// 基于云端的全量数据，更新或创建本地记录。
  @override
  Future<void> applyFullSyncData(String tableName, List<Changelog> data) async {
    if (tableName != mediaTableName || data.isEmpty) {
      return;
    }
    _log.info('正在应用全量同步数据页，包含 ${data.length} 条记录...');

    await _db.transaction(() async {
      final cloudHashes = data
          .map((c) => c.payload?['hash'] as String?)
          .whereType<String>()
          .toSet();

      if (cloudHashes.isEmpty) {
        _log.warning('此数据页中没有有效的 contentHash，跳过处理。');
        return;
      }

      // 1. 一次性查询出本地数据库中所有可能匹配的资源。
      final query = _db.select(_db.mediaAssets)
        ..where((tbl) => tbl.contentHash.isIn(cloudHashes));
      final existingLocalAssets = await query.get();
      final localAssetsMap = {
        for (var asset in existingLocalAssets) asset.contentHash!: asset,
      };

      final List<MediaAssetsCompanion> toInsert = [];
      final List<MediaAssetsCompanion> toUpdate = [];

      // 2. 遍历云端数据，决定是插入还是更新。
      for (final change in data) {
        final payload = change.payload;
        if (payload == null ||
            payload['hash'] == null ||
            payload['deleted'] == true) {
          // 在全量同步中，云端标记为 "deleted" 的记录不应被同步到客户端。
          continue;
        }

        final contentHash = payload['hash'] as String;
        final existingAsset = localAssetsMap[contentHash];
        final companion = _changelogToCompanion(change);

        if (existingAsset != null) {
          // 本地存在匹配的资源 (原状态为 localOnly)，更新为 `synced` 状态。
          toUpdate.add(
            companion.copyWith(
              id: Value(existingAsset.id),
              syncStatus: const Value(SyncStatus.synced),
            ),
          );
        } else {
          // 本地不存在匹配的资源，作为 `cloudOnly` 资源插入。
          toInsert.add(
            companion.copyWith(syncStatus: const Value(SyncStatus.cloudOnly)),
          );
        }
      }

      // 3. 批量执行数据库写入操作。
      if (toInsert.isNotEmpty) {
        await _db.batch((batch) => batch.insertAll(_db.mediaAssets, toInsert));
        _log.info('成功插入 ${toInsert.length} 条新的“仅云上”资源。');
      }
      if (toUpdate.isNotEmpty) {
        await _db.batch((batch) {
          for (final companion in toUpdate) {
            batch.replace(_db.mediaAssets, companion);
          }
        });
        _log.info('成功更新 ${toUpdate.length} 条本地资源为“已同步”状态。');
      }
    });
  }

  /// 原子性地应用增量变更。
  /// 这是最核心的同步逻辑，遵循职责分离原则。
  @override
  Future<void> applyIncrementalChanges(List<Changelog> changes) async {
    if (changes.isEmpty) return;
    _log.info('正在应用 ${changes.length} 条增量变更...');

    await _db.transaction(() async {
      // 1. 按操作类型分组
      final deletes = changes
          .where((c) => c.operationType == OperationType.deleted)
          .toList();
      final upserts = changes
          .where((c) => c.operationType != OperationType.deleted)
          .toList();

      // 2. 处理永久删除 (Hard Deletes)
      // 这些是云端记录被彻底删除的事件。
      if (deletes.isNotEmpty) {
        await _handleHardDeletes(deletes);
      }

      // 3. 处理创建和更新 (Creates and Updates)
      // 这些事件包括：新资源创建、元数据更新、软删除、恢复。
      if (upserts.isNotEmpty) {
        await _handleUpserts(upserts);
      }
    });
    _log.info('增量变更应用完成。');
  }

  /// 处理云端的永久删除事件。
  Future<void> _handleHardDeletes(List<Changelog> deletes) async {
    final cloudUuidsToDelete = deletes.map((c) => c.recordId).toList();

    // 查询本地所有与这些 cloudUuid 关联的资源
    final query = _db.select(_db.mediaAssets)
      ..where((tbl) => tbl.cloudUuid.isIn(cloudUuidsToDelete));
    final localAssets = await query.get();

    final List<int> idsToDeletePermanently = []; // 对应 cloudOnly
    final List<int> idsToResetToLocal = []; // 对应 synced

    for (final asset in localAssets) {
      if (asset.syncStatus == SyncStatus.cloudOnly) {
        idsToDeletePermanently.add(asset.id);
      } else if (asset.syncStatus == SyncStatus.synced) {
        idsToResetToLocal.add(asset.id);
      }
    }

    // 对 `cloudOnly` 资源执行物理删除
    if (idsToDeletePermanently.isNotEmpty) {
      final stmt = _db.delete(_db.mediaAssets)
        ..where((tbl) => tbl.id.isIn(idsToDeletePermanently));
      await stmt.go();
      _log.info('永久删除了 ${idsToDeletePermanently.length} 条“仅云上”的记录。');
    }

    // 对 `synced` 资源执行“断链”操作，保留本地副本
    if (idsToResetToLocal.isNotEmpty) {
      final stmt = _db.update(_db.mediaAssets)
        ..where((tbl) => tbl.id.isIn(idsToResetToLocal));
      await stmt.write(
        const MediaAssetsCompanion(
          syncStatus: Value(SyncStatus.localOnlyNotSelected),
          cloudUuid: Value(null),
          // 重置 lifecycleState 为 active，因为 severed 链接后它是一个独立的本地文件
          lifecycleState: Value(LifecycleState.active),
        ),
      );
      _log.info('将 ${idsToResetToLocal.length} 条“已同步”记录重置为“仅本地”，因云端已被永久删除。');
    }
  }

  /// 处理云端的创建和更新事件。
  Future<void> _handleUpserts(List<Changelog> upserts) async {
    final hashes = upserts
        .map((c) => c.payload?['hash'] as String?)
        .whereType<String>()
        .toSet();
    if (hashes.isEmpty) return;

    // 一次性查询出本地所有相关的资源
    final query = _db.select(_db.mediaAssets)
      ..where((tbl) => tbl.contentHash.isIn(hashes));
    final existingAssets = await query.get();
    final existingAssetsMap = {
      for (var asset in existingAssets) asset.contentHash!: asset,
    };

    final List<MediaAssetsCompanion> toInsert = [];
    final List<MediaAssetsCompanion> toUpdate = [];

    for (final change in upserts) {
      final payload = change.payload;
      if (payload == null || payload['hash'] == null) continue;

      final contentHash = payload['hash'] as String;
      final existingAsset = existingAssetsMap[contentHash];
      final companion = _changelogToCompanion(change);

      if (existingAsset != null) {
        // --- 本地存在匹配的资源 (按 hash) ---
        if (existingAsset.syncStatus == SyncStatus.localOnlyNotSelected) {
          // 场景: 本地文件先存在，后在另一端上传。现在需要将本地文件关联到云端。
          toUpdate.add(
            companion.copyWith(
              id: Value(existingAsset.id),
              syncStatus: const Value(SyncStatus.synced),
            ),
          );
        } else {
          // synced or cloudOnly
          // 场景: 幂等性处理 or 数据更新
          if (change.operationType == OperationType.created) {
            _log.finer('跳过 CREATE (hash: $contentHash)，资源已存在，确保幂等性。');
            continue;
          }
          // 场景: 元数据更新、软删除或恢复。统一处理为应用云端最新数据。
          // `syncStatus` 保持不变，只更新内容字段。

          if (payload["deleted"] == true &&
              existingAsset.lifecycleState == LifecycleState.active) {
            if (existingAsset.syncStatus == SyncStatus.synced) {
              toUpdate.add(
                companion.copyWith(
                  id: Value(existingAsset.id),
                  syncStatus: Value(SyncStatus.localOnlyNotSelected),
                ),
              );
              continue;
            } else if (existingAsset.syncStatus == SyncStatus.cloudOnly) {
              // already cloudOnly, do nothing
              _log.finer('跳过 DELETE (hash: $contentHash)，资源已是“仅云上”，确保幂等性。');
            }
            continue;
          }
          // toUpdate.add(companion.copyWith(id: Value(existingAsset.id)));
        }
      } else {
        // --- 本地不存在匹配的资源 ---
        // 场景: 从云端同步一个全新的资源。
        toInsert.add(
          companion.copyWith(syncStatus: const Value(SyncStatus.cloudOnly)),
        );
      }
    }

    if (toInsert.isNotEmpty) {
      await _db.batch((batch) => batch.insertAll(_db.mediaAssets, toInsert));
      _log.info('增量插入了 ${toInsert.length} 条“仅云上”的新记录。');
    }
    if (toUpdate.isNotEmpty) {
      await _db.batch((batch) {
        for (var comp in toUpdate) batch.replace(_db.mediaAssets, comp);
      });
      _log.info('增量更新了 ${toUpdate.length} 条本地记录的状态。');
    }
  }

  /// **核心转换函数**
  /// 将服务器返回的 `Changelog` payload 映射到 Drift 的 `MediaAssetsCompanion` 对象。
  /// 这个函数是数据映射的唯一入口，确保了业务逻辑的一致性。
  MediaAssetsCompanion _changelogToCompanion(Changelog change) {
    final payload = change.payload!;
    final isDeleted = payload['deleted'] as bool? ?? false;

    // Helper to safely parse int values
    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Helper to map item_type string to MediaType enum
    MediaType mapMediaType(String type) {
      return MediaType.values.byName(type.toLowerCase());
    }

    return MediaAssetsCompanion(
      // 核心关联字段
      cloudUuid: Value(change.recordId),
      contentHash: Value(payload['hash'] as String?),

      // 资源生命周期状态
      // lifecycleState: Value(
      //   isDeleted ? LifecycleState.trashed : LifecycleState.active,
      // ),

      // 资源元数据
      assetType: Value(mapMediaType(payload['item_type'] as String)),
      fileName: Value(payload['original_filename'] as String?),
      width: Value(parseInt(payload['width'])),
      height: Value(parseInt(payload['height'])),
      durationSec: Value(parseInt(payload['duration'])),
      createdAt: Value(DateTime.parse(payload['created_at'] as String)),

      // 本地时间戳
      updatedAt: Value(DateTime.now()),
    );
  }
}
