// lib/ui/group/pages/group_list_page.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:mobile/providers/group_providers.dart';
import 'package:mobile/ui/group/widgets/group_list_item.dart';

@RoutePage()
class GroupListPage extends ConsumerWidget {
  const GroupListPage({super.key});

  void _showJoinGroupDialog(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('使用邀请码加入圈子'),
          content: TextField(
            controller: codeController,
            decoration: const InputDecoration(
              labelText: '邀请码',
              hintText: '在此粘贴邀请码',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                final code = codeController.text.trim();
                if (code.isNotEmpty) {
                  final groupRepository = ref.read(groupRepositoryProvider);
                  await groupRepository.joinGroup(code);
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                  // ignore: unused_result
                  ref.refresh(groupListProvider);
                }
              },
              child: const Text('加入'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupListAsync = ref.watch(groupListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的圈子'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: '加入圈子',
            onPressed: () => _showJoinGroupDialog(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: groupListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('加载失败: $err')),
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(child: Text('你还没有加入任何圈子'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(groupListProvider.future),
            child: GridView.builder(
              padding: const EdgeInsets.all(12.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.8,
              ),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return GroupListItemWidget(
                  group: group,
                  onTap: () {
                    AutoRouter.of(
                      context,
                    ).push(GroupFeedRoute(uuid: group.uuid));
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AutoRouter.of(context).push(const CreateGroupRoute());
        },
        child: const Icon(Icons.add),
        tooltip: '创建新圈子',
      ),
    );
  }
}
