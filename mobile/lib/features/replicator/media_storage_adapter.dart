import 'package:drift/drift.dart';
import 'package:flutter_replicator/flutter_replicator.dart';
import 'package:logging/logging.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/core/service_locator.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';

final mediaTableName = 'media';

// 定义云端事件类型，以便与矩阵对应
enum _CloudEvent {
  created,
  updated,
  updatedDeleted, // 软删除
  deleted, // 硬删除
}

// 定义本地资源的当前状态
class _LocalState {
  final MediaAsset? asset;
  final bool exists;

  _LocalState(this.asset) : exists = asset != null;

  // 根据矩阵，将本地状态和云端事件映射到最终状态
  SyncStatus? determineNextSyncStatus(_CloudEvent event) {
    if (!exists) {
      switch (event) {
        case _CloudEvent.created:
        case _CloudEvent.updated:
          return SyncStatus.cloudOnly;
        case _CloudEvent.updatedDeleted:
        case _CloudEvent.deleted:
          return null; // 状态: x (忽略)
      }
    }

    final currentStatus = asset!.syncStatus;
    final isTrashed = asset!.lifecycleState == LifecycleState.trashed;

    // 为了简化逻辑，我们主要关心 active 和 trashed 两种状态下的变化
    // 您的矩阵显示 localOnly_trashed 和 synced_trashed 的行为非常相似
    if (isTrashed) {
      switch (currentStatus) {
        case SyncStatus.synced:
          if (event == _CloudEvent.deleted) {
            return SyncStatus.localOnly;
          }
          return SyncStatus.synced; // 保持不变
        case SyncStatus.cloudOnly:
          if (event == _CloudEvent.deleted) {
            return null; // 状态: x (删除)
          }
          return SyncStatus.cloudOnly;
        default:
          return currentStatus; // localOnly_trashed 状态不变
      }
    } else {
      // Active State
      switch (currentStatus) {
        case SyncStatus.localOnly:
          if (event == _CloudEvent.created || event == _CloudEvent.updated) {
            return SyncStatus.synced;
          }
          return SyncStatus.localOnly; // 保持不变
        case SyncStatus.synced:
          if (event == _CloudEvent.updatedDeleted ||
              event == _CloudEvent.deleted) {
            return SyncStatus.localOnly;
          }
          return SyncStatus.synced; // 保持不变
        case SyncStatus.cloudOnly:
          if (event == _CloudEvent.updatedDeleted ||
              event == _CloudEvent.deleted) {
            return null; // 状态: x (删除)
          }
          return SyncStatus.cloudOnly; // 保持不变
        default:
          return currentStatus;
      }
    }
  }
}

class MediaStorageAdapter extends StorageAdapter {
  final AppDatabase _db;
  final _log = Logger('MediaStorageAdapter');

  static const String _sequenceIdKey = 'last_media_sync_seq_id';

  MediaStorageAdapter() : _db = getIt<AppDatabase>();

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

  @override
  Future<void> prepareForFullSync(List<String> tables) async {
    if (!tables.contains(mediaTableName)) {
      _log.info('MediaAssets 表不在全量同步列表中，跳过准备阶段。');
      return;
    }

    _log.info('正在为全量同步做准备：重置与云端相关的媒体资源...');

    await _db.transaction(() async {
      final deleteCloudOnly = _db.delete(_db.mediaAssets)
        ..where((tbl) => tbl.syncStatus.equals(SyncStatus.cloudOnly.name));
      final deletedRows = await deleteCloudOnly.go();
      if (deletedRows > 0) {
        _log.info('删除了 $deletedRows 条“仅云上”的占位记录。');
      }

      final updateSynced = _db.update(_db.mediaAssets)
        ..where((tbl) => tbl.syncStatus.equals(SyncStatus.synced.name));
      final updatedRows = await updateSynced.write(
        const MediaAssetsCompanion(
          syncStatus: Value(SyncStatus.localOnly),
          cloudUuid: Value(null),
        ),
      );
      if (updatedRows > 0) {
        _log.info('将 $updatedRows 条“已同步”记录的状态重置为“仅本地”。');
      }
    });

    _log.info('全量同步准备阶段完成。');
  }

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

      final query = _db.select(_db.mediaAssets)
        ..where((tbl) => tbl.contentHash.isIn(cloudHashes));
      final existingLocalAssets = await query.get();
      final localAssetsMap = {
        for (var asset in existingLocalAssets) asset.contentHash!: asset,
      };

      final List<MediaAssetsCompanion> toInsert = [];
      final List<MediaAssetsCompanion> toUpdate = [];

      for (final change in data) {
        final payload = change.payload;
        if (payload == null ||
            payload['hash'] == null ||
            payload['deleted'] == true) {
          continue;
        }

        final contentHash = payload['hash'] as String;
        final existingAsset = localAssetsMap[contentHash];
        final companion = _changelogToCompanion(change);

        if (existingAsset != null) {
          toUpdate.add(
            companion.copyWith(
              id: Value(existingAsset.id),
              syncStatus: const Value(SyncStatus.synced),
            ),
          );
        } else {
          toInsert.add(
            companion.copyWith(syncStatus: const Value(SyncStatus.cloudOnly)),
          );
        }
      }

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

