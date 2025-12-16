// lib/services/backup/task_factory.dart

import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/data/database/enums/upload_task_type.dart';
import 'package:prismbox/services/backup/asset_path_resolver.dart';
import 'package:prismbox/services/backup/file_metadata_extractor.dart';

/// 任务工厂
///
/// **职责**：
/// - 统一任务创建逻辑
/// - 参数化任务类型、优先级等差异
/// - 处理文件路径解析和元数据提取
class TaskFactory {
  final AssetPathResolver _pathResolver;
  final FileMetadataExtractor _metadataExtractor;
  final Logger _logger = Logger('TaskFactory');

  TaskFactory({
    required AssetPathResolver pathResolver,
    required FileMetadataExtractor metadataExtractor,
  })  : _pathResolver = pathResolver,
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
    // 1. 解析文件路径
    final actualPath = await _pathResolver.resolveAssetPath(asset);
    if (actualPath == null || actualPath.isEmpty) {
      _logger.warning('No valid file path for asset: ${asset.id}');
      return null;
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
    );

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

