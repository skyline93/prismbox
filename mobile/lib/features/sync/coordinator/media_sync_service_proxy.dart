// lib/features/sync/coordinator/media_sync_service_proxy.dart

import 'dart:async';
import 'dart:isolate';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:mobile/features/sync/isolate/sync_isolate.dart';
import 'package:rxdart/rxdart.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/services.dart';

const periodicCloudSyncTask = "com.example.mobile.periodicCloudSync";

@lazySingleton
class MediaSyncServiceProxy {
  final _log = Logger('MediaSyncServiceProxy');

  Isolate? _isolate;
  SendPort? _isolateSendPort;
  final _mainReceivePort = ReceivePort();
  final _isolateReadyCompleter = Completer<void>();

  // 使用 BehaviorSubject 来缓存最新的状态，方便新监听者立即获取
  final _syncStateController = BehaviorSubject<SyncState>.seeded(
    SyncState(SyncStatus.idle),
  );

  // 用于接收原始变更事件的 StreamController
  final _mediaChangeController = StreamController<void>.broadcast();

  // 创建一个订阅，用于监听和处理防抖后的事件
  StreamSubscription? _mediaChangeSubscription;

  // 用于防止并发处理相册变更通知的锁
  // bool _isChangeHandlingLocked = false;

  /// 向UI层暴露同步状态的Stream。
  Stream<SyncState> get syncStateStream => _syncStateController.stream;

  /// 启动服务，初始化Isolate和后台任务。
  Future<void> start() async {
    if (_isolate != null) {
      _log.warning('Service has already been started.');
      return;
    }

    _log.info('Starting MediaSyncService...');
    _mainReceivePort.listen(_handleMessagesFromIsolate);

    // 2. 从主 Isolate 获取 Token
    final token = RootIsolateToken.instance;
    if (token == null) {
      _log.severe('Failed to get RootIsolateToken. Cannot spawn Sync Isolate.');
      _syncStateController.add(
        SyncState(
          SyncStatus.error,
          message: 'Failed to initialize sync service.',
        ),
      );
      return;
    }

    // 3. 将 SendPort 和 Token 打包成一个 Map
    final isolateSetupData = {
      'port': _mainReceivePort.sendPort,
      'token': token,
    };

    try {
      // 4. 将打包好的 Map 作为参数传递给 Isolate
      _isolate = await Isolate.spawn(syncIsolateEntrypoint, isolateSetupData);
      _log.info('Sync Isolate spawned successfully.');
    } catch (e, s) {
      _log.severe('Failed to spawn Sync Isolate.', e, s);
      _syncStateController.add(
        SyncState(SyncStatus.error, message: 'Failed to start sync service.'),
      );

      return; // 提前返回，因为 Isolate 启动失败
    }

    // 等待 Isolate 准备就绪
    _isolateReadyCompleter.future;

    // Isolate 准备好之后，开始监听本地媒体变更
    _startListeningForChanges();
    _registerBackgroundTasks(); // WorkManager 注册

    return _isolateReadyCompleter.future;
  }

  void _registerBackgroundTasks() {
    Workmanager().registerPeriodicTask(
      "sync-1", // 唯一的任务名称
      periodicCloudSyncTask,
      frequency: const Duration(hours: 1), // 例如，每6小时同步一次
      constraints: Constraints(
        networkType: NetworkType.connected, // 仅在有网络时运行
        requiresBatteryNotLow: true, // 电池电量低时不运行
      ),
    );
    _log.info('Periodic cloud sync task registered with WorkManager.');
  }

  void _handleMessagesFromIsolate(dynamic message) {
    if (message is SendPort) {
      _isolateSendPort = message;
      // Isolate 已经准备好接收命令
      if (!_isolateReadyCompleter.isCompleted) {
        // 避免重复完成
        _isolateReadyCompleter.complete();
      }

      _log.info(
        'Received SendPort from Sync Isolate. Communication established.',
      );
    } else if (message is SyncState) {
      _syncStateController.add(message);
      _log.fine('Received status update: ${message.status.name}');
    } else {
      _log.warning('Received unknown message type from Isolate: $message');
    }
  }

  /// 发送强制全量同步命令。
  Future<void> triggerFullSync() async {
    await _sendCommand(SyncCommand.triggerFullSync);
  }

  /// 发送云端同步命令。
  Future<void> triggerCloudSync() async {
    await _sendCommand(SyncCommand.triggerCloudSync);
  }

  Future<void> _sendCommand(SyncCommand command) async {
    if (_isolateSendPort == null) {
      _log.severe('Isolate is not ready. Cannot send command: ${command.name}');
      // 如果Isolate尚未准备好，尝试等待它准备好
      if (!_isolateReadyCompleter.isCompleted) {
        _log.info('Isolate not ready, waiting...');
        await _isolateReadyCompleter.future;
      }
      // 再次检查_isolateSendPort，如果仍然为null，则Isolate启动失败
      if (_isolateSendPort == null) {
        _log.severe(
          'Isolate failed to start after waiting. Cannot send command: ${command.name}',
        );
        return;
      }
    }
    _log.info('Sending command to Sync Isolate: ${command.name}');
    _isolateSendPort!.send(command);
  }

  /// 注册监听器以接收未来的媒体变更通知。
  /// Logic from `LocalMediaObserver._startListeningForChanges`.
  Future<void> _startListeningForChanges() async {
    final ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      _log.info(
        'Photo library permission granted. Starting to listen for changes.',
      );

      // --- 设置防抖监听 ---
      // 在启动时设置防抖监听
      _mediaChangeSubscription = _mediaChangeController.stream
          .debounceTime(const Duration(milliseconds: 800)) // 设置防抖时间，例如800毫秒
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

  /// 处理来自 PhotoManager 的变更通知。
  /// Logic from `LocalMediaObserver._onMediaChangeNotified`.
  void _onMediaChangeNotified(MethodCall call) {
    _log.fine('Raw media change notification received: ${call.method}');
    // 4. 将事件添加到 StreamController，而不是直接处理
    _mediaChangeController.add(null);
  }

  /// 关闭Isolate和端口，释放资源。
  void dispose() {
    _log.info('Disposing MediaSyncService...');

    _mediaChangeSubscription?.cancel();
    _mediaChangeController.close();

    // 停止监听相册变更
    PhotoManager.removeChangeCallback(_onMediaChangeNotified);
    PhotoManager.stopChangeNotify();

    if (_isolateSendPort != null) {
      _isolateSendPort!.send(SyncCommand.dispose);
    }
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _mainReceivePort.close();
    _syncStateController.close();
  }
}
