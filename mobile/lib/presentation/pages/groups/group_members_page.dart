// lib/presentation/pages/groups/group_members_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/data/models/group/group_member.dart';
import 'package:prismbox/providers/group/group_detail_provider.dart';
import 'package:prismbox/providers/group/group_members_provider.dart';
import 'package:prismbox/providers/group/group_list_provider.dart';

/// 圈子成员管理页面（参考 Album 项目的实现）
@RoutePage()
class GroupMembersPage extends ConsumerWidget {
  final String groupUuid;

  const GroupMembersPage({
    super.key,
    @PathParam('groupUuid') required this.groupUuid,
  });

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

  Future<void> _generateInviteCode(
    BuildContext context,
    WidgetRef ref,
    String groupUuid,
  ) async {
    try {
      final service = ref.read(groupServiceProvider);
      final inviteCode = await service.createInvite(groupUuid);
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('邀请码已生成'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('分享此码给你的朋友:'),
                const SizedBox(height: 8),
                SelectableText(
                  inviteCode.code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteCode.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已复制到剪贴板')),
                  );
                },
                child: const Text('复制'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    }
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    GroupMember memberToRemove,
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
        final service = ref.read(groupServiceProvider);
        await service.removeMember(groupUuid, memberToRemove.userId);
        // 操作成功后刷新成员列表
        ref.invalidate(groupMembersProviderProvider(groupUuid));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('成员已移除')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('移除失败: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProviderProvider(groupUuid));
    // 同时获取圈子详情以判断当前用户的角色
    final groupDetailsAsync = ref.watch(groupDetailProviderProvider(groupUuid));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.router.maybePop(),
        ),
        title: const Text(
          '圈子成员',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          groupDetailsAsync.when(
            data: (groupDetails) {
              if (groupDetails == null) return const SizedBox.shrink();
              final bool isOwnerOrAdmin =
                  groupDetails.currentUserRole == GroupRole.owner ||
                  groupDetails.currentUserRole == GroupRole.admin;
              if (!isOwnerOrAdmin) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.add, color: Colors.black87),
                tooltip: '邀请新成员',
                onPressed: () => _generateInviteCode(context, ref, groupUuid),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('加载成员列表失败: $err'),
        ),
        data: (members) {
          return groupDetailsAsync.when(
            // 只需要详情中的角色信息，所以 loading 和 error 状态可以简化处理
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text('无法获取用户权限: $err'),
            ),
            data: (groupDetails) {
              if (groupDetails == null) {
                return const Center(
                  child: Text('无法获取圈子信息'),
                );
              }

              final currentUserRole = groupDetails.currentUserRole;

              return ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];

                  // 权限判断逻辑（参考 Album 项目）
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
                      child: Text(
                        member.username.isNotEmpty
                            ? member.username.substring(0, 1).toUpperCase()
                            : '?',
                      ),
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
                            onPressed: () => _removeMember(context, ref, member),
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
