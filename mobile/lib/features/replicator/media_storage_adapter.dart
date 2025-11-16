import 'package:drift/drift.dart';
import 'package:flutter_replicator/flutter_replicator.dart';
import 'package:logging/logging.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/domain/repositories/user_repository.dart';

final mediaTableName = 'medias';

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
    final userRepo = getIt<UserRepository>();
    final user = await userRepo.getCurrentUser();

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

        if (payload["user_id"] != user.id) {
          continue;
        }

        final contentHash = payload['hash'] as String;
        final existingAsset = localAssetsMap[contentHash];
        final companion = _changelogToCompanion(change);

        if (existingAsset != null) {
          // 保护已存在的拍摄时间，只更新其他字段
          toUpdate.add(
            companion.copyWith(
              id: Value(existingAsset.id),
              syncStatus: const Value(SyncStatus.synced),
              // 保持已存在的拍摄时间不变
              mediaTakenAt: Value(existingAsset.mediaTakenAt),
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
    final userRepo = getIt<UserRepository>();
    final user = await userRepo.getCurrentUser();

    if (changes.isEmpty) return;
    _log.info('开始应用 ${changes.length} 条增量变更（严格顺序，保留原始逻辑）...');

    // 1. 确保变更是按 sequenceId 严格排序的
    changes.sort((a, b) => a.sequenceId.compareTo(b.sequenceId));

    // 2. 逐条处理每个变更
    for (final change in changes) {
      final payload = change.payload;
      if (payload == null) {
        continue;
      }

      if (payload["user_id"] != user.id) {
        continue;
      }

      // 对每一条变更都使用一个独立的事务来确保原子性
      await _db
          .transaction(() async {
            _log.fine(
              '正在处理 Seq ID: ${change.sequenceId}, Record ID: ${change.recordId}, Op: ${change.operationType}',
            );

            // --- 以下是完全复用的您原有的核心业务逻辑，但仅针对单个 `change` ---

            // 2.1. 查找本地资源，优先使用 UUID，其次是 Hash
            // （查询从批量 `isIn` 变为针对单条记录的 `equals`）
            final cloudUuid = change.recordId;
            final contentHash = change.payload?['hash'] as String?;

            MediaAsset? localAsset;
            // 构造一个可能匹配 UUID 或 Hash 的查询
            final query = _db.select(_db.mediaAssets)
              ..where((tbl) {
                Expression<bool> predicate = tbl.cloudUuid.equals(cloudUuid);
                if (contentHash != null) {
                  predicate = predicate | tbl.contentHash.equals(contentHash);
                }
                return predicate;
              });
            final possibleAssets = await query.get();

            // 采用与您原始代码完全相同的查找优先级：优先匹配UUID
            if (possibleAssets.isNotEmpty) {
              localAsset = possibleAssets.firstWhere(
                (a) => a.cloudUuid == cloudUuid,
                orElse: () => possibleAssets.first, // 如果没有UUID匹配，则使用Hash匹配的结果
              );
            }

            // 2.2. 确定云端事件和本地状态
            final event = _getCloudEvent(change);
            final localState = _LocalState(localAsset);

            // 2.3. 使用您的状态矩阵计算下一个同步状态
            final nextStatus = localState.determineNextSyncStatus(event);

            // 2.4. 根据计算结果，立即执行数据库操作（而不是加入列表）
            final companion = _changelogToCompanion(change);

            if (nextStatus == null) {
              // 对应矩阵中的 'x' (删除或忽略)
              if (localState.exists &&
                  localState.asset!.syncStatus == SyncStatus.cloudOnly) {
                await (_db.delete(
                  _db.mediaAssets,
                )..where((tbl) => tbl.id.equals(localState.asset!.id))).go();
                _log.info(
                  'Seq ID: ${change.sequenceId} -> 已删除 cloudOnly 记录 (ID: ${localState.asset!.id})',
                );
              }
            } else {
              var finalCompanion = companion.copyWith(
                syncStatus: Value(nextStatus),
                // 注意: lifecycleState 的逻辑保持您原有的方式，即不在此处显式设置，依赖于其他逻辑
              );

              if (localState.exists) {
                // 保护已存在的拍摄时间，只更新其他字段
                await (_db.update(
                  _db.mediaAssets,
                )..where((tbl) => tbl.id.equals(localState.asset!.id))).write(
                  finalCompanion.copyWith(
                    // 注意：这里不再需要手动传递 id，因为 where 条件已经定位了记录
                    cloudUuid: Value(
                      nextStatus == SyncStatus.localOnly
                          ? null
                          : change.recordId,
                    ),
                    // 保持已存在的拍摄时间不变
                    mediaTakenAt: Value(localState.asset!.mediaTakenAt),
                  ),
                );
                _log.info(
                  'Seq ID: ${change.sequenceId} -> 已更新记录 (ID: ${localState.asset!.id})，新状态: $nextStatus',
                );
              } else {
                // 插入新记录
                await _db.into(_db.mediaAssets).insert(finalCompanion);
                _log.info(
                  'Seq ID: ${change.sequenceId} -> 已插入新记录，状态: $nextStatus',
                );
              }
            }
          })
          .catchError((e, s) {
            // 如果事务失败，记录严重错误并重新抛出，以中止整个同步过程
            _log.severe('处理序列ID ${change.sequenceId} 时发生严重错误，同步流程已中止。', e, s);
            throw Exception(
              'Failed to apply change with sequence ID ${change.sequenceId}: $e',
            );
          });

      // 3. 每成功处理一条，就立即更新一次序列号
      await setLastSyncedSequenceId(change.sequenceId);
    }

    _log.info('所有增量变更已成功按顺序应用。');
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

    return MediaAssetsCompanion(
      cloudUuid: Value(change.recordId),
      contentHash: Value(payload['hash'] as String?),
      assetType: Value(MediaType.fromStringStrict(payload['item_type'])),
      fileName: Value(payload['original_filename'] as String?),
      width: Value(parseInt(payload['width'])),
      height: Value(parseInt(payload['height'])),
      durationSec: Value(parseInt(payload['duration'])),
      // 优先使用 media_taken_at（实际拍摄时间），如果没有则使用 created_at（服务器创建时间），最后才使用当前时间
      createdAt: Value(
        payload['created_at'] != null
            ? DateTime.parse(payload['created_at'] as String)
            : DateTime.now(),
      ),
      // 设置媒体拍摄时间，优先使用 media_taken_at，否则使用 created_at，最后使用当前时间
      mediaTakenAt: Value(
        payload['media_taken_at'] != null
            ? DateTime.parse(payload['media_taken_at'] as String)
            : (payload['created_at'] != null
                ? DateTime.parse(payload['created_at'] as String)
                : DateTime.now()),
      ),
      updatedAt: Value(DateTime.now()),
      // 根据 payload 'deleted' 字段设置生命周期状态
      // lifecycleState: Value(
      //     payload['deleted'] == true ? LifecycleState.trashed : LifecycleState.active),
    );
  }
}
