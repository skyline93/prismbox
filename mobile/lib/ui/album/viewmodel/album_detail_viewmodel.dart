// lib/ui/album/viewmodel/album_detail_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/datasources/local_db/enums.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/domain/repositories/media_repository.dart';

class AlbumDetailViewModel
    extends StateNotifier<AsyncValue<List<UnifiedMediaEntity>>> {
  final MediaRepository _mediaRepository;
  final String albumId;
  final AlbumSource albumSource;

  AlbumDetailViewModel(
    this._mediaRepository, {
    required this.albumId,
    required this.albumSource,
  }) : super(const AsyncValue.loading()) {
    loadMedia();
  }

  Future<void> loadMedia() async {
    state = const AsyncValue.loading();
    try {
      final media = await _mediaRepository.getMediaFromAlbum(
        albumId,
        albumSource,
      );
      if (mounted) {
        state = AsyncValue.data(media);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }
}
