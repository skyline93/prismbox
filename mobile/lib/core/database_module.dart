// lib/core/database_module.dart

import 'package:injectable/injectable.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/data/datasources/local_db/connection.dart';

@module
abstract class DatabaseModule {
  @preResolve
  @singleton
  Future<AppDatabase> get database => connect();
}
