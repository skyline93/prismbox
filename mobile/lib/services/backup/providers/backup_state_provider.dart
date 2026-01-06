// lib/services/backup/providers/backup_state_provider.dart

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/services/backup/backup_service.dart';
import 'package:prismbox/services/backup/upload_service.dart';
import 'package:prismbox/services/backup/providers/backup_providers.dart';
import 'package:prismbox/services/backup/backup_state_refresh_service.dart';

/// 备份状态状态机
enum BackupStateStatus {
  /// 初始状态
  initial,

  /// 加载中
  loading,

  /// 已加载
  loaded,

  /// 错误状态
  error,
}

/// 备份状态
///
/// 使用状态机模式管理状态，确保状态转换的一致性
class BackupState {
  final BackupCounts? counts;
  final List<UploadTaskDetail> activeTasks;
  final UploadTaskDetail? currentTask;
  final BackupStateStatus status;
  final String? errorMessage;

  BackupState({
    this.counts,
    this.activeTasks = const [],
    this.currentTask,
    this.status = BackupStateStatus.initial,
    this.errorMessage,
  });

  /// 是否正在加载
  bool get isLoading => status == BackupStateStatus.loading;

  /// 是否有错误
  bool get hasError => status == BackupStateStatus.error;

  /// 是否正在备份
  bool get isBackingUp => activeTasks.isNotEmpty;

