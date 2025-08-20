// lib/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/data/datasources/app_database.dart';
import 'data/repositories/media_repository_impl.dart';
import 'domain/repositories/media_repository.dart';
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
import 'package:mobile/domain/entities/unified_media_entity.dart';

final syncJobManagerProvider = Provider<SyncJobManager>((ref) {
  return getIt<SyncJobManager>();
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
  print("[mediaRepositoryProvider] 初始化repo=================================");
  return MediaRepositoryImpl(
    cloudDataSource: getIt<RemoteMediaDataSource>(),
    db: getIt<AppDatabase>(),
    syncJobManager: ref.read(syncJobManagerProvider),
  );
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

final mediaStreamProvider = StreamProvider<List<UnifiedMediaEntity>>((ref) {
  final mediaRepository = ref.watch(mediaRepositoryProvider);
  return mediaRepository.getUnifiedMediaStream();
});
