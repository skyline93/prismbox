// lib/ui/main/page/main_navigation_page.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobile/core/service_locator.dart';
import 'package:mobile/services/local_media_observer.dart';
import 'package:mobile/ui/media/pages/media_page.dart';
import 'package:mobile/ui/album/page/album_page.dart';
import 'package:mobile/ui/library/page/library_page.dart';

@RoutePage()
class NavigationPage extends HookConsumerWidget {
  const NavigationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // NEW: 使用 useEffect 来模拟 initState 的行为
    useEffect(() {
      // 在这里获取 LocalMediaObserver 实例并启动监听
      final observer = getIt<LocalMediaObserver>();
      observer.startObserving();

      // useEffect 可以返回一个清理函数，在组件销毁时调用。
      // 在这个场景下，我们通常希望监听在整个 App 生命周期内都保持运行，
      // 但如果你希望在用户退出登录或离开这个页面时停止监听，可以这样做：
      // return () {
      //   observer.stopObserving();
      // };

      // 如果我们只想让它运行一次，并且不需要清理，返回 null 即可。
      return null;
    }, const []); // 传入一个空的依赖数组 `[]` 意味着这个 effect 只会在组件首次构建时运行一次。

    final currentIndex = useState(0);

    final pages = [const MediaPage(), const AlbumPage(), const LibraryPage()];

    return Scaffold(
      body: IndexedStack(index: currentIndex.value, children: pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor:
            Theme.of(context).bottomAppBarTheme.color ??
            Theme.of(context).colorScheme.surface,
        selectedIndex: currentIndex.value,
        onDestinationSelected: (index) => currentIndex.value = index,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.photo_library), label: '照片'),
          NavigationDestination(icon: Icon(Icons.photo_album), label: '相册'),
          NavigationDestination(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
