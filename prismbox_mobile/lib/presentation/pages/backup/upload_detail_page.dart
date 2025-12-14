// lib/presentation/pages/backup/upload_detail_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/providers/services/auth_service_provider.dart';
import 'package:prismbox/services/backup/providers/backup_providers.dart';
import 'package:prismbox/services/backup/providers/backup_state_provider.dart';
import 'package:prismbox/services/backup/upload_service.dart';

/// 上传详情页面
/// 显示所有正在上传的任务列表，包括进度、速度等信息
@RoutePage()
class UploadDetailPage extends ConsumerStatefulWidget {
  const UploadDetailPage({super.key});

  @override
  ConsumerState<UploadDetailPage> createState() => _UploadDetailPageState();
}

class _UploadDetailPageState extends ConsumerState<UploadDetailPage> {
  @override
  Widget build(BuildContext context) {
    final authServiceAsync = ref.watch(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('上传详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.router.maybePop(),
        ),
      ),
      body: authServiceAsync.when(
        data: (authService) => FutureBuilder<String>(
          future: authService.getProfile().then((p) => p.id.toString()),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            // 使用 family provider，自动管理生命周期
            return _UploadDetailContent(userId: snapshot.data!);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('加载失败: $error'),
        ),
      ),
    );
  }
}

class _UploadDetailContent extends ConsumerWidget {
  final String userId;

  const _UploadDetailContent({
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用 family provider，自动管理生命周期
    final backupState = ref.watch(backupStateProvider(userId));
    final activeTasks = backupState.activeTasks;

    if (backupState.isLoading && activeTasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (activeTasks.isEmpty) {
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
              '暂无上传任务',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '所有文件已备份完成',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(backupStateProvider(userId).notifier).refresh(userId);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: activeTasks.length,
        itemBuilder: (context, index) {
          final task = activeTasks[index];
          return _UploadTaskCard(
            task: task,
            uploadService: ref.watch(uploadServiceProvider).value,
            userId: userId,
          );
        },
      ),
    );
  }
}

class _UploadTaskCard extends StatelessWidget {
  final UploadTaskDetail task;
  final UploadService? uploadService;
  final String userId;

  const _UploadTaskCard({
    required this.task,
    this.uploadService,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 文件名和状态
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.filename,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusIcon(context),
              ],
            ),
            const SizedBox(height: 12),
            // 进度条
            if (task.status == UploadTaskStatus.uploading ||
                task.status == UploadTaskStatus.pending)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: task.progress,
                    minHeight: 8.0,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(task.progress * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (task.networkSpeed != null)
                        Text(
                          task.networkSpeed!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.blue,
                              ),
                        ),
                    ],
                  ),
                ],
              ),
            // 文件大小
            if (task.fileSize > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _formatFileSize(task.fileSize),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ),
            // 错误信息
            if (task.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // 操作按钮
            if (task.status == UploadTaskStatus.failed ||
                task.status == UploadTaskStatus.permanentlyFailed)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: uploadService != null
                          ? () => _retryTask(context, uploadService!, userId, task.taskId)
                          : null,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    IconData icon;
    Color color;

    switch (task.status) {
      case UploadTaskStatus.pending:
        icon = Icons.pending;
        color = Colors.orange;
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

    return Icon(icon, color: color, size: 20);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  Future<void> _retryTask(
    BuildContext context,
    UploadService uploadService,
    String userId,
    String taskId,
  ) async {
    try {
      await uploadService.retryTask(userId: userId, taskId: taskId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('任务已重新加入队列')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('重试失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

