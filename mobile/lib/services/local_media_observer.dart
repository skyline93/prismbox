// lib/services/local_media_observer.dart

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/services/sync_job_manager.dart';
import 'package:photo_manager/photo_manager.dart';

@lazySingleton
class LocalMediaObserver {
  final SyncJobManager _syncJobManager;
  bool _isObserving = false;

  LocalMediaObserver(this._syncJobManager);

  void startObserving() async {
    if (_isObserving) return;

    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      print('[LocalMediaObserver] 权限被拒绝，无法监听本地媒体变更。');
      return;
    }

    _isObserving = true;
    // 回调函数的正确参数类型是 MethodCall
    PhotoManager.addChangeCallback(_handleChanges);
    PhotoManager.startChangeNotify();

    print('[LocalMediaObserver] 已启动本地相册变更监听。');
  }

  void stopObserving() {
    if (!_isObserving) return;
    PhotoManager.removeChangeCallback(_handleChanges);
    PhotoManager.stopChangeNotify();
    _isObserving = false;
    print('[LocalMediaObserver] 已停止本地相册变更监听。');
  }

  /// 正确的回调处理函数，参数为 MethodCall
  void _handleChanges(MethodCall call) {
    // 我们只关心 'onNotify' 方法
    if (call.method != 'onNotify') {
      return;
    }

    // 将参数转换为 Map
    final Map? args = call.arguments as Map?;
    if (args == null) {
      return;
    }

    // 提取新增资产的 ID 列表
    final List<String> createdIds = (args['create'] as List? ?? [])
        .cast<String>();
    if (createdIds.isNotEmpty) {
      print('[LocalMediaObserver] 检测到 ${createdIds.length} 个新增资产。');
      // 异步处理每一个新增的资产
      for (final String id in createdIds) {
        _processNewAsset(id);
      }
    }

    // 提取删除资产的 ID 列表
    final List<String> deletedIds = (args['delete'] as List? ?? [])
        .cast<String>();
    if (deletedIds.isNotEmpty) {
      print('[LocalMediaObserver] 检测到 ${deletedIds.length} 个删除资产。');
      for (final String id in deletedIds) {
        _syncJobManager.handleLocalAssetDeletion(id);
      }
    }
  }

  /// 异步辅助函数，用于处理单个新增资产
  /// 因为回调本身是同步的，所以我们将 I/O 操作放在一个独立的 async 函数中
  Future<void> _processNewAsset(String id) async {
    try {
      final AssetEntity? asset = await AssetEntity.fromId(id);
      if (asset != null) {
        print('[LocalMediaObserver] 正在处理新增资产: ${asset.id}');
        // TODO: 从用户设置中读取是否开启自动备份
        const bool isAutoBackupEnabled = true; // 假设默认为 true
        await _syncJobManager.createUploadJobForNewAsset(
          asset,
          isAutoBackupEnabled: isAutoBackupEnabled,
        );
      }
    } catch (e, s) {
      print('[LocalMediaObserver] 处理新资产 $id 时出错: $e');
      print(s);
    }
  }
}
