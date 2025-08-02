import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobile/ui/media/page/media_page.dart';
import 'package:mobile/ui/album/page/album_page.dart';
import 'package:mobile/ui/library/page/library_page.dart';

@RoutePage()
class NavigationPage extends HookConsumerWidget {
  const NavigationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
