// lib/services/local_media_observer.dart

import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:mobile/core/storage/sync_state_service.dart';
import 'package:mobile/domain/repositories/media_repository.dart';
import 'package:mobile/services/sync_job_manager.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:collection';
import 'package:mobile/services/album_sync_service.dart';

class AlbumData {
  final String id;
  final String name;
  final int assetCount;

  AlbumData({required this.id, required this.name, required this.assetCount});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'assetCount': assetCount,
  };

  factory AlbumData.fromJson(Map<String, dynamic> json) => AlbumData(
    id: json['id'] as String,
    name: json['name'] as String,
    assetCount: json['assetCount'] as int,
  );
}

class _ReconciliationResult {
  final Set<String> newIds;
  final Set<String> deletedIds;
  final List<AlbumData> albums;

  _ReconciliationResult({
    required this.newIds,
    required this.deletedIds,
    required this.albums,
  });

  Map<String, dynamic> toJson() => {
    'newIds': newIds.toList(),
    'deletedIds': deletedIds.toList(),
    'albums': albums.map((a) => a.toJson()).toList(),
  };

  factory _ReconciliationResult.fromJson(Map<String, dynamic> json) =>
      _ReconciliationResult(
        newIds: (json['newIds'] as List).cast<String>().toSet(),
        deletedIds: (json['deletedIds'] as List).cast<String>().toSet(),
        albums: (json['albums'] as List)
            .map((e) => AlbumData.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

@pragma('vm:entry-point')
Future<void> _reconcileInBackground(Map<String, dynamic> context) async {
  final SendPort port = context['port'];
  final Set<String> dbAssetIds = (context['dbAssetIds'] as List)
      .cast<String>()
      .toSet();

  final Set<String> deviceAssetIds = {};
  final List<Map<String, dynamic>> albumListJson = [];
  try {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
    );

    for (final path in paths) {
      final int count = await path.assetCountAsync;

      if (count > 0 || path.isAll) {
        // 即使是空相册也可能需要显示
        albumListJson.add({
          'id': path.id,
          'name': path.name,
          'assetCount': count,
        });
      }

      if (count == 0) continue;

      const int pageSize = 200;
      final int pageCount = (count / pageSize).ceil();

      for (int i = 0; i < pageCount; i++) {
        final List<AssetEntity> assets = await path.getAssetListPaged(
          page: i,
          size: pageSize,
        );
        for (final asset in assets) {
          deviceAssetIds.add(asset.id);
        }
      }
    }
  } catch (e, s) {
    if (kDebugMode) {
      print('[BackgroundReconcile] 在后台扫描设备资产时出错: $e');
      print(s);
    }
    port.send(
      _ReconciliationResult(newIds: {}, deletedIds: {}, albums: []).toJson(),
    );
    return;
  }

  final Set<String> newIds = deviceAssetIds.difference(dbAssetIds);
  final Set<String> deletedIds = dbAssetIds.difference(deviceAssetIds);

  port.send({
    'newIds': newIds.toList(),
    'deletedIds': deletedIds.toList(),
    'albums': albumListJson,
  });
}

@lazySingleton
class LocalMediaObserver {
  final SyncJobManager _syncJobManager;
  final MediaRepository _mediaRepository;
  final SyncStateService _syncStateService;
  final AlbumSyncService _albumSyncService;

  bool _isObserving = false;
  bool _isProcessingChanges = false;
  FlutterIsolate? _reconciliationIsolate;
  AssetProcessor? _assetProcessor;

  LocalMediaObserver(
    this._syncJobManager,
    this._mediaRepository,
    this._syncStateService,
    this._albumSyncService,
  );

  void startObserving() async {
    if (_isObserving) {
      return;
    }

    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      if (kDebugMode) {
        print('[LocalMediaObserver] 权限被拒绝，无法监听本地媒体变更。');
      }
      return;
    }

    _assetProcessor = AssetProcessor(
      processFunction: _processNewAsset,
      workerCount: 4, // 核心参数：同时运行4个worker。可以根据设备性能调整 (3-5是个安全范围)
    );

    _isObserving = true;

    await _reconcileAndStartListening();

    if (kDebugMode) {
      print('[LocalMediaObserver] 已启动本地相册变更监听。');
    }
  }

  void stopObserving() {
    if (!_isObserving) {
      return;
    }
    PhotoManager.removeChangeCallback(_handleChanges);
    PhotoManager.stopChangeNotify();

    _assetProcessor?.dispose();
    _reconciliationIsolate?.kill();
    _reconciliationIsolate = null;
    _isObserving = false;
    if (kDebugMode) {
      print('[LocalMediaObserver] 已停止本地相册变更监听。');
    }
  }

  Future<void> _processInBatches<T>(
    Iterable<T> items,
    Future<void> Function(T item) processFunction, {
    int batchSize = 50,
  }) async {
    final itemList = items.toList();
    for (int i = 0; i < itemList.length; i += batchSize) {
      final end = (i + batchSize < itemList.length)
          ? i + batchSize
          : itemList.length;
      final batch = itemList.sublist(i, end);

      for (final item in batch) {
        await processFunction(item);
      }

      await Future.delayed(Duration.zero);
    }
  }

  Future<void> _reconcileAndStartListening() async {
    if (kDebugMode) {
      print('[LocalMediaObserver] 开始执行启动时对账...');
    }
    final Set<String> dbAssetIds = await _mediaRepository
        .getAllSyncedLocalAssetIds();
    if (kDebugMode) {
      print('[LocalMediaObserver] 数据库中已知 ${dbAssetIds.length} 个资产。');
    }

    if (kDebugMode) {
      print('[LocalMediaObserver] 正在将设备扫描任务分派到后台 Isolate...');
    }

    final completer = Completer<_ReconciliationResult>();
    final receivePort = ReceivePort();

    receivePort.listen((message) {
      if (message is Map<String, dynamic>) {
        completer.complete(_ReconciliationResult.fromJson(message));
      }
      receivePort.close();
    });

    final params = {
      'port': receivePort.sendPort,
      'dbAssetIds': dbAssetIds.toList(),
    };

    _reconciliationIsolate = await FlutterIsolate.spawn(
      _reconcileInBackground,
      params,
    );

    final result = await completer.future;
    _reconciliationIsolate = null;

    if (kDebugMode) {
      print('[LocalMediaObserver] 后台对账任务完成。');
    }

    // [修改点 2] 在处理资产之前或之后，调用相册同步服务
    // 将从后台 Isolate 获取到的相册数据传递给同步服务
    await _albumSyncService.syncAlbums(localAlbums: result.albums);

    if (result.newIds.isNotEmpty) {
      if (kDebugMode) {
        print(
          '[LocalMediaObserver] [启动检查] 发现 ${result.newIds.length} 个新增资产，正在分批处理...',
        );
      }
      _assetProcessor?.addAll(result.newIds);
    }

    if (result.deletedIds.isNotEmpty) {
      if (kDebugMode) {
        print(
          '[LocalMediaObserver] [启动检查] 发现 ${result.deletedIds.length} 个已删除资产，正在分批处理...',
        );
      }
      await _processInBatches(
        result.deletedIds,
        _syncJobManager.handleLocalAssetDeletion,
      );
    }

    if (result.newIds.isEmpty && result.deletedIds.isEmpty && kDebugMode) {
      print('[LocalMediaObserver] [启动检查] 本地相册与数据库记录一致，无需操作。');
    }
    await _syncStateService.setLastSyncTimestamp(DateTime.now());
    if (kDebugMode) {
      print('[LocalMediaObserver] 已更新最后同步时间戳。');
    }

    PhotoManager.addChangeCallback(_handleChanges);
    PhotoManager.startChangeNotify();
  }

  void _handleChanges(MethodCall call) {
    if (kDebugMode) {
      print('[LocalMediaObserver] 检测到相册变更通知！方法: ${call.method}');
    }
    if (_isProcessingChanges) {
      if (kDebugMode) {
        print('[LocalMediaObserver] 正在处理上一次变更，本次通知已忽略。');
      }
      return;
    }
    _isProcessingChanges = true;
    Timer.run(() async {
      try {
        final bool processed = await _tryProcessWithMethodCall(call);
        if (!processed) {
          if (kDebugMode) {
            print('[LocalMediaObserver] MethodCall 未提供详细信息，启动完整的差异对比。');
          }
          await _reconcileAndStartListening();
        }
      } finally {
        _isProcessingChanges = false;
      }
    });
  }

  Future<bool> _tryProcessWithMethodCall(MethodCall call) async {
    if (call.method != 'onNotify') {
      return false;
    }
    final Map? args = call.arguments as Map?;
    if (args == null) {
      return false;
    }
    final createdIds = (args['create'] as List? ?? []).cast<String>();
    final deletedIds = (args['delete'] as List? ?? []).cast<String>();
    if (createdIds.isEmpty && deletedIds.isEmpty) {
      return false;
    }

    if (createdIds.isNotEmpty) {
      if (kDebugMode) {
        print(
          '[LocalMediaObserver] 从 MethodCall 解析到 ${createdIds.length} 个新增资产。',
        );
      }
      _assetProcessor?.addAll(createdIds);
    }
    if (deletedIds.isNotEmpty) {
      if (kDebugMode) {
        print(
          '[LocalMediaObserver] 从 MethodCall 解析到 ${deletedIds.length} 个删除资产。',
        );
      }
      await _processInBatches(
        deletedIds,
        _syncJobManager.handleLocalAssetDeletion,
      );
    }

    return true;
  }

  Future<void> _processNewAsset(String id) async {
    try {
      final asset = await AssetEntity.fromId(id);
      if (asset != null) {
        if (kDebugMode) {
          print('[LocalMediaObserver] 正在处理新增资产: ${asset.id}');
        }
        await _syncJobManager.createUploadJobForNewAsset(
          asset,
          isAutoBackupEnabled: false,
        );
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('[LocalMediaObserver] 处理新资产 $id 时出错: $e');
        print(s);
      }
    }
  }
}

class AssetProcessor {
  final Future<void> Function(String id) processFunction;
  final int workerCount;
  final Queue<String> _queue = Queue<String>();
  final List<Future<void>> _workers = [];
  bool _isDisposed = false;

  AssetProcessor({required this.processFunction, this.workerCount = 4}) {
    _start();
  }

  void _start() {
    for (int i = 0; i < workerCount; i++) {
      _workers.add(_runWorker(i));
    }
  }

  void add(String id) {
    _queue.add(id);
  }

  void addAll(Iterable<String> ids) {
    _queue.addAll(ids);
  }

  Future<void> _runWorker(int workerId) async {
    if (kDebugMode) {
      print('[AssetProcessor] Worker $workerId started.');
    }
    while (!_isDisposed) {
      if (_queue.isNotEmpty) {
        final String assetId = _queue.removeFirst();
        try {
          await processFunction(assetId);
        } catch (e, s) {
          if (kDebugMode) {
            print(
              '[AssetProcessor] Worker $workerId failed to process $assetId: $e',
            );
            print(s);
          }
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    if (kDebugMode) {
      print('[AssetProcessor] Worker $workerId stopped.');
    }
  }

  void dispose() {
    _isDisposed = true;
  }
}
