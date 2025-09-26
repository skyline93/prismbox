import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/services/settings_service.dart';
import 'package:mobile/ui/settings/viewmodels/settings_state.dart';
import 'package:mobile/ui/settings/viewmodels/settings_viewmodel.dart';
import 'package:mobile/services/transfer/transfer_manager.dart';

final settingsProvider =
    StateNotifierProvider.autoDispose<SettingsViewModel, SettingsState>(
      (ref) => SettingsViewModel(
        getIt<SettingsService>(),
        getIt<TransferManager>(), // <-- 2. 从 getIt 获取并传入 TransferManager
      ),
    );
