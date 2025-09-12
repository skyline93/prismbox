// lib/ui/main/widgets/user_profile_dialog.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:mobile/providers/user_profile_provider.dart';
import 'package:mobile/providers/providers.dart';
import 'package:mobile/routing/app_router.dart';

class UserProfileDialog extends HookConsumerWidget {
  const UserProfileDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(userProfileProvider);
    final notifier = ref.read(userProfileProvider.notifier);
    final authNotifier = ref.read(authNotifierProvider.notifier);

    final avatarUrl = viewModel.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundImage: hasAvatar
                                ? NetworkImage(avatarUrl)
                                : null,
                            backgroundColor: Colors.grey.shade200,
                            child: !hasAvatar
                                ? Icon(
                                    Icons.person,
                                    size: 32,
                                    color: Colors.grey.shade400,
                                  )
                                : null,
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: GestureDetector(
                              onTap: () {
                                notifier.uploadNewAvatar();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Color(0xFFE0E0E0),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              // notifier.updateUsername('一个很酷的新名字');
                            },
                            child: Text(
                              viewModel.username,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            viewModel.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '云存储空间',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            viewModel.storageText,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: viewModel.storagePercentage,
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                  leading: const Icon(Icons.swap_horiz),
                  title: const Text('传输管理'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () async {
                    context.router.pop();
                    context.router.push(const TransferManagerRoute());
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('设置'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                  leading: const Icon(Icons.info_outline),
                  title: const Text('关于'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                  leading: Icon(Icons.logout, color: Colors.red.shade700),
                  title: Text(
                    '退出登录',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  onTap: () async {
                    if (context.mounted) {
                      context.router.pop();
                    }

                    await authNotifier.logout();
                    if (context.mounted) {
                      context.router.replaceAll([const LoginRoute()]);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
