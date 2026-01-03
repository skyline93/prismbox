// lib/features/local_sync/providers/timeline_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/domain/entities/remote_asset.dart';
import 'package:prismbox/features/local_sync/models/sync_status.dart';
import 'package:prismbox/features/local_sync/models/timeline_section.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';
import 'package:prismbox/features/local_sync/services/timeline_grouping_service.dart';
import 'package:prismbox/providers/photo_filter/photo_filter_provider.dart';

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
/// 支持根据筛选模式（全部/已备份/未备份/仅云端）过滤照片
@riverpod
Future<List<TimelineSection>> timelineSections(TimelineSectionsRef ref) async {
  // 1. 获取筛选模式（先 watch，确保筛选模式变化时触发重新计算）
  final filterMode = ref.watch(photoFilterModeProvider);
  
  // 2. 获取原始数据
  // 使用固定的参数调用 timelineAssetsProvider，确保始终使用同一个 provider 实例
  // 直接 await provider 的 future，Riverpod 会自动等待数据加载完成
  // 这种方式确保数据已经加载完成后再进行筛选，避免在数据加载过程中筛选导致的问题
  final assets = await ref.watch(timelineAssetsProvider().future);

  // 3. 根据筛选模式过滤数据
  final filteredAssets = _filterAssets(assets, filterMode);

  // 4. 如果过滤后没有数据，直接返回空列表（避免不必要的分组操作）
  if (filteredAssets.isEmpty) {
    return [];
  }

  // 5. 执行分组转换
  final groupingService = TimelineGroupingService();
  final sections = groupingService.groupByTime(filteredAssets);

  // 6. 移除空分组（过滤后可能产生空分组）
  return sections.where((section) => section.assets.isNotEmpty).toList();
}

/// 根据筛选模式过滤资产列表
///
/// [assets] - 原始资产列表
/// [filterMode] - 筛选模式
/// 返回过滤后的资产列表
///
/// **过滤逻辑（解耦后）**：
/// - 全部：显示所有资产（本地和远程）
/// - 已备份：显示远程资产（因为解耦后，本地资产不再关联远程资产，所以"已备份"理解为"仅远程"）
/// - 未备份：显示本地资产（仅本地存在）
/// - 仅云端：显示远程资产（仅远程存在）
List<BaseAsset> _filterAssets(
  List<BaseAsset> assets,
  PhotoFilterModeEnum filterMode,
) {
  switch (filterMode) {
    case PhotoFilterModeEnum.all:
      // 显示全部，不过滤
      return assets;
    case PhotoFilterModeEnum.backedUp:
      // 仅显示远程资产（解耦后，"已备份"理解为"仅远程"）
      return assets.whereType<RemoteAsset>().toList();
    case PhotoFilterModeEnum.notBackedUp:
      // 仅显示本地资产（仅本地存在）
      return assets.whereType<LocalAsset>().toList();
    case PhotoFilterModeEnum.remoteOnly:
      // 仅显示远程资产（仅远程存在）
      return assets.whereType<RemoteAsset>().toList();
  }
}

/// 同步状态 Provider
@riverpod
Stream<SyncStatusInfo> syncStatus(SyncStatusRef ref) async* {
  final coordinator = await ref.watch(syncCoordinatorProvider.future);
  yield* coordinator.statusStream;
}
