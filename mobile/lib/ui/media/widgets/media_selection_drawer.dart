// lib/ui/media/widgets/media_selection_drawer.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers/providers.dart';

class MediaSelectionDrawer extends ConsumerWidget {
  final ScrollController scrollController;

  const MediaSelectionDrawer({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCount = ref.watch(
      selectionProvider.select((s) => s.selectedItems.length),
    );
    final bool hasSelection = selectedCount > 0;

    // [关键修改] 1. 将 "悬浮卡片" 的视觉效果放在内部
    // DraggableScrollableSheet 本身是看不见的，它只提供拖拽行为
    // 我们在内部用 Container + Padding 来创建我们想要的视觉样式
    return Container(
      // 背景设为透明，让下方的 Padding 和阴影正确显示
      color: Colors.transparent,
      child: Padding(
        // 这个 Padding 创造了卡片与屏幕边缘的 "呼吸空间"
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: const BorderRadius.all(Radius.circular(24.0)),
            boxShadow: [
              BoxShadow(
                // 1. 将阴影颜色稍微调深一点，增加对比度
                color: Colors.black.withOpacity(1),
                // 2. 增加一个向下的偏移量，模拟顶部光源
                offset: const Offset(0, 4),
                // 3. 大幅增加模糊半径，让阴影非常柔和、自然
                blurRadius: 24,
                // 4. 增加一个微小的扩展半径，让阴影范围更大
                spreadRadius: 2,
              ),
            ],
          ),
          // [关键修改] 2. 使用 ListView 来承载所有内容
          // 并将 DraggableScrollableSheet 的控制器赋给它
          child: ListView(
            controller: scrollController,
            // ListView 的内容就是抽屉里所有可见的元素
            children: [
              // 顶部拖拽指示器
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12.0),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // 初始状态下可见的核心操作
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    context: context,
                    icon: Icons.share_outlined,
                    label: '分享',
                    isEnabled: hasSelection,
                    onPressed: () => debugPrint('分享'),
                  ),
                  _buildActionButton(
                    context: context,
                    icon: Icons.favorite_border,
                    label: '喜欢',
                    isEnabled: hasSelection,
                    onPressed: () => debugPrint('喜欢'),
                  ),
                  _buildActionButton(
                    context: context,
                    icon: Icons.delete_outline,
                    label: '删除',
                    isEnabled: hasSelection,
                    onPressed: () => debugPrint('删除'),
                  ),
                ],
              ),
              const SizedBox(height: 16), // 分隔
              const Divider(indent: 16, endIndent: 16),

              // [关键修改] 3. 这里是向上拖拽后才会完全展示的 "隐藏内容"
              // 使用 ListTile 是展示这类列表的最佳实践
              ListTile(
                leading: const Icon(Icons.add_to_photos_outlined),
                title: const Text('添加到相册'),
                onTap: hasSelection ? () {} : null,
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('信息'),
                onTap: hasSelection ? () {} : null,
              ),
              // 你可以在下面添加更多 ListTile 来测试长列表的滚动效果
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    final color = isEnabled
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.38);

    return InkWell(
      onTap: isEnabled ? onPressed : null,
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
