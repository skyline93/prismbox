// lib/widgets/transfer_status_panel.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;
import '../providers/providers.dart';
import '../../state/transfer_state.dart';

class TransferStatusPanel extends ConsumerWidget {
  const TransferStatusPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transferState = ref.watch(transferStateProvider);
    final uploads = transferState.uploads;
    final downloads = transferState.downloads;

    if (uploads.isEmpty && downloads.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (uploads.isNotEmpty) ...[
              Text('上传中...', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...uploads.map(
                (taskProgress) => _buildProgressIndicator(taskProgress),
              ),
            ],
            if (downloads.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('下载中...', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...downloads.map(
                (taskProgress) => _buildProgressIndicator(taskProgress),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(TaskProgress taskProgress) {
    final filename = p.basename(taskProgress.task.filename);
    final progress = taskProgress.progress;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(filename, overflow: TextOverflow.ellipsis, maxLines: 1),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }
}
