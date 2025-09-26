import 'dart:async';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/features/background_jobs/core/isolate/isolate_job_manager.dart';
import 'package:mobile/features/background_jobs/impl/media_sync/domain/isolate_handler.dart';
import 'package:mobile/features/background_jobs/impl/media_sync/models/sync_models.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:rxdart/rxdart.dart';

/// 作为同步功能与应用其他部分交互的唯一门面 (Facade)。
@lazySingleton
class MediaSyncService {
  final _log = Logger('MediaSyncService');
  final IsolateJobManager _jobManager; // 使用通用的 JobManager

  StreamSubscription? _mediaChangeSubscription;
  final _mediaChangeController = StreamController<void>.broadcast();

  // 暴露同步状态的 Stream
  final _syncStateController = BehaviorSubject<SyncProgressUpdate>.seeded(
    SyncProgressUpdate(SyncStatus.idle),
  );
  Stream<SyncProgressUpdate> get syncStateStream => _syncStateController.stream;

  MediaSyncService(this._jobManager) {
    _startListeningForMediaChanges();
    _startListeningForIsolateUpdates();
  }

  Future<void> start() async {
    return _jobManager.start();
  }

  /// 发送命令的辅助方法
  Future<void> _sendCommand(SyncCommand command) async {
    await _jobManager.submitJob(
      MediaSyncIsolateHandler.taskName,
      payload: command.name,
    );
  }

  Future<void> triggerFullSync() async {
    await _sendCommand(SyncCommand.triggerFullSync);
  }

  Future<void> triggerCloudSync() async {
    await _sendCommand(SyncCommand.triggerCloudSync);
  }

  Future<void> _startListeningForMediaChanges() async {
    final ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      _log.info(
        'Photo library permission granted. Starting to listen for changes.',
      );

      _mediaChangeSubscription = _mediaChangeController.stream
          .debounceTime(const Duration(milliseconds: 800))
          .listen((_) {
            _log.info(
              'Debounced media change detected. Triggering local sync.',
            );
            _sendCommand(SyncCommand.triggerLocalMediaChangeSync);
          });

      PhotoManager.addChangeCallback(_onMediaChangeNotified);
      PhotoManager.startChangeNotify();
    } else {
      _log.warning(
        'Photo library permission denied. Cannot listen for media changes.',
      );
    }
  }

  void _onMediaChangeNotified(MethodCall call) {
    _mediaChangeController.add(null);
  }

  /// 监听来自 Isolate 的特定于 MediaSync 的进度更新
  void _startListeningForIsolateUpdates() {
    // IsolateJobManager 的 jobResultStream 会广播所有从 Isolate 发回来的消息
    // 其中包括 Orchester 发送的 SyncProgressUpdate 对象
    _jobManager.jobResultStream.listen((event) {
      if (event is SyncProgressUpdate) {
        _syncStateController.add(event as SyncProgressUpdate);
      }
    });
  }

  @disposeMethod
  void dispose() {
    _log.info('Disposing MediaSyncService...');
    _mediaChangeSubscription?.cancel();
    _mediaChangeController.close();
    _syncStateController.close();
    PhotoManager.removeChangeCallback(_onMediaChangeNotified);
    PhotoManager.stopChangeNotify();
    // _jobManager.dispose(); // Manager 是单例，不应该在这里关闭
  }
}
