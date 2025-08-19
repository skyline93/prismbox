// lib/core/injectable_modules.dart

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/data/services/dio_client.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:mobile/data/datasources/app_database.dart';

@module
abstract class InjectableModule {
  @lazySingleton
  AppDatabase get appDatabase => AppDatabase.forInjectable();

  @lazySingleton
  Dio getDio(DioClient client) => client.dio;

  @lazySingleton
  RemoteMediaDataSource getRemoteMediaSource(Dio dio) =>
      RemoteMediaDataSource(dio);

  @preResolve
  Future<SharedPreferences> get prefs async =>
      await SharedPreferences.getInstance();
}
