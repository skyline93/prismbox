import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/domain/repositories/media_repository.dart';
import 'package:mobile/ui/media/viewmodels/timeline_state.dart';

/// 时间线页面的 ViewModel，现在是 StateNotifier 的实现。
///
/// `StateNotifier` 是一个专门用于管理单一、不可变状态的类。
/// 它需要一个泛型参数来指定它所管理的状态类型，这里是 `TimelineState`。
class TimelineViewModel extends StateNotifier<TimelineState> {
  final MediaRepository _mediaRepository;
  final Ref _ref; // Riverpod 的引用，用于读取其他 provider 或执行特殊操作

  StreamSubscription<dynamic>? _mediaSubscription;

  /// 构造函数
  ///
  /// 它接收 `MediaRepository` 作为依赖，并调用父类的构造函数来设置初始状态。
  TimelineViewModel(this._mediaRepository, this._ref)
    : super(TimelineState.initial()) {
    // 在 ViewModel 被创建时，立即开始执行核心逻辑。
    _listenToMediaStream();
    _triggerInitialLoad();

    // 使用 ref.onDispose 来自动取消订阅，防止内存泄漏。
    // 这是 Riverpod 相比于手动在 dispose() 中 cancel() 的一大优势。
    _ref.onDispose(() {
      print("TimelineViewModel disposed. Cancelling stream subscription.");
      _mediaSubscription?.cancel();
    });
  }

  /// 1. 监听来自 Repository 的数据流
  void _listenToMediaStream() {
    print("TimelineViewModel: 开始监听媒体数据流...");
    _mediaSubscription = _mediaRepository.getUnifiedMediaStream().listen(
      (entities) {
        print("TimelineViewModel: 收到数据流更新，包含 ${entities.length} 个媒体项。");
        // 当收到新数据时，使用 copyWith 创建一个新的状态实例。
        // 这会通知所有监听者进行 UI 刷新。
        state = state.copyWith(
          media: entities,
          isLoading: false, // 收到数据后，不再是加载状态
        );
      },
      onError: (e) {
        print("TimelineViewModel: 监听到错误: $e");
        state = state.copyWith(error: "加载媒体时出错: $e", isLoading: false);
      },
    );
  }

  /// 2. 触发首次的本地媒体加载和索引
  Future<void> _triggerInitialLoad() async {
    print("TimelineViewModel: 触发首次本地媒体扫描...");
    try {
      // 这个调用是“即发即忘”的，它的结果会通过上面的流来更新状态。
      await _mediaRepository.loadAndIndexLocalMedia();
      print("TimelineViewModel: 本地媒体扫描任务已成功启动。");
    } catch (e) {
      print("ViewModel: 启动本地扫描时捕获到错误: $e");
      state = state.copyWith(error: "无法启动本地媒体扫描: $e", isLoading: false);
    }
  }
}
