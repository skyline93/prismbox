// lib/features/background_backup/service/background_worker_bg_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer' show Timeline;
import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/connection.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/utils/cancellation_token.dart';
import 'package:prismbox/platform/background_worker_api.g.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/core/storage/store_key.dart';
import 'package:prismbox/domain/entities/user_profile.dart';
import 'package:prismbox/services/backup/providers/backup_providers.dart' as backup;
import 'package:prismbox/services/backup/backup_service.dart';
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
  
  /// 上传服务
  UploadService? _uploadService;
  
  /// 后台 Host API（用于通知原生层）
  final BackgroundWorkerBgHostApi _backgroundHostApi;
  
  /// 后台通信通道（用于接收系统停止信号）
  static const MethodChannel _backgroundChannel = MethodChannel('prismbox/backgroundChannel');
  
  /// 取消令牌，用于取消正在执行的任务
  final CancellationToken _cancellationToken = CancellationToken();
  
  /// 是否被系统取消
  bool _canceledBySystem = false;
  
  /// 日志记录器
  final Logger _logger = Logger('BackgroundWorkerBgService');
  
  /// 是否已清理
  bool _isCleanedUp = false;
  
  /// 进度更新定时器
  Timer? _progressUpdateTimer;
  
  /// 总任务数（用于进度计算）
  int _totalTaskCount = 0;
  
  /// 锁相关变量（用于防止前台和后台同时执行备份）
  static const String _portNameLock = "prismboxLock";
  bool _hasLock = false;
  int _wantsLockTime = 0;
  SendPort? _waitingIsolate;
  ReceivePort? _rp;

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
  /// - 设置后台通道监听
  /// - 通知原生层初始化完成
  Future<void> init() async {
    try {
      _logger.info('Initializing background worker service');

      // 1. 设置后台通道监听（用于接收系统停止信号）
      _backgroundChannel.setMethodCallHandler(_callHandler);

      // 2. 初始化数据库连接
      // 在后台 Engine 中，数据库连接会连接到主应用创建的 Isolate
      _database = await DatabaseConnection.getInstance();
      
      // 3. 创建独立的 ProviderContainer
      // 这允许我们在后台 Engine 中使用 Riverpod Provider
      _container = ProviderContainer(
        overrides: [
          // 数据库 Provider
          infra.databaseProvider.overrideWith((ref) async => _database!),
        ],
      );

      // 4. 初始化服务（通过 Provider 获取）
      // 注意：这些 providers 是 AutoDisposeFutureProvider，需要使用 .future 获取 Future
      // 不再需要 BackgroundSyncManager，因为前台同步已负责填充数据库表
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
  
  /// 处理后台通道的方法调用
  Future<dynamic> _callHandler(MethodCall call) async {
    switch (call.method) {
      case "systemStop":
        _logger.warning('Received systemStop signal from native');
        _canceledBySystem = true;
        _cancellationToken.cancel();
        return true;
      default:
        _logger.warning('Unknown method: ${call.method}');
        return false;
    }
  }

  /// Android 后台上传任务执行
  /// 
  /// 由原生平台通过 BackgroundWorkerFlutterApi.onAndroidUpload() 调用
  /// 
  /// **执行流程**：
  /// 1. 获取锁（防止前台和后台同时执行）
  /// 2. 获取当前用户 ID
  /// 3. 检查备份是否启用
  /// 4. 循环执行备份，直到没有新内容变化
  /// 5. 释放锁
  @override
  Future<void> onAndroidUpload() async {
    _logger.info('Android background upload started');
    final stopwatch = Stopwatch()..start();
    
    try {
      // 1. 获取锁（防止前台和后台同时执行备份）
      final hasLock = await acquireLock();
      if (!hasLock) {
        _logger.warning('Could not acquire lock, another backup may be running');
        return;
      }

      try {
        // 2. 循环执行备份，直到没有新内容变化
        do {
          final bool backupOk = await _executeBackup();
          if (!backupOk) {
            break; // 备份失败，退出循环
          }
          
          // 检查是否有新内容变化（Android 专用）
          final hasChanged = await _backgroundHostApi.hasContentChanged();
          if (!hasChanged) {
            break; // 没有新内容，退出循环
          }
          
          _logger.info('New content detected during backup, continuing...');
        } while (true);
        
        _logger.info('Android background upload completed successfully');
      } finally {
        // 释放锁
        releaseLock();
      }
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
  
  /// 执行备份流程
  Future<bool> _executeBackup() async {
    // 检查是否被系统取消
    if (_canceledBySystem) {
      _logger.info('Backup cancelled by system');
      return false;
    }
    
    // 1. 获取当前用户 ID
    final userId = await _getCurrentUserId();
    if (userId == null) {
      _logger.warning('No authenticated user, skipping backup');
      return false;
    }

    // 2. 检查备份是否启用
    final backupStatus = await _backupService!.getBackupStatus(userId);
    if (backupStatus == null || !backupStatus.enabled) {
      _logger.info('Backup is disabled for userId=$userId');
      return false;
    }

    // 3. 跳过同步阶段 - 前台同步已经负责填充 local_asset_entity 和 remote_asset_entity 表
    // 后台备份只需要基于这些表执行备份即可
    _logger.info('Skipping sync phase - relying on foreground sync data');

    // 可选：记录数据库状态（用于调试）
    final localDao = _database!.localAssetDao;
    final localAssetCount = (await localDao.getAllAssets()).length;
    _logger.fine('Local assets in database: $localAssetCount');

    if (_cancellationToken.isCancelled || _canceledBySystem) {
      _logger.info('Backup cancelled before backup phase');
      return false;
    }

    // 4. 执行自动备份（创建上传任务）
    _logger.info('Starting auto backup');
    await _backupService!.startAutoBackup(userId);

    if (_cancellationToken.isCancelled || _canceledBySystem) {
      _logger.info('Backup cancelled after creating tasks');
      return false;
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
    
    return uploadResult.successCount > 0 || uploadResult.failedCount == 0;
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
        // 刷新任务：跳过同步步骤 - 前台同步会定期执行，后台刷新任务不需要再次同步
        _logger.info('Skipping sync for refresh task - relying on foreground sync');
        backupFuture = Future.value(null);
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
    // 1. 跳过同步阶段 - 前台同步已经负责填充数据库表
    _logger.info('Skipping sync phase - relying on foreground sync data');

    // 可选：记录数据库状态（用于调试）
    final localDao = _database!.localAssetDao;
    final localAssetCount = (await localDao.getAllAssets()).length;
    _logger.fine('Local assets in database: $localAssetCount');

    if (_cancellationToken.isCancelled) {
      _logger.info('Backup cancelled before backup phase');
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
    
    // 先查询总任务数
    try {
      if (_database != null) {
        final pendingTasks = await _database!.uploadTaskDao
            .getPendingTasksByUserId(userId);
        _totalTaskCount = pendingTasks.length;
        _logger.info('Total tasks to upload: $_totalTaskCount');
        
        // 立即发送初始进度（0/total）
        _backgroundHostApi.updateProgress(
          0,
          _totalTaskCount,
          null,
        ).catchError((error) {
          _logger.warning('Failed to send initial progress: $error');
        });
      }
    } catch (e) {
      _logger.warning('Failed to get total task count: $e');
    }
    
    // 启动定期进度更新（每2秒更新一次）
    _startProgressUpdateTimer(userId);
    
    // 用于跟踪当前正在上传的文件名
    String? currentFileName;
    
    try {
      final uploadResult = await _uploadService!.startUpload(
        userId: userId,
        cancellationToken: _cancellationToken,
        onProgress: (current, total) async {
          _logger.fine('Upload progress callback: $current/$total');
          
          // 更新总任务数（以防任务数变化）
          _totalTaskCount = total;
          
          // 尝试获取当前正在上传的文件名
          if (currentFileName == null || current > 0) {
            try {
              // 从数据库中查询当前正在上传的任务
              if (_database != null) {
                final uploadingTasks = await _database!.uploadTaskDao
                    .getTasksByUserIdAndStatus(userId, UploadTaskStatus.uploading);
                
                if (uploadingTasks.isNotEmpty) {
                  final currentTask = uploadingTasks.first;
                  // 从本地路径中提取文件名
                  final pathParts = currentTask.localPath.split('/');
                  currentFileName = pathParts.isNotEmpty ? pathParts.last : null;
                }
              }
            } catch (e) {
              _logger.warning('Failed to get current file name: $e');
            }
          }
          
          // 通过 Pigeon API 更新进度
          _backgroundHostApi.updateProgress(
            current,
            total,
            currentFileName,
          ).catchError((error) {
            _logger.warning('Failed to update progress: $error');
          });
        },
      );

      _logger.info(
        'Upload completed: success=${uploadResult.successCount}, '
        'failed=${uploadResult.failedCount}',
      );
    } finally {
      // 停止进度更新定时器
      _stopProgressUpdateTimer();
    }
  }

  /// 启动进度更新定时器
  /// 定期查询任务状态并更新通知
  void _startProgressUpdateTimer(String userId) {
    // 如果已有定时器，先停止
    _stopProgressUpdateTimer();
    
    _logger.info('Starting progress update timer');
    
    // 每2秒更新一次进度
    _progressUpdateTimer = Timer.periodic(
      const Duration(seconds: 2),
      (timer) async {
        if (_isCleanedUp || _cancellationToken.isCancelled) {
          timer.cancel();
          return;
        }
        
        try {
          await _updateProgressFromDatabase(userId);
        } catch (e) {
          _logger.warning('Failed to update progress from database: $e');
        }
      },
    );
  }
  
  /// 停止进度更新定时器
  void _stopProgressUpdateTimer() {
    _progressUpdateTimer?.cancel();
    _progressUpdateTimer = null;
    _logger.info('Stopped progress update timer');
  }
  
  /// 从数据库查询任务状态并更新进度
  Future<void> _updateProgressFromDatabase(String userId) async {
    if (_database == null) {
      return;
    }
    
    try {
      // 查询已完成的任务数
      final completedTasks = await _database!.uploadTaskDao
          .getTasksByUserIdAndStatus(userId, UploadTaskStatus.completed);
      final completedCount = completedTasks.length;
      
      // 如果总任务数为0，尝试重新查询
      if (_totalTaskCount == 0) {
        final pendingTasks = await _database!.uploadTaskDao
            .getPendingTasksByUserId(userId);
        final uploadingTasks = await _database!.uploadTaskDao
            .getTasksByUserIdAndStatus(userId, UploadTaskStatus.uploading);
        final queuedTasks = await _database!.uploadTaskDao
            .getTasksByUserIdAndStatus(userId, UploadTaskStatus.queued);
        _totalTaskCount = pendingTasks.length + uploadingTasks.length + 
                         queuedTasks.length + completedCount;
      }
      
      // 如果总任务数仍为0，不更新
      if (_totalTaskCount == 0) {
        return;
      }
      
      // 获取当前正在上传的文件名
      String? currentFileName;
      final uploadingTasks = await _database!.uploadTaskDao
          .getTasksByUserIdAndStatus(userId, UploadTaskStatus.uploading);
      
      if (uploadingTasks.isNotEmpty) {
        final currentTask = uploadingTasks.first;
        final pathParts = currentTask.localPath.split('/');
        currentFileName = pathParts.isNotEmpty ? pathParts.last : null;
      }
      
      // 更新进度通知
      _backgroundHostApi.updateProgress(
        completedCount,
        _totalTaskCount,
        currentFileName,
      ).catchError((error) {
        _logger.warning('Failed to update progress from timer: $error');
      });
      
      _logger.fine(
        'Progress updated from database: $completedCount/$_totalTaskCount',
      );
    } catch (e) {
      _logger.warning('Error updating progress from database: $e');
    }
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
      releaseLock(); // 释放锁
      await _cleanup();
    } catch (error, stackTrace) {
      _logger.severe(
        'Failed to cleanup background worker',
        error,
        stackTrace,
      );
    }
  }
  
  /// 获取锁（防止前台和后台同时执行备份）
  Future<bool> acquireLock() async {
    if (_hasLock) {
      _logger.warning('Lock already acquired');
      return true;
    }
    
    final int lockTime = Timeline.now;
    _wantsLockTime = lockTime;
    final ReceivePort rp = ReceivePort(_portNameLock);
    _rp = rp;
    final SendPort sp = rp.sendPort;

    while (!IsolateNameServer.registerPortWithName(sp, _portNameLock)) {
      try {
        await _checkLockReleasedWithHeartbeat(lockTime);
      } catch (error) {
        _logger.warning('Error checking lock: $error');
        return false;
      }
      if (_wantsLockTime != lockTime) {
        return false;
      }
    }
    _hasLock = true;
    rp.listen(_heartbeatListener);
    _logger.info('Lock acquired successfully');
    return true;
  }

  /// 检查锁是否已释放（通过心跳机制）
  Future<void> _checkLockReleasedWithHeartbeat(final int lockTime) async {
    SendPort? other = IsolateNameServer.lookupPortByName(_portNameLock);
    if (other != null) {
      final ReceivePort tempRp = ReceivePort();
      final SendPort tempSp = tempRp.sendPort;
      final bs = tempRp.asBroadcastStream();
      
      while (_wantsLockTime == lockTime) {
        other.send(tempSp);
        final dynamic answer = await bs.first.timeout(
          const Duration(seconds: 3),
          onTimeout: () => null,
        );
        
        if (_wantsLockTime != lockTime) {
          break;
        }
        
        if (answer == null) {
          // 其他 isolate 没有响应，假设它已退出但没有释放锁
          if (other == IsolateNameServer.lookupPortByName(_portNameLock)) {
            IsolateNameServer.removePortNameMapping(_portNameLock);
          }
          break;
        } else if (answer == true) {
          // 其他 isolate 释放了锁
          break;
        } else if (answer == false) {
          // 其他 isolate 仍在运行
        }
        
        final dynamic isFinished = await bs.first.timeout(
          const Duration(seconds: 3),
          onTimeout: () => false,
        );
        if (isFinished == true) {
          break;
        }
      }
      tempRp.close();
    }
  }

  /// 心跳监听器
  void _heartbeatListener(dynamic msg) {
    if (msg is SendPort) {
      _waitingIsolate = msg;
      msg.send(false); // 表示仍在运行
    }
  }

  /// 释放锁
  void releaseLock() {
    _wantsLockTime = 0;
    if (_hasLock) {
      IsolateNameServer.removePortNameMapping(_portNameLock);
      _waitingIsolate?.send(true); // 通知等待的 isolate 锁已释放
      _waitingIsolate = null;
      _hasLock = false;
      _logger.info('Lock released');
    }
    _rp?.close();
    _rp = null;
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

      // 3. 停止进度更新定时器
      _stopProgressUpdateTimer();

      // 4. 释放 ProviderContainer
      _container?.dispose();
      _container = null;

      // 5. 清理服务引用
      _backupService = null;
      _uploadService = null;
      _database = null;
      _totalTaskCount = 0;
      
      // 6. 释放锁（如果还有）
      releaseLock();

      // 7. 通知原生层任务完成
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

