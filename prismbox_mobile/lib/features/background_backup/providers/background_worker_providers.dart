// lib/features/background_backup/providers/background_worker_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/features/background_backup/service/background_worker_fg_service.dart';

part 'background_worker_providers.g.dart';

/// 前台后台工作器服务 Provider
/// 
/// 提供后台任务的启用、禁用、配置等功能
/// 
/// **使用方式**：
/// ```dart
/// final service = ref.read(backgroundWorkerFgServiceProvider);
/// await service.enable(notificationTitle: '备份中...');
/// await service.configure(
///   requiresCharging: false,
///   minimumDelaySeconds: 300,
/// );
/// await service.disable();
/// ```
/// 
/// **注意**：
/// - 使用 keepAlive: true 确保全局单例，避免重复创建
@Riverpod(keepAlive: true)
BackgroundWorkerFgService backgroundWorkerFgService(
  BackgroundWorkerFgServiceRef ref,
) {
  return BackgroundWorkerFgService();
}