  @override
  Future<void> applyIncrementalChanges(List<Changelog> changes) async {
    if (changes.isEmpty) return;
    _log.info('正在应用 ${changes.length} 条增量变更...');

    // 1. 预先提取所有相关的 IDs 和 Hashes
    final cloudUuids = changes.map((c) => c.recordId).toSet();
    final hashes = changes
        .map((c) => c.payload?['hash'] as String?)
        .whereType<String>()
        .toSet();

    // 2. 一次性查询本地数据库，获取所有可能受影响的资源
    final query = _db.select(_db.mediaAssets)
      ..where(
        (tbl) => tbl.cloudUuid.isIn(cloudUuids) | tbl.contentHash.isIn(hashes),
      );
    final localAssets = await query.get();

    // 3. 构建高效的查找映射
    final localAssetByUuid = {for (var a in localAssets) a.cloudUuid: a};
    final localAssetByHash = {for (var a in localAssets) a.contentHash: a};

    // 4. 准备数据库操作列表
    final List<MediaAssetsCompanion> toInsert = [];
    final List<MediaAssetsCompanion> toUpdate = [];
    final List<int> toDelete = [];

    // 5. 遍历云端变更，根据矩阵决定最终状态和操作
    for (final change in changes) {
      // 确定云端事件
      final event = _getCloudEvent(change);

      // 查找本地资源，优先使用 UUID，其次是 Hash
      final localAsset =
          localAssetByUuid[change.recordId] ??
          (change.payload?['hash'] == null
              ? null
              : localAssetByHash[change.payload!['hash']]);

      final localState = _LocalState(localAsset);

      // 使用表驱动逻辑计算下一个状态
      final nextStatus = localState.determineNextSyncStatus(event);

      var nextLifecycleState = localState.exists
          ? localState
                .asset!
                .lifecycleState // 默认保持本地状态
          : LifecycleState.active;

      final companion = _changelogToCompanion(change);

      if (nextStatus == null) {
        // 对应矩阵中的 'x' (删除或忽略)
        if (localState.exists &&
            localState.asset!.syncStatus == SyncStatus.cloudOnly) {
          toDelete.add(localState.asset!.id);
        }
        // 如果本地不存在，或者不是 cloudOnly，则忽略该事件
      } else {
        var finalCompanion = companion.copyWith(
          syncStatus: Value(nextStatus),
          lifecycleState: Value(nextLifecycleState),
        );
        if (localState.exists) {
          // 更新现有记录
          // 只有当状态实际发生变化时才执行更新
          // if (localState.asset!.syncStatus != nextStatus) {
          toUpdate.add(
            finalCompanion.copyWith(
              id: Value(localState.asset!.id),
              cloudUuid: Value(
                nextStatus == SyncStatus.localOnly ? null : change.recordId,
              ),
            ),
          );
          // }
        } else {
          // 插入新记录
          toInsert.add(finalCompanion);
        }
      }
    }

    // 6. 在一个事务中批量执行所有数据库操作
    if (toInsert.isEmpty && toUpdate.isEmpty && toDelete.isEmpty) {
      _log.info('增量变更分析完成，无需执行数据库操作。');
      return;
    }

    await _db.transaction(() async {
      // 使用 batch.insertAll 明确执行批量插入
      if (toInsert.isNotEmpty) {
        await _db.batch((batch) => batch.insertAll(_db.mediaAssets, toInsert));
        _log.info('成功插入 ${toInsert.length} 条新的媒体资源记录。');
      }

      // 使用 batch.replace 明确执行批量更新 (因为每个 companion 都有 id)
      if (toUpdate.isNotEmpty) {
        await _db.batch((batch) {
          for (final companion in toUpdate) {
            batch.replace(_db.mediaAssets, companion);
          }
        });
        _log.info('成功更新了 ${toUpdate.length} 条媒体资源记录。');
      }

      if (toDelete.isNotEmpty) {
        await (_db.delete(
          _db.mediaAssets,
        )..where((tbl) => tbl.id.isIn(toDelete))).go();
        _log.info('根据矩阵规则，永久删除了 ${toDelete.length} 条记录。');
      }
    });
    _log.info('增量变更应用完成。');
  }

  // 从 Changelog 解析出对应的云端事件
  _CloudEvent _getCloudEvent(Changelog change) {
    if (change.operationType == OperationType.deleted) {
      return _CloudEvent.deleted;
    }
    if (change.payload?['deleted'] == true) {
      return _CloudEvent.updatedDeleted;
    }
    if (change.operationType == OperationType.created) {
      return _CloudEvent.created;
    }
    return _CloudEvent.updated;
  }

  MediaAssetsCompanion _changelogToCompanion(Changelog change) {
    final payload = change.payload ?? {};

    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    MediaType mapMediaType(String? type) {
      if (type == null) return MediaType.image; // 提供一个默认值
      return MediaType.values.byName(type.toLowerCase());
    }

    return MediaAssetsCompanion(
      cloudUuid: Value(change.recordId),
      contentHash: Value(payload['hash'] as String?),
      assetType: Value(mapMediaType(payload['item_type'] as String?)),
      fileName: Value(payload['original_filename'] as String?),
      width: Value(parseInt(payload['width'])),
      height: Value(parseInt(payload['height'])),
      durationSec: Value(parseInt(payload['duration'])),
      // 如果云端没有提供 created_at，则使用当前时间作为备用
      createdAt: Value(
        payload['created_at'] != null
            ? DateTime.parse(payload['created_at'] as String)
            : DateTime.now(),
      ),
      updatedAt: Value(DateTime.now()),
      // 根据 payload 'deleted' 字段设置生命周期状态
      // lifecycleState: Value(
      //     payload['deleted'] == true ? LifecycleState.trashed : LifecycleState.active),
    );
  }
}
