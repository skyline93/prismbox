// lib/core/di/service_locator.dart

import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/data/services/dio_client.dart';
import 'package:mobile/features/background_jobs/impl/media_sync/domain/orchestrator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/data/datasources/local_db/connection.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:mobile/features/background_jobs/impl/media_sync/domain/synchronizers/local_media_synchronizer.dart';
import 'package:mobile/features/background_jobs/impl/media_sync/domain/synchronizers/album_synchronizer.dart';
import 'package:mobile/features/background_jobs/impl/media_sync/domain/asset_change_executor.dart';

// 假设 injectable 生成的文件名为 service_locator.config.dart
import 'service_locator.config.dart';

final getIt = GetIt.instance;

// 这是一个顶级函数，可以在应用的任何地方调用
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: false, // 设置为 false 以生成顶级的 init 函数
)
Future<void> configureDependencies() => init(getIt);

/// 为 Isolate 上下文注册特殊的依赖。
///
/// 这个函数应该在 Isolate 内部，在调用 configureDependencies() 之后被调用。
/// 它注册了那些需要在运行时动态传入参数的依赖，比如 MediaSyncServiceCore。
void configureIsolateDependencies() {
  if (getIt.isRegistered<MediaSyncOrchestrator>()) {
    getIt.unregister<MediaSyncOrchestrator>();
  }

  // 注册一个 factory，它需要一个 SendPort 作为参数。
  // get_it 将能够根据参数类型自动找到这个注册。
  getIt.registerFactoryParam<MediaSyncOrchestrator, SendPort, void>(
    (mainSendPort, _) => MediaSyncOrchestrator(
      getIt<LocalMediaSynchronizer>(),
      getIt<AlbumSynchronizer>(),
      getIt<AssetChangeExecutor>(),
      getIt<AppDatabase>(),
    ),
  );
}

@module
abstract class InjectableModule {
  @lazySingleton
  Dio getDio(DioClient client) => client.dio;

  @lazySingleton
  RemoteMediaDataSource getRemoteMediaSource(DioClient dioClient) =>
      RemoteMediaDataSource(dioClient);

  @preResolve
  Future<SharedPreferences> get prefs async =>
      await SharedPreferences.getInstance();
}

@module
abstract class DatabaseModule {
  @preResolve
  @singleton
  Future<AppDatabase> get database => connect();
}
