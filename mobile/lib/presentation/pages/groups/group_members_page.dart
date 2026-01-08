// lib/presentation/pages/groups/group_members_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/data/models/group/group_detail.dart' as models;
import 'package:prismbox/data/models/group/group_member.dart';
import 'package:prismbox/presentation/widgets/groups/member_list_item.dart';
import 'package:prismbox/providers/group/group_detail_provider.dart';
import 'package:prismbox/providers/group/group_members_provider.dart';
import 'package:prismbox/providers/group/group_list_provider.dart';

/// 成员管理页面
@RoutePage()
class GroupMembersPage extends ConsumerStatefulWidget {
  final String groupUuid;

  const GroupMembersPage({
    super.key,
    @PathParam('groupUuid') required this.groupUuid,
  });

  @override
  ConsumerState<GroupMembersPage> createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends ConsumerState<GroupMembersPage> {
  @override
  void initState() {
    super.initState();
    // 页面加载时自动加载成员列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupMembersProviderProvider(widget.groupUuid).notifier).load();
    });
  }

  Future<void> _handleCreateInvite() async {
    try {
      final service = ref.read(groupServiceProvider);
      final invite = await service.createInvite(widget.groupUuid);

      if (mounted) {
        // 复制邀请码到剪贴板
        await Clipboard.setData(ClipboardData(text: invite.code));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('邀请码已复制: ${invite.code}'),
            action: SnackBarAction(
              label: '分享',
              onPressed: () {
                // TODO: 实现分享功能
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建邀请码失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRemoveMember(GroupMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认移除'),
        content: Text('确定要移除成员 ${member.username} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('移除'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      final service = ref.read(groupServiceProvider);
      await service.removeMember(widget.groupUuid, member.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('成员已移除')),
        );
        // 刷新成员列表
        await ref.read(groupMembersProviderProvider(widget.groupUuid).notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('移除成员失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _canManageMembers(models.GroupDetail? detail) {
    if (detail == null) return false;
    return detail.currentUserRole == GroupRole.owner ||
        detail.currentUserRole == GroupRole.admin;
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(groupDetailProviderProvider(widget.groupUuid));
    final membersAsync = ref.watch(groupMembersProviderProvider(widget.groupUuid));

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
          '成员管理',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          detailAsync.when(
            data: (detail) {
              if (_canManageMembers(detail)) {
                return IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.black87),
                  onPressed: _handleCreateInvite,
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(groupMembersProviderProvider(widget.groupUuid).notifier).refresh();
        },
        child: membersAsync.when(
          data: (members) {
            if (members.isEmpty) {
              return const Center(
                child: Text('暂无成员'),
              );
            }
            return ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return detailAsync.when(
                  data: (detail) {
                    final canRemove = _canManageMembers(detail) &&
                        member.role != GroupRole.owner;
                    return MemberListItem(
                      member: member,
                      canRemove: canRemove,
                      onRemove: canRemove
                          ? () => _handleRemoveMember(member)
                          : null,
                    );
                  },
                  loading: () => MemberListItem(member: member),
                  error: (_, __) => MemberListItem(member: member),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => _buildErrorState(context, error),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(groupMembersProviderProvider(widget.groupUuid).notifier).refresh();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

