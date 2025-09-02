// lib/services/local_media_observer.dart

import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/core/storage/sync_state_service.dart';
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
  final SyncJobManager _syncJobManager;
  final MediaRepository _mediaRepository;
  final SyncStateService _syncStateService;
  final AlbumSyncService _albumSyncService;

  ObserverStatus _status = ObserverStatus.idle;
  FlutterIsolate? _reconciliationIsolate;
  AssetProcessor? _assetProcessor;
  bool _isChangeHandlingLocked = false;

  LocalMediaObserver(
    this._syncJobManager,
    this._mediaRepository,
    this._syncStateService,
    this._albumSyncService,
  );

  /// 启动本地媒体监听服务。
  Future<void> startObserving() async {
    if (_status == ObserverStatus.initializing || _status == ObserverStatus.running) {
      if (kDebugMode) {
        print('[LocalMediaObserver] Observer is already starting or running.');
      }
      return;
    }
    _status = ObserverStatus.initializing;

    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      if (kDebugMode) {
        print('[LocalMediaObserver] Permission denied. Cannot observe local media.');
      }
      _status = ObserverStatus.idle;
      return;
    }

    _assetProcessor = AssetProcessor(
      processFunction: _processNewAsset,
      workerCount: 4,
    );

    await _performInitialReconciliation();
    _startListeningForChanges();
    
    _status = ObserverStatus.running;
    if (kDebugMode) {
      print('[LocalMediaObserver] Started observing local media changes.');
    }
  }

  /// 停止本地媒体监听服务。
  void stopObserving() {
    if (_status != ObserverStatus.running) {
      return;
    }
    
    PhotoManager.removeChangeCallback(_onMediaChangeNotified);
    PhotoManager.stopChangeNotify();

    _assetProcessor?.dispose();
    _reconciliationIsolate?.kill();
    _reconciliationIsolate = null;
    
    _status = ObserverStatus.stopped;
    if (kDebugMode) {
      print('[LocalMediaObserver] Stopped observing local media changes.');
    }
  }

  /// 执行启动时的全量对账。
  Future<void> _performInitialReconciliation() async {
    if (kDebugMode) {
      print('[LocalMediaObserver] Starting initial reconciliation...');
    }
    try {
      final Set<String> dbAssetIds = await _mediaRepository.getAllSyncedLocalAssetIds();
      if (kDebugMode) {
        print('[LocalMediaObserver] Found ${dbAssetIds.length} assets in the database.');
      }

      final result = await _runReconciliationInIsolate(dbAssetIds);

      await _albumSyncService.synchronizeAllSources(localAlbums: result.localAlbums);
      await _processReconciliationResult(result, "[Initial Check]");

      await _syncStateService.setLastSyncTimestamp(DateTime.now());
      if (kDebugMode) {
        print('[LocalMediaObserver] Initial reconciliation complete. Last sync timestamp updated.');
      }
    } catch (e, s) {
        if (kDebugMode) {
            print('[LocalMediaObserver] An error occurred during initial reconciliation: $e\n$s');
        }
    }
  }

  /// 在后台 Isolate 中运行对账任务并返回结果。
  Future<ReconciliationResult> _runReconciliationInIsolate(Set<String> dbAssetIds) async {
    final completer = Completer<ReconciliationResult>();
    final receivePort = ReceivePort();

    receivePort.listen((message) {
      if (message is Map<String, dynamic>) {
        completer.complete(ReconciliationResult.fromJson(message));
      }
      receivePort.close();
    });

    final params = {
      'port': receivePort.sendPort,
      'dbAssetIds': dbAssetIds.toList(),
    };
    
    _reconciliationIsolate?.kill();
    _reconciliationIsolate = await FlutterIsolate.spawn(reconcileMediaInBackground, params);

    final result = await completer.future;
    _reconciliationIsolate = null;
    return result;
  }

  /// 处理对账结果，包括新增和删除的资产。
  Future<void> _processReconciliationResult(ReconciliationResult result, String context) async {
    if (result.newAssetIds.isNotEmpty) {
      if (kDebugMode) {
        print('[LocalMediaObserver] $context Found ${result.newAssetIds.length} new assets. Adding to processing queue...');
      }
      _assetProcessor?.addAll(result.newAssetIds);
    }

    if (result.deletedAssetIds.isNotEmpty) {
      if (kDebugMode) {
        print('[LocalMediaObserver] $context Found ${result.deletedAssetIds.length} deleted assets. Processing deletions...');
      }
      await _processInBatches(result.deletedAssetIds, _syncJobManager.handleLocalAssetDeletion);
    }

    if (result.newAssetIds.isEmpty && result.deletedAssetIds.isEmpty && kDebugMode) {
      print('[LocalMediaObserver] $context No changes detected.');
    }
  }

  /// 注册监听器以接收未来的媒体变更通知。
  void _startListeningForChanges() {
    PhotoManager.addChangeCallback(_onMediaChangeNotified);
    PhotoManager.startChangeNotify();
  }

  /// 处理来自 PhotoManager 的变更通知。
  void _onMediaChangeNotified(MethodCall call) {
    if (kDebugMode) {
      print('[LocalMediaObserver] Media change notification received: ${call.method}');
    }
    if (_isChangeHandlingLocked) {
      if (kDebugMode) {
        print('[LocalMediaObserver] Already processing a change, ignoring this notification.');
      }
      return;
    }
    _isChangeHandlingLocked = true;
    Timer.run(() async {
      try {
        final bool processed = await _tryProcessWithMethodCall(call);
        if (!processed) {
          if (kDebugMode) {
            print('[LocalMediaObserver] MethodCall did not provide details. Running full reconciliation.');
          }
          await _performInitialReconciliation();
        }
      } catch (e, s) {
        if (kDebugMode) {
            print('[LocalMediaObserver] Error handling media change notification: $e\n$s');
        }
      }
      finally {
        _isChangeHandlingLocked = false;
      }
    });
  }

  /// 尝试从 MethodCall 中直接解析变更，如果成功则处理。
  Future<bool> _tryProcessWithMethodCall(MethodCall call) async {
    if (call.method != 'onNotify' || call.arguments is! Map) {
      return false;
    }
    
    final args = call.arguments as Map;
    final createdIds = (args['create'] as List? ?? []).cast<String>().toSet();
    final deletedIds = (args['delete'] as List? ?? []).cast<String>().toSet();

    if (createdIds.isEmpty && deletedIds.isEmpty) {
      return false;
    }
    
    final result = ReconciliationResult(newAssetIds: createdIds, deletedAssetIds: deletedIds, localAlbums: []);
    await _processReconciliationResult(result, "[Incremental Update]");
    return true;
  }

  /// 处理单个新增资产的逻辑。
  Future<void> _processNewAsset(String id) async {
    try {
      final asset = await AssetEntity.fromId(id);
      if (asset != null) {
        if (kDebugMode) {
          print('[LocalMediaObserver] Processing new asset: ${asset.id}');
        }
        await _syncJobManager.createUploadJobForNewAsset(
          asset,
          isAutoBackupEnabled: false,
        );
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('[LocalMediaObserver] Error processing new asset $id: $e\n$s');
      }
    }
  }

  /// 通用的分批处理函数。
  Future<void> _processInBatches<T>(
    Iterable<T> items,
    Future<void> Function(T item) processFunction, {
    int batchSize = 50,
  }) async {
    final itemList = items.toList();
    for (int i = 0; i < itemList.length; i += batchSize) {
      final end = (i + batchSize < itemList.length) ? i + batchSize : itemList.length;
      final batch = itemList.sublist(i, end);
      await Future.wait(batch.map(processFunction));
      await Future.delayed(Duration.zero);
    }
  }
}
