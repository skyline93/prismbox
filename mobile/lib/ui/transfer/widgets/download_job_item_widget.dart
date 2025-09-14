// lib/ui/transfer/widgets/download_job_item_widget.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/providers/transfer_providers.dart';
import 'package:path/path.dart' as p;
import 'package:mobile/services/transfer/transfer_manager.dart';

class DownloadJobItemWidget extends ConsumerWidget {
  final DownloadJob job;

  const DownloadJobItemWidget({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transferManager = ref.read(transferManagerProvider);
    final theme = Theme.of(context);
    final fileName = p.basename(job.savePath); // 从完整路径中提取文件名

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusText(job.status),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildActionButton(transferManager),
              ],
            ),
            if (job.status == DownloadJobStatus.downloading) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: job.progress,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
            if (job.status == DownloadJobStatus.failed) ...[
              const SizedBox(height: 8),
              Text(
                '下载失败，请重试。',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ThemeData theme) {
    switch (job.status) {
      case DownloadJobStatus.pending:
        return const Icon(Icons.hourglass_top_rounded);
      case DownloadJobStatus.downloading:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(value: job.progress, strokeWidth: 3),
        );
      case DownloadJobStatus.paused:
        return const Icon(Icons.pause, color: Colors.orange);
      case DownloadJobStatus.success:
        return Icon(Icons.check_circle, color: Colors.green.shade600);
      case DownloadJobStatus.failed:
        return Icon(Icons.error_rounded, color: theme.colorScheme.error);
      case DownloadJobStatus.canceled:
        return const Icon(Icons.cancel, color: Colors.grey);
      case DownloadJobStatus.running:
        return const Icon(Icons.pause, color: Colors.orange);
    }
  }

  String _getStatusText(DownloadJobStatus status) {
    switch (status) {
      case DownloadJobStatus.pending:
        return '等待中...';
      case DownloadJobStatus.downloading:
        return '正在下载... ${(job.progress * 100).toStringAsFixed(0)}%';
      case DownloadJobStatus.paused:
        return '已暂停';
      case DownloadJobStatus.success:
        return '下载成功';
      case DownloadJobStatus.failed:
        return '下载失败';
      case DownloadJobStatus.canceled:
        return '已取消';
      case DownloadJobStatus.running:
        return "运行中...";
    }
  }

  Widget _buildActionButton(TransferManager service) {
    switch (job.status) {
      case DownloadJobStatus.downloading:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: () => service.downloadService.pauseDownload(job.jobId),
            ),
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () =>
                  service.downloadService.cancelDownload(job.jobId),
            ),
          ],
        );
      case DownloadJobStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () =>
                  service.downloadService.resumeDownload(job.jobId),
            ),
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () =>
                  service.downloadService.cancelDownload(job.jobId),
            ),
          ],
        );
      // 可选：为失败/取消的任务添加重试按钮
      case DownloadJobStatus.failed:
      case DownloadJobStatus.canceled:
        return IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            /* TODO: 实现重试逻辑 */
          },
        );
      default:
        return const SizedBox.shrink(); // 其他状态不显示按钮
    }
  }
}
