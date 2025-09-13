// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:isolate' as _i709;

import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../data/datasources/local_db/app_database.dart' as _i669;
import '../data/datasources/local_media_source.dart' as _i290;
import '../data/datasources/remote_media_source.dart' as _i527;
import '../data/repositories/group_repository_impl.dart' as _i875;
import '../data/repositories/media_repository_impl.dart' as _i74;
import '../data/repositories/user_repository_impl.dart' as _i223;
import '../data/services/dio_client.dart' as _i305;
import '../data/services/group_api_service.dart' as _i470;
import '../data/services/media_api_service.dart' as _i816;
import '../data/services/user_api_service.dart' as _i1052;
import '../domain/repositories/group_repository.dart' as _i957;
import '../domain/repositories/media_repository.dart' as _i442;
import '../domain/repositories/user_repository.dart' as _i544;
import '../features/sync/coordinator/media_sync_service_core.dart' as _i551;
import '../features/sync/coordinator/media_sync_service_proxy.dart' as _i34;
import '../features/sync/handlers/asset_action_handler.dart' as _i1008;
import '../features/sync/synchronizers/album_synchronizer.dart' as _i54;
import '../features/sync/synchronizers/cloud_media_synchronizer.dart' as _i907;
import '../features/sync/synchronizers/local_media_synchronizer.dart' as _i730;
import '../services/transfer/download_service.dart' as _i180;
import '../services/transfer/transfer_manager.dart' as _i422;
import '../services/transfer/upload_service.dart' as _i1069;
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
    gh.lazySingleton<_i34.MediaSyncServiceProxy>(
        () => _i34.MediaSyncServiceProxy());
    gh.lazySingleton<_i518.SyncStateService>(
        () => _i518.SyncStateService(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i65.SecureStorageService>(
        () => _i65.SecureStorageService(gh<_i669.AppDatabase>()));
    gh.lazySingleton<_i54.AlbumSynchronizer>(
        () => _i54.AlbumSynchronizer(gh<_i669.AppDatabase>()));
    gh.lazySingleton<_i1008.AssetActionHandler>(
        () => _i1008.AssetActionHandler(gh<_i669.AppDatabase>()));
    gh.lazySingleton<_i305.DioClient>(
        () => _i305.DioClient(gh<_i65.SecureStorageService>()));
    gh.lazySingleton<_i730.LocalMediaSynchronizer>(
        () => _i730.LocalMediaSynchronizer(gh<_i669.AppDatabase>()));
    gh.lazySingleton<_i290.LocalMediaDataSource>(
        () => _i290.LocalMediaDataSource(gh<_i669.AppDatabase>()));
    gh.lazySingleton<_i1069.UploadService>(() => _i1069.UploadService(
          gh<_i669.AppDatabase>(),
          gh<_i65.SecureStorageService>(),
        ));
    gh.lazySingleton<_i361.Dio>(
        () => injectableModule.getDio(gh<_i305.DioClient>()));
    gh.lazySingleton<_i1052.UserApiService>(
        () => _i1052.UserApiService(gh<_i361.Dio>()));
    gh.lazySingleton<_i470.GroupApiService>(
        () => _i470.GroupApiService(gh<_i361.Dio>()));
    gh.lazySingleton<_i816.MediaApiService>(
        () => _i816.MediaApiService(gh<_i305.DioClient>()));
    gh.lazySingleton<_i527.RemoteMediaDataSource>(
        () => injectableModule.getRemoteMediaSource(gh<_i305.DioClient>()));
    gh.lazySingleton<_i957.GroupRepository>(
        () => _i875.GroupRepositoryImpl(gh<_i470.GroupApiService>()));
    gh.lazySingleton<_i442.MediaRepository>(() => _i74.MediaRepositoryImpl(
          cloudDataSource: gh<_i527.RemoteMediaDataSource>(),
          db: gh<_i669.AppDatabase>(),
          localMediaSource: gh<_i290.LocalMediaDataSource>(),
        ));
    gh.factory<_i907.CloudMediaSynchronizer>(
        () => _i907.CloudMediaSynchronizer(gh<_i527.RemoteMediaDataSource>()));
    gh.lazySingleton<_i544.UserRepository>(
        () => _i223.UserRepositoryImpl(gh<_i1052.UserApiService>()));
    gh.lazySingleton<_i180.DownloadService>(() => _i180.DownloadService(
          gh<_i669.AppDatabase>(),
          gh<_i527.RemoteMediaDataSource>(),
        ));
    gh.lazySingleton<_i422.TransferManager>(() => _i422.TransferManager(
          gh<_i180.DownloadService>(),
          gh<_i1069.UploadService>(),
        ));
    gh.factoryParam<_i551.MediaSyncServiceCore, _i709.SendPort, dynamic>((
      mainSendPort,
      _,
    ) =>
        _i551.MediaSyncServiceCore(
          mainSendPort,
          gh<_i730.LocalMediaSynchronizer>(),
          gh<_i907.CloudMediaSynchronizer>(),
          gh<_i54.AlbumSynchronizer>(),
          gh<_i1008.AssetActionHandler>(),
          gh<_i669.AppDatabase>(),
        ));
    return this;
  }
}

class _$InjectableModule extends _i129.InjectableModule {}

class _$DatabaseModule extends _i384.DatabaseModule {}
