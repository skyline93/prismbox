// lib/services/local_media_observer.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/domain/repositories/media_repository.dart'; // 1. 引入 Repository
import 'package:mobile/services/sync_job_manager.dart';
import 'package:photo_manager/photo_manager.dart';

@lazySingleton
class LocalMediaObserver {
  final SyncJobManager _syncJobManager;
  final MediaRepository _mediaRepository; // 2. 添加 Repository 依赖
  bool _isObserving = false;

  Set<String> _knownAssetIds = {};
  bool _isProcessingChanges = false;

  // 3. 修改构造函数以接收 Repository
  LocalMediaObserver(this._syncJobManager, this._mediaRepository);

  void startObserving() async {
    if (_isObserving) return;

    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      if (kDebugMode) {
        print('[LocalMediaObserver] 权限被拒绝，无法监听本地媒体变更。');
      }
      return;
    }

    _isObserving = true;

    // 4. 执行对账并开始监听
    await _reconcileAndStartListening();

    if (kDebugMode) {
      print('[LocalMediaObserver] 已启动本地相册变更监听。');
    }
  }

  void stopObserving() {
    if (!_isObserving) return;
    PhotoManager.removeChangeCallback(_handleChanges);
    PhotoManager.stopChangeNotify();
    _isObserving = false;
    if (kDebugMode) {
      print('[LocalMediaObserver] 已停止本地相册变更监听。');
    }
  }

  /// 执行启动时对账，然后设置实时监听
  Future<void> _reconcileAndStartListening() async {
    if (kDebugMode) print('[LocalMediaObserver] 开始执行启动时对账...');

    // 1. 获取设备上的所有资产ID
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
    );
    final Set<String> deviceAssetIds = {};
    for (final path in paths) {
      final int count = await path.assetCountAsync;
      if (count == 0) continue;
      final List<AssetEntity> assets = await path.getAssetListRange(
        start: 0,
        end: count,
      );
      for (final asset in assets) {
        deviceAssetIds.add(asset.id);
      }
    }
    if (kDebugMode)
      print('[LocalMediaObserver] 设备上发现 ${deviceAssetIds.length} 个资产。');

    // 2. 从数据库获取所有已知的资产ID
    final Set<String> dbAssetIds = await _mediaRepository
        .getAllSyncedLocalAssetIds();
    if (kDebugMode)
      print('[LocalMediaObserver] 数据库中已知 ${dbAssetIds.length} 个资产。');

    // 3. 对比差异
    // 新增的：在设备上，但不在数据库里
    final Set<String> newIds = deviceAssetIds.difference(dbAssetIds);
    if (newIds.isNotEmpty) {
      if (kDebugMode)
        print('[LocalMediaObserver] [启动检查] 发现 ${newIds.length} 个新增资产，正在处理...');
      for (final String id in newIds) {
        _processNewAsset(id);
      }
    }

    // 删除的：在数据库里，但不在设备上
    final Set<String> deletedIds = dbAssetIds.difference(deviceAssetIds);
    if (deletedIds.isNotEmpty) {
      if (kDebugMode)
        print(
          '[LocalMediaObserver] [启动检查] 发现 ${deletedIds.length} 个已删除资产，正在处理...',
        );
      for (final String id in deletedIds) {
        _syncJobManager.handleLocalAssetDeletion(id);
      }
    }

    if (newIds.isEmpty && deletedIds.isEmpty && kDebugMode) {
      print('[LocalMediaObserver] [启动检查] 本地相册与数据库记录一致，无需操作。');
    }

    // 4. 对账完成后，用设备上的最新列表作为实时监听的基准
    _knownAssetIds = deviceAssetIds;

    // 5. 开始实时监听未来的变化
    PhotoManager.addChangeCallback(_handleChanges);
    PhotoManager.startChangeNotify();
  }

  void _handleChanges(MethodCall call) {
    if (kDebugMode) print('[LocalMediaObserver] 检测到相册变更通知！方法: ${call.method}');
    if (_isProcessingChanges) {
      if (kDebugMode) print('[LocalMediaObserver] 正在处理上一次变更，本次通知已忽略。');
      return;
    }
    _isProcessingChanges = true;
    Timer.run(() async {
      try {
        bool processed = await _tryProcessWithMethodCall(call);
        if (!processed) {
          if (kDebugMode)
            print('[LocalMediaObserver] MethodCall 未提供详细信息，启动完整的差异对比。');
          await _diffAndProcessChanges();
        }
      } finally {
        _isProcessingChanges = false;
      }
    });
  }

  Future<bool> _tryProcessWithMethodCall(MethodCall call) async {
    if (call.method != 'onNotify') return false;
    final Map? args = call.arguments as Map?;
    if (args == null) return false;
    final createdIds = (args['create'] as List? ?? []).cast<String>();
    final deletedIds = (args['delete'] as List? ?? []).cast<String>();
    if (createdIds.isEmpty && deletedIds.isEmpty) return false;
    if (createdIds.isNotEmpty) {
      if (kDebugMode)
        print(
          '[LocalMediaObserver] 从 MethodCall 解析到 ${createdIds.length} 个新增资产。',
        );
      createdIds.forEach(_processNewAsset);
    }
    if (deletedIds.isNotEmpty) {
      if (kDebugMode)
        print(
          '[LocalMediaObserver] 从 MethodCall 解析到 ${deletedIds.length} 个删除资产。',
        );
      deletedIds.forEach(_syncJobManager.handleLocalAssetDeletion);
    }
    _knownAssetIds.addAll(createdIds);
    _knownAssetIds.removeAll(deletedIds);
    return true;
  }

  Future<void> _diffAndProcessChanges() async {
    final paths = await PhotoManager.getAssetPathList(type: RequestType.common);
    final latestAssetIds = <String>{};
    for (final path in paths) {
      final count = await path.assetCountAsync;
      if (count > 0) {
        final assets = await path.getAssetListRange(start: 0, end: count);
        assets.forEach((asset) => latestAssetIds.add(asset.id));
      }
    }
    final createdIds = latestAssetIds.difference(_knownAssetIds);
    if (createdIds.isNotEmpty) {
      if (kDebugMode)
        print('[LocalMediaObserver] 通过对比发现 ${createdIds.length} 个新增资产。');
      createdIds.forEach(_processNewAsset);
    }
    final deletedIds = _knownAssetIds.difference(latestAssetIds);
    if (deletedIds.isNotEmpty) {
      if (kDebugMode)
        print('[LocalMediaObserver] 通过对比发现 ${deletedIds.length} 个删除资产。');
      deletedIds.forEach(_syncJobManager.handleLocalAssetDeletion);
    }
    _knownAssetIds = latestAssetIds;
  }

  Future<void> _processNewAsset(String id) async {
    try {
      final asset = await AssetEntity.fromId(id);
      if (asset != null) {
        if (kDebugMode) print('[LocalMediaObserver] 正在处理新增资产: ${asset.id}');
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
