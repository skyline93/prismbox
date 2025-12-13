// lib/features/background_backup/service/background_worker_bg_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/connection.dart';
import 'package:prismbox/utils/cancellation_token.dart';
import 'package:prismbox/platform/background_worker_api.g.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/core/storage/store_key.dart';
import 'package:prismbox/domain/entities/user_profile.dart';
import 'package:prismbox/services/backup/providers/backup_providers.dart' as backup;
import 'package:prismbox/services/backup/backup_service.dart';
import 'package:prismbox/services/backup/background_sync_manager.dart';
import 'package:prismbox/services/backup/upload_service.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart' as infra;

/// 后台任务服务
/// 运行在独立 Flutter Engine 中，处理后台备份任务
/// 
/// **职责**：
/// - 管理独立 Flutter Engine 的生命周期
/// - 处理任务初始化和清理
/// - 协调同步和上传流程
/// - 与原生平台通信
/// 
/// **注意**：此类继承自 BackgroundWorkerFlutterApi，由原生平台调用
class BackgroundWorkerBgService extends BackgroundWorkerFlutterApi {
  /// ProviderContainer 用于在后台 Engine 中管理依赖注入
  ProviderContainer? _container;
  
  /// 数据库实例
  AppDatabase? _database;
  
  /// 备份服务
  BackupService? _backupService;
  
  /// 同步管理器
  BackgroundSyncManager? _syncManager;
  
  /// 上传服务
  UploadService? _uploadService;
  
  /// 后台 Host API（用于通知原生层）
  final BackgroundWorkerBgHostApi _backgroundHostApi;
  
  /// 取消令牌，用于取消正在执行的任务
  final CancellationToken _cancellationToken = CancellationToken();
  
  /// 日志记录器
  final Logger _logger = Logger('BackgroundWorkerBgService');
  
  /// 是否已清理
  bool _isCleanedUp = false;

  /// 构造函数
  BackgroundWorkerBgService()
      : _backgroundHostApi = BackgroundWorkerBgHostApi() {
    // 注册 Flutter API（让原生平台可以调用 Flutter 方法）
    BackgroundWorkerFlutterApi.setUp(this);
  }

  /// 初始化后台服务
  /// 
  /// **职责**：
  /// - 初始化数据库连接
  /// - 创建独立的 ProviderContainer
  /// - 配置 API 客户端
  /// - 初始化同步和上传服务（后续实现）
  /// - 通知原生层初始化完成
  Future<void> init() async {
    try {
      _logger.info('Initializing background worker service');

      // 1. 初始化数据库连接
      // 在后台 Engine 中，数据库连接会连接到主应用创建的 Isolate
      _database = await DatabaseConnection.getInstance();
      
      // 2. 创建独立的 ProviderContainer
      // 这允许我们在后台 Engine 中使用 Riverpod Provider
      _container = ProviderContainer(
        overrides: [
          // 数据库 Provider
          infra.databaseProvider.overrideWith((ref) async => _database!),
        ],
      );

      // 3. 初始化服务（通过 Provider 获取）
      // 注意：这些 providers 是 AutoDisposeFutureProvider，需要使用 .future 获取 Future
      _syncManager = await _container!.read(backup.backgroundSyncManagerProvider.future);
      _uploadService = await _container!.read(backup.uploadServiceProvider.future);
      _backupService = await _container!.read(backup.backupServiceProvider.future);

      // 5. 通知原生层初始化完成
      await _backgroundHostApi.onInitialized();
      
      _logger.info('Background worker service initialized successfully');
    } catch (error, stackTrace) {
      _logger.severe(
        'Failed to initialize background worker service',
        error,
        stackTrace,
      );
      // 通知原生层初始化失败
      await _backgroundHostApi.onCompleted();
      rethrow;
    }
  }

