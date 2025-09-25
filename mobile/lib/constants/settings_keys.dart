// lib/constants/settings_keys.dart

class SettingsKeys {
  /// 标记首次全量媒体对账是否已成功完成。
  /// 值为 'true' 表示已完成。
  static const String initialReconciliationComplete =
      'initial_reconciliation_complete';

  static const String maxConcurrentUploads = 'maxConcurrentUploads';
  static const String maxConcurrentDownloads = 'maxConcurrentDownloads';
  static const String autoBackupEnabled = 'autoBackupEnabled';
}
