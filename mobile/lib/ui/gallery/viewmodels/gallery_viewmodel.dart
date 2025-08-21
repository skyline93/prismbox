// lib/ui/gallery/viewmodels/gallery_viewmodel.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/providers.dart';
import 'package:photo_manager/photo_manager.dart';

// [+] 导入 SyncJobManager 以创建任务
// import 'package:mobile/services/sync_job_manager.dart';

part 'gallery_viewmodel.freezed.dart';

@freezed
sealed class MediaData with _$MediaData {
  const factory MediaData.asset(AssetEntity entity) = _MediaDataAsset;
  const factory MediaData.bytes(Uint8List bytes) = _MediaDataBytes;
  const factory MediaData.file(File file) = _MediaDataFile;
}

// 注意：这个 Provider 的 FamilyAsyncNotifier 设计可能在重构后不是最优选择，
// 因为它是一次性的。一个更优的长期方案是也让详情页监听 getUnifiedMediaStream()
// 中特定 id 的变化。但为了最小化改动，我们先修复当前问题。
final mediaDetailProvider =
    AsyncNotifierProvider.family<
      MediaDetailNotifier,
      MediaData,
      UnifiedMediaEntity
    >(MediaDetailNotifier.new);

class MediaDetailNotifier
    extends FamilyAsyncNotifier<MediaData, UnifiedMediaEntity> {
  @override
  Future<MediaData> build(UnifiedMediaEntity arg) async {
    // build 方法的逻辑保持不变，它负责在页面加载时获取最佳可用媒体数据
    final entity = arg;

    if (entity.localId != null && entity.localId!.isNotEmpty) {
      final asset = await AssetEntity.fromId(entity.localId!);
      if (asset != null) {
        if (asset.type == AssetType.video) {
          final file = await asset.file;
          if (file != null) {
            return MediaData.file(file);
          }
        } else {
          return MediaData.asset(asset);
        }
      }
    }

    if (entity.filePath != null && entity.filePath!.isNotEmpty) {
      final file = File(entity.filePath!);
      if (await file.exists()) {
        return MediaData.file(file);
      }
    }

    if (entity.cloudUuid != null) {
      try {
        final repository = ref.read(mediaRepositoryProvider);
        final previewBytes = await repository.downloadPreview(
          entity.cloudUuid!,
        );

        if (entity.isVideo) {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File(
            p.join(tempDir.path, '${entity.cloudUuid}_preview.mp4'),
          );
          await tempFile.writeAsBytes(previewBytes);
          return MediaData.file(tempFile);
        }
        return MediaData.bytes(previewBytes);
      } catch (e) {
        debugPrint("无法从云端下载预览媒体 for cloudUuid=${entity.cloudUuid}: $e");
        throw Exception('本地资源不可用，且从云端下载预览失败: $e');
      }
    }

    throw Exception('媒体资源不可用 for entity id: ${entity.id}');
  }

  // =======================================================================
  // [*] 重构 download 方法
  // =======================================================================
  Future<void> download() async {
    // 1. 获取 SyncJobManager
    final jobManager = ref.read(syncJobManagerProvider);

    // 2. 调用 repository 中的新方法来创建下载任务
    // 这个方法会立即返回，不会等待下载完成
    await jobManager.createDownloadJob(arg);

    // 3. (可选) 短暂地将状态置为 loading，以给UI一个即时反馈
    // 更好的做法是在UI层直接监听数据库中该媒体的状态变化
    // state = const AsyncValue.loading();

    // 4. (重要) 我们不再等待结果，也不再更新 state。
    // 下载任务已在后台排队。UI 会通过监听 mediaViewModelProvider
    // 的数据流自动更新。当下载完成，数据库记录被更新，
    // mediaViewModelProvider 会推送新的媒体列表，UI自然刷新。
    // 我们也不再需要手动 invalidate mediaViewModelProvider。
  }

  // =======================================================================
  // [*] 重构 upload 方法 (这是需要修改的地方)
  // =======================================================================
  Future<void> upload() async {
    // 1. 获取 SyncJobManager
    final jobManager = ref.read(syncJobManagerProvider);

    // 2. 调用为“已存在资产”设计的全新方法
    await jobManager.createUploadJobForExistingAsset(arg);

    // 3. 完成！无需任何其他操作。
    // UI 会通过监听数据库的数据流自动更新状态。
  }
}
