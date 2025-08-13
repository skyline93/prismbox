// lib/ui/media/viewmodels/media_detail_viewmodel.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/providers.dart';
import 'package:photo_manager/photo_manager.dart';

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

    // --- 优先级 1: 尝试通过 localId 从系统媒体库加载 (最可靠) ---
    if (entity.localId != null && entity.localId!.isNotEmpty) {
      final asset = await AssetEntity.fromId(entity.localId!);
      if (asset != null) {
        if (entity.isVideo) {
          // 使用 photo_manager 获取可访问的 File 对象
          final file = await asset.file;
          if (file != null) {
            return MediaData.file(file);
          }
        } else {
          // 对于图片，获取原始字节
          final bytes = await asset.originBytes;
          if (bytes != null) {
            return MediaData.bytes(bytes);
          }
        }
      }
      // 如果 asset 为 null 或获取文件/字节失败，则会自然地“掉落”到下一个逻辑
    }

    // --- 优先级 2: 如果 localId 不可用或失败，回退到使用 filePath ---
    // (适用于从云端下载到本地私有目录的文件)
    if (entity.filePath != null && entity.filePath!.isNotEmpty) {
      final file = File(entity.filePath!);
      if (await file.exists()) {
        if (entity.isVideo) return MediaData.file(file);
        return MediaData.bytes(await file.readAsBytes());
      }
    }

    // --- 优先级 3: 如果本地完全找不到，则从云端下载预览 ---
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

    // 如果以上所有逻辑都失败了（既没有可用的本地文件，也没有 cloudUuid），
    // 说明资源是真正不可用。
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
