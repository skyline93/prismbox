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

import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

@RoutePage()
class NavigationPage extends HookConsumerWidget {
  const NavigationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        // [关键改动] 添加此行以强制标题在所有平台上都靠左对齐
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
