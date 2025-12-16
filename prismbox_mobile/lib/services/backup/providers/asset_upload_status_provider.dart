// lib/services/backup/providers/asset_upload_status_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/features/backup/models/asset_upload_status.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/data/database/daos/upload_task_dao.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart' as infra;

part 'asset_upload_status_provider.g.dart';

/// 资产上传状态 Provider
/// 
/// 根据资产查询上传状态，结合数据库和任务状态
/// 使用唯一标识符（assetId）作为 family 参数，确保每个资产有独立的 Provider 实例
/// 使用 StreamProvider 实现实时状态更新，避免状态闪烁
/// 
/// **优化措施**：
/// - 使用唯一标识符作为 family 参数，避免对象相等性比较问题
/// - 先查询初始值，避免 Stream 先返回 null 导致的闪烁
/// - 状态去重，只在状态真正改变时才 yield
/// 
/// **参数**：
/// - [assetId] - 资产的唯一标识符（localId 或 id）
/// - [hasRemote] - 资产是否有远程版本（用于快速判断已上传状态）
/// 
/// **状态判断逻辑**：
/// 1. 如果 hasRemote == true → 已上传
/// 2. 如果是 LocalAsset，监听上传任务状态变化：
///    - uploading/pending → 上传中
///    - failed/permanentlyFailed → 上传失败
///    - completed → 已上传（即使 remoteAssetId 为空，可能是数据不一致）
/// 3. 否则 → 未上传
@riverpod
Stream<AssetUploadStatusInfo> assetUploadStatus(
  AssetUploadStatusRef ref,
  String assetId, // 使用唯一标识符作为 family 参数
  bool hasRemote, // 资产是否有远程版本
) async* {
  final database = await ref.watch(infra.databaseProvider.future);
  
  // 1. 检查是否已上传（通过 remoteAssetId）
  if (hasRemote) {
    yield const AssetUploadStatusInfo(
      status: AssetUploadStatus.uploaded,
    );
    return;
  }
  
  // 2. 监听上传任务状态变化
  final dao = UploadTaskDao(database);
  
  // 先查询一次初始值，避免 Stream 先返回 null 导致的闪烁
  final initialTask = await dao.getTaskByLocalAssetId(assetId);
  AssetUploadStatusInfo? lastStatus;
  
  if (initialTask != null) {
    lastStatus = _getStatusFromTask(initialTask);
    yield lastStatus;
  } else {
    lastStatus = const AssetUploadStatusInfo(
      status: AssetUploadStatus.notUploaded,
    );
    yield lastStatus;
  }
  
  // 监听上传任务变化（获取最新的任务）
  // 使用状态去重，只在状态真正改变时才 yield
  await for (final task in dao.watchTaskByLocalAssetId(assetId)) {
    final newStatus = task != null 
        ? _getStatusFromTask(task)
        : const AssetUploadStatusInfo(
            status: AssetUploadStatus.notUploaded,
          );
    
    // 只有在状态真正改变时才 yield（避免重复更新导致的抖动）
    if (lastStatus?.status != newStatus.status ||
        lastStatus?.progress != newStatus.progress) {
      lastStatus = newStatus;
      yield newStatus;
    }
  }
}

/// 根据任务状态转换为资产上传状态信息
AssetUploadStatusInfo _getStatusFromTask(UploadTaskEntityData task) {
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
  }
}

