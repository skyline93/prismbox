// lib/services/backup/providers/backup_state_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/services/backup/backup_service.dart';
import 'package:prismbox/services/backup/upload_service.dart';
import 'package:prismbox/services/backup/providers/backup_providers.dart';

/// 备份状态
class BackupState {
  final BackupCounts? counts;
  final List<UploadTaskDetail> activeTasks;
  final UploadTaskDetail? currentTask;
  final bool isBackingUp;
  final bool hasError;
  final String? errorMessage;
  final bool isLoading;
  
  BackupState({
    this.counts,
    this.activeTasks = const [],
    this.currentTask,
    this.isBackingUp = false,
    this.hasError = false,
    this.errorMessage,
    this.isLoading = false,
  });
  
  BackupState copyWith({
    BackupCounts? counts,
    List<UploadTaskDetail>? activeTasks,
    UploadTaskDetail? currentTask,
    bool? isBackingUp,
    bool? hasError,
    String? errorMessage,
    bool? isLoading,
  }) {
    return BackupState(
      counts: counts ?? this.counts,
      activeTasks: activeTasks ?? this.activeTasks,
      currentTask: currentTask ?? this.currentTask,
      isBackingUp: isBackingUp ?? this.isBackingUp,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// 备份状态 Notifier
class BackupStateNotifier extends StateNotifier<BackupState> {
  final Ref _ref;
  BackupService? _backupService;
  UploadService? _uploadService;
  StreamSubscription? _uploadStatusSubscription;
  Timer? _refreshTimer;
  String? _currentUserId;
  
  BackupStateNotifier._(this._ref) : super(BackupState()) {
    _initialize();
  }
  
  /// 初始化服务
  Future<void> _initialize() async {
    final backupServiceAsync = _ref.watch(backupServiceProvider);
    final uploadServiceAsync = _ref.watch(uploadServiceProvider);
    
    // 等待服务加载完成
    if (backupServiceAsync is! AsyncData) {
      await backupServiceAsync.when(
        data: (service) {
          _backupService = service;
        },
        loading: () async {
          // 等待加载完成，最多等待 5 秒
          for (int i = 0; i < 50; i++) {
            await Future.delayed(const Duration(milliseconds: 100));
            final current = _ref.read(backupServiceProvider);
            if (current is AsyncData) {
              _backupService = current.value;
              break;
            }
          }
        },
        error: (_, __) {},
      );
    } else {
      _backupService = backupServiceAsync.value;
    }
    
    if (uploadServiceAsync is! AsyncData) {
      await uploadServiceAsync.when(
        data: (service) {
          _uploadService = service;
        },
        loading: () async {
          // 等待加载完成，最多等待 5 秒
          for (int i = 0; i < 50; i++) {
            await Future.delayed(const Duration(milliseconds: 100));
            final current = _ref.read(uploadServiceProvider);
            if (current is AsyncData) {
              _uploadService = current.value;
              break;
            }
          }
        },
        error: (_, __) {},
      );
    } else {
      _uploadService = uploadServiceAsync.value;
    }
  }
  
  /// 刷新备份状态
  Future<void> refresh(String userId) async {
    _currentUserId = userId;
    
    // 确保服务已初始化
    if (_backupService == null || _uploadService == null) {
      await _initialize();
      if (_backupService == null || _uploadService == null) {
        state = state.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: 'Services not available',
        );
        return;
      }
    }
    
    state = state.copyWith(isLoading: true);
    
    try {
      // 1. 获取备份统计信息
      final counts = await _backupService!.getBackupCounts(userId);
      
      // 2. 获取当前上传任务
      final activeTasks = await _uploadService!.getActiveUploadTasks(userId);
      
      // 3. 更新状态
      state = state.copyWith(
        counts: counts,
        activeTasks: activeTasks,
        currentTask: activeTasks.isNotEmpty ? activeTasks.first : null,
        isBackingUp: activeTasks.isNotEmpty,
        isLoading: false,
        hasError: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: e.toString(),
      );
    }
  }
  
  /// 开始监听上传任务状态变化
  void startListening(String userId) async {
    _currentUserId = userId;
    
    // 确保服务已初始化
    if (_backupService == null || _uploadService == null) {
      await _initialize();
    }
    
    // 立即刷新一次
    await refresh(userId);
    
    // 定期刷新状态（每 1 秒，更频繁地更新）
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (_currentUserId != null) {
          refresh(_currentUserId!);
        }
      },
    );
    
    // 监听上传任务状态变化
    listenToUploadStatus();
  }
  
  /// 停止监听
  void stopListening() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _uploadStatusSubscription?.cancel();
    _uploadStatusSubscription = null;
  }
  
  /// 监听上传任务状态变化
  void listenToUploadStatus() {
    _uploadStatusSubscription?.cancel();
    
    // TODO: 实现 Stream 监听
    // 如果 UploadService 提供 Stream，使用 Stream
    // 否则使用定期轮询（已在 startListening 中实现）
  }
  
  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}

/// 备份状态 Provider
/// 
/// 注意：由于 backupServiceProvider 和 uploadServiceProvider 是 FutureProvider,
/// 我们需要在 StateNotifier 的 build 方法中处理异步加载
final backupStateProvider = StateNotifierProvider.autoDispose<BackupStateNotifier, BackupState>((ref) {
  // 延迟初始化，在 build 方法中处理
  final notifier = BackupStateNotifier._(ref);
  return notifier;
});

