// lib/presentation/viewmodels/home_viewmodel.dart

import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/utils/logger.dart';
import '../../data/datasources/local/app_database.dart'; 
import '../../data/repositories/media_repository.dart';
import '../../services/transfer/download_service.dart';
import '../../services/transfer/upload_service.dart';
import '../providers/providers.dart'; // 引入 providers.dart
import '../../state/transfer_state.dart'; // 引入 TransferState

class HomePageViewModel extends StateNotifier<bool> {
  final MediaRepository _mediaRepository;
  final UploadService _uploadService;
  final DownloadService _downloadService;
  final Ref _ref; // <--- 声明为 final 字段

  HomePageViewModel({
    required MediaRepository mediaRepository,
    required UploadService uploadService,
    required DownloadService downloadService,
    required Ref ref, // <--- 接收 ref 作为参数
  }) : _mediaRepository = mediaRepository,
       _uploadService = uploadService,
       _downloadService = downloadService,
       _ref = ref, // <--- 在初始化列表中正确初始化 _ref
       super(false) {
    _listenToUploads(); // 在初始化时开始监听
  }

  // 监听器方法
  void _listenToUploads() {
    _ref.listen<TransferState>(transferStateProvider, (
      previousState,
      nextState,
    ) {
      // 检查状态是否从“正在上传”变为“没有上传任务”
      final bool wasUploading = previousState?.uploads.isNotEmpty ?? false;
      final bool isFinishedUploading = nextState.uploads.isEmpty;

      if (wasUploading && isFinishedUploading) {
        logger.i("Upload queue finished. Triggering media sync.");
        syncMedia(); // 当所有上传任务完成时，自动触发同步
      }
    });
  }

  Future<void> syncMedia() async {
    state = true; // isLoading = true
    try {
      await _mediaRepository.syncRemoteMedia();
    } catch (e, s) {
      logger.e("Failed to sync media", error: e);
      print("Failed to sync media: $e, $s");
    } finally {
      state = false; // isLoading = false
    }
  }

  Future<void> startUploads(List<File> files) async {
    _uploadService.startUploads(files);
  }

  Future<void> startDownloads(
    List<MediaAsset> assets,
    String directoryPath,
  ) async {
    await _downloadService.startDownloads(assets, directoryPath);
  }
}
