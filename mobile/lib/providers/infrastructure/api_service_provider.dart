import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_service_provider.g.dart';

/// ApiService Provider
/// 使用 keepAlive 保持实例存活，避免重复初始化
@Riverpod(keepAlive: true)
ApiService apiService(ApiServiceRef ref) {
  final service = ApiService();
  service.initialize();
  return service;
}

