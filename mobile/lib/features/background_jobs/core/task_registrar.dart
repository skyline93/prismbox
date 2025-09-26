// lib/features/background_jobs/core/task_registrar.dart

import 'package:logging/logging.dart';
import 'package:workmanager/workmanager.dart';
import 'package:mobile/features/background_jobs/impl/media_sync/background/periodic_sync_adapter.dart';

/// 统一的后台任务注册器。
class TaskRegistrar {
  static final _log = Logger('TaskRegistrar');

  /// 注册应用中所有需要的后台任务。
  static void registerAllTasks() {
    Workmanager().registerPeriodicTask(
      "sync-periodic-1", // 唯一的任务ID
      periodicCloudSyncTask, // 任务名称
      frequency: const Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 10),
    );
    _log.info('Periodic cloud sync task registered with WorkManager.');
  }
}
