// lib/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'data/repositories/media_repository_impl.dart';
import 'domain/repositories/media_repository.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/storage/sync_state_service.dart';
import 'package:mobile/core/service_locator.dart';
import 'package:mobile/data/services/dio_client.dart';
import 'package:mobile/auth/auth_notifier.dart';
import 'package:mobile/auth/auth_state.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/data/services/auth_service.dart';
import 'package:mobile/data/services/server_check_service.dart';
import 'package:mobile/services/sync_job_manager.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/data/datasources/local_media_source.dart';
import 'package:mobile/domain/entities/unified_album_entity.dart';
import 'package:mobile/data/datasources/local_db/enums.dart';
import 'package:mobile/ui/album/viewmodel/album_detail_viewmodel.dart';

final syncJobManagerProvider = Provider<SyncJobManager>((ref) {
  return getIt<SyncJobManager>();
});

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
  print("[mediaRepositoryProvider] 初始化repo=================================");
  return MediaRepositoryImpl(
    cloudDataSource: getIt<RemoteMediaDataSource>(),
    db: getIt<AppDatabase>(),
    syncJobManager: ref.read(syncJobManagerProvider),
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

final serverCheckServiceProvider = Provider<ServerCheckService>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return ServerCheckService(dio);
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

// [新增] albumDetailViewModelProvider
// 这是一个全新的 family Provider，专门为相册详情页服务。
// 它接收相册ID和来源作为参数，创建独立的 ViewModel 实例。
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

// --- 新增：选择状态管理的 Provider ---
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

  /// [正确添加回来] 明确地开始选择模式，通常由长按触发。
  void startSelection(UnifiedMediaEntity initialItem) {
    if (state.isSelecting) return;
    state = SelectionState(isSelecting: true, selectedItems: {initialItem});
  }

  /// 用于同步来自 drag_select_grid_view 的选择状态。
  void setSelection(bool isSelecting, Set<UnifiedMediaEntity> items) {
    state = SelectionState(isSelecting: isSelecting, selectedItems: items);
  }

  /// 切换单个项目的选中状态，通常由点击触发。
  void toggleItem(UnifiedMediaEntity item) {
    // 如果不在选择模式下，则不执行任何操作。
    // 启动选择必须通过 startSelection 或 setSelection 来完成。
    if (!state.isSelecting) return;

    final newSelectedItems = Set<UnifiedMediaEntity>.from(state.selectedItems);
    if (newSelectedItems.contains(item)) {
      newSelectedItems.remove(item);
    } else {
      newSelectedItems.add(item);
    }

    // 如果取消选择后列表为空，则自动退出选择模式
    if (newSelectedItems.isEmpty) {
      state = SelectionState(isSelecting: false, selectedItems: {});
    } else {
      state = state.copyWith(selectedItems: newSelectedItems);
    }
  }

  /// 清除所有选择并退出选择模式。
  void clearSelection() {
    state = SelectionState();
  }
}

final selectionProvider =
    StateNotifierProvider<SelectionNotifier, SelectionState>((ref) {
      return SelectionNotifier();
    });
