// lib/presentation/widgets/user/user_profile_dialog.dart

import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/presentation/widgets/user/user_circle_avatar.dart';
import 'package:prismbox/providers/auth/auth_state_provider.dart';
import 'package:prismbox/providers/services/auth_service_provider.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';

/// 用户主页对话框
///
/// 显示用户信息、设置入口和退出登录
/// 参考 Immich 的设计
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
                borderRadius: BorderRadius.circular(14),
                color: Colors.grey[50],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 顶部栏（关闭按钮和标题）
                      _buildTopBar(context),

                      // 用户账户信息卡片
                      _buildUserAccountCard(context, ref, user, theme),

                      // 服务器存储卡片
                      _buildServerStorageCard(context, ref, theme),

                      // 版本信息
                      _buildVersionSection(context, theme),

                      // 导航项
                      _buildNavigationItems(context, ref, theme),

                      // 底部链接
                      _buildFooterLinks(context, theme),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('加载失败: $error')),
    );
  }

  /// 构建顶部栏
  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 关闭按钮（左侧）
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 20, color: Colors.black87),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          // 标题（居中）
          const Text(
            'PrismBox',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建用户账户信息卡片
  Widget _buildUserAccountCard(BuildContext context, WidgetRef ref, user, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // 头像（带相机图标）
          Stack(
            clipBehavior: Clip.none,
            children: [
              UserCircleAvatar(user: user, radius: 24.0, hasBorder: false),
              // 右下角相机图标
              Positioned(
                right: -2,
                bottom: -2,
                child: GestureDetector(
                  onTap: () => _handleUploadAvatar(context, ref),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // 用户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建服务器存储卡片
  Widget _buildServerStorageCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    // TODO: 从API获取真实的存储使用情况
    // 暂时使用模拟数据，后续需要接入真实API
    final usedBytes = 0; // 已使用的字节数
    final totalBytes = 0; // 总容量字节数

    // 计算使用百分比
    final usagePercent = totalBytes > 0
        ? (usedBytes / totalBytes).clamp(0.0, 1.0)
        : 0.0;

    // 格式化存储大小
    String formatBytes(int bytes) {
      if (bytes == 0) return '0 B';
      const units = ['B', 'KB', 'MB', 'GB', 'TB'];
      int unitIndex = 0;
      double size = bytes.toDouble();
      while (size >= 1024 && unitIndex < units.length - 1) {
        size /= 1024;
        unitIndex++;
      }
      return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${units[unitIndex]}';
    }

    final usedText = formatBytes(usedBytes);
    final totalText = formatBytes(totalBytes);

    // 根据使用百分比选择颜色
    Color progressColor;
    if (usagePercent < 0.7) {
      progressColor = Colors.blue;
    } else if (usagePercent < 0.9) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list, size: 20, color: Colors.black87),
              const SizedBox(width: 10),
              const Text(
                '服务器存储',
                style: TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 进度条
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: totalBytes > 0 && usagePercent > 0
                  ? FractionallySizedBox(
                      widthFactor: usagePercent,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: double.infinity,
                        height: 6,
                        decoration: BoxDecoration(
                          color: progressColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$usedText / $totalText 已使用',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              if (totalBytes > 0)
                Text(
                  '${(usagePercent * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建版本信息区域
  Widget _buildVersionSection(BuildContext context, ThemeData theme) {
    // 获取服务器地址
    final apiService = ApiService();
    final serverAddress = apiService.endpoint ?? '--';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 版本信息列表
          _buildVersionInfoItem('App 版本', '2.3.0 build.3027'),
          const SizedBox(height: 10),
          _buildVersionInfoItem('服务器版本', '--'),
          const SizedBox(height: 10),
          _buildVersionInfoItem('服务器地址', serverAddress),
          const SizedBox(height: 10),
          _buildVersionInfoItem('最新版本', '--'),
        ],
      ),
    );
  }

  /// 构建版本信息项
  Widget _buildVersionInfoItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 构建导航项
  Widget _buildNavigationItems(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildNavItem(
            context: context,
            icon: Icons.description_outlined,
            label: '日志',
            onTap: () {
              Navigator.of(context).pop();
              // TODO: 跳转到日志页面
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('日志页面开发中')));
            },
          ),
          Divider(height: 1, color: Colors.grey[200], indent: 44),
          _buildNavItem(
            context: context,
            icon: Icons.settings_outlined,
            label: '设置',
            onTap: () {
              Navigator.of(context).pop();
              context.router.push(const SettingsRoute());
            },
          ),
          Divider(height: 1, color: Colors.grey[200], indent: 44),
          _buildNavItem(
            context: context,
            icon: Icons.logout,
            label: '退出登录',
            onTap: () => _handleSignOut(context, ref),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  /// 构建导航项
  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDestructive ? Colors.red[600] : Colors.black87,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDestructive ? Colors.red[600] : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建底部链接
  Widget _buildFooterLinks(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLink('帮助文档', () {
            // TODO: 打开帮助文档
          }),
          Text(' • ', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          _buildLink('GitHub', () {
            // TODO: 打开GitHub
          }),
          Text(' • ', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          _buildLink('许可证', () {
            // TODO: 打开许可证
          }),
        ],
      ),
    );
  }

  /// 构建链接
  Widget _buildLink(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          // color: Colors.blue[700],
          // decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  /// 处理退出登录
  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final router = context.router;

    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题区域
              Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 12)),
              // 内容区域
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Text(
                  '确定要退出登录吗？',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ),
              // 按钮区域
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(ctx).pop(false),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(14),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: const Text(
                              '取消',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, height: 48, color: Colors.grey[200]),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(ctx).pop(true),
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(14),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              '退出',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.red[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      // 先关闭主对话框
      Navigator.of(context).pop();

      // 执行登出
      try {
        await ref.read(authNotifierProvider.notifier).logout();

        // 导航到登录页
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

  /// 处理上传头像
  Future<void> _handleUploadAvatar(BuildContext context, WidgetRef ref) async {
    try {
      // 使用 ImagePicker 选择图片
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 400,
        maxHeight: 400,
      );

      if (pickedFile == null) {
        // 用户取消了选择
        return;
      }

      // 显示加载提示
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正在上传头像...'),
          duration: Duration(seconds: 2),
        ),
      );

      // 上传头像
      final imageFile = File(pickedFile.path);
      final authService = await ref.read(authServiceProvider.future);
      await authService.uploadAvatar(imageFile);

      // 刷新认证状态（更新用户信息）
      ref.invalidate(authNotifierProvider);

      // 显示成功提示
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('头像上传成功'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // 显示错误提示
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('上传失败: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

/// 显示用户主页对话框的辅助函数
void showUserProfileDialog(BuildContext context) {
  showDialog(
    context: context,
    useRootNavigator: false,
    barrierDismissible: true,
    builder: (ctx) => const UserProfileDialog(),
  );
}
