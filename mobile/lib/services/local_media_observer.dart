// lib/services/local_media_observer.dart

import 'dart:async';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart'; // 引入 logging 包
import 'package:mobile/constants/settings_keys.dart';
import 'package:mobile/core/storage/sync_state_service.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/domain/repositories/media_repository.dart';
import 'package:mobile/services/album_sync_service.dart';
import 'package:mobile/services/background_tasks/local_media_reconciliation.dart';
import 'package:mobile/services/sync_job_manager.dart';
import 'package:mobile/utils/asset_processor.dart';
import 'package:photo_manager/photo_manager.dart';

/// 监听器的运行状态
enum ObserverStatus { idle, initializing, running, stopped }

@lazySingleton
class LocalMediaObserver {
  // 创建一个 Logger 实例
  final _log = Logger('LocalMediaObserver');

  final SyncJobManager _syncJobManager;
  final MediaRepository _mediaRepository;
  final SyncStateService _syncStateService;
  final AlbumSyncService _albumSyncService;
  final AppDatabase db;
  final UserSettingDao _userSettingDao;

  ObserverStatus _status = ObserverStatus.idle;
  FlutterIsolate? _reconciliationIsolate;
  AssetProcessor? _assetProcessor;
  bool _isChangeHandlingLocked = false;

  LocalMediaObserver(
    this._syncJobManager,
    this._mediaRepository,
    this._syncStateService,
    this._albumSyncService,
    this.db,
  ) : _userSettingDao = db.userSettingDao;

  /// 启动本地媒体监听服务。
  Future<void> startObserving() async {
    _log.info('Attempting to start local media observer...');
    if (_status == ObserverStatus.initializing ||
        _status == ObserverStatus.running) {
      _log.warning(
        'Observer is already starting or running. Current status: $_status.',
      );
      return;
    }
    _status = ObserverStatus.initializing;
    _log.info('Observer status set to initializing.');

    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      _log.warning('Permission denied. Cannot observe local media.');
      _status = ObserverStatus.idle;
      return;
    }
    _log.info('Photo library permission granted.');

    _assetProcessor = AssetProcessor(
      processFunction: _processNewAsset,
      workerCount: 4,
    );
    _log.info('AssetProcessor initialized with 4 workers.');

    // 根据首次同步完成状态，执行不同的对账策略
    await _runStartupReconciliation();

    _startListeningForChanges();

