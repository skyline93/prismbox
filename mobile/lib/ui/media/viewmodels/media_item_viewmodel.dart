// lib/ui/media/viewmodels/media_item_viewmodel.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/providers/providers.dart';

final thumbnailProvider = FutureProvider.family<Uint8List?, UnifiedMediaEntity>(
  (ref, entity) async {
    final cache = ref.read(thumbnailCacheProvider);
    final cacheKey = '${entity.id}_${entity.localId ?? entity.cloudUuid}';

    if (cache.containsKey(cacheKey)) {
      return cache[cacheKey];
    }

    Uint8List? thumbnailData;

    if (entity.localId != null && entity.localId!.isNotEmpty) {
      try {
        final assetEntity = await AssetEntity.fromId(entity.localId!);
        if (assetEntity != null) {
          thumbnailData = await assetEntity.thumbnailDataWithSize(
            const ThumbnailSize(200, 200),
          );
        }
      } catch (e) {
        if (e.toString().contains('permission')) {
          debugPrint("权限被拒绝，无法访问本地相册: $e");
        } else if (e.toString().contains('not found')) {
          debugPrint("本地资源不存在: $e");
        } else {
          debugPrint("PhotoManager 加载失败: $e");
        }
      }
    }

    if (thumbnailData == null &&
        (entity.syncStatus == SyncStatus.cloudOnly ||
            entity.syncStatus == SyncStatus.synced) &&
        entity.cloudUuid != null) {
      try {
        final repository = ref.read(mediaRepositoryProvider);
        thumbnailData = await repository.downloadThumbnail(entity.cloudUuid!);
      } catch (e) {
        debugPrint("云端缩略图下载失败: $e");
      }
    }

    if (thumbnailData == null &&
        entity.filePath != null &&
        entity.filePath!.isNotEmpty) {
      try {
        final file = File(entity.filePath!);
        if (await file.exists()) {
          final originalBytes = await file.readAsBytes();
          thumbnailData = await _compressImage(originalBytes, 200, 200);
        }
      } catch (e) {
        debugPrint("文件读取失败: $e");
      }
    }

    if (thumbnailData != null) {
      ref
          .read(thumbnailCacheProvider.notifier)
          .addToCache(cacheKey, thumbnailData);
    }

    return thumbnailData;
  },
);

Future<Uint8List> _compressImage(
  Uint8List bytes,
  int maxWidth,
  int maxHeight,
) async {
  try {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: maxWidth,
      targetHeight: maxHeight,
    );
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } catch (e) {
    debugPrint("图片压缩失败: $e");
    return bytes;
  }
}
