// lib/services/transfer_service.dart

import 'package:background_downloader/background_downloader.dart';
import 'package:drift/drift.dart' as d;
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:mobile/core/enums.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

@lazySingleton
class TransferService {
  final DownloadJobDao _downloadJobDao;
  final RemoteMediaDataSource _remoteMediaSource;
  final _log = Logger('TransferService');
  final _uuid = const Uuid();

  TransferService(AppDatabase db, this._remoteMediaSource)
    : _downloadJobDao = db.downloadJobDao;

  Future<void> initialize() async {
    await FileDownloader().configure(
      androidConfig: [
        // <--- 使用方括号 [] 将配置项变为一个列表
        ('logLevel', 'verbose'),
        ('network', 'any'), // <-- 添加这一行，允许在任何网络（包括移动数据）下下载
      ],
    );
    // 关键步骤：激活下载器
    await FileDownloader().start();

    FileDownloader().updates.listen(_onTaskUpdate);
    _log.info("TransferService initialized and listening for updates.");
  }

  void _onTaskUpdate(dynamic update) {
    final group = update.task.group;
    if (group == 'download') {
      _handleDownloadUpdate(update);
    } else {
      _handleUploadUpdate(update);
    }
  }

  Future<void> enqueueDownloadJob({
    required String mediaUuid,
    required String originalFilename,
  }) async {
    final jobId = _uuid.v4();
    final saveDir = await getApplicationDocumentsDirectory();
    final savePath = '${saveDir.path}/$originalFilename';

    try {
      // 步骤 1: 先通过网络请求获取媒体详情和下载 URL
      _log.info('Fetching media detail for mediaUuid: $mediaUuid');
      final mediaDetail = await _remoteMediaSource.getMediaDetail(mediaUuid);
      final downloadUrl = mediaDetail.downloadUrl;

      // 步骤 2: 创建一个包含所有必需字段的完整 Job 对象
      final newJob = DownloadJobsCompanion(
        jobId: d.Value(jobId),
        mediaUuid: d.Value(mediaUuid),
        savePath: d.Value(savePath),
        downloadUrl: d.Value(downloadUrl), // <-- 在这里提供 downloadUrl
        status: const d.Value(DownloadJobStatus.pending),
        progress: const d.Value(0.0),
        createdAt: d.Value(DateTime.now()),
      );

      // 步骤 3: 将完整的 Job 对象插入数据库
      await _downloadJobDao.insertJob(newJob);
      _log.info('Download job created in DB with jobId: $jobId');

      _log.info(
        '==> [DIAGNOSTIC LOG] Creating DownloadTask with requiresWiFi: false <==',
      );

      // 步骤 4: 创建并入队 background_downloader 的任务
      final task = DownloadTask(
        url: downloadUrl,
        filename: originalFilename,
        directory: saveDir.path,
        group: 'download',
        updates: Updates.statusAndProgress,
        requiresWiFi: false,
      );

      final result = await FileDownloader().enqueue(task);
      if (result) {
        // 步骤 5: 更新数据库中的 taskId 和状态
        await _downloadJobDao.updateJob(
          DownloadJobsCompanion(
            jobId: d.Value(jobId),
            taskId: d.Value(task.taskId),
            status: const d.Value(DownloadJobStatus.running),
          ),
        );
        _log.info(
          'Task enqueued with taskId: ${task.taskId} for jobId: $jobId',
        );
      } else {
        throw Exception('FileDownloader failed to enqueue the task.');
      }
    } catch (e, stacktrace) {
      _log.severe(
        'Failed to create or enqueue download for mediaUuid: $mediaUuid. Error: $e, Stacktrace: $stacktrace',
      );
      // 注意：因为错误可能发生在数据库插入之前，所以这里不需要再尝试更新状态。
      // 如果需要记录失败状态，您应该在 catch 块中插入一条状态为 failed 的记录。
      // 为了简化，这里我们假设获取URL失败或入队失败时，就不在数据库中创建记录。
    }
  }

  Future<void> _handleDownloadUpdate(dynamic update) async {
    final task = update.task;
    final job = await _downloadJobDao.getJobByTaskId(task.taskId);

    if (job == null) {
      _log.warning('Received update for an unknown taskId: ${task.taskId}');
      return;
    }

    DownloadJobsCompanion companion;
    if (update is TaskStatusUpdate) {
      final newStatus = _statusFromTaskStatus(update.status);
      companion = DownloadJobsCompanion(
        jobId: d.Value(job.jobId),
        status: d.Value(newStatus),
      );
      _log.fine('Download job ${job.jobId} status updated to $newStatus');
    } else if (update is TaskProgressUpdate) {
      companion = DownloadJobsCompanion(
        jobId: d.Value(job.jobId),
        progress: d.Value(update.progress),
        status: job.status == DownloadJobStatus.running
            ? const d.Value(DownloadJobStatus.running)
            : const d.Value.absent(),
      );
    } else {
      return;
    }
    await _downloadJobDao.updateJob(companion);
  }

  DownloadJobStatus _statusFromTaskStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.enqueued:
      case TaskStatus.running:
      case TaskStatus.waitingToRetry:
        return DownloadJobStatus.running;
      case TaskStatus.complete:
        return DownloadJobStatus.success;
      case TaskStatus.notFound:
      case TaskStatus.failed:
        return DownloadJobStatus.failed;
      case TaskStatus.canceled:
        return DownloadJobStatus.canceled;
      case TaskStatus.paused:
        return DownloadJobStatus.paused;
    }
  }

  /// [最终正确版] 暂停下载
  Future<void> pauseDownload(String jobId) async {
    final job = await _downloadJobDao.getJob(jobId);
    if (job != null && job.taskId != null) {
      // 正确流程 1: 使用 taskId 从 downloader 数据库获取 TaskRecord
      final record = await FileDownloader().database.recordForId(job.taskId!);
      if (record != null) {
        // 正确流程 2: 从 record 中获取 Task 对象，然后执行操作
        await FileDownloader().pause(record.task as DownloadTask);
      }
    }
  }

  /// [最终正确版] 恢复下载
  Future<void> resumeDownload(String jobId) async {
    final job = await _downloadJobDao.getJob(jobId);
    if (job != null && job.taskId != null) {
      final record = await FileDownloader().database.recordForId(job.taskId!);
      if (record != null) {
        await FileDownloader().resume(record.task as DownloadTask);
      }
    }
  }

  /// [最终正确版] 取消下载
  Future<void> cancelDownload(String jobId) async {
    final job = await _downloadJobDao.getJob(jobId);
    if (job != null && job.taskId != null) {
      // 对于取消，有更直接的 API
      await FileDownloader().cancelTasksWithIds([job.taskId!]);
    }
  }

  void _handleUploadUpdate(dynamic update) {
    // 待实现
  }
}
