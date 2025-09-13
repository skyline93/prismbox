// lib/features/sync/worker/sync_worker.dart

import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart'; // 必须导入
import 'package:logging/logging.dart';
import 'package:mobile/features/sync/isolate/sync_isolate.dart';
import 'package:workmanager/workmanager.dart';

final _log = Logger('SyncWorker');

// 确保这里的任务名称与 MediaSyncServiceProxy 中注册的名称一致
const periodicCloudSyncTask = "com.example.app.periodicCloudSync";

/// 这是 workmanager 后台任务的入口点。
/// 它本身在一个独立的 Isolate 中运行。
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    _log.info('Background task started: $task');

    // 关键修复 1:
    // Workmanager 的后台上下文也需要初始化平台通道，才能使用插件。
    final token = RootIsolateToken.instance;
    if (token == null) {
      _log.severe('Failed to get RootIsolateToken in background task.');
      return Future.value(false);
    }
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);

    switch (task) {
      case periodicCloudSyncTask:
        try {
          // 为了逻辑复用和隔离，我们从这里再启动我们专用的 syncIsolate
          await _runSyncIsolate();
          _log.info('Background sync task completed successfully.');
          return Future.value(true);
        } catch (e, s) {
          _log.severe('Error executing background sync task', e, s);
          return Future.value(false);
        }
      default:
        _log.warning('Unknown background task: $task');
        return Future.value(true);
    }
  });
}

/// 一个辅助函数，用于在后台 worker 中启动并管理我们的 syncIsolate
Future<void> _runSyncIsolate() async {
  final completer = Completer<void>();
  final mainReceivePort = ReceivePort();
  SendPort? isolateSendPort;

  // 关键修复 2:
  // 创建与 syncIsolateEntrypoint 期望的参数完全匹配的 Map
  final isolateSetupData = {
    'port': mainReceivePort.sendPort,
    'token': RootIsolateToken.instance!, // 我们在上面已经检查过不为 null
  };

  mainReceivePort.listen((message) {
    if (message is SendPort) {
      isolateSendPort = message;
      // Isolate 准备就绪，发送同步命令
      _log.info(
        'Background worker received SendPort. Sending cloud sync command.',
      );
      isolateSendPort?.send(SyncCommand.triggerCloudSync);
    } else if (message is SyncState) {
      _log.info(
        'Background worker received sync state: ${message.status.name}',
      );
      // 当同步完成 (idle) 或出错时，我们认为任务结束
      if (message.status == SyncStatus.idle ||
          message.status == SyncStatus.error) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    }
  });

  // 关键修复 3:
  // 使用正确的参数 Map 来创建 Isolate，这修复了类型不匹配的编译错误
  final isolate = await Isolate.spawn(syncIsolateEntrypoint, isolateSetupData);

  // 等待任务完成，设置一个超时以防万一
  await completer.future.timeout(
    const Duration(minutes: 5),
    onTimeout: () {
      _log.warning('Background sync task timed out.');
    },
  );

  // 清理资源
  isolateSendPort?.send(SyncCommand.dispose);
  isolate.kill(priority: Isolate.immediate);
  mainReceivePort.close();
  _log.info('Cleaned up background sync isolate.');
}
