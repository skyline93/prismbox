// lib/presentation/widgets/groups/member_list_item.dart

import 'package:flutter/material.dart';
import 'package:prismbox/data/models/group/group_member.dart';

/// 成员列表项组件
/// 用于成员管理页面，展示成员信息
class MemberListItem extends StatelessWidget {
  final GroupMember member;
  final bool canRemove;
  final VoidCallback? onRemove;

  const MemberListItem({
    super.key,
    required this.member,
    this.canRemove = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade300,
        child: Text(
          member.username.isNotEmpty
              ? member.username[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      title: Text(
        member.username,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        _getRoleText(member.role),
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: canRemove && onRemove != null
          ? IconButton(
              icon: Icon(
                Icons.remove_circle_outline,
                color: Colors.red.shade400,
              ),
              onPressed: onRemove,
            )
          : null,
    );
  }

  String _getRoleText(GroupRole role) {
    switch (role) {
      case GroupRole.owner:
        return '所有者';
      case GroupRole.admin:
        return '管理员';
      case GroupRole.member:
        return '成员';
    }
  }
}

