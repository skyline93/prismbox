// lib/features/local_sync/providers/timeline_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/features/local_sync/models/sync_status.dart';
import 'package:prismbox/features/local_sync/models/timeline_section.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';
import 'package:prismbox/features/local_sync/services/timeline_grouping_service.dart';
import 'package:prismbox/providers/photo_filter/photo_filter_provider.dart';

part 'timeline_provider.g.dart';

/// 时间线数据 Provider
/// 提供时间线数据（BaseAsset 列表）
@riverpod
Future<List<LocalAsset>> timelineAssets(
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
/// 支持根据筛选模式（全部/已备份/未备份）过滤照片
@riverpod
Future<List<TimelineSection>> timelineSections(TimelineSectionsRef ref) async {
  // 1. 获取原始数据
  final assets = await ref.watch(timelineAssetsProvider().future);

  // 2. 获取筛选模式并过滤数据
  final filterMode = ref.watch(photoFilterModeProvider);
  final filteredAssets = _filterAssets(assets, filterMode);

  // 3. 如果过滤后没有数据，直接返回空列表（避免不必要的分组操作）
  if (filteredAssets.isEmpty) {
    return [];
  }

  // 4. 执行分组转换
  final groupingService = TimelineGroupingService();
  final sections = groupingService.groupByTime(filteredAssets);

  // 5. 移除空分组（过滤后可能产生空分组）
  return sections.where((section) => section.assets.isNotEmpty).toList();
}

/// 根据筛选模式过滤资产列表
///
/// [assets] - 原始资产列表
/// [filterMode] - 筛选模式
/// 返回过滤后的资产列表
List<LocalAsset> _filterAssets(
  List<LocalAsset> assets,
  PhotoFilterModeEnum filterMode,
) {
  switch (filterMode) {
    case PhotoFilterModeEnum.all:
      // 显示全部，不过滤
      return assets;
    case PhotoFilterModeEnum.backedUp:
      // 仅显示已备份（remoteAssetId != null）
      return assets.where((asset) => asset.remoteAssetId != null).toList();
    case PhotoFilterModeEnum.notBackedUp:
      // 仅显示未备份（remoteAssetId == null）
      return assets.where((asset) => asset.remoteAssetId == null).toList();
  }
}

/// 同步状态 Provider
@riverpod
Stream<SyncStatusInfo> syncStatus(SyncStatusRef ref) async* {
  final coordinator = await ref.watch(syncCoordinatorProvider.future);
  yield* coordinator.statusStream;
}
