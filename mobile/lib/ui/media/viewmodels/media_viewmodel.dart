// lib/ui/media/viewmodels/media_viewmodel.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/repositories/media_repository.dart';
import 'package:mobile/ui/media/viewmodels/media_state.dart';

// [*] These global state providers are no longer needed and should be deleted.
// final isSyncingWithCloudProvider = StateProvider<bool>((ref) => false);
// final cloudSyncErrorProvider = StateProvider<String?>((ref) => null);

class MediaViewModel extends StateNotifier<MediaState> {
  final MediaRepository _mediaRepository;
  StreamSubscription<dynamic>? _mediaSubscription;

  MediaViewModel(this._mediaRepository) : super(const MediaState.loading()) {
    _listenToMediaStream();
  }

  void _listenToMediaStream() {
    state = const MediaState.loading(); // Set initial state
    _mediaSubscription = _mediaRepository.getUnifiedMediaStream().listen(
      (entities) {
        state = MediaState.data(media: entities);
      },
      onError: (e) {
        state = MediaState.error(error: "加载媒体流时出错: $e");
      },
    );
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
