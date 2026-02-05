// lib/services/backup/providers/asset_upload_status_provider.dart

import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/features/backup/models/asset_upload_status.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/data/database/daos/upload_task_dao.dart';
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
import 'package:prismbox/services/backup/models/live_photo_upload_metadata.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart' as infra;

part 'asset_upload_status_provider.g.dart';


/// 资产上传状态 Provider
/// 
/// **⚠️ 架构问题：此接口负担过重**
/// 
/// 此 Provider 承担了过多职责，包括：
/// 1. 查询上传任务状态（upload_task_entity 表）
/// 2. 查询远程资产表（remote_asset_entity 表）
/// 3. 查询本地资产表（local_asset_entity 表，用于获取 checksum）
/// 4. 同时监听多个数据源的变化
/// 5. 合并多个数据源的状态判断逻辑
/// 6. 处理状态去重和错误处理
/// 
/// **建议重构方向**：
/// - 将状态判断逻辑提取到独立的 Service 层
/// - 使用组合模式，将不同数据源的查询分离
/// - 考虑使用 StateNotifier 替代 StreamProvider，提供更细粒度的控制
/// - 将状态合并逻辑提取为独立的函数或类
/// 
/// **当前实现说明**：
/// 根据资产查询上传状态，结合数据库和任务状态
/// 使用唯一标识符（assetId）作为 family 参数，确保每个资产有独立的 Provider 实例
/// 使用 StreamProvider 实现实时状态更新，避免状态闪烁
/// 
/// **优化措施**：
/// - 使用唯一标识符作为 family 参数，避免对象相等性比较问题
/// - 先查询初始值，避免 Stream 先返回 null 导致的闪烁
/// - 状态去重，只在状态真正改变时才 yield
/// - 同时监听上传任务表和远程资产表，确保状态实时更新
/// 
/// **参数**：
/// - [assetId] - 资产的唯一标识符（localId 或 id）
/// - [hasRemote] - 资产是否有远程版本（保留用于向后兼容，但不再使用）
/// - [checksum] - 资产的 checksum（保留用于向后兼容，但不再使用）
/// 
/// **状态判断逻辑（优先级顺序）**：
/// 1. 优先查询上传任务状态（最可靠的数据源，用于显示上传进度）
/// 2. 如果没有任务记录，检查本地资产的 isUploaded 字段
/// 3. 否则显示未上传
@riverpod
Stream<AssetUploadStatusInfo> assetUploadStatus(
  AssetUploadStatusRef ref,
  String assetId, // 使用唯一标识符作为 family 参数
  bool hasRemote, // 保留用于向后兼容，但不再使用
  String? checksum, // 保留用于向后兼容，但不再使用
) async* {
  final database = await ref.watch(infra.databaseProvider.future);
  final uploadDao = UploadTaskDao(database);
  final localDao = LocalAssetDao(database);
  
  // 1. 查询初始状态
  AssetUploadStatusInfo? lastStatus;
  
  // 1.1 优先查询上传任务状态（用于显示上传进度）
  final initialTask = await uploadDao.getTaskByLocalAssetId(assetId);
  if (initialTask != null) {
    final livePhotoState =
        await _computeLivePhotoUploadState(uploadDao, assetId);
    lastStatus = _getStatusFromTask(initialTask).copyWith(
      livePhotoState: livePhotoState,
    );
    yield lastStatus;
  } else {
    // 1.2 如果没有任务记录，检查本地资产的 isUploaded 字段
    final localAsset = await localDao.getAssetById(assetId);
    if (localAsset != null && localAsset.isUploaded) {
      lastStatus = const AssetUploadStatusInfo(
        status: AssetUploadStatus.uploaded,
      );
      yield lastStatus;
    } else {
      lastStatus = const AssetUploadStatusInfo(
        status: AssetUploadStatus.notUploaded,
      );
      yield lastStatus;
    }
  }
  
  // 2. 监听上传任务变化（主要数据源）
  await for (final task in uploadDao.watchTaskByLocalAssetId(assetId)) {
    AssetUploadStatusInfo newStatus;
    final livePhotoState =
        await _computeLivePhotoUploadState(uploadDao, assetId);
    
    if (task != null) {
      // 任务存在，使用任务状态
      newStatus = _getStatusFromTask(task).copyWith(
        livePhotoState: livePhotoState,
      );
    } else {
      // 任务不存在，检查本地资产的 isUploaded 字段
      final localAsset = await localDao.getAssetById(assetId);
      if (localAsset != null && localAsset.isUploaded) {
        newStatus = const AssetUploadStatusInfo(
          status: AssetUploadStatus.uploaded,
        );
      } else {
        newStatus = AssetUploadStatusInfo(
          status: AssetUploadStatus.notUploaded,
          livePhotoState: livePhotoState,
        );
      }
    }
    
    // 只有在状态真正改变时才 yield（避免重复更新导致的抖动）
    if (lastStatus?.status != newStatus.status ||
        lastStatus?.progress != newStatus.progress) {
      lastStatus = newStatus;
      yield newStatus;
    }
  }
}

