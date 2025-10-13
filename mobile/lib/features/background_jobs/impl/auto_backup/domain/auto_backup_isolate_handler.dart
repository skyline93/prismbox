// lib/features/background_jobs/impl/auto_backup/domain/auto_backup_isolate_handler.dart

import 'dart:isolate';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/features/background_jobs/core/contracts/isolate_task_handler.dart';
import 'package:mobile/services/settings_service.dart';
import 'package:mobile/services/transfer/upload_orchestrator.dart';

@injectable
class AutoBackupIsolateHandler implements IsolateTaskHandler {
  static const String taskName = 'autoMediaBackup';
  final _log = Logger('AutoBackupIsolateHandler');

  // ignore: unused_field
  final AppDatabase _db;
  final SettingsService _settingsService;
  final MediaAssetDao _mediaAssetDao;
  final UploadOrchestrator _uploadOrchestrator;

  AutoBackupIsolateHandler(
    this._settingsService,
    this._db,
    this._uploadOrchestrator,
  ) : _mediaAssetDao = _db.mediaAssetDao;

  @override
  Future<void> initialize(SendPort mainSendPort) async {
    _log.info('AutoBackupIsolateHandler initialized.');
  }

  @override
  Future<dynamic> handle(dynamic payload) async {
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

  @override
  Future<void> dispose() async {
    // 如果有需要释放的资源
  }
}
