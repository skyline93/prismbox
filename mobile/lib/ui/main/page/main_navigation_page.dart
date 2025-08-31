// lib/ui/main/page/main_navigation_page.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobile/providers/providers.dart';
import 'package:mobile/ui/media/pages/media_page.dart';
import 'package:mobile/ui/album/page/album_page.dart';
import 'package:mobile/ui/library/page/library_page.dart';
import 'package:mobile/ui/group/pages/group_list_page.dart';

@RoutePage()
class NavigationPage extends HookConsumerWidget {
  const NavigationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = useState(0);

    // 2. 监听全局选择状态
    // 我们使用 .select 来只监听 isSelecting 布尔值的变化，这样更高效
    final isSelecting = ref.watch(
      selectionProvider.select((s) => s.isSelecting),
    );

    final pages = [
      const MediaPage(),
      const AlbumPage(),
      const GroupListPage(),
      const LibraryPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex.value, children: pages),
      // 3. 根据 isSelecting 的值来决定是否显示底部导航栏
      bottomNavigationBar: isSelecting
          ? null // 如果在选择模式下，不构建底部栏 (null)
          : NavigationBar(
              backgroundColor:
                  Theme.of(context).bottomAppBarTheme.color ??
                  Theme.of(context).colorScheme.surface,
              selectedIndex: currentIndex.value,
              onDestinationSelected: (index) => currentIndex.value = index,
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.photo_library),
                  label: '照片',
                ),
                NavigationDestination(
                  icon: Icon(Icons.photo_album),
                  label: '相册',
                ),
                NavigationDestination(icon: Icon(Icons.people), label: '圈子'),
                NavigationDestination(icon: Icon(Icons.person), label: '我的'),
              ],
            ),
    );
  }
}
