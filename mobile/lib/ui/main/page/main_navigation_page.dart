// lib/ui/main/page/main_navigation_page.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobile/providers/providers.dart';
import 'package:mobile/ui/media/pages/media_page.dart';
import 'package:mobile/ui/album/page/album_page.dart';
import 'package:mobile/ui/group/pages/group_list_page.dart';
import 'package:mobile/ui/main/widgets/user_profile_dialog.dart';
import 'package:mobile/providers/user_profile_provider.dart';
import 'package:mobile/services/app_init_service.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

@RoutePage()
class NavigationPage extends HookConsumerWidget {
  const NavigationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用 useEffect 来执行一次性初始化
    useEffect(() {
      // 在下一帧执行，以确保页面已经准备好
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 调用初始化服务
        AppInitService().initializeAppServices();
      });

      // 返回 null 表示没有清理工作需要执行
      return null;
    }, const []); // 空数组作为 keys，确保这个 effect 只运行一次

    final currentIndex = useState(0);

    final isSelecting = ref.watch(
      selectionProvider.select((s) => s.isSelecting),
    );

    final userProfile = ref.watch(userProvider);
    final avatarUrl = userProfile.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    final pages = [const MediaPage(), const AlbumPage(), const GroupListPage()];

    const pageTitles = ['照片', '相册', '圈子'];

    void showUserProfileDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return const UserProfileDialog();
        },
      );
    }

    final iconList = <IconData>[
      Icons.photo_library_outlined,
      Icons.photo_album_outlined,
      Icons.people_outline,
    ];

    final selectedIconList = <IconData>[
      Icons.photo_library,
      Icons.photo_album,
      Icons.people,
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        centerTitle: false,
        title: Text(
          pageTitles[currentIndex.value],
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: showUserProfileDialog,
              child: CircleAvatar(
                radius: 20,
                backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                backgroundColor: Colors.grey.shade200,
                child: !hasAvatar
                    ? Icon(Icons.person, size: 20, color: Colors.grey.shade400)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: IndexedStack(index: currentIndex.value, children: pages),
      ),
      bottomNavigationBar: isSelecting
          ? null
          : AnimatedBottomNavigationBar.builder(
              height: 80,
              itemCount: iconList.length,
              tabBuilder: (int index, bool isActive) {
                return Icon(
                  isActive ? selectedIconList[index] : iconList[index],
                  size: 28,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                );
              },
              activeIndex: currentIndex.value,
              onTap: (index) {
                currentIndex.value = index;
              },
              gapLocation: GapLocation.none,
              notchSmoothness: NotchSmoothness.softEdge,
              leftCornerRadius: 0,
              rightCornerRadius: 0,
              backgroundColor: Theme.of(context).colorScheme.surface,
              shadow: BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, -2),
              ),
            ),
    );
  }
}
