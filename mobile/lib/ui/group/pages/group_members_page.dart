// lib/ui/group/pages/group_members_page.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 修正：导入 providers 文件
import 'package:mobile/group_providers.dart';
// 修正：导入模型文件以访问 GroupMemberModel 和 GroupRole
import 'package:mobile/data/models/group/group_models.dart';

@RoutePage()
class GroupMembersPage extends ConsumerWidget {
  final String uuid;
  const GroupMembersPage({super.key, @PathParam('uuid') required this.uuid});

  // 修正：使用正确的枚举类型 GroupRole
  String _roleToString(GroupRole role) {
    switch (role) {
      // 修正：使用正确的枚举值
      case GroupRole.owner:
        return '圈主';
      case GroupRole.admin:
        return '管理员';
      case GroupRole.member:
        return '成员';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 此处 provider 名称 groupMembersProvider 是正确的
    final membersAsync = ref.watch(groupMembersProvider(uuid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('圈子成员'),
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('加载成员列表失败: $err')),
        data: (members) {
          if (members.isEmpty) {
            return const Center(child: Text('圈子还没有成员'));
          }
          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: member.avatarUrl != null
                      ? NetworkImage(member.avatarUrl!)
                      : null,
                  child: member.avatarUrl == null
                      ? Text(member.username.substring(0, 1).toUpperCase())
                      : null,
                ),
                title: Text(member.username),
                trailing: Text(
                  _roleToString(member.role),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // TODO: 添加点击后的管理操作 (Sprint M4)
                onTap: () {},
              );
            },
          );
        },
      ),
    );
  }
}
