// lib/presentation/pages/groups/create_group_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/providers/group/group_list_provider.dart';

/// 创建圈子页面
@RoutePage()
class CreateGroupPage extends ConsumerStatefulWidget {
  const CreateGroupPage({super.key});

  @override
  ConsumerState<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends ConsumerState<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(groupServiceProvider);
      final group = await service.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      // 刷新圈子列表
      await ref.read(groupListProviderProvider.notifier).refresh();

      if (mounted) {
        // 跳转到新创建的圈子详情页
        context.router.push(GroupDetailRoute(groupUuid: group.uuid));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          '创建圈子',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleCreate,
            child: Text(
              '创建',
              style: TextStyle(
                color: _isLoading || _nameController.text.trim().isEmpty
                    ? Colors.grey
                    : Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 名称输入
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '圈子名称',
                  hintText: '请输入圈子名称',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入圈子名称';
                  }
                  if (value.trim().length > 100) {
                    return '圈子名称不能超过100个字符';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {}); // 更新创建按钮状态
                },
              ),
              const SizedBox(height: 16),
              // 描述输入
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '圈子描述（可选）',
                  hintText: '请输入圈子描述',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                maxLength: 255,
              ),
              const SizedBox(height: 24),
              // 封面图选择（预留，当前不实现）
              // TODO: 后续可以添加封面图选择功能
            ],
          ),
        ),
      ),
    );
  }
}

