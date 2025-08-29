// lib/ui/group/widgets/group_list_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 修正：使用正确的模型类 GroupModel 并导入
import 'package:mobile/data/models/group/group_models.dart';

class GroupListItemWidget extends ConsumerWidget {
  const GroupListItemWidget(
      {super.key, required this.group, required this.onTap});

  // 修正：使用正确的类型 GroupModel
  final GroupModel group;
  final VoidCallback onTap;

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Center(
        child: Icon(
          Icons.group_work_outlined,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context, WidgetRef ref) {
    // TODO: 实现封面图加载逻辑 (Sprint M3)
    // final coverAsyncValue = ref.watch(groupCoverProvider(group.coverMediaUuid));
    // return coverAsyncValue.when(...)
    return _buildPlaceholder(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildCover(context, ref),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8.0).copyWith(top: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // 使用你的模型中定义的 memberCount 字段
                    Text(
                      '${group.memberCount ?? 0} 成员',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}