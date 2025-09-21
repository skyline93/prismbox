import 'package:drift/drift.dart';
import 'package:flutter_replicator/flutter_replicator.dart';
import 'package:logging/logging.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/core/service_locator.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';

final mediaTableName = 'media';

/// MediaStorageAdapter 实现了 StorageAdapter 抽象类，是云端同步引擎与本地数据库之间的桥梁。
///
/// ## 设计原则 (最终版) ##
///
/// 1.  **用户体验优先**: 同步逻辑的设计以符合用户直觉为第一要务。
///
/// 2.  **远程删除 = 本地解耦**: 任何来自云端的删除事件（软删除或硬删除），
///     对于一个已同步 (`synced`) 的本地资源，都只意味着断开同步链接，
///     使其变回一个普通的本地文件 (`localOnlyNotSelected`)。
///     这避免了远程操作导致本地文件意外进入回收站或从回收站恢复的反直觉行为。
///
/// 3.  **本地意图至上**: 只有用户在本机上执行删除操作，才会改变资源的生命周期状态
///     (例如，从 `active` 变为 `trashed`)。
///
/// 4.  **职责分离**:
///     - `syncStatus`: 严格管理本地记录与云端的 **同步关系**。
///     - `lifecycleState`: 严格管理资源本身的 **生命周期**，主要由本地用户操作驱动。
///
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
      return;
    }
    _log.info('正在为全量同步做准备：重置与云端相关的媒体资源...');
    await _db.transaction(() async {
      final deleteCloudOnly = _db.delete(_db.mediaAssets)
        ..where((tbl) => tbl.syncStatus.equals(SyncStatus.cloudOnly.name));
      await deleteCloudOnly.go();

      final updateSynced = _db.update(_db.mediaAssets)
        ..where((tbl) => tbl.syncStatus.equals(SyncStatus.synced.name));
      await updateSynced.write(
        const MediaAssetsCompanion(
          syncStatus: Value(SyncStatus.localOnlyNotSelected),
          cloudUuid: Value(null),
        ),
      );
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
        return;
      }

      final query = _db.select(_db.mediaAssets)
        ..where((tbl) => tbl.contentHash.isIn(cloudHashes));
      final localAssetsMap = {
        for (var asset in await query.get()) asset.contentHash!: asset,
      };

      final List<MediaAssetsCompanion> toInsert = [];
      final List<MediaAssetsCompanion> toUpdate = [];

      for (final change in data) {
        final payload = change.payload;
        if (payload == null ||
            payload['hash'] == null ||
            (payload['deleted'] as bool? ?? false)) {
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
      }
      if (toUpdate.isNotEmpty) {
        await _db.batch((batch) => batch.replaceAll(_db.mediaAssets, toUpdate));
      }
    });
  }

  @override
  Future<void> applyIncrementalChanges(List<Changelog> changes) async {
    if (changes.isEmpty) {
      return;
    }
    _log.info('正在应用 ${changes.length} 条增量变更...');
    await _db.transaction(() async {
      final deletes = changes
          .where((c) => c.operationType == OperationType.deleted)
          .toList();
      final upserts = changes
          .where((c) => c.operationType != OperationType.deleted)
          .toList();

      if (deletes.isNotEmpty) {
        await _handleHardDeletes(deletes);
      }
      if (upserts.isNotEmpty) {
        await _handleUpserts(upserts);
      }
    });
    _log.info('增量变更应用完成。');
  }

  Future<void> _handleHardDeletes(List<Changelog> deletes) async {
    final cloudUuids = deletes.map((c) => c.recordId).toList();
    final query = _db.select(_db.mediaAssets)
      ..where((tbl) => tbl.cloudUuid.isIn(cloudUuids));

    final List<int> idsToDelete = [];
    final List<int> idsToDecouple = [];

    for (final asset in await query.get()) {
      if (asset.syncStatus == SyncStatus.cloudOnly) {
        idsToDelete.add(asset.id);
      } else if (asset.syncStatus == SyncStatus.synced) {
        idsToDecouple.add(asset.id);
      }
    }

    if (idsToDelete.isNotEmpty) {
      await (_db.delete(
        _db.mediaAssets,
      )..where((tbl) => tbl.id.isIn(idsToDelete))).go();
      _log.info('[Hard Delete] 永久删除了 ${idsToDelete.length} 条“仅云上”的记录。');
    }
    if (idsToDecouple.isNotEmpty) {
      // --- FIX: Respect local lifecycleState on hard delete decoupling ---
      await (_db.update(
        _db.mediaAssets,
      )..where((tbl) => tbl.id.isIn(idsToDecouple))).write(
        MediaAssetsCompanion(
          syncStatus: const Value(SyncStatus.localOnlyNotSelected),
          cloudUuid: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );
      _log.info('[Hard Delete] 将 ${idsToDecouple.length} 条记录解耦为“仅本地”。');
    }
  }

  Future<void> _handleUpserts(List<Changelog> upserts) async {
    final cloudUuids = upserts.map((c) => c.recordId).toSet();
    final hashes = upserts
        .map((c) => c.payload?['hash'] as String?)
        .whereType<String>()
        .toSet();
    if (cloudUuids.isEmpty && hashes.isEmpty) {
      return;
    }

    final query = _db.select(_db.mediaAssets)
      ..where(
        (tbl) => tbl.cloudUuid.isIn(cloudUuids) | tbl.contentHash.isIn(hashes),
      );
    final existingAssets = await query.get();

    final uuidMap = {
      for (var asset in existingAssets)
        if (asset.cloudUuid != null) asset.cloudUuid!: asset,
    };
    final hashMap = {
      for (var asset in existingAssets)
        if (asset.contentHash != null) asset.contentHash!: asset,
    };

    final List<MediaAssetsCompanion> toInsert = [];
    final List<MediaAssetsCompanion> toUpdate = [];
    final List<int> idsToDecouple = [];

    for (final change in upserts) {
      final payload = change.payload;
      if (payload == null) {
        continue;
      }

      final existingAsset =
          uuidMap[change.recordId] ?? hashMap[payload['hash'] as String?];
      final isSoftDelete = payload['deleted'] as bool? ?? false;

      if (isSoftDelete &&
          existingAsset != null &&
          existingAsset.syncStatus == SyncStatus.synced) {
        idsToDecouple.add(existingAsset.id);
        continue;
      }

      final companion = _changelogToCompanion(change);

      if (existingAsset != null) {
        if (existingAsset.syncStatus == SyncStatus.localOnlyNotSelected) {
          toUpdate.add(
            companion.copyWith(
              id: Value(existingAsset.id),
              syncStatus: const Value(SyncStatus.synced),
            ),
          );
        } else {
          if (change.operationType == OperationType.created) {
            continue;
          }
          toUpdate.add(companion.copyWith(id: Value(existingAsset.id)));
        }
      } else if (!isSoftDelete) {
        toInsert.add(
          companion.copyWith(syncStatus: const Value(SyncStatus.cloudOnly)),
        );
      }
    }

    if (idsToDecouple.isNotEmpty) {
      // --- FIX: Respect local lifecycleState on soft delete decoupling ---
      await (_db.update(
        _db.mediaAssets,
      )..where((tbl) => tbl.id.isIn(idsToDecouple))).write(
        MediaAssetsCompanion(
          syncStatus: const Value(SyncStatus.localOnlyNotSelected),
          cloudUuid: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );
      _log.info('[Soft Delete] 将 ${idsToDecouple.length} 条记录解耦为“仅本地”。');
    }

    if (toInsert.isNotEmpty) {
      await _db.batch((batch) => batch.insertAll(_db.mediaAssets, toInsert));
      _log.info('[Upsert] 插入了 ${toInsert.length} 条“仅云上”的新记录。');
    }
    if (toUpdate.isNotEmpty) {
      await _db.batch((batch) => batch.replaceAll(_db.mediaAssets, toUpdate));
      _log.info('[Upsert] 更新了 ${toUpdate.length} 条本地记录的状态。');
    }
  }

  MediaAssetsCompanion _changelogToCompanion(Changelog change) {
    final payload = change.payload!;
    final isDeleted = payload['deleted'] as bool? ?? false;

    int? parseInt(dynamic value) =>
        (value is int) ? value : (value is String ? int.tryParse(value) : null);
    MediaType mapMediaType(String type) =>
        MediaType.values.byName(type.toLowerCase());

    return MediaAssetsCompanion(
      cloudUuid: Value(change.recordId),
      contentHash: Value(payload['hash'] as String?),
      lifecycleState: Value(
        isDeleted ? LifecycleState.trashed : LifecycleState.active,
      ),
      assetType: Value(mapMediaType(payload['item_type'] as String)),
      fileName: Value(payload['original_filename'] as String?),
      width: Value(parseInt(payload['width'])),
      height: Value(parseInt(payload['height'])),
      durationSec: Value(parseInt(payload['duration'])),
      createdAt: Value(DateTime.parse(payload['created_at'] as String)),
      updatedAt: Value(DateTime.now()),
    );
  }
}
