// lib/services/backup/task_factory.dart

import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/asset_type.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/data/database/enums/upload_task_type.dart';
import 'package:prismbox/infrastructure/asset/asset_path_resolver.dart';
import 'package:prismbox/services/backup/file_metadata_extractor.dart';
import 'package:prismbox/services/backup/models/live_photo_upload_metadata.dart';

/// 任务工厂
///
/// **职责**：
/// - 统一任务创建逻辑
/// - 参数化任务类型、优先级等差异
/// - 处理文件路径解析和元数据提取
class TaskFactory {
  final AppDatabase _database;
  final AssetPathResolver _pathResolver;
  final FileMetadataExtractor _metadataExtractor;
  final Logger _logger = Logger('TaskFactory');

  TaskFactory({
    required AppDatabase database,
    required AssetPathResolver pathResolver,
    required FileMetadataExtractor metadataExtractor,
  })  : _database = database,
        _pathResolver = pathResolver,
        _metadataExtractor = metadataExtractor;

  /// 创建单个上传任务
  ///
  /// **参数**：
  /// - [asset] - 本地资产实体
  /// - [userId] - 用户 ID
  /// - [remotePath] - 远程路径（上传目标路径）
  /// - [taskType] - 任务类型（manual/auto）
  /// - [priority] - 优先级（数字越小优先级越高）
  ///
  /// **返回**：
  /// - UploadTaskEntityData（如果成功创建）
  /// - null（如果文件不存在或无法解析路径）
  Future<UploadTaskEntityData?> createTask({
    required LocalAssetEntityData asset,
    required String userId,
    required String remotePath,
    required UploadTaskType taskType,
    required int priority,
  }) async {
    // 0. 针对 Live Photo 的特殊处理：
    //    如果当前资产是 Live Photo 的主图（image + livePhotoVideoId 非空），
    //    则本任务只负责上传对应的视频文件，图片部分稍后在视频完成回调中派生。
    LocalAssetEntityData assetForUpload = asset;
    LivePhotoUploadMetadata? livePhotoMetadata;

    final isLivePhotoImage = asset.type == AssetType.image &&
        asset.livePhotoVideoId != null &&
        asset.livePhotoVideoId!.isNotEmpty;

    if (isLivePhotoImage) {
      _logger.info(
        '[LivePhoto] TaskFactory: asset recognized as Live Photo main image, '
        'imageAssetId=${asset.id}, videoLocalId=${asset.livePhotoVideoId}',
      );
      try {
        final videoAsset = await _database.localAssetDao
            .getAssetById(asset.livePhotoVideoId!);

        if (videoAsset != null) {
          assetForUpload = videoAsset;
          livePhotoMetadata = LivePhotoUploadMetadata(
            localAssetId: asset.id,
            isLivePhoto: true,
            part: LivePhotoTaskPart.video,
          );
          _logger.info(
            '[LivePhoto] TaskFactory: will create VIDEO task, '
            'imageAssetId=${asset.id}, videoAssetId=${videoAsset.id}',
          );
        } else {
          _logger.warning(
            'Live Photo video asset not found, fallback to image upload: '
            'imageAssetId=${asset.id}, videoLocalId=${asset.livePhotoVideoId}',
          );
        }
      } catch (e, stackTrace) {
        _logger.warning(
          'Failed to resolve Live Photo video asset, fallback to image upload: '
          'imageAssetId=${asset.id}, videoLocalId=${asset.livePhotoVideoId}, '
          'error=$e',
          e,
          stackTrace,
        );
      }
    }

    // 1. 解析文件路径（对于 Live Photo 主图，优先解析对应视频资产的路径）
    final actualPath = await _pathResolver.resolveAssetPath(assetForUpload);
    if (actualPath == null || actualPath.isEmpty) {
      _logger.warning('No valid file path for asset: ${asset.id}');
      return null;
    }

    if (livePhotoMetadata != null) {
      final pathTail = actualPath.split('/').last;
      _logger.info(
        '[LivePhoto] TaskFactory: resolved path for VIDEO task, '
        'pathTail=$pathTail, assetForUpload.type=${assetForUpload.type.name}',
      );
    }

    // 2. 提取文件大小
    final fileSize = await _metadataExtractor.extractFileSize(actualPath);

    // 3. 生成任务 ID
    final taskIdPrefix = taskType == UploadTaskType.manual ? 'manual' : 'auto';
    final taskId =
        '${taskIdPrefix}_${asset.id}_${DateTime.now().millisecondsSinceEpoch}';

    // 4. 创建任务实体
    final task = UploadTaskEntityData(
      id: taskId,
      userId: userId,
      assetId: asset.id,
      localPath: actualPath,
      remotePath: remotePath,
      fileSize: fileSize,
      taskType: taskType,
      priority: priority,
      status: UploadTaskStatus.pending,
      retryCount: 0,
      maxRetries: 3,
      errorMessage: null,
      uploadedAt: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      progress: 0,
      livePhotoMetadataJson: livePhotoMetadata?.toJsonString(),
    );

    if (task.livePhotoMetadataJson != null &&
        task.livePhotoMetadataJson!.isNotEmpty) {
      _logger.info(
        '[LivePhoto] TaskFactory: task created with livePhotoMetadata, '
        'taskId=${task.id}, assetId=${task.assetId}, '
        'localPathTail=${task.localPath.split("/").last}, '
        'metadataLength=${task.livePhotoMetadataJson!.length}',
      );
    }

    return task;
  }

  /// 批量创建上传任务
  ///
  /// **参数**：
  /// - [assets] - 本地资产实体列表
  /// - [userId] - 用户 ID
  /// - [remotePath] - 远程路径（上传目标路径）
  /// - [taskType] - 任务类型（manual/auto）
  /// - [priority] - 优先级（数字越小优先级越高）
  ///
  /// **返回**：
  /// - 成功创建的任务列表（跳过无法创建的任务）
  Future<List<UploadTaskEntityData>> createTasks({
    required List<LocalAssetEntityData> assets,
    required String userId,
    required String remotePath,
    required UploadTaskType taskType,
    required int priority,
  }) async {
    final tasks = <UploadTaskEntityData>[];

    for (final asset in assets) {
      final task = await createTask(
        asset: asset,
        userId: userId,
        remotePath: remotePath,
        taskType: taskType,
        priority: priority,
      );

      if (task != null) {
        tasks.add(task);
      }
    }

    return tasks;
  }
}

