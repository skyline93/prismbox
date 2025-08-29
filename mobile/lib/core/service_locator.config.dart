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

import '../data/datasources/local_db/app_database.dart' as _i669;
import '../data/datasources/local_media_source.dart' as _i290;
import '../data/datasources/remote_media_source.dart' as _i527;
import '../data/repositories/group_repository_impl.dart' as _i875;
import '../data/repositories/media_repository_impl.dart' as _i74;
import '../data/services/dio_client.dart' as _i305;
import '../data/services/group_api_service.dart' as _i470;
import '../domain/repositories/group_repository.dart' as _i957;
import '../domain/repositories/media_repository.dart' as _i442;
import '../services/album_sync_service.dart' as _i166;
import '../services/local_media_observer.dart' as _i538;
import '../services/sync_job_manager.dart' as _i987;
import '../services/sync_job_processor.dart' as _i642;
import 'database_module.dart' as _i384;
import 'injectable_modules.dart' as _i129;
import 'storage/secure_storage_service.dart' as _i65;
import 'storage/sync_state_service.dart' as _i518;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final injectableModule = _$InjectableModule();
    final databaseModule = _$DatabaseModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => injectableModule.prefs,
      preResolve: true,
    );
    await gh.singletonAsync<_i669.AppDatabase>(
      () => databaseModule.database,
      preResolve: true,
    );
    gh.lazySingleton<_i518.SyncStateService>(
        () => _i518.SyncStateService(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i65.SecureStorageService>(
        () => _i65.SecureStorageService(gh<_i669.AppDatabase>()));
    gh.lazySingleton<_i166.AlbumSyncService>(
        () => _i166.AlbumSyncService(gh<_i669.AppDatabase>()));
    gh.lazySingleton<_i987.SyncJobManager>(
        () => _i987.SyncJobManager(gh<_i669.AppDatabase>()));
    gh.lazySingleton<_i305.DioClient>(
        () => _i305.DioClient(gh<_i65.SecureStorageService>()));
    gh.lazySingleton<_i290.LocalMediaDataSource>(
        () => _i290.LocalMediaDataSource(
              gh<_i669.AppDatabase>(),
              gh<_i987.SyncJobManager>(),
            ));
    gh.lazySingleton<_i361.Dio>(
        () => injectableModule.getDio(gh<_i305.DioClient>()));
    gh.lazySingleton<_i527.RemoteMediaDataSource>(
        () => injectableModule.getRemoteMediaSource(gh<_i361.Dio>()));
    gh.lazySingleton<_i470.GroupApiService>(
        () => _i470.GroupApiService(gh<_i361.Dio>()));
    gh.lazySingleton<_i442.MediaRepository>(() => _i74.MediaRepositoryImpl(
          cloudDataSource: gh<_i527.RemoteMediaDataSource>(),
          db: gh<_i669.AppDatabase>(),
          syncJobManager: gh<_i987.SyncJobManager>(),
          localMediaSource: gh<_i290.LocalMediaDataSource>(),
        ));
    gh.lazySingleton<_i957.GroupRepository>(
        () => _i875.GroupRepositoryImpl(gh<_i470.GroupApiService>()));
    gh.factory<_i642.SyncJobProcessor>(() => _i642.SyncJobProcessor(
          db: gh<_i669.AppDatabase>(),
          remoteApi: gh<_i527.RemoteMediaDataSource>(),
        ));
    gh.lazySingleton<_i538.LocalMediaObserver>(() => _i538.LocalMediaObserver(
          gh<_i987.SyncJobManager>(),
          gh<_i442.MediaRepository>(),
          gh<_i518.SyncStateService>(),
          gh<_i166.AlbumSyncService>(),
        ));
    return this;
  }
}

class _$InjectableModule extends _i129.InjectableModule {}

class _$DatabaseModule extends _i384.DatabaseModule {}
