// lib/ui/group/pages/create_group_page.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers/group_providers.dart';

@RoutePage()
class CreateGroupPage extends HookConsumerWidget {
  const CreateGroupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final isCreating = useState(false);

    Future<void> createGroup() async {
      if (formKey.currentState?.validate() ?? false) {
        isCreating.value = true;
        try {
          await ref
              .read(groupRepositoryProvider)
              .createGroup(
                nameController.text,
                description: descriptionController.text,
              );

          // ignore: unused_result
          ref.refresh(groupListProvider);
          if (context.mounted) {
            // ignore: deprecated_member_use
            AutoRouter.of(context).pop();
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('创建失败: $e'), backgroundColor: Colors.red),
            );
          }
        } finally {
          isCreating.value = false;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('创建新圈子')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '圈子名称',
                  border: OutlineInputBorder(),
                  helperText: '给你的圈子起个响亮的名字吧',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '圈子名称不能为空';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '圈子简介 (可选)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isCreating.value ? null : createGroup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isCreating.value
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('完成创建'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
