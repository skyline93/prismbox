// lib/ui/media/viewmodels/media_viewmodel.dart

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
        state = MediaState.data(media: entities);
      },
      onError: (e) {
        state = MediaState.error(error: "加载媒体时出错: $e");
      },
    );
  }

  Future<void> _initialize() async {
    _listenToMediaStream();

    try {
      // await _mediaRepository.loadAndIndexLocalMedia();
      // syncWithCloud();
    } catch (e) {
      state = MediaState.error(error: "初始化失败: $e");
    }
  }

  Future<void> syncWithCloud() async {
    if (_ref.read(isSyncingWithCloudProvider)) {
      return;
    }

    _ref.read(isSyncingWithCloudProvider.notifier).state = true;
    _ref.read(cloudSyncErrorProvider.notifier).state = null;

    try {
      await _mediaRepository.syncWithCloud();
      _ref.read(isSyncingWithCloudProvider.notifier).state = false;
    } catch (e) {
      _ref.read(isSyncingWithCloudProvider.notifier).state = false;
      _ref.read(cloudSyncErrorProvider.notifier).state = '与云端同步时发生错误，请稍后重试。';
    }
  }

  Future<void> retry() async {
    state = const MediaState.loading();
    await _initialize();
  }
}
