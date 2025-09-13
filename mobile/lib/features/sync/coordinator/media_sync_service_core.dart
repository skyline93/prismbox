// lib/features/sync/coordinator/media_sync_service_core.dart

import 'dart:isolate';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/features/sync/handlers/asset_action_handler.dart';
import 'package:mobile/features/sync/isolate/sync_isolate.dart';
import 'package:mobile/features/sync/synchronizers/album_synchronizer.dart';
import 'package:mobile/features/sync/synchronizers/cloud_media_synchronizer.dart';
import 'package:mobile/features/sync/synchronizers/local_media_synchronizer.dart';

@injectable
class MediaSyncServiceCore {
  final SendPort _mainSendPort; // 用于向主 Isolate 发送状态更新
  final LocalMediaSynchronizer _localSync;
  final CloudMediaSynchronizer _cloudSync;
  final AlbumSynchronizer _albumSync;
  final AssetActionHandler _actionHandler;

  final _log = Logger('MediaSyncServiceCore');
  bool _isSyncInProgress = false;

  // 使用 @factoryParam 注入从 Isolate 入口传来的 SendPort
  MediaSyncServiceCore(
    @factoryParam SendPort mainSendPort,
    this._localSync,
    this._cloudSync,
    this._albumSync,
    this._actionHandler,
  ) : _mainSendPort = mainSendPort;

  /// 统一的命令处理入口
  void handleCommand(SyncCommand command) {
    switch (command) {
      case SyncCommand.triggerFullSync:
        _runFullSync();
        break;
      case SyncCommand.triggerCloudSync:
        _runCloudSync();
        break;
      case SyncCommand.dispose:
        // 在这里可以添加清理逻辑
        break;
    }
  }

  /// 执行完整的同步流程：本地对账 -> 云端同步
  Future<void> _runFullSync() async {
    if (_isSyncInProgress) {
      _log.warning(
        'Sync is already in progress. Ignoring triggerFullSync command.',
      );
      return;
    }
    _isSyncInProgress = true;
    _log.info('Starting full sync process...');

    try {
      // 1. 本地对账
      _sendStatus(SyncStatus.syncingLocal);
      final localResult = await _localSync.runFullReconciliation();

      // 2. 处理本地对账结果
      if (localResult.newAssetIds.isNotEmpty) {
        await _actionHandler.handleNewLocalAssets(localResult.newAssetIds);
      }
      if (localResult.deletedAssetIds.isNotEmpty) {
        await _actionHandler.handleDeletedLocalAssets(
          localResult.deletedAssetIds,
        );
      }
      await _albumSync.synchronizeLocalAlbums(localResult.localAlbums);
      _log.info('Local reconciliation and processing finished.');

      // 3. 云端同步
      await _runCloudSync(isChained: true);
    } catch (e, s) {
      _log.severe('An error occurred during the full sync process.', e, s);
      _sendStatus(SyncStatus.error, message: e.toString());
    } finally {
      _isSyncInProgress = false;
      _sendStatus(SyncStatus.idle);
      _log.info('Full sync process finished.');
    }
  }

  /// 仅执行云端同步
  Future<void> _runCloudSync({bool isChained = false}) async {
    if (!isChained) {
      // 如果是独立调用，需要检查锁
      if (_isSyncInProgress) {
        _log.warning(
          'Sync is already in progress. Ignoring triggerCloudSync command.',
        );
        return;
      }
      _isSyncInProgress = true;
      _log.info('Starting cloud-only sync process...');
    }

    try {
      // 1. 获取云端变更
      _sendStatus(SyncStatus.syncingCloud);
      final cloudResult = await _cloudSync.run();

      // 2. 应用云端变更
      await _actionHandler.handleCloudChanges(cloudResult);
      // 3. 同步云端相册（如果实现）
      await _albumSync.synchronizeRemoteAlbums();
      _log.info('Cloud sync and processing finished.');
    } catch (e, s) {
      _log.severe('An error occurred during the cloud sync process.', e, s);
      _sendStatus(SyncStatus.error, message: e.toString());
    } finally {
      if (!isChained) {
        // 如果是独立调用，需要释放锁并更新状态
        _isSyncInProgress = false;
        _sendStatus(SyncStatus.idle);
        _log.info('Cloud-only sync process finished.');
      }
    }
  }

  /// 向主 Isolate 发送状态更新
  void _sendStatus(SyncStatus status, {String? message}) {
    final state = SyncState(status, message: message);
    _mainSendPort.send(state);
  }
}
