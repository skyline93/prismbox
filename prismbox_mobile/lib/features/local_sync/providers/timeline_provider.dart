// lib/features/local_sync/providers/timeline_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/features/local_sync/models/sync_status.dart';
import 'package:prismbox/features/local_sync/models/timeline_section.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';
import 'package:prismbox/features/local_sync/services/timeline_grouping_service.dart';

part 'timeline_provider.g.dart';

/// 时间线数据 Provider
/// 提供时间线数据（BaseAsset 列表）
@riverpod
Future<List<LocalAsset>> timelineAssets(
  TimelineAssetsRef ref, {
  bool forcePhotoManager = false,
}) async {
  final service = await ref.watch(timelineProviderServiceProvider.future);
  return await service.getTimelineAssets(
    forcePhotoManager: forcePhotoManager,
  );
}

/// 时间线分组数据 Provider
/// 
/// 将原始的时间线数据转换为按时间分组的 TimelineSection 列表
/// 依赖 timelineAssetsProvider 获取原始数据，然后通过 TimelineGroupingService 进行分组转换
@riverpod
Future<List<TimelineSection>> timelineSections(
  TimelineSectionsRef ref,
) async {
  // 1. 获取原始数据
  final assets = await ref.watch(timelineAssetsProvider().future);

  // 2. 执行分组转换
  final groupingService = TimelineGroupingService();
  final sections = groupingService.groupByTime(assets);

  return sections;
}

/// 同步状态 Provider
@riverpod
Stream<SyncStatusInfo> syncStatus(SyncStatusRef ref) async* {
  final coordinator = await ref.watch(syncCoordinatorProvider.future);
  yield* coordinator.statusStream;
}

