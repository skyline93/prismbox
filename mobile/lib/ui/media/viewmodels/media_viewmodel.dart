import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/domain/repositories/media_repository.dart';
import 'package:mobile/ui/media/viewmodels/media_state.dart';

final isSyncingWithCloudProvider = StateProvider<bool>((ref) => false);
final cloudSyncErrorProvider = StateProvider<String?>((ref) => null);

class MediaViewModel extends StateNotifier<MediaState> {
  final MediaRepository _mediaRepository;
  final Ref _ref;

  StreamSubscription<dynamic>? _mediaSubscription;

  // 初始状态现在是 loading()
  MediaViewModel(this._mediaRepository, this._ref)
    : super(const MediaState.loading()) {
    _initialize();

    _ref.onDispose(() {
      _mediaSubscription?.cancel();
    });
  }

  void _listenToMediaStream() {
    _mediaSubscription = _mediaRepository.getUnifiedMediaStream().listen(
      (entities) {
        // 当收到数据时，转换为 data 状态
        state = MediaState.data(media: entities);
      },
      onError: (e) {
        // 当流发生错误时，转换为 error 状态
        state = MediaState.error(error: "加载媒体时出错: $e");
      },
    );
  }

  Future<void> _initialize() async {
    // 初始状态已经是 loading，所以这里不需要再设置
    _listenToMediaStream();

    try {
      await _mediaRepository.loadAndIndexLocalMedia();
      // 本地加载完成后，在后台触发云同步
      syncWithCloud();
    } catch (e) {
      // 初始化失败，转换为 error 状态
      state = MediaState.error(error: "初始化失败: $e");
    }
  }

  /// 触发与云端同步的方法
  Future<void> syncWithCloud() async {
    // 从独立的 Provider 读取状态，而不是从 MediaState
    if (_ref.read(isSyncingWithCloudProvider)) {
      return;
    }

    // 使用 ref.read(provider.notifier) 来更新 Provider 的状态
    _ref.read(isSyncingWithCloudProvider.notifier).state = true;
    _ref.read(cloudSyncErrorProvider.notifier).state = null;

    try {
      await _mediaRepository.syncWithCloud();
      // 同步成功，重置状态
      _ref.read(isSyncingWithCloudProvider.notifier).state = false;
    } catch (e) {
      // 同步失败，更新错误 Provider 并重置加载状态
      _ref.read(isSyncingWithCloudProvider.notifier).state = false;
      _ref.read(cloudSyncErrorProvider.notifier).state = '与云端同步时发生错误，请稍后重试。';
    }
  }

  Future<void> retry() async {
    // 重试时，将状态重置为 loading 并重新初始化
    state = const MediaState.loading();
    await _initialize();
  }
}
