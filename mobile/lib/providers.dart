import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/data/datasources/local_media_source.dart';
import 'package:mobile/data/datasources/app_database.dart';
import 'package:mobile/ui/media/viewmodels/timeline_state.dart';
// 导入所有需要被注入的类
import 'data/repositories/media_repository_impl.dart';
import 'domain/repositories/media_repository.dart';
import 'package:mobile/ui/media/viewmodels/timeline_viewmodel.dart';

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

/// 媒体仓库的提供者
/// 这里我们注册的是抽象类 `MediaRepository`，返回的是具体实现。
/// 这是依赖倒置原则的最佳实践。
final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  final localDataSource = ref.watch(localMediaDataSourceProvider);
  final db = ref.watch(databaseProvider);
  return MediaRepositoryImpl(localDataSource: localDataSource, db: db);
});

// ==========================================================================
// Presentation Layer Providers (表现层提供者)
// ==========================================================================

/// Timeline ViewModel 的提供者
///
/// 使用 `StateNotifierProvider`，它专门用于提供 `StateNotifier` 的实例。
/// UI 将通过监听这个 provider 来获取状态并响应变化。
final timelineViewModelProvider =
    StateNotifierProvider<TimelineViewModel, TimelineState>((ref) {
      // 将 MediaRepository 注入到 ViewModel 中。
      final mediaRepository = ref.watch(mediaRepositoryProvider);
      return TimelineViewModel(mediaRepository, ref);
    });
