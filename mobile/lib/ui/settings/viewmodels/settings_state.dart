import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_state.freezed.dart';

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    // Default to 3 for initial UI display before loading
    @Default(3) int maxConcurrentUploads,
    @Default(3) int maxConcurrentDownloads,
    @Default(false) bool isAutoBackupEnabled,
    // Indicates if settings are being loaded from the database
    @Default(true) bool isLoading,
  }) = _SettingsState;
}
