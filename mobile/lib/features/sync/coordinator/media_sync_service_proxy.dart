// lib/features/sync/coordinator/media_sync_service_proxy.dart

import 'dart:async';
import 'dart:isolate';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/features/sync/isolate/sync_isolate.dart';
import 'package:rxdart/rxdart.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/services.dart';

const periodicCloudSyncTask = "com.example.app.periodicCloudSync";

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
    }

    // Register background tasks once communication is established
    _isolateReadyCompleter.future.then((_) {
      _registerBackgroundTasks();
    });

    // 等待 Isolate 准备就绪并返回其 SendPort
    return _isolateReadyCompleter.future;
  }

  void _registerBackgroundTasks() {
    Workmanager().registerPeriodicTask(
      "sync-1", // 唯一的任务名称
      periodicCloudSyncTask,
      frequency: const Duration(hours: 6), // 例如，每6小时同步一次
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
      _isolateReadyCompleter.complete();
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
      return;
    }
    _log.info('Sending command to Sync Isolate: ${command.name}');
    _isolateSendPort!.send(command);
  }

  /// 关闭Isolate和端口，释放资源。
  void dispose() {
    _log.info('Disposing MediaSyncService...');
    if (_isolateSendPort != null) {
      _isolateSendPort!.send(SyncCommand.dispose);
    }
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _mainReceivePort.close();
    _syncStateController.close();
  }
}
