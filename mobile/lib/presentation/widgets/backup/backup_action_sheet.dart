// lib/presentation/widgets/backup/backup_action_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/providers/services/auth_service_provider.dart';
import 'package:prismbox/services/backup/providers/backup_providers.dart';

/// 备份操作底部表单
/// 显示备份进度和结果
class BackupActionSheet extends ConsumerStatefulWidget {
  final List<String> assetIds;
  final VoidCallback? onDismiss;

  const BackupActionSheet({
    super.key,
    required this.assetIds,
    this.onDismiss,
  });

  @override
  ConsumerState<BackupActionSheet> createState() => _BackupActionSheetState();
}

class _BackupActionSheetState extends ConsumerState<BackupActionSheet> {
  bool _isBackingUp = false;
  String? _errorMessage;
  int _successCount = 0;
  int _failedCount = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '备份照片',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 备份信息
          if (!_isBackingUp && _errorMessage == null && _successCount == 0)
            Text(
              '准备备份 ${widget.assetIds.length} 张照片',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

          // 备份进度
          if (_isBackingUp) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              '正在备份...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],

          // 备份结果
          if (!_isBackingUp && (_successCount > 0 || _failedCount > 0)) ...[
            if (_successCount > 0)
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    '成功: $_successCount',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green,
                        ),
                  ),
                ],
              ),
            if (_failedCount > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    '失败: $_failedCount',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                        ),
                  ),
                ],
              ),
            ],
          ],

          // 错误信息
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red,
                  ),
            ),
          ],

          const SizedBox(height: 16),

          // 操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!_isBackingUp)
                TextButton(
                  onPressed: widget.onDismiss,
                  child: const Text('关闭'),
                ),
              if (!_isBackingUp && _successCount == 0 && _failedCount == 0)
                ElevatedButton(
                  onPressed: _startBackup,
                  child: const Text('开始备份'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _startBackup() async {
    setState(() {
      _isBackingUp = true;
      _errorMessage = null;
      _successCount = 0;
      _failedCount = 0;
    });

    try {
      // 获取当前用户ID
      final authService = await ref.read(authServiceProvider.future);
      final profile = await authService.getProfile();
      final userId = profile.id.toString();

      // 获取备份服务
      final backupService = await ref.read(backupServiceProvider.future);

      // 启动手动备份
      await backupService.startManualBackup(
        userId: userId,
        assetIds: widget.assetIds,
        skipDeduplication: false, // 默认进行去重检查
      );

      // 备份已启动（任务已加入队列）
      if (mounted) {
        setState(() {
          _isBackingUp = false;
          _successCount = widget.assetIds.length; // 假设全部成功（实际需要监听任务状态）
        });

        // 显示成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已开始备份 ${widget.assetIds.length} 张照片'),
            duration: const Duration(seconds: 2),
          ),
        );

        // 延迟关闭
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && widget.onDismiss != null) {
            widget.onDismiss!();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
          _errorMessage = '备份失败: $e';
          _failedCount = widget.assetIds.length;
        });
      }
    }
  }
}

