import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/providers/selection/asset_selection_provider.dart';
import 'package:prismbox/providers/services/auth_service_provider.dart';
import 'package:prismbox/services/backup/providers/backup_providers.dart';

/// 时间线上传处理器
///
/// 负责处理上传业务逻辑，包括：
/// - 获取用户信息
/// - 启动备份服务
/// - 显示成功/错误提示
class TimelineUploadHandler {
  final BuildContext context;
  final WidgetRef ref;
  final bool Function() mounted;

  TimelineUploadHandler({
    required this.context,
    required this.ref,
    required this.mounted,
  });

  /// 处理上传
  Future<void> handleUpload() async {
    final selectedIds = ref.read(
      assetSelectionProvider.select((s) => s.selectedIds),
    );
    if (selectedIds.isEmpty) return;

    try {
      // 获取用户ID
      final authService = await ref.read(authServiceProvider.future);
      final profile = await authService.getProfile();
      final userId = profile.id.toString();

      // 获取备份服务
      final backupService = await ref.read(backupServiceProvider.future);

      // 启动上传
      await backupService.startManualBackup(
        userId: userId,
        assetIds: selectedIds.toList(),
        skipDeduplication: false,
      );

      // 显示成功提示
      if (mounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已开始上传 ${selectedIds.length} 张照片'),
            duration: const Duration(seconds: 2),
          ),
        );

        // 退出选择模式
        ref.read(assetSelectionProvider.notifier).deactivate();
      }
    } catch (e) {
      // 显示错误提示
      if (mounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('上传失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

