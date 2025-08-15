// lib/services/background_service_manager.dart

import 'package:mobile/services/sync_job_processor.dart';
import 'package:workmanager/workmanager.dart';
import 'package:mobile/core/service_locator.dart';

const String _periodicSyncTask = "com.album.periodicCloudSync";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("[BackgroundService] 后台任务触发: $task");

    try {
      await configureDependencies();

      final processor = getIt<SyncJobProcessor>();

      await processor.processNextJob();

      print("[BackgroundService] 任务处理完成。");
      return true; // 表示任务成功
    } catch (e, stacktrace) {
      print("[BackgroundService] 执行后台任务时发生严重错误: $e");
      print(stacktrace);
      return false; // 表示任务失败
    }
  });
}

class BackgroundServiceManager {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  }

  static Future<void> registerPeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      _periodicSyncTask,
      "periodicCloudSync",
      frequency: const Duration(minutes: 5),
    );
    print("[BackgroundServiceManager] 周期性同步任务已注册。");
  }

  static void triggerImmediateSync() {
    Workmanager().registerOneOffTask(
      "immediateSyncTask-${DateTime.now().millisecondsSinceEpoch}",
      "immediateCloudSync",
    );
    print("[BackgroundServiceManager] 立即同步任务已触发。");
  }
}
