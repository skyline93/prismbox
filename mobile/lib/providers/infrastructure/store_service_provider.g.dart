// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$storeServiceHash() => r'79fc5f2caa7d25a1a411373c3f7afe1075aa9abc';

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
///
/// Copied from [storeService].
@ProviderFor(storeService)
final storeServiceProvider = Provider<StoreService>.internal(
  storeService,
  name: r'storeServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$storeServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StoreServiceRef = ProviderRef<StoreService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
