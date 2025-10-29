// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../data/datasources/local_db/app_database.dart' as _i870;
import '../../data/datasources/local_media_source.dart' as _i273;
import '../../data/datasources/remote_media_source.dart' as _i200;
import '../../data/repositories/group_repository_impl.dart' as _i654;
import '../../data/repositories/media_repository_impl.dart' as _i872;
import '../../data/repositories/user_repository_impl.dart' as _i790;
import '../../data/services/dio_client.dart' as _i153;
import '../../data/services/group_api_service.dart' as _i637;
import '../../data/services/user_api_service.dart' as _i663;
import '../../domain/repositories/group_repository.dart' as _i708;
import '../../domain/repositories/media_repository.dart' as _i777;
import '../../domain/repositories/user_repository.dart' as _i271;
import '../../features/background_jobs/core/isolate/isolate_job_manager.dart'
    as _i317;
import '../../features/background_jobs/impl/auto_backup/domain/auto_backup_isolate_handler.dart'
    as _i872;
import '../../features/background_jobs/impl/media_sync/domain/asset_change_executor.dart'
    as _i367;
import '../../features/background_jobs/impl/media_sync/domain/isolate_handler.dart'
    as _i1062;
import '../../features/background_jobs/impl/media_sync/domain/orchestrator.dart'
    as _i91;
import '../../features/background_jobs/impl/media_sync/domain/synchronizers/album_synchronizer.dart'
    as _i799;
import '../../features/background_jobs/impl/media_sync/domain/synchronizers/local_media_synchronizer.dart'
    as _i137;
import '../../features/background_jobs/impl/media_sync/service/media_sync_service.dart'
    as _i436;
import '../../services/auto_backup_service.dart' as _i439;
import '../../services/settings_service.dart' as _i583;
import '../../services/transfer/backupground_upload_service.dart' as _i1039;
import '../../services/transfer/download_service.dart' as _i1014;
import '../../services/transfer/transfer_manager.dart' as _i134;
import '../../services/transfer/upload_auth_handler.dart' as _i100;
import '../../services/transfer/upload_orchestrator.dart' as _i0;
import '../../services/transfer/upload_service.dart' as _i851;
import '../storage/secure_storage_service.dart' as _i666;
import '../storage/sync_state_service.dart' as _i446;
import 'service_locator.dart' as _i105;

