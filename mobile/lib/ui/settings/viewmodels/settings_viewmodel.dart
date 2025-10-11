import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/services/settings_service.dart';
import 'package:mobile/services/transfer/transfer_manager.dart';
import 'package:mobile/ui/settings/viewmodels/settings_state.dart';

class SettingsViewModel extends StateNotifier<SettingsState> {
  final SettingsService _settingsService;
  final TransferManager _transferManager;

  SettingsViewModel(this._settingsService, this._transferManager)
    : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);

    final settingsData = await Future.wait([
      _settingsService.getMaxConcurrentUploads(),
      _settingsService.getMaxConcurrentDownloads(),
      _settingsService.isAutoBackupEnabled(),
      _settingsService.getBackupFrequency(),
      _settingsService.isBackupOnWifiOnly(),
      // 加载日期设置
      _settingsService.getBackupStartDate(),
      _settingsService.getBackupEndDate(),
    ]);

    state = state.copyWith(
      maxConcurrentUploads: settingsData[0] as int,
      maxConcurrentDownloads: settingsData[1] as int,
      isAutoBackupEnabled: settingsData[2] as bool,
      backupFrequency: settingsData[3] as BackupFrequency,
      isBackupOnWifiOnly: settingsData[4] as bool,
      // 更新状态
      backupStartDate: settingsData[5] as DateTime?,
      backupEndDate: settingsData[6] as DateTime?,
      isLoading: false,
    );
  }

  Future<void> updateMaxConcurrentUploads(int value) async {
    state = state.copyWith(maxConcurrentUploads: value);
    await _settingsService.setMaxConcurrentUploads(value);
    _transferManager.updateConcurrencyLimits(uploadLimit: value);
  }

  Future<void> updateMaxConcurrentDownloads(int value) async {
    state = state.copyWith(maxConcurrentDownloads: value);
    await _settingsService.setMaxConcurrentDownloads(value);
    _transferManager.updateConcurrencyLimits(downloadLimit: value);
  }

  Future<void> updateAutoBackupEnabled(bool isEnabled) async {
    state = state.copyWith(isAutoBackupEnabled: isEnabled);
    await _settingsService.setAutoBackupEnabled(isEnabled);
  }

  Future<void> updateBackupFrequency(BackupFrequency frequency) async {
    state = state.copyWith(backupFrequency: frequency);
    await _settingsService.setBackupFrequency(frequency);
  }

  Future<void> updateBackupOnWifiOnly(bool isWifiOnly) async {
    state = state.copyWith(isBackupOnWifiOnly: isWifiOnly);
    await _settingsService.setBackupOnWifiOnly(isWifiOnly);
  }

  // --- 新增日期更新方法 ---
  Future<void> updateBackupStartDate(DateTime? date) async {
    state = state.copyWith(backupStartDate: date);
    await _settingsService.setBackupStartDate(date);
  }

  Future<void> updateBackupEndDate(DateTime? date) async {
    state = state.copyWith(backupEndDate: date);
    await _settingsService.setBackupEndDate(date);
  }
}
