import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/models/group/group_models.dart';
import 'package:mobile/providers/group_providers.dart';

@RoutePage()
class GroupMembersPage extends ConsumerWidget {
  final String uuid;
  const GroupMembersPage({super.key, @PathParam('uuid') required this.uuid});

  String _roleToString(GroupRole role) {
    switch (role) {
      case GroupRole.owner:
        return '圈主';
      case GroupRole.admin:
        return '管理员';
      case GroupRole.member:
        return '成员';
    }
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    GroupMemberModel memberToRemove,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认移除'),
        content: Text('你确定要将 "${memberToRemove.username}" 移出圈子吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await ref
            .read(groupRepositoryProvider)
            .removeMember(
              groupUuid: uuid,
              userId: memberToRemove.userId.toString(),
            );
        // 操作成功后刷新成员列表
        ref.invalidate(groupMembersProvider(uuid));
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('成员已移除')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('移除失败: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(uuid));
    // 同时获取圈子详情以判断当前用户的角色
    final groupDetailsAsync = ref.watch(groupDetailsProvider(uuid));

    return Scaffold(
      appBar: AppBar(title: const Text('圈子成员')),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('加载成员列表失败: $err')),
        data: (members) {
          return groupDetailsAsync.when(
            // 只需要详情中的角色信息，所以 loading 和 error 状态可以简化处理
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('无法获取用户权限: $err')),
            data: (groupDetails) {
              final currentUserRole = groupDetails.currentUserRole;

              return ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];

                  // 权限判断逻辑
                  bool canRemove = false;
                  if (currentUserRole == GroupRole.owner &&
                      member.role != GroupRole.owner) {
                    canRemove = true;
                  } else if (currentUserRole == GroupRole.admin &&
                      member.role == GroupRole.member) {
                    canRemove = true;
                  }

                  // 不能移除自己
                  if (member.userId == groupDetails.currentUserId) {
                    canRemove = false;
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      // 假设有头像 URL
                      // backgroundImage: NetworkImage(member.avatarUrl ?? ''),
                      child: Text(member.username.substring(0, 1)),
                    ),
                    title: Text(member.username),
                    subtitle: Text(_roleToString(member.role)),
                    trailing: canRemove
                        ? IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            tooltip: '移除成员',
                            onPressed: () =>
                                _removeMember(context, ref, member),
                          )
                        : null,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
