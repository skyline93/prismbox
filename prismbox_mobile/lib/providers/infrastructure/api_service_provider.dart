import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_service_provider.g.dart';

/// ApiService Provider
@riverpod
ApiService apiService(ApiServiceRef ref) {
  final service = ApiService();
  service.initialize();
  return service;
}

