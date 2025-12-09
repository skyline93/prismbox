// lib/features/local_sync/providers/timeline_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/features/local_sync/models/sync_status.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';

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

/// 同步状态 Provider
@riverpod
Stream<SyncStatusInfo> syncStatus(SyncStatusRef ref) async* {
  final coordinator = await ref.watch(syncCoordinatorProvider.future);
  yield* coordinator.statusStream;
}

