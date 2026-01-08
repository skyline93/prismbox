// lib/services/post/post_task_manager.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/post_task_status.dart';
import 'package:prismbox/services/post/post_service.dart';
import 'package:prismbox/services/backup/upload_service.dart';
import 'package:prismbox/services/backup/upload_orchestrator.dart';
import 'package:prismbox/data/database/enums/upload_task_type.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/services/backup/file_metadata_extractor.dart';
import 'package:prismbox/utils/cancellation_token.dart';

/// 帖子任务管理器
/// 管理帖子发布任务的生命周期：媒体上传 → 创建帖子
class PostTaskManager {
  final AppDatabase _database;
  final PostService _postService;
  final UploadService _uploadService;
  final UploadOrchestrator _uploadOrchestrator;
  final Logger _logger = Logger('PostTaskManager');

  // 任务执行流控制器
  final _taskStatusController = StreamController<PostTaskStatusUpdate>.broadcast();

  /// 任务状态更新流
  Stream<PostTaskStatusUpdate> get taskStatusStream => _taskStatusController.stream;

  PostTaskManager({
    required AppDatabase database,
    required PostService postService,
    required UploadService uploadService,
    required UploadOrchestrator uploadOrchestrator,
  })  : _database = database,
        _postService = postService,
        _uploadService = uploadService,
        _uploadOrchestrator = uploadOrchestrator;

