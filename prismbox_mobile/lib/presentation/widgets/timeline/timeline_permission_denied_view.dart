import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/providers/permission/photo_permission_provider.dart';

/// 时间线权限被拒绝视图
///
/// 显示相册权限被拒绝时的 UI，包含提示信息和授权按钮
class TimelinePermissionDeniedView extends ConsumerWidget {
  /// 权限状态
  final PhotoPermissionState permissionState;

  const TimelinePermissionDeniedView({
    super.key,
    required this.permissionState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPermanentlyDenied =
        permissionState is PhotoPermissionPermanentlyDenied;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              '需要相册权限',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              isPermanentlyDenied
                  ? '相册权限已被拒绝。请在系统设置中授予相册访问权限。'
                  : '需要相册权限才能查看您的照片。请授予相册访问权限。',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final permissionNotifier = ref.read(
                  photoPermissionNotifierProvider.notifier,
                );
                await permissionNotifier.requestPermission();
              },
              icon: const Icon(Icons.lock_open),
              label: const Text('授予权限'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
