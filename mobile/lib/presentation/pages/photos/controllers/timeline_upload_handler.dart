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

  /// 处理上传（使用选择模式下的已选 ID）
  Future<void> handleUpload() async {
    final selectedIds = ref.read(
      assetSelectionProvider.select((s) => s.selectedIds),
    );
    if (selectedIds.isEmpty) return;
    await handleUploadWithAssetIds(selectedIds.toList());
    // 退出选择模式
    ref.read(assetSelectionProvider.notifier).deactivate();
  }

  /// 上传指定资产 ID 列表（与选择模式共用同一上传逻辑，可用于预览页单张上传等）
  Future<void> handleUploadWithAssetIds(List<String> assetIds) async {
    if (assetIds.isEmpty) return;

    try {
      final authService = await ref.read(authServiceProvider.future);
      final profile = await authService.getProfile();
      final userId = profile.id.toString();

      final backupService = await ref.read(backupServiceProvider.future);

      await backupService.startManualBackup(
        userId: userId,
        assetIds: assetIds,
        skipDeduplication: false,
      );

      if (mounted()) {
        final count = assetIds.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count == 1 ? '已开始上传' : '已开始上传 $count 张照片'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
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

