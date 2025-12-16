// lib/presentation/widgets/backup/backup_status_indicator.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/providers/services/auth_service_provider.dart';
import 'package:prismbox/services/backup/backup_service.dart';
import 'package:prismbox/services/backup/providers/backup_providers.dart';
import 'package:prismbox/services/backup/providers/backup_state_provider.dart';

/// 备份状态指示器
/// 显示在 AppBar 中，显示备份状态图标
class BackupStatusIndicator extends ConsumerWidget {
  const BackupStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authServiceAsync = ref.watch(authServiceProvider);

    return authServiceAsync.when(
      data: (authService) => FutureBuilder<String>(
        future: authService.getProfile().then((p) => p.id.toString()),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }
          return _BackupIndicatorContent(userId: snapshot.data!);
        },
      ),
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
        final backupState = ref.watch(backupStateProvider(userId));
        final backupServiceAsync = ref.watch(backupServiceProvider);

        return backupServiceAsync.when(
          data: (backupService) => FutureBuilder<BackupStatus?>(
            future: backupService.getBackupStatus(userId),
            builder: (context, snapshot) {
              final backupStatus = snapshot.data;
              final isEnabled = backupStatus?.enabled ?? false;
              final isBackingUp = backupState.isBackingUp;
              final hasError = backupState.hasError;

              final indicatorIcon = _getBackupBadgeIcon(
                context,
                isEnabled,
                isBackingUp,
                hasError,
              );

              final backgroundColor = _getBackgroundColor(
                context,
                isEnabled,
                isBackingUp,
                hasError,
              );

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // 跳转到备份设置页面
                    context.router.push(const BackupSettingsRoute());
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: backgroundColor != null
                        ? BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(20),
                          )
                        : null,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 主图标
                        Icon(
                          _getMainIcon(isEnabled, isBackingUp, hasError),
                          size: 24,
                          color: _getIconColor(
                            context,
                            isEnabled,
                            isBackingUp,
                            hasError,
                          ),
                        ),
                        // 状态指示器（右上角小点）
                        if (indicatorIcon != null)
                          Positioned(top: 5, right: 5, child: indicatorIcon),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// 获取主图标
  /// 统一使用 backup_rounded 图标，通过颜色和状态指示器区分不同状态
  IconData _getMainIcon(bool isEnabled, bool isBackingUp, bool hasError) {
    return Icons.backup_rounded;
  }

  /// 获取图标颜色
  Color _getIconColor(
    BuildContext context,
    bool isEnabled,
    bool isBackingUp,
    bool hasError,
  ) {
    if (hasError) {
      return Theme.of(context).colorScheme.error;
    }
    if (!isEnabled) {
      return Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    }
    if (isBackingUp) {
      return Theme.of(context).colorScheme.primary;
    }
    return Theme.of(context).colorScheme.primary;
  }

  /// 获取背景颜色
  /// 使用更简洁的设计，只在必要时显示背景
  Color? _getBackgroundColor(
    BuildContext context,
    bool isEnabled,
    bool isBackingUp,
    bool hasError,
  ) {
    // 只在备份中或错误时显示背景，其他情况透明
    if (hasError) {
      return Theme.of(context).colorScheme.errorContainer.withOpacity(0.15);
    }
    if (isBackingUp) {
      return Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2);
    }
    return null; // 透明背景，更简洁
  }

  /// 获取状态指示器图标（右上角小点）
  Widget? _getBackupBadgeIcon(
    BuildContext context,
    bool isEnabled,
    bool isBackingUp,
    bool hasError,
  ) {
    if (hasError) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.error.withOpacity(0.5),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      );
    }

    if (!isEnabled) {
      return null; // 未启用时不显示指示器
    }

    if (isBackingUp) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      );
    }

    // 已备份状态：显示绿色小点
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
