// lib/ui/album/viewmodel/album_detail_viewmodel.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/datasources/local_db/enums.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/domain/repositories/media_repository.dart';

class AlbumDetailViewModel
    extends StateNotifier<AsyncValue<List<UnifiedMediaEntity>>> {
  final MediaRepository _mediaRepository;
  final String albumId;
  final AlbumSource albumSource;
  StreamSubscription<List<UnifiedMediaEntity>>? _mediaSubscription;

  AlbumDetailViewModel(
    this._mediaRepository, {
    required this.albumId,
    required this.albumSource,
  }) : super(const AsyncValue.loading()) {
    _listenToMedia();
  }

  void _listenToMedia() {
    // 在开始新的监听之前，总是先取消旧的监听，防止重复订阅
    _mediaSubscription?.cancel();

    // 将状态设置为加载中，以便UI显示加载指示器
    state = const AsyncValue.loading();

    // 调用 repository 中新的 watch 方法并开始监听
    _mediaSubscription = _mediaRepository
        .watchMediaFromAlbum(albumId, albumSource)
        .listen(
          (media) {
            // [成功回调] 当流中有新数据到达时
            if (mounted) {
              // 检查组件是否还在树上
              state = AsyncValue.data(media);
            }
          },
          onError: (e, st) {
            // [失败回调] 当流中发生错误时
            if (mounted) {
              state = AsyncValue.error(e, st);
            }
          },
        );
  }

  @override
  void dispose() {
    // 当 ViewModel 不再被使用时（例如用户离开页面），确保取消订阅
    _mediaSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadMedia() async {
    // 用户下拉刷新时，简单地重新建立监听即可获取最新数据
    _listenToMedia();
  }
}