  /// 创建帖子发布任务
  /// 
  /// [userId] 用户 ID
  /// [groupId] 圈子 UUID
  /// [caption] 帖子文字说明
  /// [mediaPaths] 媒体文件路径列表
  /// [mediaAssetIds] 媒体资产 ID 列表（LocalAssetEntity 的 id，可选）
  /// 
  /// 返回任务 ID
  /// 
  /// 注意：如果提供了 mediaAssetIds，将使用 LocalAssetEntity 的 assetId 来创建上传任务
  Future<String> createTask({
    required String userId,
    required String groupId,
    String? caption,
    required List<String> mediaPaths,
    List<String>? mediaAssetIds,
  }) async {
    final taskId = const Uuid().v4();
    final now = DateTime.now();
    final mediaPathsJson = jsonEncode(mediaPaths);
    final mediaAssetIdsJson = mediaAssetIds != null ? jsonEncode(mediaAssetIds) : null;

    final task = PostTaskEntityCompanion(
      id: Value(taskId),
      userId: Value(userId),
      groupId: Value(groupId),
      caption: Value(caption),
      mediaPaths: Value(mediaPathsJson),
      mediaAssetIds: Value(mediaAssetIdsJson),
      status: const Value(PostTaskStatus.pending),
      progress: const Value(0),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    await _database.postTaskDao.createTask(task);
    _logger.info('Created post task: taskId=$taskId, groupId=$groupId, mediaCount=${mediaPaths.length}');

    // 立即开始执行任务
    _executeTask(taskId).catchError((error) {
      _logger.severe('Failed to execute task: taskId=$taskId, error=$error', error);
    });

    return taskId;
  }

  /// 执行任务（媒体上传 → 创建帖子）
  Future<void> _executeTask(String taskId) async {
    try {
      final task = await _database.postTaskDao.getTaskById(taskId);
      if (task == null) {
        _logger.warning('Task not found: taskId=$taskId');
        return;
      }

      _logger.info('Executing post task: taskId=$taskId');

      // 阶段 1: 上传媒体
      await _uploadMedia(task);

      // 重新获取最新的 task（包含更新后的 mediaUuids）
      final updatedTask = await _database.postTaskDao.getTaskById(taskId);
      if (updatedTask == null) {
        throw Exception('Task not found after media upload: $taskId');
      }

      // 阶段 2: 创建帖子
      await _createPost(updatedTask);

      // 任务完成
      await _database.postTaskDao.updateTaskStatus(
        taskId,
        PostTaskStatus.completed,
        progress: 100,
      );

      _taskStatusController.add(PostTaskStatusUpdate(
        taskId: taskId,
        status: PostTaskStatus.completed,
        progress: 100,
      ));

      _logger.info('Post task completed: taskId=$taskId');
    } catch (e, stackTrace) {
      _logger.severe('Post task failed: taskId=$taskId, error=$e', e, stackTrace);
      
      final failedTask = await _database.postTaskDao.getTaskById(taskId);
      await _database.postTaskDao.updateTaskStatus(
        taskId,
        PostTaskStatus.failed,
        errorMessage: e.toString(),
        progress: failedTask?.progress ?? 0,
      );

      _taskStatusController.add(PostTaskStatusUpdate(
        taskId: taskId,
        status: PostTaskStatus.failed,
        progress: failedTask?.progress ?? 0,
        errorMessage: e.toString(),
      ));
    }
  }

  /// 上传媒体文件
  Future<void> _uploadMedia(PostTaskEntityData task) async {
    await _database.postTaskDao.updateTaskStatus(
      task.id,
      PostTaskStatus.uploadingMedia,
      progress: 0,
    );

    _taskStatusController.add(PostTaskStatusUpdate(
      taskId: task.id,
      status: PostTaskStatus.uploadingMedia,
      progress: 0,
    ));

    final mediaPaths = jsonDecode(task.mediaPaths) as List;
    final mediaUuids = <String>[];
    
    // 解析 mediaAssetIds（如果存在）
    List<String>? mediaAssetIds;
    if (task.mediaAssetIds != null) {
      mediaAssetIds = (jsonDecode(task.mediaAssetIds!) as List)
          .map((e) => e as String)
          .toList();
    }

    _logger.info('Uploading ${mediaPaths.length} media files for task: ${task.id}');

    // 如果提供了 mediaAssetIds，从 LocalAssetDao 获取资产信息
    Map<String, LocalAssetEntityData>? localAssetsMap;
    if (mediaAssetIds != null && mediaAssetIds.isNotEmpty) {
      localAssetsMap = await _database.localAssetDao.getAssetsByIds(mediaAssetIds);
      _logger.info('Loaded ${localAssetsMap.length} local assets from database');
    }

    // 为每个媒体文件创建上传任务
    final uploadTasks = <UploadTaskEntityData>[];
    for (int i = 0; i < mediaPaths.length; i++) {
      final mediaPath = mediaPaths[i] as String;
      final file = File(mediaPath);
      
      if (!await file.exists()) {
        throw Exception('Media file not found: $mediaPath');
      }

      // 获取文件大小
      final fileSize = await FileMetadataExtractor().extractFileSize(mediaPath);
      
      // 确定 assetId：如果提供了 mediaAssetIds，使用真实的 assetId；否则使用临时 ID
      final assetId = (mediaAssetIds != null && i < mediaAssetIds.length)
          ? mediaAssetIds[i]
          : '${task.id}_media_$i';
      
      // 验证 assetId 是否存在于 LocalAssetEntity 中（如果提供了 mediaAssetIds）
      if (mediaAssetIds != null && i < mediaAssetIds.length) {
        final localAsset = localAssetsMap?[assetId];
        if (localAsset == null) {
          throw Exception('Local asset not found: $assetId');
        }
        // 验证文件路径是否匹配
        if (localAsset.path != mediaPath) {
          _logger.warning(
            'Path mismatch for asset $assetId: expected ${localAsset.path}, got $mediaPath',
          );
        }
      }
      
      // 创建上传任务
      final uploadTaskId = '${task.id}_media_$i';
      final uploadTask = UploadTaskEntityData(
        id: uploadTaskId,
        userId: task.userId,
        assetId: assetId, // 使用真实的 assetId（如果提供）
        localPath: mediaPath,
        remotePath: '', // 由上传服务填充
        fileSize: fileSize,
        taskType: UploadTaskType.manual,
        priority: 1, // 高优先级
        status: UploadTaskStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        errorMessage: null,
        uploadedAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        progress: 0,
      );

      uploadTasks.add(uploadTask);
    }

    // 添加上传任务到队列
    await _uploadService.addTasks(uploadTasks);

    // 等待所有上传完成
    final cancellationToken = CancellationToken();
    final result = await _uploadOrchestrator.orchestrateUpload(
      userId: task.userId,
      tasks: uploadTasks,
      cancellationToken: cancellationToken,
      taskType: UploadTaskType.manual,
      onProgress: (current, total) {
        final progress = ((current / total) * 50).round(); // 媒体上传占 50% 进度
        _database.postTaskDao.updateTaskProgress(task.id, progress);
        _taskStatusController.add(PostTaskStatusUpdate(
          taskId: task.id,
          status: PostTaskStatus.uploadingMedia,
          progress: progress,
        ));
      },
    );

    if (result.failedCount > 0) {
      throw Exception('Failed to upload ${result.failedCount} media files');
    }

    // 获取上传后的媒体 UUID
    // 从 orchestrateUpload 的返回值获取 UUID（不再直接读取数据库）
    if (result.mediaUuids != null && result.mediaUuids!.isNotEmpty) {
      // 按照 uploadTasks 的顺序提取 UUID
      for (int i = 0; i < uploadTasks.length; i++) {
        final taskId = uploadTasks[i].id;
        final mediaUuid = result.mediaUuids![taskId];
        if (mediaUuid != null && mediaUuid.isNotEmpty) {
          mediaUuids.add(mediaUuid);
        } else {
          _logger.warning(
            'Media UUID not found in result for task: taskId=$taskId',
          );
          throw Exception(
            'Media UUID not available for upload task: $taskId',
          );
        }
      }
    } else {
      _logger.warning(
        'Media UUIDs not available in upload result: taskId=${task.id}',
      );
      throw Exception('Media UUIDs not available in upload result');
    }

    if (mediaUuids.length != mediaPaths.length) {
      throw Exception(
        'Not all media files uploaded successfully: '
        'expected=${mediaPaths.length}, got=${mediaUuids.length}',
      );
    }

    // 保存媒体 UUID 列表
    await _database.postTaskDao.updateMediaUuids(task.id, mediaUuids);

    await _database.postTaskDao.updateTaskStatus(
      task.id,
      PostTaskStatus.mediaUploaded,
      progress: 50,
    );

    _taskStatusController.add(PostTaskStatusUpdate(
      taskId: task.id,
      status: PostTaskStatus.mediaUploaded,
      progress: 50,
    ));
  }

  /// 创建帖子
  Future<void> _createPost(PostTaskEntityData task) async {
    await _database.postTaskDao.updateTaskStatus(
      task.id,
      PostTaskStatus.creatingPost,
      progress: 75,
    );

    _taskStatusController.add(PostTaskStatusUpdate(
      taskId: task.id,
      status: PostTaskStatus.creatingPost,
      progress: 75,
    ));

    final mediaUuids = task.mediaUuids != null
        ? task.mediaUuids!.split(',')
        : <String>[];

    if (mediaUuids.isEmpty) {
      throw Exception('No media UUIDs available');
    }

    await _postService.createPost(
      groupUuid: task.groupId,
      mediaUuids: mediaUuids,
      caption: task.caption,
    );

    await _database.postTaskDao.updateTaskStatus(
      task.id,
      PostTaskStatus.completed,
      progress: 100,
    );

    _taskStatusController.add(PostTaskStatusUpdate(
      taskId: task.id,
      status: PostTaskStatus.completed,
      progress: 100,
    ));
  }

  /// 取消任务
  Future<void> cancelTask(String taskId) async {
    final task = await _database.postTaskDao.getTaskById(taskId);
    if (task == null) {
      return;
    }

    // 取消相关的上传任务
    // 注意：UploadService 没有直接的 cancelTask 方法
    // 需要通过 UploadOrchestrator 或直接更新任务状态
    // TODO: 实现取消上传任务的逻辑
    // 可以通过更新任务状态为 cancelled 或调用 UploadService 的取消方法

    // 删除任务
    await _database.postTaskDao.deleteTask(taskId);
  }

  /// 重试失败的任务
  Future<void> retryTask(String taskId) async {
    final task = await _database.postTaskDao.getTaskById(taskId);
    if (task == null) {
      throw Exception('Task not found: $taskId');
    }

    if (task.status != PostTaskStatus.failed) {
      throw Exception('Task is not in failed state: $taskId');
    }

    // 重置任务状态
    await _database.postTaskDao.updateTaskStatus(
      taskId,
      PostTaskStatus.pending,
      errorMessage: null,
      progress: 0,
    );

    // 重新执行任务
    _executeTask(taskId).catchError((error) {
      _logger.severe('Failed to retry task: taskId=$taskId, error=$error', error);
    });
  }

  /// 恢复未完成的任务（应用启动时调用）
  /// 
  /// 检查并恢复所有处于 pending、uploading_media 或 creating_post 状态的任务
  Future<void> resumePendingTasks(String userId) async {
    try {
      final pendingTasks = await _database.postTaskDao.getPendingTasksByUserId(userId);
      
      if (pendingTasks.isEmpty) {
        return;
      }

      _logger.info('Resuming ${pendingTasks.length} pending post tasks for user: $userId');

      for (final task in pendingTasks) {
        // 如果任务处于可恢复状态，重新执行
        if (task.status == PostTaskStatus.pending ||
            task.status == PostTaskStatus.uploadingMedia ||
            task.status == PostTaskStatus.creatingPost) {
          _logger.info('Resuming post task: ${task.id}, status: ${task.status}');
          
          // 重新执行任务
          _executeTask(task.id).catchError((error) {
            _logger.severe('Failed to resume task: taskId=${task.id}, error=$error', error);
          });
        }
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to resume pending tasks: $e', e, stackTrace);
    }
  }

  void dispose() {
    _taskStatusController.close();
  }
}

/// 任务状态更新
class PostTaskStatusUpdate {
  final String taskId;
  final PostTaskStatus status;
  final int progress;
  final String? errorMessage;

  PostTaskStatusUpdate({
    required this.taskId,
    required this.status,
    required this.progress,
    this.errorMessage,
  });
}

