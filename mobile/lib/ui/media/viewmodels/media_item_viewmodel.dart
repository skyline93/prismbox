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
    // 检查内存缓存
    final cache = ref.read(thumbnailCacheProvider);
    final cacheKey = '${entity.id}_${entity.localId ?? entity.cloudUuid}';

    if (cache.containsKey(cacheKey)) {
      return cache[cacheKey];
    }

    Uint8List? thumbnailData;

    // 优先尝试通过 photo_manager 从本地相册加载高质量缩略图
    if (entity.localId != null && entity.localId!.isNotEmpty) {
      try {
        final assetEntity = await AssetEntity.fromId(entity.localId!);
        if (assetEntity != null) {
          // 使用默认尺寸，实际尺寸将在UI层根据屏幕密度调整
          thumbnailData = await assetEntity.thumbnailDataWithSize(
            const ThumbnailSize(200, 200),
          );
        }
      } catch (e) {
        // 记录具体错误类型，便于调试
        if (e.toString().contains('permission')) {
          debugPrint("权限被拒绝，无法访问本地相册: $e");
        } else if (e.toString().contains('not found')) {
          debugPrint("本地资源不存在: $e");
        } else {
          debugPrint("PhotoManager 加载失败: $e");
        }
      }
    }

    // 后备方案：如果本地资源ID不可用，或 photo_manager 失败，
    // 尝试从云端下载缩略图
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

    // 最后的后备方案：从文件路径读取并压缩
    if (thumbnailData == null &&
        entity.filePath != null &&
        entity.filePath!.isNotEmpty) {
      try {
        final file = File(entity.filePath!);
        if (await file.exists()) {
          // 读取文件并压缩
          final originalBytes = await file.readAsBytes();
          thumbnailData = await _compressImage(originalBytes, 200, 200);
        }
      } catch (e) {
        debugPrint("文件读取失败: $e");
      }
    }

    // 如果成功获取到数据，缓存到内存中
    if (thumbnailData != null) {
      ref
          .read(thumbnailCacheProvider.notifier)
          .addToCache(cacheKey, thumbnailData);
    }

    return thumbnailData;
  },
);

/// 图片压缩函数
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
    // 如果压缩失败，返回原始数据
    return bytes;
  }
}
