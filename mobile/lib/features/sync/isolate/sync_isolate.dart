// lib/features/sync/isolate/sync_isolate.dart

import 'dart:isolate';
import 'package:logging/logging.dart';
import 'package:mobile/core/service_locator.dart';
import 'package:mobile/features/sync/coordinator/media_sync_service_core.dart';
import 'package:flutter/services.dart';

final _log = Logger('SyncIsolate');

// ------------------- Communication Models -------------------

/// 从主 Isolate 发送到后台 Isolate 的命令
enum SyncCommand {
  /// 触发一次完整的本地+云端同步
  triggerFullSync,

  /// 仅触发一次云端同步
  triggerCloudSync,

  /// 停止服务并关闭 Isolate
  dispose,
}

/// 同步状态，从后台 Isolate 发送回主 Isolate
enum SyncStatus { idle, syncingLocal, syncingCloud, error }

/// 封装同步状态更新的数据结构
class SyncState {
  final SyncStatus status;
  final String? message; // 可选，用于传递进度或错误信息

  SyncState(this.status, {this.message});
}

// ------------------- Isolate Entry Point -------------------
@pragma('vm:entry-point')
void syncIsolateEntrypoint(Map<String, dynamic> initialData) async {
  final mainSendPort = initialData['port'] as SendPort;
  final token = initialData['token'] as RootIsolateToken;

  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  final isolateReceivePort = ReceivePort();

  try {
    // 步骤 1: 首先完成所有耗时的初始化工作
    await configureDependencies();
    _log.info('Dependencies configured inside SyncIsolate.');

    // 步骤 2: 创建核心服务实例
    final core = getIt<MediaSyncServiceCore>(param1: mainSendPort);

    // 步骤 3: 提前设置好命令监听器，让 Isolate 具备处理命令的能力
    isolateReceivePort.listen((message) {
      if (message is SyncCommand) {
        _log.info('Received command: ${message.name}');
        core.handleCommand(message);
      }
    });

    // 关键步骤 4: 在一切准备就绪后，才将 SendPort 发送回主 Isolate
    // 这就像是举起一面旗帜说：“现在可以向我发号施令了！”
    mainSendPort.send(isolateReceivePort.sendPort);
    _log.info('SyncIsolate is running and ready to receive commands.');
  } catch (e, s) {
    _log.severe('Error during SyncIsolate initialization.', e, s);
    // 发生错误时，也可以向主 Isolate 发送一个错误信号
    mainSendPort.send(
      SyncState(SyncStatus.error, message: 'Isolate failed to initialize: $e'),
    );
  }
}
