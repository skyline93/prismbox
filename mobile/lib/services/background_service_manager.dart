// lib/services/background_service_manager.dart

import 'package:mobile/services/sync_job_manager.dart';
import 'package:mobile/services/sync_job_processor.dart'; // This import is now correctly used.
import 'package:workmanager/workmanager.dart';
import 'package:mobile/core/service_locator.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/native.dart';
import 'dart:io';
import 'package:mobile/data/datasources/app_database.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
// import 'package:injectable/injectable.dart';

const String _periodicSyncTask = "com.album.periodicCloudSync";
const String _queueProcessorTask = "com.album.queueProcessor";

LazyDatabase _openBackgroundConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'media_library.sqlite'));
    return NativeDatabase.createInBackground(
      file,
      setup: (database) {
        // 开启 WAL 模式
        database.execute('PRAGMA journal_mode = WAL;');
      },
    );
  });
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await configureDependencies();

    final db = AppDatabase(_openBackgroundConnection());
    final remoteApi = getIt<RemoteMediaDataSource>();
    final processor = SyncJobProcessor(db: db, remoteApi: remoteApi);

    print("[BackgroundService] 后台任务触发: $task");

    try {
      // 根据任务名称执行不同逻辑
      switch (task) {
        case _periodicSyncTask:
          final jobManager = getIt<SyncJobManager>();
          await jobManager.createCloudChangesSyncJob();
          print("[BackgroundService] 已成功创建云端同步检查任务。");
          break;

        case _queueProcessorTask:
          // FIXED: Corrected the typo from SyncJobGProcessor to SyncJobProcessor
          // final processor = getIt<SyncJobProcessor>();
          await processor.processNextJob();
          break;

        default:
          print("[BackgroundService] 未知的任务类型: $task");
          return Future.value(false);
      }

      await db.close();
      return Future.value(true);
    } catch (e, stacktrace) {
      print("[BackgroundService] 执行后台任务时发生严重错误: $e");
      print(stacktrace);
      await db.close();
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
      frequency: const Duration(minutes: 1),
      constraints: Constraints(networkType: NetworkType.connected),
    );
    print("[BackgroundServiceManager] 周期性“创建云端同步任务”的作业已注册。");
  }

  static void triggerImmediateSync() {
    Workmanager().registerOneOffTask(
      "immediateQueueProcessing-${DateTime.now().millisecondsSinceEpoch}",
      _queueProcessorTask,
      // constraints: Constraints(networkType: NetworkType.connected),
    );
    print("[BackgroundServiceManager] 立即“处理任务队列”的作业已触发。");
  }
}
