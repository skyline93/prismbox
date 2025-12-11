// lib/providers/infrastructure/store_service_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/core/storage/store_service.dart';

part 'store_service_provider.g.dart';

/// StoreService Provider
/// 
/// 基础设施 Provider，管理应用级键值存储服务
/// 
/// **注意**：StoreService 在 main.dart 中已初始化（确保早期可用），
/// 此 Provider 返回已初始化的单例实例，符合依赖注入模式。
/// 
/// 使用方式：
/// ```dart
/// // 在 Widget 或 Provider 中使用
/// final store = ref.watch(storeServiceProvider);
/// final token = store.tryGet<String>(StoreKey.accessToken);
/// 
/// // 或者直接使用单例（全局函数中）
/// final store = StoreService();
/// final token = store.tryGet<String>(StoreKey.accessToken);
/// ```
@Riverpod(keepAlive: true)
StoreService storeService(StoreServiceRef ref) {
  // 返回已初始化的单例实例
  // StoreService 在 main.dart 中已初始化，这里直接返回单例
  return StoreService();
}

