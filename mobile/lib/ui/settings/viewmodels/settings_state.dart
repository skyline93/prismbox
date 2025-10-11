import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile/services/settings_service.dart';

part 'settings_state.freezed.dart';

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    // Default to 3 for initial UI display before loading
    @Default(3) int maxConcurrentUploads,
    @Default(3) int maxConcurrentDownloads,
    @Default(false) bool isAutoBackupEnabled,
    @Default(BackupFrequency.daily) BackupFrequency backupFrequency,
    @Default(true) bool isBackupOnWifiOnly,
    // 备份时间段的开始日期，可为空
    DateTime? backupStartDate,
    // 备份时间段的结束日期，可为空
    DateTime? backupEndDate,
    // Indicates if settings are being loaded from the database
    @Default(true) bool isLoading,
  }) = _SettingsState;
}
