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
import 'package:prismbox/config/app_config.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/services/backup/task_factory.dart';
import 'package:prismbox/services/backup/upload_service.dart';
import 'package:prismbox/services/backup/upload_orchestrator.dart';
import 'package:prismbox/data/database/enums/upload_task_type.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/services/backup/file_metadata_extractor.dart';
import 'package:prismbox/utils/cancellation_token.dart';

/// 帖子任务管理器
/// 管理帖子发布任务的生命周期：媒体上传 → 创建帖子
/// 发帖媒体上传与手动备份共用同一套任务创建（TaskFactory）与编排，以支持完整 Live Photo 成对上传。
class PostTaskManager {
  final AppDatabase _database;
  final PostService _postService;
  final UploadService _uploadService;
  final UploadOrchestrator _uploadOrchestrator;
  final TaskFactory _taskFactory;
  final ApiService _apiService;
  final Logger _logger = Logger('PostTaskManager');

  static const String _uploadEndpoint = '/api/v1/media/upload-stream';

  // 任务执行流控制器
  final _taskStatusController = StreamController<PostTaskStatusUpdate>.broadcast();

  /// 任务状态更新流
  Stream<PostTaskStatusUpdate> get taskStatusStream => _taskStatusController.stream;

  PostTaskManager({
    required AppDatabase database,
    required PostService postService,
    required UploadService uploadService,
    required UploadOrchestrator uploadOrchestrator,
    required TaskFactory taskFactory,
    required ApiService apiService,
  })  : _database = database,
        _postService = postService,
        _uploadService = uploadService,
        _uploadOrchestrator = uploadOrchestrator,
        _taskFactory = taskFactory,
        _apiService = apiService;

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
  /// 当提供 mediaAssetIds 时与手动备份对齐：使用 TaskFactory 建任务（支持 Live Photo 成对上传），
  /// 并按 displayAssetIdToUuid 得到有序展示用 UUID；否则回退为按路径建任务。
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
    List<String>? mediaAssetIds;
    if (task.mediaAssetIds != null) {
      mediaAssetIds = (jsonDecode(task.mediaAssetIds!) as List)
          .map((e) => e as String)
          .toList();
    }

    final List<UploadTaskEntityData> uploadTasks;
    if (mediaAssetIds != null && mediaAssetIds.isNotEmpty) {
      // 与手动备份一致：按资产建任务（含 Live Photo 先视频后图片）
      uploadTasks = await _createUploadTasksFromAssets(
        task: task,
        mediaAssetIds: mediaAssetIds,
        mediaPaths: mediaPaths,
      );
    } else {
      uploadTasks = await _createUploadTasksFromPaths(
        task: task,
        mediaPaths: mediaPaths,
      );
    }

    if (uploadTasks.isEmpty) {
      throw Exception('No upload tasks created for task: ${task.id}');
    }

    await _uploadService.addTasks(uploadTasks);

    final cancellationToken = CancellationToken();
    final result = await _uploadOrchestrator.orchestrateUpload(
      userId: task.userId,
      tasks: uploadTasks,
      cancellationToken: cancellationToken,
      taskType: UploadTaskType.manual,
      onProgress: (current, total) {
        final progress = ((current / total) * 50).round();
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

    final mediaUuids = _collectOrderedMediaUuids(
      result: result,
      uploadTasks: uploadTasks,
      mediaAssetIds: mediaAssetIds,
      mediaPathsCount: mediaPaths.length,
      taskId: task.id,
    );

    if (mediaUuids.length != mediaPaths.length) {
      throw Exception(
        'Not all media files uploaded successfully: '
        'expected=${mediaPaths.length}, got=${mediaUuids.length}',
      );
    }

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

  /// 使用 TaskFactory 按资产创建上传任务（与 BackupService 手动备份一致，支持 Live Photo）
  Future<List<UploadTaskEntityData>> _createUploadTasksFromAssets({
    required PostTaskEntityData task,
    required List<String> mediaAssetIds,
    required List mediaPaths,
  }) async {
    final localAssets = <LocalAssetEntityData>[];
    for (final assetId in mediaAssetIds) {
      final asset = await _database.localAssetDao.getAssetById(assetId);
      if (asset == null) {
        throw Exception('Local asset not found: $assetId');
      }
      localAssets.add(asset);
    }
    final endpoint = _apiService.endpoint ?? ApiConfig.apiEndpoint;
    final remotePath = '$endpoint$_uploadEndpoint';
    final tasks = await _taskFactory.createTasks(
      assets: localAssets,
      userId: task.userId,
      remotePath: remotePath,
      taskType: UploadTaskType.manual,
      priority: 1,
    );
    _logger.info(
      'Created ${tasks.length} upload tasks from assets for post task: ${task.id}',
    );
    return tasks;
  }

  /// 按路径创建上传任务（回退路径，无 Live Photo 成对逻辑）
  Future<List<UploadTaskEntityData>> _createUploadTasksFromPaths({
    required PostTaskEntityData task,
    required List mediaPaths,
  }) async {
    final uploadTasks = <UploadTaskEntityData>[];
    for (int i = 0; i < mediaPaths.length; i++) {
      final mediaPath = mediaPaths[i] as String;
      final file = File(mediaPath);
      if (!await file.exists()) {
        throw Exception('Media file not found: $mediaPath');
      }
      final fileSize = await FileMetadataExtractor().extractFileSize(mediaPath);
      final assetId = '${task.id}_media_$i';
      uploadTasks.add(UploadTaskEntityData(
        id: '${task.id}_media_$i',
        userId: task.userId,
        assetId: assetId,
        localPath: mediaPath,
        remotePath: '',
        fileSize: fileSize,
        taskType: UploadTaskType.manual,
        priority: 1,
        status: UploadTaskStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        errorMessage: null,
        uploadedAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        progress: 0,
      ));
    }
    return uploadTasks;
  }

  /// 按选中顺序收集媒体 UUID：优先 displayAssetIdToUuid，否则按 taskId 顺序
  List<String> _collectOrderedMediaUuids({
    required UploadResult result,
    required List<UploadTaskEntityData> uploadTasks,
    required List<String>? mediaAssetIds,
    required int mediaPathsCount,
    required String taskId,
  }) {
    if (result.displayAssetIdToUuid != null &&
        result.displayAssetIdToUuid!.isNotEmpty &&
        mediaAssetIds != null &&
        mediaAssetIds.length == mediaPathsCount) {
      final ordered = <String>[];
      for (final id in mediaAssetIds) {
        final uuid = result.displayAssetIdToUuid![id];
        if (uuid == null || uuid.isEmpty) {
          throw Exception(
            'Media UUID not available for display asset: $id (post task: $taskId)',
          );
        }
        ordered.add(uuid);
      }
      return ordered;
    }
    // 回退：按初始任务顺序从 mediaUuids 取
    if (result.mediaUuids == null || result.mediaUuids!.isEmpty) {
      throw Exception('Media UUIDs not available in upload result');
    }
    final ordered = <String>[];
    for (final uploadTask in uploadTasks) {
      final uuid = result.mediaUuids![uploadTask.id];
      if (uuid == null || uuid.isEmpty) {
        throw Exception(
          'Media UUID not available for upload task: ${uploadTask.id}',
        );
      }
      ordered.add(uuid);
    }
    return ordered;
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

