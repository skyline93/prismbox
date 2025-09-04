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

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('搜索页面', style: TextStyle(fontSize: 24)));
  }
}

@RoutePage()
class NavigationPage extends HookConsumerWidget {
  const NavigationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = useState(0);

    final isSelecting = ref.watch(
      selectionProvider.select((s) => s.isSelecting),
    );

    final userProfile = ref.watch(userProfileProvider);
    final avatarUrl = userProfile.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    // [改动 1/3] 调整页面列表以匹配新的导航项
    final pages = [
      const MediaPage(), // 对应 "照片"
      const SearchPage(), // 对应 "搜索"
      const AlbumPage(), // 对应 "相册"
      const GroupListPage(), // 对应 "圈子"
    ];

    // [改动 2/3] 调整标题列表
    const pageTitles = ['照片', '搜索', '相册', '圈子'];

    void showUserProfileDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return const UserProfileDialog();
        },
      );
    }

    // [改动 3/3] 调整图标列表
    final iconList = <IconData>[
      Icons.photo_library_outlined, // 照片
      Icons.search, // 搜索 (搜索图标通常不区分 outlined/filled)
      Icons.photo_album_outlined, // 相册
      Icons.people_outline, // 圈子
    ];

    final selectedIconList = <IconData>[
      Icons.photo_library, // 照片 (选中)
      Icons.search, // 搜索 (选中)
      Icons.photo_album, // 相册 (选中)
      Icons.people, // 圈子 (选中)
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        // AppBar 标题现在会正确地显示新页面的标题
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
              // [关键改动 3/3] 使用动态数据构建 CircleAvatar
              child: CircleAvatar(
                radius: 20,
                // 如果有头像，使用 NetworkImage；否则为 null
                backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                backgroundColor: Colors.grey.shade200,
                // 如果没有头像，则显示一个默认的 person 图标作为 child
                child: !hasAvatar
                    ? Icon(Icons.person, size: 20, color: Colors.grey.shade400)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: currentIndex.value, children: pages),

      // 中央悬浮的 "添加" 按钮 (功能不变)
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          // TODO: 定义添加/上传的点击事件
          // ScaffoldMessenger.of(
          //   context,
          // ).showSnackBar(const SnackBar(content: Text('触发添加操作！')));
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: const CircleBorder(),
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
      ),
      floatingActionButtonLocation: const SinkingFabCenterDocked(yOffset: 20.0),

      // 底部导航栏
      bottomNavigationBar: isSelecting
          ? null
          : AnimatedBottomNavigationBar.builder(
              height: 80,
              itemCount: iconList.length,
              tabBuilder: (int index, bool isActive) {
                // 这个控件的 onTap 返回的 index 是从 0 到 3
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
                // 当点击底部导航项时，更新 currentIndex
                currentIndex.value = index;
              },
              // 美化配置保持不变，效果已经很好了
              gapLocation: GapLocation.center,
              notchSmoothness: NotchSmoothness.softEdge,
              leftCornerRadius: 32,
              rightCornerRadius: 32,
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

class SinkingFabCenterDocked extends FloatingActionButtonLocation {
  const SinkingFabCenterDocked({
    this.yOffset = 0.0, // 垂直方向的偏移量，正数表示向下
  });

  final double yOffset;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // 使用 Flutter 内置的 centerDocked 计算器来获取基础位置
    final Offset fabOffset = FloatingActionButtonLocation.centerDocked
        .getOffset(scaffoldGeometry);

    // 在计算出的 y 坐标上加上我们的偏移量
    return Offset(fabOffset.dx, fabOffset.dy + yOffset);
  }
}
