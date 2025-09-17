// lib/ui/media/viewmodels/media_viewmodel.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/repositories/media_repository.dart';
import 'package:mobile/ui/media/viewmodels/media_state.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';

class MediaViewModel extends StateNotifier<MediaState> {
  final MediaRepository _mediaRepository;
  StreamSubscription<dynamic>? _mediaSubscription;

  MediaViewModel(this._mediaRepository) : super(const MediaState.loading()) {
    _listenToMediaStream();
  }

  void _listenToMediaStream() {
    state = const MediaState.loading();
    _mediaSubscription = _mediaRepository.getUnifiedMediaStream().listen(
      (entities) {
        state = MediaState.data(media: entities);
      },
      onError: (e) {
        state = MediaState.error(error: "加载媒体流时出错: $e");
      },
    );
  }

  /// 将指定的媒体资源移动到回收站
  Future<void> moveAssetsToTrash(List<UnifiedMediaEntity> assets) async {
    await _mediaRepository.moveAssetsToTrash(assets);
  }

  Future<void> retry() async {
    _mediaSubscription?.cancel();
    _listenToMediaStream();
  }

  @override
  void dispose() {
    _mediaSubscription?.cancel();
    super.dispose();
  }
}
