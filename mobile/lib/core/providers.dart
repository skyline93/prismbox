// lib/core/providers.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/dio_client.dart';
import '../data/services/auth_service.dart';
import '../core/storage/secure_storage_service.dart';
import 'package:mobile/data/services/server_check_service.dart';

// 1. Dio Provider (基础)
final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

// 2. DioClient Provider (依赖 Dio 和 Storage)
final dioClientProvider = Provider<DioClient>((ref) {
  // 注意这里的变化，我们直接传入 Ref
  return DioClient(ref.read(dioProvider), ref);
});

// 3. AuthService Provider (依赖 DioClient)
final authServiceProvider = Provider<AuthService>((ref) {
  // 注意：我们从DioClient获取配置好的dio实例
  final dio = ref.watch(dioClientProvider).dio;
  final storage = ref.watch(secureStorageServiceProvider);
  return AuthService(dio, storage);
});

final serverCheckServiceProvider = Provider<ServerCheckService>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return ServerCheckService(dio);
});
