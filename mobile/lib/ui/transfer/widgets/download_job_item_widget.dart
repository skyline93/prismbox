// lib/ui/transfer/widgets/download_job_item_widget.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/providers/transfer_providers.dart';
import 'package:path/path.dart' as p;
import 'package:mobile/services/transfer_service.dart';

class DownloadJobItemWidget extends ConsumerWidget {
  final DownloadJob job;

  const DownloadJobItemWidget({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transferService = ref.read(transferServiceProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    p.basename(job.savePath), // 从完整路径中提取文件名
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildActionButton(transferService),
              ],
            ),
            const SizedBox(height: 8),
            if (job.status == DownloadJobStatus.downloading ||
                job.status == DownloadJobStatus.paused)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: job.progress,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getStatusText(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${(job.progress * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            if (job.status == DownloadJobStatus.failed)
              Text(
                'Download failed. Please try again.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (job.status) {
      case DownloadJobStatus.downloading:
        return const Icon(Icons.downloading, color: Colors.blue);
      case DownloadJobStatus.paused:
        return const Icon(Icons.pause, color: Colors.orange);
      case DownloadJobStatus.success:
        return const Icon(Icons.check_circle, color: Colors.green);
      case DownloadJobStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
      case DownloadJobStatus.canceled:
        return const Icon(Icons.cancel, color: Colors.grey);
      default:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
    }
  }

  String _getStatusText() {
    // 将枚举值转换为更友好的字符串
    return job.status.name[0].toUpperCase() + job.status.name.substring(1);
  }

  Widget _buildActionButton(TransferService service) {
    switch (job.status) {
      case DownloadJobStatus.downloading:
        return Row(
          children: [
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: () => service.pauseDownload(job.jobId),
            ),
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () => service.cancelDownload(job.jobId),
            ),
          ],
        );
      case DownloadJobStatus.paused:
        return Row(
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => service.resumeDownload(job.jobId),
            ),
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () => service.cancelDownload(job.jobId),
            ),
          ],
        );
      // 可选：为失败/取消的任务添加重试按钮
      // case DownloadJobStatus.failed:
      // case DownloadJobStatus.canceled:
      //   return IconButton(
      //     icon: const Icon(Icons.refresh),
      //     onPressed: () { /* 实现重试逻辑 */ },
      //   );
      default:
        return const SizedBox.shrink(); // 其他状态不显示按钮
    }
  }
}
