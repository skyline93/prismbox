// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_worker_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$backgroundWorkerFgServiceHash() =>
    r'ae315bc98a26ff4bf41cfc2e49ff8a7fe9dc39b2';

/// 前台后台工作器服务 Provider
///
/// 提供后台任务的启用、禁用、配置等功能
///
/// **使用方式**：
/// ```dart
/// final service = ref.read(backgroundWorkerFgServiceProvider);
/// await service.enable(notificationTitle: '备份中...');
/// await service.configure(
///   requiresCharging: false,
///   minimumDelaySeconds: 300,
/// );
/// await service.disable();
/// ```
///
/// **注意**：
/// - 使用 keepAlive: true 确保全局单例，避免重复创建
///
/// Copied from [backgroundWorkerFgService].
@ProviderFor(backgroundWorkerFgService)
final backgroundWorkerFgServiceProvider =
    Provider<BackgroundWorkerFgService>.internal(
  backgroundWorkerFgService,
  name: r'backgroundWorkerFgServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$backgroundWorkerFgServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BackgroundWorkerFgServiceRef = ProviderRef<BackgroundWorkerFgService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
