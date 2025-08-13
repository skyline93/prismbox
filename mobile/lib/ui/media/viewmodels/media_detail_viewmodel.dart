import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/data/datasources/app_database.dart';
import 'package:mobile/providers.dart'; // 全局 Provider
// import 'package:mobile/ui/media/viewmodels/media_viewmodel.dart'; // mediaViewModelProvider

part 'media_detail_viewmodel.freezed.dart';

// --- 1. 定义一个类型安全的状态 ---
// 这个密封类将取代之前模糊的 `dynamic` 类型。
@freezed
sealed class MediaData with _$MediaData {
  const factory MediaData.bytes(Uint8List bytes) = _MediaDataBytes;
  const factory MediaData.file(File file) = _MediaDataFile;
}

// --- 2. 创建 ViewModel (Notifier) ---
final mediaDetailProvider =
    AsyncNotifierProvider.family<
      MediaDetailNotifier,
      MediaData,
      UnifiedMediaEntity
    >(MediaDetailNotifier.new);

class MediaDetailNotifier
    extends FamilyAsyncNotifier<MediaData, UnifiedMediaEntity> {
  // build 方法现在返回 Future<MediaData>，更加明确。
  @override
  Future<MediaData> build(UnifiedMediaEntity arg) async {
    final entity = arg;

    // 逻辑 A: 从本地文件路径加载
    if (entity.filePath != null && entity.filePath!.isNotEmpty) {
      final file = File(entity.filePath!);
      if (await file.exists()) {
        if (entity.isVideo) return MediaData.file(file);
        // 对于图片，我们直接读取字节，方便后续创建 MemoryImage
        return MediaData.bytes(await file.readAsBytes());
      }
    }

    // 逻辑 B: 从云端下载预览
    if (entity.syncStatus == SyncStatus.cloudOnly && entity.cloudUuid != null) {
      try {
        final repository = ref.read(mediaRepositoryProvider);
        final previewBytes = await repository.downloadPreview(
          entity.cloudUuid!,
        );

        if (entity.isVideo) {
          // 视频需要写入临时文件
          final tempDir = await getTemporaryDirectory();
          final tempFile = File(
            p.join(tempDir.path, '${entity.cloudUuid}_preview.mp4'),
          );
          await tempFile.writeAsBytes(previewBytes);
          return MediaData.file(tempFile);
        }

        // 图片直接返回字节
        return MediaData.bytes(previewBytes);
      } catch (e) {
        debugPrint("无法从云端下载预览媒体 for cloudUuid=${entity.cloudUuid}: $e");
        throw Exception('无法下载云端预览资源: $e');
      }
    }

    // 如果以上条件都不满足，说明资源不可用
    throw Exception('媒体资源不可用 for entity id: ${entity.id}');
  }

  // --- 3. Action 方法 ---

  Future<void> download() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(mediaRepositoryProvider);
      // 下载完成后，repository 会返回更新后的实体
      final updatedEntity = await repository.downloadAndSaveOriginal(arg);

      // 关键：通知列表刷新
      ref.invalidate(mediaViewModelProvider);

      // 返回新下载的本地文件，用于更新当前详情页UI
      return MediaData.file(File(updatedEntity.filePath!));
    });
  }

  Future<void> upload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(mediaRepositoryProvider);
      await repository.uploadLocalMedia(arg);

      // 关键：通知列表刷新
      ref.invalidate(mediaViewModelProvider);

      // 返回原始文件，因为文件本身没有变化
      // 注意：这里我们假设图片被上传，所以读取字节
      final file = File(arg.filePath!);
      return arg.isVideo
          ? MediaData.file(file)
          : MediaData.bytes(await file.readAsBytes());
    });
  }
}
