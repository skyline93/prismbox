// lib/providers/services/auth_service_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/core/storage/secure_storage_service.dart';
import 'package:prismbox/infrastructure/repositories/auth_repository_impl.dart';
import 'package:prismbox/providers/infrastructure/api_service_provider.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart';
import 'package:prismbox/services/auth/auth_service.dart';

part 'auth_service_provider.g.dart';

/// 认证仓库 Provider
@riverpod
AuthRepositoryImpl authRepository(AuthRepositoryRef ref) {
  return AuthRepositoryImpl(ref.read(apiServiceProvider));
}

/// 认证服务 Provider
@riverpod
Future<AuthService> authService(AuthServiceRef ref) async {
  final database = await ref.read(databaseProvider.future);
  return AuthService(
    repository: ref.read(authRepositoryProvider),
    apiService: ref.read(apiServiceProvider),
    secureStorage: SecureStorageService(),
    database: database,
  );
}

