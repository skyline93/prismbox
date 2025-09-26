import 'dart:async';
import 'package:logging/logging.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/features/background_jobs/core/contracts/background_task.dart';
import 'package:mobile/features/background_jobs/core/isolate/isolate_job_manager.dart';
import 'package:mobile/features/background_jobs/impl/media_sync/domain/isolate_handler.dart';
import 'package:mobile/features/background_jobs/impl/media_sync/models/sync_models.dart';

const String periodicCloudSyncTask = "com.example.mobile.periodicCloudSync";

/// 将 Workmanager 的周期性任务适配到通用 Isolate 作业。
class PeriodicSyncAdapter implements BackgroundTask {
  final _log = Logger('PeriodicSyncAdapter');

  @override
  Future<bool> execute(Map<String, dynamic>? inputData) async {
    _log.info('Executing periodic background sync task...');
    final completer = Completer<bool>();
    StreamSubscription? subscription;

    // 获取通用 Isolate 管理器的单例
    final jobManager = getIt<IsolateJobManager>();

    try {
      await jobManager.start();

      // 监听特定的同步状态更新
      subscription = jobManager.jobResultStream.listen((event) {
        if (event is SyncProgressUpdate) {
          _log.info(
            'Background adapter received sync state: ${event.status.name}',
          );
          if (event.status == SyncStatus.idle) {
            if (!completer.isCompleted) completer.complete(true);
          } else if (event.status == SyncStatus.error) {
            if (!completer.isCompleted) completer.complete(false);
          }
        }
      });

      // 提交 "triggerCloudSync" 作业到 Isolate
      await jobManager.submitJob(
        MediaSyncIsolateHandler.taskName,
        payload: SyncCommand.triggerCloudSync.name,
      );

      return await completer.future.timeout(
        const Duration(minutes: 15),
        onTimeout: () {
          _log.warning('Background sync task timed out.');
          return false;
        },
      );
    } catch (e, s) {
      _log.severe('Exception in background task', e, s);
      if (!completer.isCompleted) completer.complete(false);
      return false;
    } finally {
      await subscription?.cancel();
      jobManager.dispose(); // 后台任务完成，关闭 Isolate
      _log.info('Cleaned up resources for background task.');
    }
  }
}
