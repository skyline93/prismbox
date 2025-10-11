// lib/ui/transfer/widgets/upload_job_item_widget.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:path/path.dart' as p;

class UploadJobItemWidget extends ConsumerWidget {
  final UploadJob job;

  const UploadJobItemWidget({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final icon = _getIconForStatus(job.status, theme);
    final fileName = p.basename(job.filePath);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusText(job.status),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (job.status == UploadJobStatus.uploading ||
                      job.status == UploadJobStatus.completing) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: job.progress,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ],
                ],
              ),
            ),
            // TODO: Add action buttons (retry, cancel) in the future
          ],
        ),
      ),
    );
  }

  Widget _getIconForStatus(UploadJobStatus status, ThemeData theme) {
    switch (status) {
      case UploadJobStatus.pending:
      case UploadJobStatus.initiating:
        return const Icon(Icons.hourglass_top_rounded);
      case UploadJobStatus.uploading:
      case UploadJobStatus.waitingForWifi:
      case UploadJobStatus.completing:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(value: job.progress, strokeWidth: 3),
        );
      case UploadJobStatus.success:
        return Icon(Icons.check_circle_rounded, color: Colors.green.shade600);
      case UploadJobStatus.failed:
        return Icon(Icons.error_rounded, color: theme.colorScheme.error);
    }
  }

  String _getStatusText(UploadJobStatus status) {
    switch (status) {
      case UploadJobStatus.pending:
        return '等待中...';
      case UploadJobStatus.initiating:
        return '正在初始化...';
      case UploadJobStatus.uploading:
        return '正在上传... ${(job.progress * 100).toStringAsFixed(0)}%';
      case UploadJobStatus.completing:
        return '正在合并文件...';
      case UploadJobStatus.success:
        return '上传成功';
      case UploadJobStatus.failed:
        return '上传失败';
      case UploadJobStatus.waitingForWifi:
        return "等待连接wifi后上传";
    }
  }
}
