// lib/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/data/datasources/local_media_source.dart';
import 'package:mobile/data/datasources/app_database.dart';
import 'package:mobile/ui/media/viewmodels/media_state.dart';
// 导入所有需要被注入的类
import 'data/repositories/media_repository_impl.dart';
import 'domain/repositories/media_repository.dart';
import 'package:mobile/ui/media/viewmodels/media_viewmodel.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:mobile/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/storage/sync_state_service.dart';

// ==========================================================================
// Data Layer Providers (数据层提供者)
// ==========================================================================

/// 数据库实例的提供者 (Singleton)
final databaseProvider = Provider<AppDatabase>((ref) {
  // Provider 默认就是单例。这个实例在应用的生命周期内只会被创建一次。
  return AppDatabase();
});

/// 本地媒体数据源的提供者
final localMediaDataSourceProvider = Provider<LocalMediaDataSource>((ref) {
  // `ref.watch` 用于读取其他 provider 的实例。
  // 当 databaseProvider 的值变化时（虽然在这里它不会变），这个 provider 会自动重新计算。
  final db = ref.watch(databaseProvider);
  return LocalMediaDataSource(db);
});

final remoteMediaSourceProvider = Provider<RemoteMediaDataSource>((ref) {
  // RemoteMediaDataSource 依赖于 Dio 实例
  final dio = ref.watch(dioClientProvider).dio;
  return RemoteMediaDataSource(dio);
});

/// 媒体仓库的提供者
/// 这里我们注册的是抽象类 `MediaRepository`，返回的是具体实现。
/// 这是依赖倒置原则的最佳实践。
final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepositoryImpl(
    localDataSource: ref.watch(localMediaDataSourceProvider),
    cloudDataSource: ref.watch(remoteMediaSourceProvider),
    syncStateService: ref.watch(syncStateServiceProvider),
    db: ref.watch(databaseProvider),
  );
});

// ==========================================================================
// Presentation Layer Providers (表现层提供者)
// ==========================================================================

/// Media ViewModel 的提供者
///
/// 使用 `StateNotifierProvider`，它专门用于提供 `StateNotifier` 的实例。
/// UI 将通过监听这个 provider 来获取状态并响应变化。
final mediaViewModelProvider =
    StateNotifierProvider<MediaViewModel, MediaState>((ref) {
      // 将 MediaRepository 注入到 ViewModel 中。
      final mediaRepository = ref.watch(mediaRepositoryProvider);
      return MediaViewModel(mediaRepository, ref);
    });

/// 定义视图模式的枚举
enum MediaViewMode {
  grid, // 网格视图
  timeline, // 时间线视图
}

/// 创建一个 StateProvider 来管理当前的视图模式。
///
/// StateProvider 是 Riverpod 中最简单的 Provider，非常适合管理简单、可变的 UI 状态。
/// 我们在这里设置默认视图为 `MediaViewMode.grid`。
final mediaViewModeProvider = StateProvider<MediaViewMode>(
  (_) => MediaViewMode.timeline,
);

// ==========================================================================
// Core/Infra Layer Providers (核心/基础设施层提供者)
// ==========================================================================

/// ✅ 第 1 步: 将 FutureProvider 修改为 Provider
/// 它现在只是一个占位符，期望在 main.dart 中被 override
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  // 这行代码理论上不应该被执行。
  // 如果执行了，说明你在 main.dart 中忘记了 override 这个 Provider。
  throw UnimplementedError('SharedPreferencesProvider was not overridden');
});

/// ✅ 第 2 步: 简化 syncStateServiceProvider
/// 它可以直接、同步地 watch 上面的 provider
final syncStateServiceProvider = Provider<SyncStateService>((ref) {
  // 直接 watch，不再需要 .when()
  // 因为 main.dart 中的 override 保证了实例在此处一定是可用的。
  final prefs = ref.watch(sharedPreferencesProvider);
  return SyncStateService(prefs);
});
