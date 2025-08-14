import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers.dart';

class MediaAppBar extends HookConsumerWidget implements PreferredSizeWidget {
  const MediaAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSyncing = ref.watch(
      mediaViewModelProvider.select((s) => s.isSyncingWithCloud),
    );
    final viewMode = ref.watch(mediaViewTypeProvider);

    return AppBar(
      title: const Text('所有照片'),
      actions: [
        if (isSyncing)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),

        // 2. 视图切换按钮
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
