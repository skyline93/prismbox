import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/presentation/widgets/backup/backup_status_indicator.dart';
import 'package:prismbox/presentation/widgets/timeline/timeline_filter_button.dart';
import 'package:prismbox/presentation/widgets/user/user_profile_indicator.dart';

/// 时间线正常模式 AppBar
///
/// 显示正常模式下的 SliverAppBar，包含标题、筛选按钮、备份状态指示器和用户头像指示器
class TimelineNormalAppBar extends ConsumerWidget {
  const TimelineNormalAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      floating: true,
      pinned: true, // 与选择模式保持一致，避免布局变化导致滚动位置变动
      snap: false,
      title: Row(
        children: [
          const Text('照片'),
          const SizedBox(width: 12),
          // 筛选模式按钮（放在标题右侧）
          const TimelineFilterButton(),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: BackupStatusIndicator(),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: UserProfileIndicator(),
        ),
      ],
    );
  }
}