  BackupState copyWith({
    BackupCounts? counts,
    List<UploadTaskDetail>? activeTasks,
    UploadTaskDetail? currentTask,
    BackupStateStatus? status,
    String? errorMessage,
    bool? clearError,
  }) {
    return BackupState(
      counts: counts ?? this.counts,
      activeTasks: activeTasks ?? this.activeTasks,
      currentTask: currentTask ?? this.currentTask,
      status: status ?? this.status,
      errorMessage: clearError == true
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 备份状态 Notifier
///
/// **职责**：
/// - 管理备份状态和业务逻辑
/// - 提供状态刷新接口
/// - 不管理定时器（由 BackupStateRefreshService 负责）
///
/// **设计改进**：
/// - 通过构造函数注入服务，确保服务已初始化
/// - 移除 _initialize() 方法，简化初始化逻辑
/// - 使用状态机模式管理状态
class BackupStateNotifier extends StateNotifier<BackupState> {
  final Ref _ref;
  final BackupService _backupService;
  final UploadService _uploadService;
  final BackupStateRefreshService _refreshService;
  StreamSubscription? _uploadStatusSubscription;
  String? _currentUserId;
  bool _isDisposed = false;
  final Logger _logger = Logger('BackupStateNotifier');

  BackupStateNotifier._(
    this._ref,
    this._backupService,
    this._uploadService,
    this._refreshService,
  ) : super(BackupState()) {
    // 使用 ref.onDispose 自动管理生命周期
    _ref.onDispose(() {
      _isDisposed = true;
      _refreshService.dispose();
      _uploadStatusSubscription?.cancel();
      _uploadStatusSubscription = null;
    });
  }

  /// 设置用户 ID 并开始刷新
  ///
  /// 这个方法会启动定时器，定期刷新状态
  /// 生命周期由 Provider 自动管理（通过 ref.onDispose）
  void setUserId(String userId) {
    if (_isDisposed || _currentUserId == userId) {
      return;
    }

    _currentUserId = userId;

    // 如果还没有数据，设置加载状态
    if (state.status == BackupStateStatus.initial) {
      state = state.copyWith(status: BackupStateStatus.loading);
    }

    // 启动刷新服务（异步调用，但不等待，让它在后台执行）
    _refreshService.start(userId, this).catchError((e, stackTrace) {
      _logger.warning('Failed to start refresh service', e, stackTrace);
    });
    // 监听上传任务状态变化
    listenToUploadStatus();
  }

  /// 刷新备份状态
  ///
  /// 这个方法只负责获取数据并更新状态，不管理定时器
  Future<void> refresh(String userId) async {
    if (_isDisposed) {
      return;
    }

    _currentUserId = userId;

    // 设置加载状态
    state = state.copyWith(status: BackupStateStatus.loading, clearError: true);

    try {
      // 1. 获取备份统计信息
      final counts = await _backupService.getBackupCounts(userId);

      if (_isDisposed) return;

      // 2. 获取当前上传任务
      final activeTasks = await _uploadService.getActiveUploadTasks(userId);

      if (_isDisposed) return;

      // 3. 更新状态（成功）
      state = state.copyWith(
        counts: counts,
        activeTasks: activeTasks,
        currentTask: activeTasks.isNotEmpty ? activeTasks.first : null,
        status: BackupStateStatus.loaded,
        clearError: true,
      );
    } catch (e, stackTrace) {
      if (_isDisposed) return;

      // 记录错误日志
      _logger.severe('Failed to refresh backup state', e, stackTrace);

      // 设置错误状态
      state = state.copyWith(
        status: BackupStateStatus.error,
        errorMessage: _formatErrorMessage(e),
      );
    }
  }

  /// 格式化错误信息
  String _formatErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return '网络错误，请检查网络连接';
    } else if (errorString.contains('timeout')) {
      return '请求超时，请稍后重试';
    } else if (errorString.contains('unauthorized') ||
        errorString.contains('401')) {
      return '认证失败，请重新登录';
    } else if (errorString.contains('forbidden') ||
        errorString.contains('403')) {
      return '权限不足';
    } else if (errorString.contains('server') || errorString.contains('500')) {
      return '服务器错误，请稍后重试';
    } else {
      return '加载失败：${error.toString()}';
    }
  }

  /// 停止刷新
  ///
  /// 注意：通常不需要手动调用，Provider 会自动管理生命周期
  /// 只有在特殊情况下（如用户手动停止）才需要调用
  void stopRefresh() {
    _refreshService.stop();
  }

  /// 监听上传任务状态变化
  ///
  /// 目前使用定时器轮询（由 BackupStateRefreshService 管理）
  /// 未来可以扩展为使用 Stream 实时监听
  void listenToUploadStatus() {
    _uploadStatusSubscription?.cancel();

    // TODO: 实现 Stream 监听
    // 如果 UploadService 提供 Stream，使用 Stream
    // 否则使用定期轮询（由 BackupStateRefreshService 管理）
  }

  @override
  void dispose() {
    _isDisposed = true;
    _refreshService.dispose();
    _uploadStatusSubscription?.cancel();
    _uploadStatusSubscription = null;
    super.dispose();
  }

  // 保留旧的 startListening/stopListening 作为兼容方法（已废弃）
  @Deprecated('使用 setUserId 代替，生命周期由 Provider 自动管理')
  void startListening(String userId) {
    setUserId(userId);
  }

  @Deprecated('使用 stopRefresh 代替，或让 Provider 自动管理')
  void stopListening() {
    stopRefresh();
  }
}

/// 服务就绪检查 Provider
///
/// 确保 BackupService 和 UploadService 都已初始化完成
/// 如果服务初始化失败，会抛出异常
///
/// **注意**：FutureProvider 如果返回 null，说明服务初始化失败，会抛出异常
final backupServicesReadyProvider = FutureProvider<void>((ref) async {
  try {
    // 等待服务初始化完成
    // 如果服务初始化失败，这里会抛出异常
    await ref.watch(backupServiceProvider.future);
    await ref.watch(uploadServiceProvider.future);
  } catch (e, stackTrace) {
    Logger(
      'BackupServicesReady',
    ).severe('Failed to initialize backup services', e, stackTrace);
    rethrow;
  }
});

/// 备份状态 Provider
///
/// 使用 family 来参数化 userId，每个用户有独立的状态实例
/// 生命周期由 Riverpod 自动管理（autoDispose）
///
/// **设计改进**：
/// - 等待服务就绪后再创建 Notifier
/// - 通过构造函数注入服务，确保服务已初始化
/// - 每个 Notifier 使用独立的 RefreshService 实例
///
/// **注意**：
/// - 如果服务还在加载中，ref.watch 会等待服务加载完成
/// - 如果服务加载失败，会抛出异常，Riverpod 会处理错误状态
///
/// **使用方式**：
/// ```dart
/// final backupState = ref.watch(backupStateProvider(userId));
/// ```
final backupStateProvider = StateNotifierProvider.autoDispose
    .family<BackupStateNotifier, BackupState, String>((ref, userId) {
      // 等待服务就绪（ref.watch 会等待 FutureProvider 完成）
      // 如果服务还在加载，ref.watch 会等待；如果失败，会抛出异常
      // 注意：如果服务还在加载，这里会阻塞，但 Riverpod 会正确处理这种情况
      final servicesReady = ref.watch(backupServicesReadyProvider);

      // 如果服务还在加载或失败，Riverpod 会处理错误状态
      // 但为了安全起见，我们检查一下
      if (servicesReady.isLoading) {
        // 这种情况不应该发生，因为 ref.watch 会等待
        // 但如果发生了，我们抛出一个异常，让 Riverpod 处理
        throw StateError('Backup services are still loading');
      }

      if (servicesReady.hasError) {
        // 服务初始化失败，抛出异常
        throw servicesReady.error!;
      }

      // 获取服务（此时已确保初始化完成）
      final backupServiceAsync = ref.watch(backupServiceProvider);
      final uploadServiceAsync = ref.watch(uploadServiceProvider);

      // 此时服务应该已经加载完成（因为 backupServicesReadyProvider 已经完成）
      final backupService = backupServiceAsync.value;
      final uploadService = uploadServiceAsync.value;

      if (backupService == null || uploadService == null) {
        // 这种情况不应该发生，但为了安全起见
        throw StateError(
          'Backup services not available. '
          'This should not happen if backupServicesReadyProvider completed successfully.',
        );
      }

      // 每个 Notifier 使用独立的 RefreshService 实例
      final refreshService = BackupStateRefreshService();

      // 创建 Notifier（服务已就绪，可以安全使用）
      final notifier = BackupStateNotifier._(
        ref,
        backupService,
        uploadService,
        refreshService,
      );

      // 立即设置 userId（服务已就绪，可以安全调用）
      // 使用 addPostFrameCallback 确保在 Widget 构建完成后执行
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.setUserId(userId);
      });

      return notifier;
    });
