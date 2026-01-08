// lib/features/local_sync/providers/timeline_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/local_sync/models/sync_status.dart';
import 'package:prismbox/features/local_sync/models/timeline_section.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';
import 'package:prismbox/features/local_sync/services/timeline_grouping_service.dart';
import 'package:prismbox/providers/photo_filter/photo_filter_provider.dart';
import 'package:prismbox/providers/timeline/timeline_content_filter_provider.dart';
import 'package:prismbox/providers/timeline/timeline_sort_provider.dart';

part 'timeline_provider.g.dart';

/// 时间线数据 Provider
/// 提供时间线数据（BaseAsset 列表）
@riverpod
Future<List<BaseAsset>> timelineAssets(
  TimelineAssetsRef ref, {
  bool forcePhotoManager = false,
}) async {
  final service = await ref.watch(timelineProviderServiceProvider.future);
  return await service.getTimelineAssets(forcePhotoManager: forcePhotoManager);
}

/// 时间线分组数据 Provider
///
/// 将原始的时间线数据转换为按时间分组的 TimelineSection 列表
/// 依赖 timelineAssetsProvider 获取原始数据，然后通过 TimelineGroupingService 进行分组转换
/// 支持多级过滤和排序：
/// - 本地/远程隔离过滤（全局共享，通过 `PhotoFilterModeProvider`）
/// - 内容过滤（页面级，通过 `TimelineContentFilterConfigProvider`）
/// - 排序（页面级，通过 `TimelineSortConfigProvider`）
///
/// [pageId] 页面标识符，用于区分不同页面（如 'main', 'favorite', 'video', 'recentlyAdded'）
@riverpod
Future<List<TimelineSection>> timelineSections(
  TimelineSectionsRef ref, {
  String pageId = 'main',
}) async {
  // 1. 获取本地/远程隔离过滤模式（全局共享）
  final filterMode = ref.watch(photoFilterModeProvider);

  // 2. 获取内容过滤配置（页面级）
  final contentFilter = ref.watch(
    timelineContentFilterConfigProviderProvider(pageId),
  );

  // 3. 获取排序配置（页面级）
  final sortConfig = ref.watch(timelineSortConfigProviderProvider(pageId));

  // 4. 获取原始数据
  // 使用固定的参数调用 timelineAssetsProvider，确保始终使用同一个 provider 实例
  // 直接 await provider 的 future，Riverpod 会自动等待数据加载完成
  // 这种方式确保数据已经加载完成后再进行筛选，避免在数据加载过程中筛选导致的问题
  final service = await ref.watch(timelineProviderServiceProvider.future);
  final assets = await service.getTimelineAssets(
    filterMode: filterMode,
    contentFilter: contentFilter.hasContentFilter ? contentFilter : null,
    sortConfig: sortConfig,
  );

  // 5. 如果过滤后没有数据，直接返回空列表（避免不必要的分组操作）
  if (assets.isEmpty) {
    return [];
  }

  // 6. 执行分组转换
  final groupingService = TimelineGroupingService();
  final sections = groupingService.groupByTime(assets);

  // 7. 移除空分组（过滤后可能产生空分组）
  return sections.where((section) => section.assets.isNotEmpty).toList();
}

/// 同步状态 Provider
@riverpod
Stream<SyncStatusInfo> syncStatus(SyncStatusRef ref) async* {
  final coordinator = await ref.watch(syncCoordinatorProvider.future);
  yield* coordinator.statusStream;
}
