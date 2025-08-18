// lib/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/data/datasources/local_media_source.dart';
import 'package:mobile/data/datasources/app_database.dart';
import 'package:mobile/ui/media/viewmodels/media_state.dart';
import 'data/repositories/media_repository_impl.dart';
import 'domain/repositories/media_repository.dart';
import 'package:mobile/ui/media/viewmodels/media_viewmodel.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/storage/sync_state_service.dart';
import 'package:mobile/core/service_locator.dart';
import 'package:mobile/data/services/dio_client.dart';
import 'package:mobile/auth/auth_notifier.dart';
import 'package:mobile/auth/auth_state.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/data/services/auth_service.dart';
import 'package:mobile/data/services/server_check_service.dart';
import 'package:mobile/services/sync_job_manager.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return getIt<AppDatabase>();
});

final syncJobManagerProvider = Provider<SyncJobManager>((ref) {
  return getIt<SyncJobManager>();
});

/// 本地媒体数据源的提供者
final localMediaDataSourceProvider = Provider<LocalMediaDataSource>((ref) {
  return getIt<LocalMediaDataSource>();
});

final remoteMediaSourceProvider = Provider<RemoteMediaDataSource>((ref) {
  return getIt<RemoteMediaDataSource>();
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier(ref);
});

final dioClientProvider = Provider<DioClient>((ref) {
  final dio = DioClient(getIt<SecureStorageService>());

  final authNotifier = ref.read(authNotifierProvider.notifier);
  dio.onAuthFailure = authNotifier.logout;

  return dio;
});

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepositoryImpl(
    // [-] localDataSource is no longer needed in the repo
    cloudDataSource: getIt<RemoteMediaDataSource>(),
    // [-] syncStateService is removed
    db: getIt<AppDatabase>(),
    syncJobManager: ref.watch(syncJobManagerProvider), // [+] Add syncJobManager
  );
});

final mediaViewModelProvider =
    StateNotifierProvider<MediaViewModel, MediaState>((ref) {
      final mediaRepository = ref.watch(mediaRepositoryProvider);
      return MediaViewModel(mediaRepository); // [-] Remove the 'ref' argument
    });

enum MediaViewType { grid, timeline }

final mediaViewTypeProvider = StateProvider<MediaViewType>(
  (_) => MediaViewType.timeline,
);

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final syncStateServiceProvider = Provider<SyncStateService>((ref) {
  final prefs = getIt<SharedPreferences>();
  return SyncStateService(prefs);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  final storage = ref.watch(secureStorageServiceProvider);
  return AuthService(dio, storage);
});

final serverCheckServiceProvider = Provider<ServerCheckService>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return ServerCheckService(dio);
});
