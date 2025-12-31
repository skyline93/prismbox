import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/features/local_sync/providers/timeline_provider.dart';

/// 时间线错误视图
///
/// 显示加载错误时的 UI，包含错误图标、错误信息和重试按钮
class TimelineErrorView extends ConsumerWidget {
  /// 错误消息
  final String errorMessage;

  /// 标题（默认为"加载失败"）
  final String? title;

  const TimelineErrorView({super.key, required this.errorMessage, this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            title ?? '加载失败',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.red),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              errorMessage,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(timelineSectionsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
