// lib/ui/trash/viewmodels/trash_viewmodel.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/domain/repositories/media_repository.dart';
import 'package:mobile/providers/providers.dart';
import 'package:mobile/ui/trash/viewmodels/trash_state.dart';

// 用于垃圾箱页面的独立选择状态
final trashSelectionProvider =
    StateNotifierProvider<SelectionNotifier, SelectionState>(
      (ref) => SelectionNotifier(),
    );

class TrashViewModel extends StateNotifier<TrashState> {
  final MediaRepository _mediaRepository;
  StreamSubscription<dynamic>? _trashSubscription;

  TrashViewModel(this._mediaRepository) : super(const TrashState.loading()) {
    _listenToTrashStream();
  }

  void _listenToTrashStream() {
    state = const TrashState.loading();
    _trashSubscription = _mediaRepository.watchTrashedAssets().listen(
      (entities) {
        state = TrashState.data(trashedMedia: entities);
      },
      onError: (e) {
        state = TrashState.error(error: "加载回收站媒体时出错: $e");
      },
    );
  }

  Future<void> restoreAssets(List<UnifiedMediaEntity> assets) async {
    await _mediaRepository.restoreAssetsFromTrash(assets);
  }

  Future<void> permanentlyDeleteAssets(List<UnifiedMediaEntity> assets) async {
    await _mediaRepository.permanentlyDeleteAssets(assets);
  }

  @override
  void dispose() {
    _trashSubscription?.cancel();
    super.dispose();
  }
}
