// lib/ui/gallery/viewmodels/gallery_viewmodel.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/providers/providers.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:mobile/providers/transfer_providers.dart';

part 'gallery_viewmodel.freezed.dart';

@freezed
sealed class MediaData with _$MediaData {
  const factory MediaData.asset(AssetEntity entity) = _MediaDataAsset;
  const factory MediaData.bytes(Uint8List bytes) = _MediaDataBytes;
  const factory MediaData.file(File file) = _MediaDataFile;
}

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

  Future<void> download() async {
    final transferService = ref.read(transferServiceProvider);
    await transferService.downloadService.startDownloadForAsset(arg);
  }

  // Future<void> upload() async {
  //   final repo = ref.read(mediaRepositoryProvider);
  //   await repo.createUploadJobForExistingAsset(arg);
  // }
}
