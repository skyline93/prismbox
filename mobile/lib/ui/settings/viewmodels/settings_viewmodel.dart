import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/services/settings_service.dart';
import 'package:mobile/services/transfer/transfer_manager.dart'; // <-- 1. 导入 TransferManager
import 'package:mobile/ui/settings/viewmodels/settings_state.dart';

class SettingsViewModel extends StateNotifier<SettingsState> {
  final SettingsService _settingsService;
  final TransferManager _transferManager; // <-- 2. 添加 TransferManager 依赖

  // <-- 3. 更新构造函数以接收 TransferManager
  SettingsViewModel(this._settingsService, this._transferManager)
    : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);
    final uploads = await _settingsService.getMaxConcurrentUploads();
    final downloads = await _settingsService.getMaxConcurrentDownloads();
    final backup = await _settingsService.isAutoBackupEnabled();
    state = state.copyWith(
      maxConcurrentUploads: uploads,
      maxConcurrentDownloads: downloads,
      isAutoBackupEnabled: backup,
      isLoading: false,
    );
  }

  Future<void> updateMaxConcurrentUploads(int value) async {
    state = state.copyWith(maxConcurrentUploads: value);
    await _settingsService.setMaxConcurrentUploads(value);
    // <-- 4. 调用 TransferManager 更新实时并发数
    _transferManager.updateConcurrencyLimits(uploadLimit: value);
  }

  Future<void> updateMaxConcurrentDownloads(int value) async {
    state = state.copyWith(maxConcurrentDownloads: value);
    await _settingsService.setMaxConcurrentDownloads(value);
    // <-- 5. 调用 TransferManager 更新实时并发数
    _transferManager.updateConcurrencyLimits(downloadLimit: value);
  }

  Future<void> updateAutoBackupEnabled(bool isEnabled) async {
    state = state.copyWith(isAutoBackupEnabled: isEnabled);
    await _settingsService.setAutoBackupEnabled(isEnabled);
  }
}
