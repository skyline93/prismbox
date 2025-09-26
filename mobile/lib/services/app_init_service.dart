// lib/services/app_init_service.dart

import 'package:logging/logging.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/services/transfer/transfer_manager.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/constants/settings_keys.dart';
import 'package:workmanager/workmanager.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:mobile/features/replicator/media_sync_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/background_jobs/core/task_dispatcher.dart';
import 'package:mobile/features/background_jobs/core/task_registrar.dart';
import 'package:mobile/features/background_jobs/impl/media_sync/service/media_sync_service.dart'
    as mss;

class AppInitService {
  static final AppInitService _instance = AppInitService._internal();
  factory AppInitService() => _instance;
  AppInitService._internal();

  bool _isInitialized = false;

  /// 辅助方法：使用 PhotoManager 请求相册权限
  Future<bool> _requestPermissions() async {
    final log = Logger('AppInitService');

    // 2. 使用 PhotoManager 的 API 请求权限
    final PermissionState ps = await PhotoManager.requestPermissionExtend();

    // 3. ps.isAuth 会在 authorized 和 limited 状态下返回 true
    final bool isPermissionGranted = ps.isAuth;

    if (isPermissionGranted) {
      // 在 iOS 14+，limited 状态意味着用户只授权访问了部分照片
      // 对于同步服务来说，这可能不是理想状态，但应用至少可以工作
      log.info('相册权限已授予 (状态: $ps)。');
      return true;
    } else {
      // 权限被拒绝 (denied)
      log.severe('相册权限被拒绝 (状态: $ps)。');
      log.info('正在尝试引导用户去系统设置页面...');
      // 4. 引导用户去设置页面，这是权限被拒绝后唯一的解决办法
      await PhotoManager.openSetting();
      return false;
    }
  }

  Future<void> initializeAppServices(WidgetRef ref) async {
    if (_isInitialized) {
      Logger.root.info('App services already initialized. Skipping.');
      return;
    }

    Logger.root.info('Initializing app services...');

    // 首先请求必要的权限
    final bool permissionsGranted = await _requestPermissions();
    if (!permissionsGranted) {
      Logger.root.severe('必要的相册权限未被授予，初始化中止！');
      return; // 如果权限被拒绝，则中止后续所有服务的初始化
    }

    Logger.root.info('所有必要权限已获取。');

    Logger.root.info('正在触发启动时的媒体资源同步 (replicator)...');
    try {
      // 使用 ref.read 来执行一次性操作，获取 MediaSyncService 实例并调用同步方法
      final mediaSyncService = await ref.read(mediaSyncServiceProvider.future);
      await mediaSyncService.syncMediaAssets();
    } catch (e) {
      // 即使同步失败，也不应阻塞应用启动，仅记录错误
      Logger.root.severe('启动时媒体资源同步 (replicator) 失败: $e');
    }

    await getIt<TransferManager>().initialize();
    Logger.root.info('TransferManager initialized.');

    // ignore: deprecated_member_use
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    Logger.root.info('Workmanager initialized.');

    TaskRegistrar.registerAllTasks();

    final mediaSyncEntryService = getIt<mss.MediaSyncService>();
    await mediaSyncEntryService.start();
    Logger.root.info('MediaSyncEntryService started.');

    final userSettingDao = getIt<AppDatabase>().userSettingDao;
    final isInitialSyncComplete =
        await userSettingDao.getSetting(
          SettingsKeys.initialReconciliationComplete,
        ) ==
        'true';

    if (!isInitialSyncComplete) {
      Logger.root.info(
        'Initial full sync has not been completed. Triggering now...',
      );
      mediaSyncEntryService.triggerFullSync();
    } else {
      Logger.root.info(
        'Initial full sync already completed. Skipping automatic trigger on startup.',
      );
    }

    _isInitialized = true;
    Logger.root.info('App services initialization complete.');
  }
}