  /// Android 后台上传任务执行
  /// 
  /// 由原生平台通过 BackgroundWorkerFlutterApi.onAndroidUpload() 调用
  /// 
  /// **执行流程**：
  /// 1. 获取当前用户 ID
  /// 2. 检查备份是否启用
  /// 3. 执行三阶段同步（本地同步、远程同步、哈希计算）
  /// 4. 执行自动备份
  /// 5. 执行上传编排
  /// 6. 更新备份状态
  @override
  Future<void> onAndroidUpload() async {
    _logger.info('Android background upload started');
    final stopwatch = Stopwatch()..start();
    
    try {
      // 1. 获取当前用户 ID
      final userId = await _getCurrentUserId();
      if (userId == null) {
        _logger.warning('No authenticated user, skipping backup');
        return;
      }

      // 2. 检查备份是否启用
      final backupStatus = await _backupService!.getBackupStatus(userId);
      if (backupStatus == null || !backupStatus.enabled) {
        _logger.info('Backup is disabled for userId=$userId');
        return;
      }

      // 3. 执行三阶段同步
      _logger.info('Starting three-phase sync');
      final syncResult = await _syncManager!.syncAll(
        cancellationToken: _cancellationToken,
      );
      _logger.info(
        'Sync completed: added=${syncResult.addedCount}, '
        'updated=${syncResult.updatedCount}, deleted=${syncResult.deletedCount}',
      );

      if (_cancellationToken.isCancelled) {
        _logger.info('Backup cancelled after sync');
        return;
      }

      // 4. 执行自动备份（创建上传任务）
      _logger.info('Starting auto backup');
      await _backupService!.startAutoBackup(userId);

      if (_cancellationToken.isCancelled) {
        _logger.info('Backup cancelled after creating tasks');
        return;
      }

      // 5. 执行上传编排
      _logger.info('Starting upload orchestration');
      final uploadResult = await _uploadService!.startUpload(
        userId: userId,
        cancellationToken: _cancellationToken,
        onProgress: (current, total) {
          _logger.fine('Upload progress: $current/$total');
          // 通过 Pigeon API 更新进度
          _backgroundHostApi.updateProgress(
            current,
            total,
            null, // 当前文件名（可选，后续可以从任务中获取）
          ).catchError((error) {
            _logger.warning('Failed to update progress: $error');
          });
        },
      );

      _logger.info(
        'Upload completed: success=${uploadResult.successCount}, '
        'failed=${uploadResult.failedCount}',
      );

      _logger.info('Android background upload completed successfully');
    } catch (error, stackTrace) {
      _logger.severe(
        'Failed to complete Android background upload',
        error,
        stackTrace,
      );
    } finally {
      stopwatch.stop();
      _logger.info(
        'Android background upload finished in ${stopwatch.elapsed.inSeconds}s',
      );
      await _cleanup();
    }
  }

  /// iOS 后台上传任务执行
  /// 
  /// 由原生平台通过 BackgroundWorkerFlutterApi.onIosUpload() 调用
  /// 
  /// **参数**：
  /// - [isRefresh] - 是否为刷新任务（BGAppRefreshTask）
  /// - [maxSeconds] - 最大执行时间（秒），BGProcessingTask 使用
  /// 
  /// **执行流程**：
  /// 类似 Android，但需要处理超时限制
  /// - 如果是刷新任务（isRefresh=true），只执行快速同步
  /// - 如果是处理任务（isRefresh=false），执行完整备份流程
  @override
  Future<void> onIosUpload(bool isRefresh, int? maxSeconds) async {
    _logger.info(
      'iOS background upload started (isRefresh: $isRefresh, maxSeconds: $maxSeconds)',
    );
    final stopwatch = Stopwatch()..start();
    
    try {
      // 1. 获取当前用户 ID
      final userId = await _getCurrentUserId();
      if (userId == null) {
        _logger.warning('No authenticated user, skipping backup');
        return;
      }

      // 2. 检查备份是否启用
      final backupStatus = await _backupService!.getBackupStatus(userId);
      if (backupStatus == null || !backupStatus.enabled) {
        _logger.info('Backup is disabled for userId=$userId');
        return;
      }

      // 3. 根据任务类型执行不同流程
      Future<void> backupFuture;

      if (isRefresh) {
        // 刷新任务：只执行快速同步
        _logger.info('Executing quick sync for refresh task');
        backupFuture = _syncManager!.syncLocal(
          cancellationToken: _cancellationToken,
        ).then((_) => null);
      } else {
        // 处理任务：执行完整备份流程
        _logger.info('Executing full backup for processing task');
        backupFuture = _executeFullBackup(userId);
      }

      // 4. 根据 maxSeconds 设置超时
      if (maxSeconds != null) {
        await backupFuture.timeout(
          Duration(seconds: maxSeconds - 1),
          onTimeout: () {
            _logger.warning(
              'Backup timeout after ${maxSeconds - 1} seconds',
            );
          },
        );
      } else {
        await backupFuture;
      }

      _logger.info('iOS background upload completed successfully');
    } catch (error, stackTrace) {
      _logger.severe(
        'Failed to complete iOS background upload',
        error,
        stackTrace,
      );
    } finally {
      stopwatch.stop();
      _logger.info(
        'iOS background upload finished in ${stopwatch.elapsed.inSeconds}s',
      );
      await _cleanup();
    }
  }

