// lib/providers/infrastructure/database_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/connection.dart';

part 'database_provider.g.dart';

/// 数据库 Provider
@Riverpod(keepAlive: true)
Future<AppDatabase> database(DatabaseRef ref) async {
  return await DatabaseConnection.getInstance();
}