/// 根据任务状态转换为资产上传状态信息
/// 
/// **参数**：
/// - [task] - 上传任务实体（类型由 Drift 生成，在 app_database.g.dart 中定义）
/// 
/// **注意**：UploadTaskEntityData 类型由 Drift 代码生成器自动生成。
/// 如果遇到类型错误，请运行 `dart run build_runner build` 重新生成代码。
AssetUploadStatusInfo _getStatusFromTask(dynamic task) {
  // 类型安全：task 的实际类型是 UploadTaskEntityData（由 Drift 生成）
  // 但由于代码生成时机问题，暂时使用 dynamic
  switch (task.status) {
    case UploadTaskStatus.uploading:
      // 上传中，计算进度（0.0 - 1.0）
      final progress = task.progress / 100.0;
      return AssetUploadStatusInfo(
        status: AssetUploadStatus.uploading,
        progress: progress.clamp(0.0, 1.0),
      );
    case UploadTaskStatus.queued:
    case UploadTaskStatus.pending:
      // pending/queued 状态显示为上传中（但进度为0）
      // 这样用户可以看到任务已经创建并等待执行
      return const AssetUploadStatusInfo(
        status: AssetUploadStatus.uploading,
        progress: 0.0,
      );
    case UploadTaskStatus.failed:
    case UploadTaskStatus.permanentlyFailed:
      // 上传失败
      return AssetUploadStatusInfo(
        status: AssetUploadStatus.failed,
        errorMessage: task.errorMessage,
      );
    case UploadTaskStatus.completed:
      // 已完成但 remoteAssetId 为空，可能是数据不一致
      // 显示为已上传（后续需要修复数据）
      return const AssetUploadStatusInfo(
        status: AssetUploadStatus.uploaded,
      );
    case UploadTaskStatus.paused:
      // 暂停状态，显示为上传中（用户可能继续上传）
      final progress = task.progress / 100.0;
      return AssetUploadStatusInfo(
        status: AssetUploadStatus.uploading,
        progress: progress.clamp(0.0, 1.0),
      );
    case UploadTaskStatus.cancelled:
      // 已取消，显示为未上传
      return const AssetUploadStatusInfo(
        status: AssetUploadStatus.notUploaded,
      );
    default:
      // 未知状态，显示为未上传
      return const AssetUploadStatusInfo(
        status: AssetUploadStatus.notUploaded,
      );
  }
}

/// 计算指定资产的 Live Photo 聚合上传状态。
///
/// - 如果该资产不存在任何 Live Photo 相关任务，返回 null；
/// - 否则根据视频任务与图片任务的组合状态计算枚举值。
Future<LivePhotoUploadState?> _computeLivePhotoUploadState(
  UploadTaskDao uploadDao,
  String assetId,
) async {
  final tasks = await uploadDao.getTasksByLocalAssetIdAll(assetId);
  if (tasks.isEmpty) {
    return null;
  }

  final videoTasks = <dynamic>[];
  final imageTasks = <dynamic>[];

  for (final task in tasks) {
    final metadata = task.livePhotoMetadata;
    if (metadata == null || !metadata.isLivePhoto) {
      continue;
    }

    switch (metadata.part) {
      case LivePhotoTaskPart.video:
        videoTasks.add(task);
        break;
      case LivePhotoTaskPart.image:
        imageTasks.add(task);
        break;
    }
  }

  final hasVideo = videoTasks.isNotEmpty;
  final hasImage = imageTasks.isNotEmpty;

  if (!hasVideo && !hasImage) {
    // 虽然有任务，但都不是 Live Photo 相关
    return null;
  }

  bool _anyCompleted(List<dynamic> ts) =>
      ts.any((t) => t.status == UploadTaskStatus.completed);

  bool _anyUploading(List<dynamic> ts) => ts.any(
        (t) =>
            t.status == UploadTaskStatus.pending ||
            t.status == UploadTaskStatus.queued ||
            t.status == UploadTaskStatus.uploading ||
            t.status == UploadTaskStatus.paused,
      );

  bool _anyFailed(List<dynamic> ts) => ts.any(
        (t) =>
            t.status == UploadTaskStatus.failed ||
            t.status == UploadTaskStatus.permanentlyFailed ||
            t.status == UploadTaskStatus.cancelled,
      );

  final videoCompleted = hasVideo && _anyCompleted(videoTasks);
  final imageCompleted = hasImage && _anyCompleted(imageTasks);
  final videoUploading = hasVideo && _anyUploading(videoTasks);
  final imageUploading = hasImage && _anyUploading(imageTasks);
  final videoFailed = hasVideo && _anyFailed(videoTasks);
  final imageFailed = hasImage && _anyFailed(imageTasks);

  // 组合逻辑（按“进行中” > “成功” > “失败”的优先级）：

  // 1. 仍在进行中的场景优先
  if (videoUploading && !hasImage) {
    return LivePhotoUploadState.uploadingVideo;
  }
  if (videoCompleted && imageUploading) {
    return LivePhotoUploadState.uploadingPhoto;
  }

  // 2. 全部成功
  if (videoCompleted && imageCompleted) {
    return LivePhotoUploadState.bothUploaded;
  }

  // 3. 仅一边成功
  if (videoCompleted && !imageCompleted && !imageUploading && !imageFailed) {
    return LivePhotoUploadState.videoOnlyUploaded;
  }
  if (imageCompleted && !videoCompleted && !videoUploading && !videoFailed) {
    return LivePhotoUploadState.photoOnlyUploaded;
  }

  // 4. 失败场景
  if (videoFailed && imageFailed) {
    return LivePhotoUploadState.failedBoth;
  }
  if (videoFailed) {
    return LivePhotoUploadState.failedVideo;
  }
  if (imageFailed) {
    return LivePhotoUploadState.failedPhoto;
  }

  // 5. 无任务或未知组合，回退为 none
  return LivePhotoUploadState.none;
}