  /// 执行完整备份流程
  Future<void> _executeFullBackup(String userId) async {
    // 1. 执行三阶段同步
    _logger.info('Starting three-phase sync');
    final syncResult = await _syncManager!.syncAll(
      cancellationToken: _cancellationToken,
    );
    _logger.info(
      'Sync completed: added=${syncResult.addedCount}, '
      'updated=${syncResult.updatedCount}, deleted=${syncResult.deletedCount}',
    );

    if (_cancellationToken.isCancelled) {
      _logger.info('Backup cancelled after sync');
      return;
    }

    // 2. 执行自动备份（创建上传任务）
    _logger.info('Starting auto backup');
    await _backupService!.startAutoBackup(userId);

    if (_cancellationToken.isCancelled) {
      _logger.info('Backup cancelled after creating tasks');
      return;
    }

    // 3. 执行上传编排
    _logger.info('Starting upload orchestration');
    final uploadResult = await _uploadService!.startUpload(
      userId: userId,
      cancellationToken: _cancellationToken,
      onProgress: (current, total) {
        _logger.fine('Upload progress: $current/$total');
        // 通过 Pigeon API 更新进度
        _backgroundHostApi.updateProgress(
          current,
          total,
          null, // 当前文件名（可选，后续可以从任务中获取）
        ).catchError((error) {
          _logger.warning('Failed to update progress: $error');
        });
      },
    );

    _logger.info(
      'Upload completed: success=${uploadResult.successCount}, '
      'failed=${uploadResult.failedCount}',
    );
  }

  /// 获取当前用户 ID
  /// 
  /// 从 StoreService 中读取 currentUser（JSON 字符串），解析为 UserProfile，返回 id
  Future<String?> _getCurrentUserId() async {
    try {
      final store = StoreService();
      if (!store.isInitialized) {
        _logger.warning('StoreService not initialized, cannot get current user ID');
        return null;
      }

      final userJson = store.get<String>(StoreKey.currentUser);
      if (userJson.isEmpty) {
        _logger.warning('No current user in store');
        return null;
      }

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      final user = UserProfile.fromJson(userMap);
      return user.id.toString();
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to get current user ID',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// 取消任务
  /// 
  /// 由原生平台通过 BackgroundWorkerFlutterApi.cancel() 调用
  /// 
  /// **职责**：
  /// - 取消正在执行的任务
  /// - 清理资源
  /// 
  /// **当前状态**：基础实现
  @override
  Future<void> cancel() async {
    _logger.warning('Background worker cancelled');
    try {
      _cancellationToken.cancel();
      await _cleanup();
    } catch (error, stackTrace) {
      _logger.severe(
        'Failed to cleanup background worker',
        error,
        stackTrace,
      );
    }
  }

  /// 清理资源
  /// 
  /// **职责**：
  /// - 取消所有进行中的任务
  /// - 关闭数据库连接
  /// - 释放 ProviderContainer
  /// - 销毁 Engine（由原生层处理）
  Future<void> _cleanup() async {
    if (_isCleanedUp) {
      return;
    }

    try {
      _isCleanedUp = true;
      _logger.info('Cleaning up background worker resources');

      // 1. 取消所有进行中的任务
      _cancellationToken.cancel();

      // 2. 关闭数据库连接
      // 注意：在后台 Engine 中，我们只是关闭当前连接的引用
      // 实际的数据库连接在 Isolate 中，不会被关闭
      // TODO: 根据实际需求决定是否需要关闭连接
      // if (_database != null) {
      //   await _database!.close();
      //   _database = null;
      // }

      // 3. 释放 ProviderContainer
      _container?.dispose();
      _container = null;

      // 4. 通知原生层任务完成
      await _backgroundHostApi.onCompleted();

      _logger.info('Background worker resources cleaned up');
    } catch (error, stackTrace) {
      _logger.severe(
        'Error during background worker cleanup',
        error,
        stackTrace,
      );
    }
  }
}

/// 后台任务入口点
/// 
/// 由原生平台调用，作为独立 Flutter Engine 的入口点
/// 
/// **注意**：
/// - 使用 @pragma('vm:entry-point') 确保不会被 tree-shaking 移除
/// - 此函数会被原生代码通过字符串名称调用
/// - 如果重命名或移动此函数，需要同时更新原生代码中的入口点配置
@pragma('vm:entry-point')
Future<void> backgroundSyncNativeEntrypoint() async {
  // 1. 初始化 Flutter 绑定
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. 初始化插件注册（如果需要在后台 Engine 中使用插件）
  // DartPluginRegistrant.ensureInitialized();
  
  // 3. 创建后台服务实例并初始化
  // 注意：BinaryMessenger 会自动从 ServicesBinding 获取
  final service = BackgroundWorkerBgService();
  await service.init();
}

