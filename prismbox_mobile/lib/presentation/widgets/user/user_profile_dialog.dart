// lib/presentation/widgets/user/user_profile_dialog.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/presentation/widgets/user/user_circle_avatar.dart';
import 'package:prismbox/providers/auth/auth_state_provider.dart';


/// 用户主页对话框
/// 
/// 显示用户信息、设置入口和退出登录
/// 参考 Immich 和 Google Photos 的设计
class UserProfileDialog extends ConsumerWidget {
  const UserProfileDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);
    final isHorizontal = MediaQuery.of(context).size.width > 600;
    final horizontalPadding = isHorizontal ? 100.0 : 20.0;

    return authStateAsync.when(
      data: (authState) {
        if (authState is! AuthStateAuthenticated) {
          // 如果未认证，不显示对话框
          return const SizedBox.shrink();
        }

        final user = authState.user;

        return Dialog(
          clipBehavior: Clip.hardEdge,
          alignment: Alignment.topCenter,
          insetPadding: EdgeInsets.only(
            top: isHorizontal ? 20 : 40,
            left: horizontalPadding,
            right: horizontalPadding,
            bottom: isHorizontal ? 20 : 100,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Dismissible(
            key: const Key('user_profile_dialog'),
            direction: DismissDirection.down,
            onDismissed: (_) => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 顶部栏（关闭按钮）
                    _buildTopBar(context, theme),

                    // 用户信息区域（卡片样式）
                    _buildUserInfoSection(context, user, theme),

                    // 操作按钮区域
                    _buildActionsSection(context, ref, theme),

                    // 底部信息
                    _buildFooter(context, theme),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('加载失败: $error'),
      ),
    );
  }

  /// 构建顶部栏
  Widget _buildTopBar(BuildContext context, ThemeData theme) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Material(
            color: Colors.transparent,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.close_rounded,
                size: 22,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(12),
                minimumSize: const Size(40, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              splashRadius: 20,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              'PrismBox',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建用户信息区域
  Widget _buildUserInfoSection(
    BuildContext context,
    user,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // 用户头像（更大，更突出）
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: UserCircleAvatar(
              user: user,
              radius: 32.0,
              hasBorder: true,
            ),
          ),
          const SizedBox(width: 16),
          // 用户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.username,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    fontSize: 20,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (user.email.isNotEmpty)
                  Text(
                    user.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      letterSpacing: 0,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮区域
  Widget _buildActionsSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // 设置按钮（卡片样式）
          _buildActionCard(
            context: context,
            icon: Icons.settings_outlined,
            text: '设置',
            onTap: () {
              Navigator.of(context).pop();
              // TODO: 跳转到设置页面（如果有的话）
              // context.router.push(const SettingsRoute());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('设置页面开发中')),
              );
            },
            theme: theme,
          ),
          const SizedBox(height: 8),
          // 退出登录按钮（卡片样式，红色）
          _buildActionCard(
            context: context,
            icon: Icons.logout_rounded,
            text: '退出登录',
            onTap: () => _handleSignOut(context, ref),
            theme: theme,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  /// 构建操作卡片按钮
  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isDestructive = false,
  }) {
    final backgroundColor = isDestructive
        ? theme.colorScheme.errorContainer.withOpacity(0.1)
        : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3);
    final iconColor = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface.withOpacity(0.87);
    final textColor = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface.withOpacity(0.87);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? theme.colorScheme.errorContainer.withOpacity(0.2)
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (!isDestructive)
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 处理退出登录
  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final router = context.router; // 提前获取 router 引用
    
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          '退出登录',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '确定要退出登录吗？',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              '取消',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text(
              '退出',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 先关闭主对话框
      Navigator.of(context).pop();

      // 执行登出
      try {
        await ref.read(authNotifierProvider.notifier).logout();
        
        // 导航到登录页（使用提前获取的 router 引用）
        router.replaceAll([const LoginRoute()]);
      } catch (e) {
        // 登出失败，但已经关闭对话框，显示错误提示
        if (router.canPop()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('退出登录失败: $e'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      }
    }
  }


  /// 构建底部信息
  Widget _buildFooter(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  theme.colorScheme.outline.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Text(
            'PrismBox',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              letterSpacing: 0.5,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 显示用户主页对话框的辅助函数
void showUserProfileDialog(BuildContext context) {
  showDialog(
    context: context,
    useRootNavigator: false,
    barrierDismissible: true, // 允许点击外部关闭对话框
    builder: (ctx) => const UserProfileDialog(),
  );
}

