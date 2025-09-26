// lib/features/background_jobs/core/task_dispatcher.dart

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:workmanager/workmanager.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/features/background_jobs/core/contracts/background_task.dart';
import 'package:mobile/features/background_jobs/impl/media_sync/background/periodic_sync_adapter.dart';

final _log = Logger('TaskDispatcher');

/// 通用后台任务调度器，是 workmanager 的唯一入口点。
@pragma('vm:entry-point')
void callbackDispatcher() {
  // 任务处理器映射表，新增后台任务时在此处添加映射
  final Map<String, BackgroundTask> taskHandlers = {
    periodicCloudSyncTask: PeriodicSyncAdapter(),
  };

  Workmanager().executeTask((taskName, inputData) async {
    _log.info('Background task started by Workmanager: $taskName');

    final token = RootIsolateToken.instance;
    if (token == null) {
      _log.severe('Failed to get RootIsolateToken in background task.');
      return false;
    }
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);

    // 在后台 Isolate 中初始化依赖
    // 注意：这里不需要 configureIsolateDependencies，因为它只在 syncIsolate 中需要
    await configureDependencies();

    final handler = taskHandlers[taskName];
    if (handler != null) {
      try {
        return await handler.execute(inputData);
      } catch (e, s) {
        _log.severe('Error executing handler for task: $taskName', e, s);
        return false;
      }
    } else {
      _log.warning('No handler found for task: $taskName');
      return true; // 未知任务返回成功，避免重试
    }
  });
}
