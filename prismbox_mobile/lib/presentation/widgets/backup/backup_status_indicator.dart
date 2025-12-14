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

          if (indicatorIcon == null) {
            return const SizedBox.shrink();
          }

          return SizedBox(
            width: 40,
            height: 40,
            child: InkWell(
              onTap: () {
                // 跳转到备份设置页面
                context.router.push(const BackupSettingsRoute());
              },
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: Badge(
                label: indicatorIcon,
                backgroundColor: Colors.transparent,
                alignment: Alignment.bottomRight,
                isLabelVisible: true,
                offset: const Offset(-2, -12),
                child: Icon(
                  Icons.backup_rounded,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
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

  Widget? _getBackupBadgeIcon(
    BuildContext context,
    bool isEnabled,
    bool isBackingUp,
    bool hasError,
  ) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDarkTheme ? Colors.white : Colors.black;

    if (hasError) {
      return _BadgeLabel(
        Icon(
          Icons.warning_rounded,
          size: 12,
          color: Theme.of(context).colorScheme.error,
        ),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
      );
    }

    if (!isEnabled) {
      return _BadgeLabel(
        Icon(
          Icons.cloud_off_rounded,
          size: 9,
          color: iconColor,
        ),
      );
    }

    if (isBackingUp) {
      return _BadgeLabel(
        Container(
          padding: const EdgeInsets.all(3.5),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            strokeCap: StrokeCap.round,
            valueColor: AlwaysStoppedAnimation<Color>(iconColor),
          ),
        ),
      );
    }

    return _BadgeLabel(
      Icon(
        Icons.check_outlined,
        size: 9,
        color: iconColor,
      ),
    );
  }
}

class _BadgeLabel extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const _BadgeLabel(
    this.child, {
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    const widgetSize = 30.0;
    final badgeBackground = backgroundColor ??
        Theme.of(context).colorScheme.surfaceContainer;

    return Container(
      width: widgetSize / 2,
      height: widgetSize / 2,
      decoration: BoxDecoration(
        color: badgeBackground,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(widgetSize / 2),
      ),
      child: Center(child: child),
    );
  }
}

