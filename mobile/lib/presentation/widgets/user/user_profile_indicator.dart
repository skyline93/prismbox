// lib/presentation/widgets/user/user_profile_indicator.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/presentation/widgets/user/user_circle_avatar.dart';
import 'package:prismbox/presentation/widgets/user/user_profile_dialog.dart';
import 'package:prismbox/providers/auth/auth_state_provider.dart';

/// 用户主页入口指示器
/// 
/// 显示在 AppBar 中，点击后弹出用户主页对话框
/// 参考 Immich 和 Google Photos 的设计
class UserProfileIndicator extends ConsumerWidget {
  const UserProfileIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authNotifierProvider);

    return authStateAsync.when(
      data: (authState) {
        if (authState is! AuthStateAuthenticated) {
          // 未认证时不显示
          return const SizedBox.shrink();
        }

        final user = authState.user;

        return InkWell(
          onTap: () => showUserProfileDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: UserCircleAvatar(
            user: user,
            radius: 17.0,
            hasBorder: false,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

