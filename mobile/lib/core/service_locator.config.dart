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

import '../data/datasources/app_database.dart' as _i630;
import '../data/datasources/remote_media_source.dart' as _i527;
import '../data/services/dio_client.dart' as _i305;
import '../services/sync_job_processor.dart' as _i642;
import 'injectable_modules.dart' as _i129;
import 'storage/secure_storage_service.dart' as _i65;

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
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => injectableModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i65.SecureStorageService>(
        () => _i65.SecureStorageService());
    gh.lazySingleton<_i630.AppDatabase>(() => _i630.AppDatabase());
    gh.lazySingleton<_i305.DioClient>(
        () => _i305.DioClient(gh<_i65.SecureStorageService>()));
    gh.lazySingleton<_i361.Dio>(
        () => injectableModule.getDio(gh<_i305.DioClient>()));
    gh.lazySingleton<_i527.RemoteMediaDataSource>(
        () => injectableModule.getRemoteMediaSource(gh<_i361.Dio>()));
    gh.factory<_i642.SyncJobProcessor>(() => _i642.SyncJobProcessor(
          db: gh<_i630.AppDatabase>(),
          remoteApi: gh<_i527.RemoteMediaDataSource>(),
        ));
    return this;
  }
}

class _$InjectableModule extends _i129.InjectableModule {}
