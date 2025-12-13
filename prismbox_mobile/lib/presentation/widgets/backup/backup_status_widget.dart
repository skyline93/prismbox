// lib/presentation/widgets/backup/backup_status_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prismbox/providers/services/auth_service_provider.dart';
import 'package:prismbox/services/backup/providers/backup_providers.dart';
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

class _BackupStatusContent extends ConsumerWidget {
  final String userId;

  const _BackupStatusContent({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupServiceFuture = ref.watch(backupServiceProvider.future);
    final uploadServiceFuture = ref.watch(uploadServiceProvider.future);

    return FutureBuilder<BackupService>(
      future: backupServiceFuture,
      builder: (context, backupSnapshot) {
        if (!backupSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<UploadService>(
          future: uploadServiceFuture,
          builder: (context, uploadSnapshot) {
            if (!uploadSnapshot.hasData) {
              return const SizedBox.shrink();
            }

            return FutureBuilder<UploadQueueStatus>(
              future: uploadSnapshot.data!.getQueueStatusAsync(userId),
              builder: (context, queueSnapshot) {
                return _BackupStatusInfo(
                  userId: userId,
                  backupService: backupSnapshot.data!,
                  queueStatus: queueSnapshot.data,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _BackupStatusInfo extends ConsumerStatefulWidget {
  final String userId;
  final BackupService backupService;
  final UploadQueueStatus? queueStatus;

  const _BackupStatusInfo({
    required this.userId,
    required this.backupService,
    required this.queueStatus,
  });

  @override
  ConsumerState<_BackupStatusInfo> createState() =>
      _BackupStatusInfoState();
}

class _BackupStatusInfoState extends ConsumerState<_BackupStatusInfo> {
  BackupStatus? _backupStatus;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await widget.backupService.getBackupStatus(widget.userId);
    if (mounted) {
      setState(() {
        _backupStatus = status;
      });
    }
  }

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
            if (_backupStatus != null) ...[
              _StatusRow(
                label: '自动备份',
                value: _backupStatus!.enabled ? '已启用' : '已禁用',
                valueColor: _backupStatus!.enabled
                    ? Colors.green
                    : Colors.grey,
              ),
              if (_backupStatus!.lastBackupTime != null) ...[
                const SizedBox(height: 8),
                _StatusRow(
                  label: '最后备份时间',
                  value: DateFormat('yyyy-MM-dd HH:mm:ss')
                      .format(_backupStatus!.lastBackupTime!),
                ),
              ],
            ],
            if (widget.queueStatus != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _StatusRow(
                label: '总任务数',
                value: '${widget.queueStatus!.totalCount}',
              ),
              const SizedBox(height: 8),
              _StatusRow(
                label: '待上传',
                value: '${widget.queueStatus!.pendingCount}',
                valueColor: Colors.orange,
              ),
              const SizedBox(height: 8),
              _StatusRow(
                label: '上传中',
                value: '${widget.queueStatus!.uploadingCount}',
                valueColor: Colors.blue,
              ),
              const SizedBox(height: 8),
              _StatusRow(
                label: '已完成',
                value: '${widget.queueStatus!.completedCount}',
                valueColor: Colors.green,
              ),
              const SizedBox(height: 8),
              _StatusRow(
                label: '失败',
                value: '${widget.queueStatus!.failedCount}',
                valueColor: Colors.red,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatusRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