    _status = ObserverStatus.running;
    _log.info(
      'Successfully started observing local media changes. Status: running.',
    );
  }

  /// 停止本地媒体监听服务。
  void stopObserving() {
    _log.info('Attempting to stop local media observer...');
    if (_status != ObserverStatus.running) {
      _log.warning(
        'Observer is not running, cannot stop. Current status: $_status.',
      );
      return;
    }

    PhotoManager.removeChangeCallback(_onMediaChangeNotified);
    PhotoManager.stopChangeNotify();
    _log.info(
      'PhotoManager change listener removed and notifications stopped.',
    );

    _assetProcessor?.dispose();
    _log.info('AssetProcessor disposed.');

    _reconciliationIsolate?.kill();
    _reconciliationIsolate = null;
    _log.info('Reconciliation isolate killed.');

    _status = ObserverStatus.stopped;
    _log.info('Stopped observing local media changes. Status: stopped.');
  }

  /// 【新】执行启动对账，根据状态决定执行全量或增量对账。
  Future<void> _runStartupReconciliation() async {
    _log.info('Running startup reconciliation...');
    final isInitialSyncComplete =
        await _userSettingDao.getSetting(
          SettingKeys.initialReconciliationComplete,
        ) ==
        'true';
    _log.info(
      'Is initial full reconciliation complete? $isInitialSyncComplete.',
    );

    if (!isInitialSyncComplete) {
      // 如果首次全量对账未完成，则执行它
      await _performFullReconciliation();
    } else {
      // 否则，执行常规的增量对账
      await _performIncrementalReconciliation();
    }
  }

  /// 【修改】执行首次全量对账，成功后写入标志位。
  /// 此函数保证了任务的原子性：只有在所有步骤都成功后，才会标记为完成。
  Future<void> _performFullReconciliation() async {
    _log.info('Starting FIRST-TIME FULL reconciliation...');
    try {
      final dbAssetIds = await _mediaRepository.getAllSyncedLocalAssetIds();
      _log.info('Found ${dbAssetIds.length} assets in the local database.');

      final result = await _runReconciliationInIsolate(dbAssetIds);
      _log.info(
        'Reconciliation isolate completed. New: ${result.newAssetIds.length}, Deleted: ${result.deletedAssetIds.length}.',
      );

      await _albumSyncService.synchronizeAllSources(
        localAlbums: result.localAlbums,
      );
      _log.info('Album sources synchronized.');

      await _processReconciliationResult(result, '[Full Reconciliation]');

      // 所有步骤成功后，更新最后同步时间戳并设置完成标志
      await _syncStateService.setLastSyncTimestamp(DateTime.now());
      await _userSettingDao.upsertSetting(
        UserSettingsCompanion(
          key: const Value(SettingKeys.initialReconciliationComplete),
          value: const Value('true'),
        ),
      );

      _log.info('First-time full reconciliation COMPLETE. Flag set.');
    } catch (e, s) {
      _log.severe(
        'An error occurred during full reconciliation. It will be retried on next launch.',
        e,
        s,
      );
    }
  }

  /// 【新】执行后续启动时的增量对账。
  Future<void> _performIncrementalReconciliation() async {
    _log.info('Starting incremental reconciliation...');
    try {
      final dbAssetIds = await _mediaRepository.getAllSyncedLocalAssetIds();
      _log.finer(
        'Found ${dbAssetIds.length} assets in the local database for incremental check.',
      );

      final result = await _runReconciliationInIsolate(dbAssetIds);
      _log.info(
        'Reconciliation isolate completed. New: ${result.newAssetIds.length}, Deleted: ${result.deletedAssetIds.length}.',
      );

      // 检查是否有变更，避免不必要的处理
      if (result.newAssetIds.isEmpty && result.deletedAssetIds.isEmpty) {
        _log.info('Incremental reconciliation found no changes.');
        return;
      }

      // 仅在有变更时才同步相册和处理结果
      await _albumSyncService.synchronizeAllSources(
        localAlbums: result.localAlbums,
      );
      _log.info('Album sources synchronized due to detected changes.');

      await _processReconciliationResult(
        result,
        '[Incremental Reconciliation]',
      );

      await _syncStateService.setLastSyncTimestamp(DateTime.now());
      _log.info('Incremental reconciliation complete.');
    } catch (e, s) {
      _log.severe('An error occurred during incremental reconciliation.', e, s);
    }
  }

  /// 在后台 Isolate 中运行对账任务并返回结果。
  Future<ReconciliationResult> _runReconciliationInIsolate(
    Set<String> dbAssetIds,
  ) async {
    _log.info(
      'Spawning reconciliation isolate with ${dbAssetIds.length} DB asset IDs.',
    );
    final completer = Completer<ReconciliationResult>();
    final receivePort = ReceivePort();

    receivePort.listen((message) {
      if (message is Map<String, dynamic>) {
        _log.info('Received result from reconciliation isolate.');
        completer.complete(ReconciliationResult.fromJson(message));
      } else {
        _log.warning('Received unexpected message from isolate: $message');
        if (!completer.isCompleted) {
          completer.completeError('Unexpected message type from isolate');
        }
      }
      receivePort.close();
      _log.finer('Isolate receive port closed.');
    });

    final params = {
      'port': receivePort.sendPort,
      'dbAssetIds': dbAssetIds.toList(),
    };

    _reconciliationIsolate?.kill();
    _log.info('Previous isolate instance killed, spawning a new one.');
    _reconciliationIsolate = await FlutterIsolate.spawn(
      reconcileMediaInBackground,
      params,
    );

    final result = await completer.future;
    _reconciliationIsolate = null;
    _log.info('Reconciliation isolate has finished its work.');
    return result;
  }

  /// 处理对账结果，包括新增和删除的资产。
  Future<void> _processReconciliationResult(
    ReconciliationResult result,
    String context,
  ) async {
    _log.info('Processing reconciliation result for context: $context');
    if (result.newAssetIds.isNotEmpty) {
      _log.info(
        '$context: Found ${result.newAssetIds.length} new assets. Adding to processing queue...',
      );
      _assetProcessor?.addAll(result.newAssetIds);
    }

    if (result.deletedAssetIds.isNotEmpty) {
      _log.info(
        '$context: Found ${result.deletedAssetIds.length} deleted assets. Processing deletions...',
      );
      await _processInBatches(
        result.deletedAssetIds,
        _syncJobManager.handleLocalAssetDeletion,
      );
      _log.info(
        '$context: Finished processing ${result.deletedAssetIds.length} deletions.',
      );
    }

    if (result.newAssetIds.isEmpty && result.deletedAssetIds.isEmpty) {
      _log.info('$context: No changes detected.');
    }
  }

  /// 注册监听器以接收未来的媒体变更通知。
  void _startListeningForChanges() {
    _log.info('Registering listener for future media changes.');
    PhotoManager.addChangeCallback(_onMediaChangeNotified);
    PhotoManager.startChangeNotify();
  }

  /// 处理来自 PhotoManager 的变更通知。
  void _onMediaChangeNotified(MethodCall call) {
    _log.info('Media change notification received: ${call.method}');
    if (_isChangeHandlingLocked) {
      _log.warning(
        'Already processing a change, ignoring this notification to prevent race conditions.',
      );
      return;
    }
    _log.info('Locking change handling to process notification.');
    _isChangeHandlingLocked = true;
    Timer.run(() async {
      try {
        _log.finer(
          'Attempting to process notification with MethodCall details...',
        );
        final bool processed = await _tryProcessWithMethodCall(call);
        if (!processed) {
          _log.info(
            'MethodCall did not provide details or was not applicable. Running a fallback incremental reconciliation.',
          );
          // 后续的实时变更通知，应触发增量对账
          await _performIncrementalReconciliation();
        } else {
          _log.info('Successfully processed changes directly from MethodCall.');
        }
      } catch (e, s) {
        _log.severe('Error handling media change notification.', e, s);
      } finally {
        _log.info('Unlocking change handling.');
        _isChangeHandlingLocked = false;
      }
    });
  }

  /// 尝试从 MethodCall 中直接解析变更，如果成功则处理。
  Future<bool> _tryProcessWithMethodCall(MethodCall call) async {
    if (call.method != 'onNotify' || call.arguments is! Map) {
      _log.finer(
        'MethodCall is not a valid "onNotify" event, cannot process directly.',
      );
      return false;
    }

    final args = call.arguments as Map;
    final createdIds = (args['create'] as List? ?? []).cast<String>().toSet();
    final deletedIds = (args['delete'] as List? ?? []).cast<String>().toSet();
    _log.info(
      'Parsed from MethodCall: ${createdIds.length} created, ${deletedIds.length} deleted.',
    );

    if (createdIds.isEmpty && deletedIds.isEmpty) {
      _log.info('No asset changes found in MethodCall arguments.');
      return false;
    }

    final result = ReconciliationResult(
      newAssetIds: createdIds,
      deletedAssetIds: deletedIds,
      localAlbums:
          [], // Album changes are not detailed here, will be synced by reconciliation if needed.
    );
    await _processReconciliationResult(result, '[Incremental Update]');
    return true;
  }

  /// 处理单个新增资产的逻辑。
  Future<void> _processNewAsset(String id) async {
    _log.info('Processing new asset with local ID: $id');
    try {
      final asset = await AssetEntity.fromId(id);
      if (asset != null) {
        _log.info(
          'Successfully fetched AssetEntity for ID: ${asset.id}. Creating upload job.',
        );
        await _syncJobManager.createUploadJobForNewAsset(
          asset,
          isAutoBackupEnabled: false, // 假设默认行为
        );
        _log.info('Upload job created for asset: ${asset.id}');
      } else {
        _log.warning(
          'Could not find AssetEntity for ID: $id. It might have been deleted already.',
        );
      }
    } catch (e, s) {
      _log.severe('Error processing new asset ID $id.', e, s);
    }
  }

  /// 通用的分批处理函数。
  Future<void> _processInBatches<T>(
    Iterable<T> items,
    Future<void> Function(T item) processFunction, {
    int batchSize = 50,
  }) async {
    final itemList = items.toList();
    _log.info('Processing ${itemList.length} items in batches of $batchSize.');
    for (int i = 0; i < itemList.length; i += batchSize) {
      final end = (i + batchSize < itemList.length)
          ? i + batchSize
          : itemList.length;
      final batch = itemList.sublist(i, end);
      _log.finer(
        'Processing batch #${(i / batchSize).floor() + 1}, size: ${batch.length}.',
      );
      await Future.wait(batch.map(processFunction));
      // Yield to the event loop to prevent blocking
      await Future.delayed(Duration.zero);
    }
    _log.info('Finished processing all batches.');
  }
}
