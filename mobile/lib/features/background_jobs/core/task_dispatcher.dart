// lib/features/background_jobs/core/task_dispatcher.dart

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:workmanager/workmanager.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/features/background_jobs/core/contracts/background_task.dart';
import 'package:mobile/features/background_jobs/impl/media_sync/background/periodic_sync_adapter.dart';
import 'package:mobile/services/transfer/backupground_upload_service.dart';
import 'package:mobile/features/background_jobs/impl/group_post/background/create_post_runner.dart';

// 后台任务常量
const String autoMediaBackupTask = 'com.example.mobile.autobackup';

final _log = Logger('TaskDispatcher');

/// 通用后台任务调度器，是 workmanager 的唯一入口点。
@pragma('vm:entry-point')
void callbackDispatcher() {
  // 任务处理器映射表，新增后台任务时在此处添加映射
  final Map<String, BackgroundTask> taskHandlers = {
    periodicCloudSyncTask: PeriodicSyncAdapter(),
    // autoMediaBackupTask: AutoBackupAdapter(),
  };

  Workmanager().executeTask((taskName, inputData) async {
    _log.info('Background task started by Workmanager: $taskName');

    final token = RootIsolateToken.instance;
    if (token == null) {
      _log.severe('Failed to get RootIsolateToken in background task.');
      return false;
    }
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);

    await configureDependencies();

    if (taskName == periodicCloudSyncTask) {
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
    } else if (taskName == autoMediaBackupTask) {
      try {
        // iOS后台任务时间限制检查
        final startTime = DateTime.now();
        
        final autoBackupHandler = getIt<AutoBackupHandler>();
        final result = await autoBackupHandler.handle(inputData);
        
        final duration = DateTime.now().difference(startTime);
        _log.info('Auto backup completed in ${duration.inSeconds}s: $result');
        
        return true;
      } catch (e, s) {
        _log.severe('Auto backup failed in background task', e, s);
        return false;
      }
    } else if (taskName == createPostTask) {
      try {
        return await CreatePostRunner.run(inputData);
      } catch (e, s) {
        _log.severe('Create post task failed', e, s);
        return false;
      }
    }

    return false;
  });
}
