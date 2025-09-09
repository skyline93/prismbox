// lib/services/background_service_manager.dart
import 'dart:ui';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider_foundation/path_provider_foundation.dart';

import 'package:mobile/data/services/dio_client.dart';
import 'package:mobile/services/sync_job_manager.dart';
import 'package:mobile/services/sync_job_processor.dart';
import 'package:workmanager/workmanager.dart';
import 'package:mobile/data/datasources/local_db/connection.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';

const String _periodicSyncTask = "com.album.periodicCloudSync";
const String _queueProcessorTask = "com.album.queueProcessor";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final token = RootIsolateToken.instance;
    if (token == null) {
      print('[BackgroundService] Fatal: Could not get RootIsolateToken.');
      return false;
    }
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    DartPluginRegistrant.ensureInitialized();
    if (Platform.isIOS) {
      PathProviderFoundation.registerWith();
    }

    final db = await connect();

    final secStor = SecureStorageService(db);
    final dioClient = DioClient(secStor);

    final remoteApi = RemoteMediaDataSource(dioClient.dio);
    final processor = SyncJobProcessor(db: db, remoteApi: remoteApi);
    final jobManager = SyncJobManager(db);

    print("[BackgroundService] 后台任务触发: $task");

    try {
      switch (task) {
        case _periodicSyncTask:
          await jobManager.createCloudChangesSyncJob();
          print("[BackgroundService] 已成功创建云端同步检查任务。");
          break;

        case _queueProcessorTask:
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
    await Workmanager().initialize(callbackDispatcher);
  }

  static Future<void> registerPeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      _periodicSyncTask,
      _periodicSyncTask,
      frequency: const Duration(minutes: 1),
      // constraints: Constraints(networkType: NetworkType.connected),
    );
    print("[BackgroundServiceManager] 周期性“创建云端同步任务”的作业已注册。");
  }

  static void triggerImmediateSync() {
    Workmanager().registerOneOffTask(
      _queueProcessorTask,
      _queueProcessorTask,
      // constraints: Constraints(networkType: NetworkType.connected),
    );
    print("[BackgroundServiceManager] 立即“处理任务队列”的作业已触发。");
  }
}
