// lib/presentation/widgets/backup/backup_status_indicator.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/providers/auth/auth_state_provider.dart';
import 'package:prismbox/services/backup/providers/backup_providers.dart';
import 'package:prismbox/services/backup/providers/backup_state_provider.dart';

/// 备份状态指示器
/// 显示在 AppBar 中，显示备份状态图标
/// 参考 Immich 和 Google Photos 的设计，使用 Badge 组件显示动态状态
class BackupStatusIndicator extends ConsumerWidget {
  const BackupStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用已缓存的 authNotifierProvider，避免频繁调用 getProfile()
    final authStateAsync = ref.watch(authNotifierProvider);

    return authStateAsync.when(
      data: (authState) {
        // 从已认证状态中提取 userId，避免重复调用 API
        if (authState is AuthStateAuthenticated) {
          return _BackupIndicatorContent(userId: authState.user.id.toString());
        }
        // 未认证或错误状态，不显示备份指示器
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _BackupIndicatorContent extends ConsumerWidget {
  final String userId;

  const _BackupIndicatorContent({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 先检查服务是否准备好
    final servicesReadyAsync = ref.watch(backupServicesReadyProvider);

    return servicesReadyAsync.when(
      data: (_) {
        // 服务已准备好，可以安全使用 backupStateProvider
        // 使用 select 精准订阅，只监听 isBackingUp 和 hasError
        final isBackingUp = ref.watch(
          backupStateProvider(userId).select((state) => state.isBackingUp),
        );
        final hasError = ref.watch(
          backupStateProvider(userId).select((state) => state.hasError),
        );
        
        final backupServiceAsync = ref.watch(backupServiceProvider);

        return backupServiceAsync.when(
          data: (backupService) {
            // 使用 FutureProvider 替代 FutureBuilder，避免频繁重建
            final backupStatusAsync = ref.watch(
              FutureProvider((ref) => backupService.getBackupStatus(userId)),
            );

            return backupStatusAsync.when(
              data: (backupStatus) {
                final isEnabled = backupStatus?.enabled ?? false;

                // 使用 RepaintBoundary 隔离动画区域，避免整树重绘
                return RepaintBoundary(
                  child: InkWell(
                    onTap: () {
                      context.router.push(const BackupSettingsRoute());
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Badge(
                      label: _BackupBadgeIcon(
                        isEnabled: isEnabled,
                        isBackingUp: isBackingUp,
                        hasError: hasError,
                      ),
                      backgroundColor: Colors.transparent,
                      alignment: Alignment.bottomRight,
                      isLabelVisible: isBackingUp || hasError || !isEnabled,
                      offset: const Offset(-2, -12),
                      child: Icon(
                        Icons.backup_rounded,
                        size: 24.0,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                );
              },
              // loading 时也显示主图标，只是不显示 badge
              loading: () => _buildMainIcon(context),
              // error 时也显示主图标，只是不显示 badge
              error: (_, __) => _buildMainIcon(context),
            );
          },
          // loading 时也显示主图标
          loading: () => _buildMainIcon(context),
          // error 时也显示主图标
          error: (_, __) => _buildMainIcon(context),
        );
      },
      // loading 时也显示主图标
      loading: () => _buildMainIcon(context),
      // error 时也显示主图标
      error: (_, __) => _buildMainIcon(context),
    );
  }

  /// 构建主图标（不包含 badge）
  Widget _buildMainIcon(BuildContext context) {
    return InkWell(
      onTap: () {
        context.router.push(const BackupSettingsRoute());
      },
      borderRadius: BorderRadius.circular(12),
      child: Icon(
        Icons.backup_rounded,
        size: 24.0,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// 备份徽章图标组件
/// 独立组件，使用 const 优化，避免频繁重建
class _BackupBadgeIcon extends StatelessWidget {
  final bool isEnabled;
  final bool isBackingUp;
  final bool hasError;

  const _BackupBadgeIcon({
    required this.isEnabled,
    required this.isBackingUp,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    // 调试日志：检查状态
    debugPrint('BackupStatusIndicator: isEnabled=$isEnabled, isBackingUp=$isBackingUp, hasError=$hasError');
    
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDarkTheme ? Colors.white : Colors.black;
    const badgeSize = 15.0;

    // 1. 错误状态：显示警告图标
    if (hasError) {
      return _BadgeLabel(
        Icon(
          Icons.warning_rounded,
          size: badgeSize,
          color: Theme.of(context).colorScheme.error,
        ),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
      );
    }

    // 2. 未启用状态：显示云关闭图标
    if (!isEnabled) {
      return _BadgeLabel(
        Icon(
          Icons.cloud_off_rounded,
          size: 9,
          color: iconColor,
        ),
      );
    }

    // 3. 备份中状态：显示动态进度指示器
    if (isBackingUp) {
      return _BadgeLabel(
        // 使用 SizedBox 明确指定尺寸，确保有足够空间
        SizedBox(
          width: badgeSize,
          height: badgeSize,
          child: Padding(
            padding: const EdgeInsets.all(2.0), // 减小 padding，从 3.5 改为 2.0
            child: CircularProgressIndicator(
              strokeWidth: 2,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              // 不设置 value，显示无限旋转动画
            ),
          ),
        ),
      );
    }

    // 4. 已备份状态：显示勾选图标
    return _BadgeLabel(
      Icon(
        Icons.check_outlined,
        size: 9,
        color: iconColor,
      ),
    );
  }
}

/// 徽章标签组件
/// 参考 Immich 的 _BadgeLabel 设计
class _BadgeLabel extends StatelessWidget {
  final Widget indicator;
  final Color? backgroundColor;

  const _BadgeLabel(
    this.indicator, {
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    const badgeSize = 15.0;
    final defaultBackgroundColor = backgroundColor ??
        Theme.of(context).colorScheme.surfaceContainer;

    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: defaultBackgroundColor,
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(badgeSize / 2),
      ),
      child: indicator,
    );
  }
}
