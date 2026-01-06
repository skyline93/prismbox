// lib/presentation/widgets/backup/upload_task_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/data/database/enums/upload_task_type.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart';
import 'package:prismbox/services/backup/backup_query_builder.dart';
import 'package:prismbox/services/backup/upload_service.dart';

/// 上传任务列表组件
/// 支持虚拟滚动，显示任务详情和操作
class UploadTaskList extends ConsumerStatefulWidget {
  final String userId;
  final UploadService uploadService;
  final UploadTaskStatus? filterStatus;
  final UploadTaskType? filterTaskType;

  const UploadTaskList({
    super.key,
    required this.userId,
    required this.uploadService,
    this.filterStatus,
    this.filterTaskType,
  });

  @override
  ConsumerState<UploadTaskList> createState() => _UploadTaskListState();
}

class _UploadTaskListState extends ConsumerState<UploadTaskList> {
  @override
  Widget build(BuildContext context) {
    // 获取数据库实例
    final databaseFuture = ref.watch(databaseProvider.future);

    return FutureBuilder<AppDatabase>(
      future: databaseFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final database = snapshot.data!;
        final queryBuilder = BackupQueryBuilder(database)
            .withUserId(widget.userId);

        final query = queryBuilder.buildTaskQuery(
          status: widget.filterStatus,
          taskType: widget.filterTaskType,
        );

        return StreamBuilder<List<UploadTaskEntityData>>(
          stream: query.watch(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final tasks = snapshot.data!;

            if (tasks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_done,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无任务',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _UploadTaskItem(
                  task: task,
                  uploadService: widget.uploadService,
                  onRetry: () => _retryTask(task),
                  onCancel: () => _cancelTask(task),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _retryTask(UploadTaskEntityData task) async {
    try {
      await widget.uploadService.retryTask(
        userId: widget.userId,
        taskId: task.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('任务已重新加入队列')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('重试失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelTask(UploadTaskEntityData task) async {
    try {
      await widget.uploadService.cancelUpload(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('任务已取消')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('取消失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _UploadTaskItem extends StatelessWidget {
  final UploadTaskEntityData task;
  final UploadService uploadService;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const _UploadTaskItem({
    required this.task,
    required this.uploadService,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: _buildStatusIcon(),
        title: Text(
          task.assetId,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('状态: ${_getStatusText(task.status)}'),
            if (task.status == UploadTaskStatus.uploading)
              LinearProgressIndicator(
                value: task.progress / 100.0,
              ),
            if (task.errorMessage != null)
              Text(
                '错误: ${task.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            Text(
              '创建时间: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(task.createdAt)}',
            ),
          ],
        ),
        trailing: _buildActionButtons(context),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (task.status) {
      case UploadTaskStatus.pending:
        icon = Icons.pending;
        color = Colors.orange;
        break;
      case UploadTaskStatus.queued:
        icon = Icons.queue;
        color = Colors.blue;
        break;
      case UploadTaskStatus.uploading:
        icon = Icons.cloud_upload;
        color = Colors.blue;
        break;
      case UploadTaskStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case UploadTaskStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
      case UploadTaskStatus.permanentlyFailed:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case UploadTaskStatus.cancelled:
        icon = Icons.cancel_outlined;
        color = Colors.grey;
        break;
      case UploadTaskStatus.paused:
        icon = Icons.pause;
        color = Colors.orange;
        break;
    }

    return Icon(icon, color: color);
  }

  String _getStatusText(UploadTaskStatus status) {
    switch (status) {
      case UploadTaskStatus.pending:
        return '待上传';
      case UploadTaskStatus.queued:
        return '已入队';
      case UploadTaskStatus.uploading:
        return '上传中';
      case UploadTaskStatus.completed:
        return '已完成';
      case UploadTaskStatus.failed:
        return '失败';
      case UploadTaskStatus.permanentlyFailed:
        return '永久失败';
      case UploadTaskStatus.cancelled:
        return '已取消';
      case UploadTaskStatus.paused:
        return '已暂停';
    }
  }

  Widget? _buildActionButtons(BuildContext context) {
    switch (task.status) {
      case UploadTaskStatus.failed:
      case UploadTaskStatus.permanentlyFailed:
        return IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: '重试',
          onPressed: onRetry,
        );
      case UploadTaskStatus.pending:
      case UploadTaskStatus.uploading:
        return IconButton(
          icon: const Icon(Icons.cancel),
          tooltip: '取消',
          onPressed: onCancel,
        );
      default:
        return null;
    }
  }
}

