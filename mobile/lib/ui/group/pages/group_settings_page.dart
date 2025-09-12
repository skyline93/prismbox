import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/models/group/group_models.dart';
import 'package:mobile/providers/group_providers.dart';
import 'package:mobile/routing/app_router.dart';

@RoutePage()
class GroupSettingsPage extends ConsumerStatefulWidget {
  final String uuid;
  const GroupSettingsPage({super.key, @PathParam('uuid') required this.uuid});

  @override
  ConsumerState<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends ConsumerState<GroupSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();

    final groupDetails = ref.read(groupDetailsProvider(widget.uuid));
    groupDetails.whenData((group) {
      _nameController.text = group.name;
      _descriptionController.text = group.description ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateGroupInfo() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref
            .read(groupRepositoryProvider)
            .updateGroup(
              widget.uuid,
              name: _nameController.text,
              description: _descriptionController.text,
            );
        ref.invalidate(groupDetailsProvider(widget.uuid));
        ref.invalidate(groupListProvider);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('圈子信息更新成功')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('更新失败: $e')));
        }
      }
    }
  }

  Future<void> _generateInviteCode() async {
    try {
      final inviteCode = await ref
          .read(groupRepositoryProvider)
          .createInviteCode(widget.uuid);
      if (mounted) {
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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('已复制到剪贴板')));
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('生成失败: $e')));
      }
    }
  }

  Future<void> _leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('你确定要退出这个圈子吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await ref.read(groupRepositoryProvider).leaveGroup(widget.uuid);
        ref.invalidate(groupListProvider);
        if (mounted) {
          AutoRouter.of(
            context,
          ).popUntil((route) => route.settings.name == GroupListRoute.name);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('退出失败: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupDetailsAsync = ref.watch(groupDetailsProvider(widget.uuid));

    return Scaffold(
      appBar: AppBar(title: const Text('圈子设置')),
      body: groupDetailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('加载失败: $err')),
        data: (group) {
          final bool isOwnerOrAdmin =
              group.currentUserRole == GroupRole.owner ||
              group.currentUserRole == GroupRole.admin;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (isOwnerOrAdmin)
                _buildAdminSection(group)
              else
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(group.name),
                  subtitle: Text(group.description ?? '暂无描述'),
                ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              if (isOwnerOrAdmin)
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1),
                  title: const Text('邀请新成员'),
                  subtitle: const Text('生成一个邀请码'),
                  onTap: _generateInviteCode,
                ),

              ListTile(
                leading: Icon(Icons.exit_to_app, color: Colors.red.shade700),
                title: Text(
                  '退出圈子',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                onTap: _leaveGroup,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdminSection(GroupModel group) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '圈子名称',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                (value == null || value.isEmpty) ? '名称不能为空' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: '圈子描述 (可选)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _updateGroupInfo,
              icon: const Icon(Icons.save),
              label: const Text('保存更改'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
