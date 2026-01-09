// lib/presentation/pages/groups/group_list_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/presentation/widgets/groups/group_card.dart';
import 'package:prismbox/providers/group/group_list_provider.dart';

/// 圈子列表页面
@RoutePage()
class GroupListPage extends ConsumerStatefulWidget {
  const GroupListPage({super.key});

  @override
  ConsumerState<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends ConsumerState<GroupListPage> {
  @override
  void initState() {
    super.initState();
    // 页面加载时自动加载圈子列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupListProviderProvider.notifier).load();
    });
  }

  Future<void> _showJoinGroupDialog() async {
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('加入圈子'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: '邀请码',
                hintText: '请输入邀请码',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              enabled: !isLoading,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入邀请码';
                }
                if (value.trim().length < 4) {
                  return '邀请码格式不正确';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() {
                          isLoading = true;
                        });

                        try {
                          final service = ref.read(groupServiceProvider);
                          final group = await service.joinGroup(codeController.text.trim());
                          
                          // 刷新圈子列表
                          ref.invalidate(groupListProviderProvider);
                          await ref.read(groupListProviderProvider.notifier).refresh();

                          if (mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('成功加入圈子：${group.name}'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            // 跳转到新加入的圈子详情页
                            context.router.push(GroupDetailRoute(groupUuid: group.uuid));
                          }
                        } catch (e) {
                          setDialogState(() {
                            isLoading = false;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('加入失败: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('加入'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupListProviderProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '我的圈子',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.login, size: 18),
            label: const Text('加入'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black87,
            ),
            onPressed: _showJoinGroupDialog,
          ),
          TextButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('创建'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black87,
            ),
            onPressed: () {
              context.router.push(const CreateGroupRoute());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(groupListProviderProvider.notifier).refresh();
        },
        child: groupsAsync.when(
          data: (groups) {
            if (groups.isEmpty) {
              return _buildEmptyState(context);
            }
            return ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return GroupCard(
                  group: group,
                  onTap: () {
                    context.router.push(GroupDetailRoute(groupUuid: group.uuid));
                  },
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有圈子',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '创建第一个圈子，与朋友分享照片',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.router.push(const CreateGroupRoute());
            },
            icon: const Icon(Icons.add),
            label: const Text('创建圈子'),
          ),
        ],
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
              ref.read(groupListProviderProvider.notifier).refresh();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

