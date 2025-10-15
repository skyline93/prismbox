// lib/features/background_jobs/core/task_dispatcher.dart

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:injectable/injectable.dart';
import 'package:workmanager/workmanager.dart';
import 'package:mobile/core/di/service_locator.dart';
// import 'package:mobile/features/background_jobs/core/contracts/background_task.dart';
// import 'package:mobile/features/background_jobs/impl/media_sync/background/periodic_sync_adapter.dart';
// import 'package:mobile/features/background_jobs/impl/auto_backup/background/auto_backup_adapter.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/services/settings_service.dart';
import 'package:mobile/services/transfer/upload_orchestrator.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';

final _log = Logger('TaskDispatcher');

/// 通用后台任务调度器，是 workmanager 的唯一入口点。
@pragma('vm:entry-point')
void callbackDispatcher() {
  // 任务处理器映射表，新增后台任务时在此处添加映射
  // final Map<String, BackgroundTask> taskHandlers = {
  //   periodicCloudSyncTask: PeriodicSyncAdapter(),
  //   autoMediaBackupTask: AutoBackupAdapter(),
  // };

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

    final autoBackupHandler = getIt<AutoBackupHandler>();
    final result = await autoBackupHandler.handle(inputData);
    _log.severe(result);

    return true;

    // final handler = taskHandlers[taskName];
    // if (handler != null) {
    //   try {
    //     return await handler.execute(inputData);
    //   } catch (e, s) {
    //     _log.severe('Error executing handler for task: $taskName', e, s);
    //     return false;
    //   }
    // } else {
    //   _log.warning('No handler found for task: $taskName');
    //   return true; // 未知任务返回成功，避免重试
    // }
  });
}

@injectable
class AutoBackupHandler {
  final _log = Logger('AutoBackupHandler');

  // ignore: unused_field
  final AppDatabase _db;
  final SettingsService _settingsService;
  final MediaAssetDao _mediaAssetDao;
  final UploadOrchestrator _uploadOrchestrator;

  AutoBackupHandler(
    this._settingsService,
    this._db,
    this._uploadOrchestrator,
  ) : _mediaAssetDao = _db.mediaAssetDao;

  Future<String> handle(dynamic payload) async {
    _log.info('Starting automatic media backup check...');

    // 1. 检查功能是否开启
    final settings = await _settingsService.watchBackupSettings().first;
    if (!settings.isAutoBackupEnabled) {
      _log.info('Auto backup is disabled. Skipping task.');
      return 'Auto backup disabled.';
    }

    // 2. 扫描仅本地状态的媒体资源，并传入时间段
    _log.info(
      'Scanning for local assets from ${settings.backupStartDate} to ${settings.backupEndDate}',
    );
    final localAssets = await _mediaAssetDao.getLocalOnlyAssets(
      startDate: settings.backupStartDate,
      endDate: settings.backupEndDate,
    );

    if (localAssets.isEmpty) {
      _log.info('No new local media assets to back up in the given timeframe.');
      return 'No new assets found.';
    }

    _log.info('Found ${localAssets.length} local media assets to back up.');

    // 3. 将 List<MediaAsset> 转换为 List<UnifiedMediaEntity>
    final List<UnifiedMediaEntity> entitiesToUpload = localAssets
        .map((asset) => UnifiedMediaEntity.fromDbModel(asset))
        .toList();

    if (entitiesToUpload.isEmpty) {
      _log.warning(
        'Found local assets but failed to convert them to entities. Skipping enqueue.',
      );
      return 'Assets found but could not be converted.';
    }

    // 4. 调用接口加入上传队列
    await _uploadOrchestrator.processAndEnqueueUploads(entitiesToUpload);

    _log.info(
      'Successfully enqueued ${entitiesToUpload.length} assets for upload.',
    );
    return 'Enqueued ${entitiesToUpload.length} assets.';
  }
}
