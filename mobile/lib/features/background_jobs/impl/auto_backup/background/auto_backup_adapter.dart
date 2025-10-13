// lib/features/background_jobs/impl/auto_backup/background/auto_backup_adapter.dart

import 'package:logging/logging.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/features/background_jobs/core/contracts/background_task.dart';
import 'package:mobile/features/background_jobs/core/isolate/isolate_job_manager.dart';
import 'package:mobile/features/background_jobs/impl/auto_backup/domain/auto_backup_isolate_handler.dart';

// 为 WorkManager 定义一个唯一的任务名称
const String autoMediaBackupTask = 'com.example.mobile.autobackup';

class AutoBackupAdapter implements BackgroundTask {
  final _log = Logger('AutoBackupAdapter');

  @override
  Future<bool> execute(Map<String, dynamic>? inputData) async {
    _log.info('AutoBackupAdapter triggered by Workmanager.');
    try {
      final isolateManager = getIt<IsolateJobManager>();
      // 确保 Isolate 已经启动
      await isolateManager.start();

      // 将真正的业务逻辑派发到后台 Isolate 执行
      await isolateManager.executeJob(AutoBackupIsolateHandler.taskName);

      _log.info('Auto backup job successfully dispatched to isolate.');
      return true; // 返回 true 表示任务成功
    } catch (e, s) {
      _log.severe('Failed to execute auto backup job in isolate.', e, s);
      return false; // 返回 false 表示任务失败，Workmanager 会根据策略重试
    }
  }
}
