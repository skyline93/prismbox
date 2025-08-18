// lib/services/background_service_manager.dart

import 'package:mobile/services/sync_job_manager.dart';
import 'package:mobile/services/sync_job_processor.dart'; // This import is now correctly used.
import 'package:workmanager/workmanager.dart';
import 'package:mobile/core/service_locator.dart';

const String _periodicSyncTask = "com.album.periodicCloudSync";
const String _queueProcessorTask = "com.album.queueProcessor";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("[BackgroundService] 后台任务触发: $task");

    try {
      await configureDependencies();

      // 根据任务名称执行不同逻辑
      switch (task) {
        case _periodicSyncTask:
          final jobManager = getIt<SyncJobManager>();
          await jobManager.createCloudChangesSyncJob();
          print("[BackgroundService] 已成功创建云端同步检查任务。");
          break;

        case _queueProcessorTask:
          // FIXED: Corrected the typo from SyncJobGProcessor to SyncJobProcessor
          final processor = getIt<SyncJobProcessor>();
          await processor.processNextJob();
          break;

        default:
          print("[BackgroundService] 未知的任务类型: $task");
          return Future.value(false);
      }

      return Future.value(true);
    } catch (e, stacktrace) {
      print("[BackgroundService] 执行后台任务时发生严重错误: $e");
      print(stacktrace);
      return Future.value(false);
    }
  });
}

class BackgroundServiceManager {
  static Future<void> initialize() async {
    // FIXED: Removed the deprecated 'isInDebugMode' parameter
    await Workmanager().initialize(callbackDispatcher);
  }

  static Future<void> registerPeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      _periodicSyncTask,
      _periodicSyncTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
    );
    print("[BackgroundServiceManager] 周期性“创建云端同步任务”的作业已注册。");
  }

  static void triggerImmediateSync() {
    Workmanager().registerOneOffTask(
      "immediateQueueProcessing-${DateTime.now().millisecondsSinceEpoch}",
      _queueProcessorTask,
      constraints: Constraints(networkType: NetworkType.connected),
    );
    print("[BackgroundServiceManager] 立即“处理任务队列”的作业已触发。");
  }
}
