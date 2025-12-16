// lib/services/backup/providers/asset_upload_status_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/features/backup/models/asset_upload_status.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/data/database/daos/upload_task_dao.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart' as infra;

part 'asset_upload_status_provider.g.dart';

/// 资产上传状态 Provider
/// 
/// 根据资产查询上传状态，结合数据库和任务状态
/// 使用 family 参数化，每个资产有独立的状态实例
/// 
/// **状态判断逻辑**：
/// 1. 如果 asset.hasRemote == true → 已上传
/// 2. 如果是 LocalAsset，查询上传任务状态：
///    - uploading/pending → 上传中
///    - failed/permanentlyFailed → 上传失败
///    - completed → 已上传（即使 remoteAssetId 为空，可能是数据不一致）
/// 3. 否则 → 未上传
@riverpod
Future<AssetUploadStatusInfo> assetUploadStatus(
  AssetUploadStatusRef ref,
  BaseAsset asset, // family 参数通过函数参数传递
) async {
  final database = await ref.watch(infra.databaseProvider.future);
  
  // 1. 检查是否已上传（通过 remoteAssetId）
  if (asset.hasRemote) {
    return const AssetUploadStatusInfo(
      status: AssetUploadStatus.uploaded,
    );
  }
  
  // 2. 如果是 LocalAsset，查询上传任务状态
  if (asset is LocalAsset) {
    final localId = asset.localId;
    
    // 如果 localId 为空，返回未上传状态
    if (localId == null) {
      return const AssetUploadStatusInfo(
        status: AssetUploadStatus.notUploaded,
      );
    }
    
    // 查询上传任务（获取最新的任务）
    final dao = UploadTaskDao(database);
    final task = await dao.getTaskByLocalAssetId(localId);
    
    if (task != null) {
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
  }
  
  // 3. 默认状态：未上传
  return const AssetUploadStatusInfo(
    status: AssetUploadStatus.notUploaded,
  );
}