// initializes the registration of main-scope dependencies inside of GetIt
Future<_i174.GetIt> init(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) async {
  final gh = _i526.GetItHelper(
    getIt,
    environment,
    environmentFilter,
  );
  final injectableModule = _$InjectableModule();
  final databaseModule = _$DatabaseModule();
  await gh.factoryAsync<_i460.SharedPreferences>(
    () => injectableModule.prefs,
    preResolve: true,
  );
  gh.factory<_i0.UploadOrchestrator>(() => _i0.UploadOrchestrator());
  await gh.singletonAsync<_i870.AppDatabase>(
    () => databaseModule.database,
    preResolve: true,
  );
  gh.lazySingleton<_i317.IsolateJobManager>(
    () => _i317.IsolateJobManager(),
    dispose: (i) => i.dispose(),
  );
  gh.lazySingleton<_i446.SyncStateService>(
      () => _i446.SyncStateService(gh<_i870.AppDatabase>()));
  gh.lazySingleton<_i666.SecureStorageService>(
      () => _i666.SecureStorageService(gh<_i870.AppDatabase>()));
  gh.lazySingleton<_i799.AlbumSynchronizer>(
      () => _i799.AlbumSynchronizer(gh<_i870.AppDatabase>()));
  gh.lazySingleton<_i367.AssetChangeExecutor>(
      () => _i367.AssetChangeExecutor(gh<_i870.AppDatabase>()));
  gh.lazySingleton<_i100.UploadAuthHandler>(
      () => _i100.UploadAuthHandler(gh<_i666.SecureStorageService>()));
  gh.lazySingleton<_i436.MediaSyncService>(
    () => _i436.MediaSyncService(gh<_i317.IsolateJobManager>()),
    dispose: (i) => i.dispose(),
  );
  gh.lazySingleton<_i153.DioClient>(
      () => _i153.DioClient(gh<_i666.SecureStorageService>()));
  gh.lazySingleton<_i137.LocalMediaSynchronizer>(
      () => _i137.LocalMediaSynchronizer(gh<_i870.AppDatabase>()));
  gh.lazySingleton<_i273.LocalMediaDataSource>(
      () => _i273.LocalMediaDataSource(gh<_i870.AppDatabase>()));
  gh.lazySingleton<_i583.SettingsService>(
      () => _i583.SettingsService(gh<_i870.AppDatabase>()));
  gh.lazySingleton<_i851.UploadService>(() => _i851.UploadService(
        gh<_i870.AppDatabase>(),
        gh<_i583.SettingsService>(),
        gh<_i100.UploadAuthHandler>(),
      ));
  gh.lazySingleton<_i1039.BackupgroundUploadService>(
      () => _i1039.BackupgroundUploadService(
            gh<_i870.AppDatabase>(),
            gh<_i583.SettingsService>(),
            gh<_i100.UploadAuthHandler>(),
          ));
  gh.factory<_i91.MediaSyncOrchestrator>(() => _i91.MediaSyncOrchestrator(
        gh<_i137.LocalMediaSynchronizer>(),
        gh<_i799.AlbumSynchronizer>(),
        gh<_i367.AssetChangeExecutor>(),
        gh<_i870.AppDatabase>(),
      ));
  gh.lazySingleton<_i439.AutoBackupService>(
    () => _i439.AutoBackupService(gh<_i583.SettingsService>()),
    dispose: (i) => i.dispose(),
  );
  gh.lazySingleton<_i361.Dio>(
      () => injectableModule.getDio(gh<_i153.DioClient>()));
  gh.factory<_i1062.MediaSyncIsolateHandler>(
      () => _i1062.MediaSyncIsolateHandler(gh<_i91.MediaSyncOrchestrator>()));
  gh.lazySingleton<_i663.UserApiService>(
      () => _i663.UserApiService(gh<_i361.Dio>()));
  gh.lazySingleton<_i637.GroupApiService>(
      () => _i637.GroupApiService(gh<_i361.Dio>()));
  gh.factory<_i1039.AutoBackupHandler>(() => _i1039.AutoBackupHandler(
        gh<_i583.SettingsService>(),
        gh<_i870.AppDatabase>(),
      ));
  gh.factory<_i872.AutoBackupIsolateHandler>(
      () => _i872.AutoBackupIsolateHandler(
            gh<_i583.SettingsService>(),
            gh<_i870.AppDatabase>(),
            gh<_i0.UploadOrchestrator>(),
          ));
  gh.lazySingleton<_i200.RemoteMediaDataSource>(
      () => injectableModule.getRemoteMediaSource(gh<_i153.DioClient>()));
  gh.lazySingleton<_i708.GroupRepository>(
      () => _i654.GroupRepositoryImpl(gh<_i637.GroupApiService>()));
  gh.lazySingleton<_i777.MediaRepository>(() => _i872.MediaRepositoryImpl(
        cloudDataSource: gh<_i200.RemoteMediaDataSource>(),
        db: gh<_i870.AppDatabase>(),
        localMediaSource: gh<_i273.LocalMediaDataSource>(),
      ));
  gh.lazySingleton<_i271.UserRepository>(
      () => _i790.UserRepositoryImpl(gh<_i663.UserApiService>()));
  gh.lazySingleton<_i1014.DownloadService>(() => _i1014.DownloadService(
        gh<_i870.AppDatabase>(),
        gh<_i200.RemoteMediaDataSource>(),
      ));
  gh.lazySingleton<_i134.TransferManager>(() => _i134.TransferManager(
        gh<_i1014.DownloadService>(),
        gh<_i851.UploadService>(),
        gh<_i583.SettingsService>(),
      ));
  return getIt;
}

class _$InjectableModule extends _i105.InjectableModule {}

class _$DatabaseModule extends _i105.DatabaseModule {}
