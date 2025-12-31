import 'package:flutter/material.dart';

/// 时间线空状态视图
///
/// 显示无照片时的空状态 UI
class TimelineEmptyStateView extends StatelessWidget {
  const TimelineEmptyStateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无照片',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
