// lib/ui/media/widgets/media_bar_top.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers.dart';
// [-] isSyncingWithCloudProvider 已被删除，不再需要导入
// import 'package:mobile/ui/media/viewmodels/media_viewmodel.dart';

class MediaAppBar extends HookConsumerWidget implements PreferredSizeWidget {
  const MediaAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // [-] 删除此行，isSyncing 状态已不存在
    // final isSyncing = ref.watch(isSyncingWithCloudProvider);
    final viewMode = ref.watch(mediaViewTypeProvider);

    return AppBar(
      title: const Text('所有照片'),
      actions: [
        // [-] 删除整个 if 条件块，不再显示全局加载指示器
        // if (isSyncing)
        //   const Padding(
        //     padding: EdgeInsets.symmetric(horizontal: 16.0),
        //     child: Center(
        //       child: SizedBox(
        //         width: 20,
        //         height: 20,
        //         child: CircularProgressIndicator(
        //           strokeWidth: 2.5,
        //           color: Colors.white,
        //         ),
        //       ),
        //     ),
        //   ),

        // 视图切换按钮保持不变
        IconButton(
          icon: Icon(
            viewMode == MediaViewType.grid
                ? Icons.view_timeline_outlined
                : Icons.grid_view_outlined,
          ),
          onPressed: () {
            final notifier = ref.read(mediaViewTypeProvider.notifier);
            notifier.state = viewMode == MediaViewType.grid
                ? MediaViewType.timeline
                : MediaViewType.grid;
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
