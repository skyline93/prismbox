// lib/presentation/pages/groups/group_settings_page.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/data/models/group/group_detail.dart';
import 'package:prismbox/data/models/group/group_member.dart';
import 'package:prismbox/providers/group/group_detail_provider.dart';
import 'package:prismbox/providers/group/group_list_provider.dart';
import 'package:prismbox/presentation/routing/app_router.dart';

/// 圈子设置页面（参考 Album 项目的实现）
@RoutePage()
class GroupSettingsPage extends ConsumerStatefulWidget {
  final String groupUuid;

  const GroupSettingsPage({
    super.key,
    @PathParam('groupUuid') required this.groupUuid,
  });

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

    // 初始化表单数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupDetails = ref.read(groupDetailProviderProvider(widget.groupUuid));
      groupDetails.whenData((group) {
        if (group != null) {
          _nameController.text = group.name;
          _descriptionController.text = group.description ?? '';
        }
      });
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
        final service = ref.read(groupServiceProvider);
        await service.updateGroup(
          groupUuid: widget.groupUuid,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
        // 刷新详情和列表
        ref.invalidate(groupDetailProviderProvider(widget.groupUuid));
        ref.invalidate(groupListProviderProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('圈子信息更新成功')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('更新失败: $e')),
          );
        }
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        final service = ref.read(groupServiceProvider);
        await service.leaveGroup(widget.groupUuid);
        ref.invalidate(groupListProviderProvider);
        if (mounted) {
          // 退出成功后，跳转回圈子列表页
          context.router.popUntil((route) => route.settings.name == GroupListRoute.name);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('退出失败: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupDetailsAsync = ref.watch(groupDetailProviderProvider(widget.groupUuid));

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
          '圈子设置',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: groupDetailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('加载失败: $err')),
        data: (group) {
          if (group == null) {
            return const Center(child: Text('无法获取圈子信息'));
          }

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

  Widget _buildAdminSection(GroupDetail group) {
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
                (value == null || value.trim().isEmpty) ? '名称不能为空' : null,
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

