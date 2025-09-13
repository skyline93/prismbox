// lib/providers.dart

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/data/datasources/local_db/app_database.dart';
import '../data/repositories/media_repository_impl.dart';
import '../domain/repositories/media_repository.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/storage/sync_state_service.dart';
import 'package:mobile/core/service_locator.dart';
import 'package:mobile/data/services/dio_client.dart';
import 'package:mobile/auth/auth_notifier.dart';
import 'package:mobile/auth/auth_state.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/data/services/auth_service.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/data/datasources/local_media_source.dart';
import 'package:mobile/domain/entities/unified_album_entity.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/ui/album/viewmodel/album_detail_viewmodel.dart';

final thumbnailCacheProvider =
    StateNotifierProvider<ThumbnailCacheNotifier, Map<String, Uint8List>>((
      ref,
    ) {
      return ThumbnailCacheNotifier();
    });

class ThumbnailCacheNotifier extends StateNotifier<Map<String, Uint8List>> {
  static const int _maxCacheSize = 100;
  static const int _maxMemorySize = 50 * 1024 * 1024;

  ThumbnailCacheNotifier() : super({});

  void addToCache(String key, Uint8List data) {
    if (state.length >= _maxCacheSize) {
      _cleanupCache();
    }

    final currentMemoryUsage = _calculateMemoryUsage();
    if (currentMemoryUsage + data.length > _maxMemorySize) {
      _cleanupCache();
    }

    state = {...state, key: data};
  }

  void _cleanupCache() {
    final keysToRemove = state.keys.take((state.length * 0.2).round()).toList();
    final newCache = Map<String, Uint8List>.from(state);
    for (final key in keysToRemove) {
      newCache.remove(key);
    }
    state = newCache;
  }

  int _calculateMemoryUsage() {
    return state.values.fold(0, (sum, data) => sum + data.length);
  }

  void clearCache() {
    state = {};
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier(ref);
});

final dioClientProvider = Provider<DioClient>((ref) {
  final dio = DioClient(getIt<SecureStorageService>());

  final authNotifier = ref.read(authNotifierProvider.notifier);
  dio.onAuthFailure = authNotifier.logout;

  return dio;
});

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepositoryImpl(
    cloudDataSource: getIt<RemoteMediaDataSource>(),
    db: getIt<AppDatabase>(),
    localMediaSource: getIt<LocalMediaDataSource>(),
  );
});

enum MediaViewType { grid, timeline }

final mediaViewTypeProvider = StateProvider<MediaViewType>(
  (_) => MediaViewType.timeline,
);

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(getIt<AppDatabase>());
});

final syncStateServiceProvider = Provider<SyncStateService>((ref) {
  final prefs = getIt<SharedPreferences>();
  return SyncStateService(prefs);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  final storage = ref.watch(secureStorageServiceProvider);
  return AuthService(dio, storage);
});

final mediaStreamProvider = StreamProvider<List<UnifiedMediaEntity>>((ref) {
  final mediaRepository = ref.watch(mediaRepositoryProvider);
  return mediaRepository.getUnifiedMediaStream();
});

final mediaEntityProvider = StreamProvider.family<UnifiedMediaEntity, int>((
  ref,
  id,
) {
  final repository = ref.watch(mediaRepositoryProvider);
  return repository.watchMediaEntity(id);
});

final albumStreamProvider =
    StreamProvider.autoDispose<List<UnifiedAlbumEntity>>((ref) {
      final mediaRepository = ref.watch(mediaRepositoryProvider);
      return mediaRepository.watchAlbums();
    });

final albumDetailViewModelProvider = StateNotifierProvider.autoDispose
    .family<
      AlbumDetailViewModel,
      AsyncValue<List<UnifiedMediaEntity>>,
      (String, AlbumSource)
    >((ref, params) {
      final mediaRepository = ref.watch(mediaRepositoryProvider);
      final (albumId, albumSource) = params;

      return AlbumDetailViewModel(
        mediaRepository,
        albumId: albumId,
        albumSource: albumSource,
      );
    });

final albumCoverProvider = FutureProvider.autoDispose
    .family<UnifiedMediaEntity?, UnifiedAlbumEntity>((ref, album) {
      final mediaRepository = ref.watch(mediaRepositoryProvider);
      return mediaRepository.getCoverForAlbum(album);
    });

class SelectionState {
  final bool isSelecting;
  final Set<UnifiedMediaEntity> selectedItems;

  SelectionState({this.isSelecting = false, this.selectedItems = const {}});

  SelectionState copyWith({
    bool? isSelecting,
    Set<UnifiedMediaEntity>? selectedItems,
  }) {
    return SelectionState(
      isSelecting: isSelecting ?? this.isSelecting,
      selectedItems: selectedItems ?? this.selectedItems,
    );
  }
}

class SelectionNotifier extends StateNotifier<SelectionState> {
  SelectionNotifier() : super(SelectionState());

  void startSelection(UnifiedMediaEntity initialItem) {
    if (state.isSelecting) return;
    state = SelectionState(isSelecting: true, selectedItems: {initialItem});
  }

  void setSelection(bool isSelecting, Set<UnifiedMediaEntity> items) {
    state = SelectionState(isSelecting: isSelecting, selectedItems: items);
  }

  void toggleItem(UnifiedMediaEntity item) {
    if (!state.isSelecting) return;

    final newSelectedItems = Set<UnifiedMediaEntity>.from(state.selectedItems);
    if (newSelectedItems.contains(item)) {
      newSelectedItems.remove(item);
    } else {
      newSelectedItems.add(item);
    }

    if (newSelectedItems.isEmpty) {
      state = SelectionState(isSelecting: false, selectedItems: {});
    } else {
      state = state.copyWith(selectedItems: newSelectedItems);
    }
  }

  void clearSelection() {
    state = SelectionState();
  }
}

final selectionProvider =
    StateNotifierProvider<SelectionNotifier, SelectionState>((ref) {
      return SelectionNotifier();
    });
