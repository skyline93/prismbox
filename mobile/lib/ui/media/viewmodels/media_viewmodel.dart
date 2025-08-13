// lib/ui/media/viewmodels/media_viewmodel.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/domain/repositories/media_repository.dart';
import 'package:mobile/ui/media/viewmodels/media_state.dart';

/// 媒体页面的 ViewModel，现在是 StateNotifier 的实现。
///
/// `StateNotifier` 是一个专门用于管理单一、不可变状态的类。
/// 它需要一个泛型参数来指定它所管理的状态类型，这里是 `MediaState`。
class MediaViewModel extends StateNotifier<MediaState> {
  final MediaRepository _mediaRepository;
  final Ref _ref; // Riverpod 的引用，用于读取其他 provider 或执行特殊操作

  StreamSubscription<dynamic>? _mediaSubscription;

  /// 构造函数
  ///
  /// 它接收 `MediaRepository` 作为依赖，并调用父类的构造函数来设置初始状态。
  MediaViewModel(this._mediaRepository, this._ref)
    // 【修改】确保初始状态与 MediaState 的定义一致，特别是包含新增的字段。
    : super(
        const MediaState(
          isLoading: false,
          media: [],
          isSyncingWithCloud: false,
        ),
      ) {
    // 【修改】将构造函数内的逻辑统一到一个初始化方法中，使结构更清晰。
    _initialize();

    // 使用 ref.onDispose 来自动取消订阅，防止内存泄漏。
    // 这是 Riverpod 相比于手动在 dispose() 中 cancel() 的一大优势。
    _ref.onDispose(() {
      print("MediaViewModel disposed. Cancelling stream subscription.");
      _mediaSubscription?.cancel();
    });
  }

  /// 1. 监听来自 Repository 的数据流
  void _listenToMediaStream() {
    print("MediaViewModel: 开始监听媒体数据流...");
    _mediaSubscription = _mediaRepository.getUnifiedMediaStream().listen(
      (entities) {
        print("MediaViewModel: 收到数据流更新，包含 ${entities.length} 个媒体项。");
        // 当收到新数据时，使用 copyWith 创建一个新的状态实例。
        // 这会通知所有监听者进行 UI 刷新。
        state = state.copyWith(
          media: entities,
          isLoading: false, // 【修改】统一使用 isInitialLoading 字段
        );
      },
      onError: (e) {
        print("MediaViewModel: 监听到错误: $e");
        state = state.copyWith(
          error: "加载媒体时出错: $e",
          isLoading: false, // 【修改】统一使用 isInitialLoading 字段
        );
      },
    );
  }

  /// 【修改】统一的初始化流程
  Future<void> _initialize() async {
    print("MediaViewModel: 开始初始化流程...");

    // 步骤 A: 立即开始监听数据库，确保任何变化都能被捕获
    _listenToMediaStream();

    try {
      // 步骤 B: 首先加载本地媒体，实现 "Local-First"
      await _mediaRepository.loadAndIndexLocalMedia();
      print("MediaViewModel: 本地媒体索引完成。");

      // 步骤 C: 本地加载完成后，在后台自动触发一次云端同步
      // 不使用 await，让它在后台运行，UI 不会被阻塞
      syncWithCloud();
    } catch (e) {
      print("MediaViewModel: 初始化加载时捕获到错误: $e");
      state = state.copyWith(error: "初始化失败: $e", isLoading: false);
    }
  }

  /// **【新增】触发与云端同步的公共核心方法**
  ///
  /// 这个方法既可以由初始化流程自动调用，也可以由用户的操作（如下拉刷新）手动调用。
  Future<void> syncWithCloud() async {
    // 防止在一次同步正在进行时，用户又触发了另一次同步
    if (state.isSyncingWithCloud) {
      print("ViewModel: 云端同步已在进行中，本次请求被忽略。");
      return;
    }

    print("ViewModel: 开始触发云端同步流程...");

    try {
      // 1. 更新UI状态，向用户反馈“同步正在进行”
      state = state.copyWith(isSyncingWithCloud: true, cloudSyncError: null);

      // 2. 调用 Repository 执行核心的同步逻辑
      await _mediaRepository.syncWithCloud();

      // 3. 同步成功，清除加载状态
      // 此时不需要手动更新 media 列表，因为数据库的变更会通过 _listenToMediaStream 自动更新UI
      state = state.copyWith(isSyncingWithCloud: false);
      print("ViewModel: 云端同步流程成功完成。");
    } catch (e) {
      // 4. 同步失败，记录错误信息并更新UI
      print("ViewModel: 云端同步流程捕获到错误: $e");
      state = state.copyWith(
        isSyncingWithCloud: false,
        cloudSyncError: '与云端同步时发生错误，请稍后重试。', // 提供对用户友好的错误信息
      );
    }
  }

  /// 重试方法 - 清除错误状态并重新初始化
  Future<void> retry() async {
    print("MediaViewModel: 用户触发重试...");
    
    // 清除错误状态
    state = state.copyWith(
      error: null,
      cloudSyncError: null,
      isLoading: true,
    );

    try {
      // 重新初始化
      await _initialize();
    } catch (e) {
      print("MediaViewModel: 重试失败: $e");
      state = state.copyWith(
        error: "重试失败: $e",
        isLoading: false,
      );
    }
  }
}
