import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/services/dio_client.dart';
import '../../data/services/secure_storage_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../../state/transfer_state.dart';
import '../../services/transfer/download_service.dart';
import '../../services/transfer/upload_service.dart';
import '../../services/transfer/transfer_manager.dart';
import '../../core/config/app_config.dart';

//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// DATA LAYER PROVIDERS
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

// --- Database ---
final dbProvider = Provider<AppDatabase>((ref) => AppDatabase());

// --- Services ---
final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(ref.watch(dbProvider)),
);

final dioClientProvider = Provider<DioClient>(
  (ref) => DioClient(ref.watch(secureStorageProvider)),
);

// --- API Client ---
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioClientProvider)),
);

// --- Repositories ---
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  ),
);

final mediaRepositoryProvider = Provider<MediaRepository>(
  (ref) => MediaRepository(ref.watch(apiClientProvider), ref.watch(dbProvider)),
);

//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// PRESENTATION LAYER PROVIDERS
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

// --- ViewModels / Notifiers ---

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AsyncValue<void>>(
      (ref) => AuthViewModel(ref.watch(authRepositoryProvider)),
    );

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(ref.watch(dbProvider));
});

final homeViewModelProvider = StateNotifierProvider<HomePageViewModel, bool>((
  ref,
) {
  return HomePageViewModel(
    ref: ref,
    mediaRepository: ref.watch(mediaRepositoryProvider),
    uploadService: ref.watch(uploadServiceProvider),
    downloadService: ref.watch(downloadServiceProvider),
  );
});

final uploadServiceProvider = Provider<UploadService>((ref) {
  // The dependency on homeViewModelProvider is now completely gone.
  return UploadService(
    mediaRepository: ref.watch(mediaRepositoryProvider),
    secureStorage: ref.watch(secureStorageServiceProvider),
    apiBaseUrl: "${ApiConfig.defaultServerAddr}/api/v1",
    transferStateNotifier: ref.watch(transferStateProvider.notifier),
  );
});

final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService(
    transferStateNotifier: ref.watch(transferStateProvider.notifier),
  );
});

// --- Streams / Futures ---

final mediaAssetsStreamProvider = StreamProvider<List<MediaAsset>>((ref) {
  return ref.watch(mediaRepositoryProvider).watchLocalMediaAssets();
});

final transferStateProvider =
    StateNotifierProvider<TransferStateNotifier, TransferState>(
      (ref) => TransferStateNotifier(),
    );

final transferManagerProvider = Provider<TransferManager>((ref) {
  final manager = TransferManager(
    ref.watch(downloadServiceProvider),
    ref.watch(uploadServiceProvider),
  );
  manager.initialize(); // Call initialize immediately upon creation
  return manager;
});
