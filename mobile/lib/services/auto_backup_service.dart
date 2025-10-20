// lib/services/auto_backup_service.dart

import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/features/background_jobs/impl/auto_backup/background/auto_backup_adapter.dart';
import 'package:mobile/services/settings_service.dart';
import 'package:workmanager/workmanager.dart';

/// 一个动态管理自动媒体备份后台任务生命周期的服务。
///
/// 它的核心职责是监听用户设置的变化，并据此向 Workmanager 注册、更新或取消
/// 对应的后台任务，确保任务的调度总是与用户的意图保持一致。
@lazySingleton
class AutoBackupService {
  final _log = Logger('AutoBackupService');
  final SettingsService _settingsService;
  // [修正] StreamSubscription 的类型参数应为 BackupSettings
  StreamSubscription<BackupSettings>? _settingsSubscription;

  AutoBackupService(this._settingsService);

  /// 初始化服务，开始监听用户设置的变更。
  /// 此方法应在应用启动时调用一次。
  void initialize() {
    _log.info(
      'Initializing AutoBackupService and listening for settings changes.',
    );
    _settingsSubscription?.cancel();

    _settingsSubscription = _settingsService.watchBackupSettings().listen((
      settings,
    ) {
      _log.info(
        'Detected settings change. Re-evaluating auto backup task registration.',
      );
      _updateTaskRegistration(
        isEnabled: settings.isAutoBackupEnabled,
        frequency: settings.frequency,
        isWifiOnly: settings.isBackupOnWifiOnly,
      );
    });
  }

  /// 根据最新的用户设置，注册、更新或取消后台任务。
  Future<void> _updateTaskRegistration({
    required bool isEnabled,
    required BackupFrequency? frequency,
    required bool isWifiOnly,
  }) async {
    if (isEnabled) {
      final backupDuration = _getDurationFromFrequency(frequency);
      _log.info(
        'Auto backup is enabled. Registering/updating periodic task with frequency: ${backupDuration.inMinutes} minutes.',
      );

      await Workmanager().registerPeriodicTask(
        autoMediaBackupTask,
        autoMediaBackupTask,
        frequency: backupDuration,
        constraints: Constraints(
          networkType: isWifiOnly
              ? NetworkType.unmetered
              : NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 1),
      );
      _log.info('Periodic auto backup task registered/updated successfully.');
    } else {
      _log.info('Auto backup is disabled. Cancelling task.');
      await Workmanager().cancelByUniqueName(autoMediaBackupTask);
      _log.info('Periodic auto backup task cancelled successfully.');
    }
  }

  /// 将存储的频率字符串转换为 Workmanager 需要的 Duration 对象。
  Duration _getDurationFromFrequency(BackupFrequency? frequency) {
    switch (frequency) {
      case BackupFrequency.minutes:
        return const Duration(minutes: 15);
      case BackupFrequency.hours:
        return const Duration(hours: 1);
      case BackupFrequency.daily:
        return const Duration(days: 1);
      case BackupFrequency.weekly:
        return const Duration(days: 7);
      default:
        _log.warning(
          'Invalid or null backup frequency "$frequency". Defaulting to daily.',
        );
        return const Duration(days: 1);
    }
  }

  /// 清理资源，在服务被销毁时取消流监听。
  @disposeMethod
  void dispose() {
    _log.info('Disposing AutoBackupService.');
    _settingsSubscription?.cancel();
  }
}
