// lib/presentation/widgets/backup/backup_status_widget.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/providers/services/auth_service_provider.dart';
import 'package:prismbox/services/backup/providers/backup_state_provider.dart';
import 'package:prismbox/services/backup/backup_service.dart';
import 'package:prismbox/services/backup/upload_service.dart';

/// 备份状态组件
/// 显示备份状态、进度和统计信息
class BackupStatusWidget extends ConsumerWidget {
  const BackupStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authServiceAsync = ref.watch(authServiceProvider);

    return authServiceAsync.when(
      data: (authService) => FutureBuilder<String>(
        future: authService.getProfile().then((p) => p.id.toString()),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }
          return _BackupStatusContent(userId: snapshot.data!);
        },
      ),
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class _BackupStatusContent extends ConsumerStatefulWidget {
  final String userId;

  const _BackupStatusContent({required this.userId});

  @override
  ConsumerState<_BackupStatusContent> createState() => _BackupStatusContentState();
}

class _BackupStatusContentState extends ConsumerState<_BackupStatusContent> {
  @override
  void initState() {
    super.initState();
    // 开始监听备份状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 不等待异步操作完成，让它在后台执行
      ref.read(backupStateProvider.notifier).startListening(widget.userId);
    });
  }

  @override
  void dispose() {
    // 停止监听
    ref.read(backupStateProvider.notifier).stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backupState = ref.watch(backupStateProvider);

    if (backupState.isLoading && backupState.counts == null) {
      return const Card(
        margin: EdgeInsets.all(16.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return _BackupStatusInfo(
      userId: widget.userId,
      backupState: backupState,
    );
  }
}

class _BackupStatusInfo extends StatelessWidget {
  final String userId;
  final BackupState backupState;

  const _BackupStatusInfo({
    required this.userId,
    required this.backupState,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '备份状态',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // 统计信息卡片
            if (backupState.counts != null) ...[
              _BackupCountsSection(counts: backupState.counts!),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ],
            
            // 当前上传信息（包括 pending 和 uploading 状态）
            if (backupState.activeTasks.isNotEmpty) ...[
              _CurrentUploadSection(
                task: backupState.activeTasks.first,
                totalTasks: backupState.activeTasks.length,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ] else if (backupState.isBackingUp) ...[
              // 显示备份进行中的提示
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '正在准备上传...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ],
            
            // 错误信息
            if (backupState.hasError) ...[
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        backupState.errorMessage ?? '发生错误',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 备份统计信息部分
class _BackupCountsSection extends StatelessWidget {
  final BackupCounts counts;

  const _BackupCountsSection({required this.counts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '统计信息',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CountCard(
                label: '总数量',
                value: counts.total,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CountCard(
                label: '已备份',
                value: counts.backupCount,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _CountCard(
                label: '剩余',
                value: counts.remainder,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CountCard(
                label: '处理中',
                value: counts.processing,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 进度条
        LinearProgressIndicator(
          value: counts.progress,
          minHeight: 8.0,
        ),
        const SizedBox(height: 4),
        Text(
          '${(counts.progress * 100).toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// 统计卡片
class _CountCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _CountCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

/// 当前上传信息部分
class _CurrentUploadSection extends StatelessWidget {
  final UploadTaskDetail task;
  final int totalTasks;

  const _CurrentUploadSection({
    required this.task,
    this.totalTasks = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '当前上传',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (totalTasks > 1)
              TextButton(
                onPressed: () {
                  context.router.push(const UploadDetailRoute());
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('查看全部 ($totalTasks)'),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, size: 12),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            context.router.push(const UploadDetailRoute());
          },
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.filename,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: task.progress,
                  minHeight: 6.0,
                ),
                const SizedBox(height: 4),
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
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


