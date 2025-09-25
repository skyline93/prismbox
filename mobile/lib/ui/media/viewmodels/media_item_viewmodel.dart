// lib/ui/media/viewmodels/media_item_viewmodel.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/providers/providers.dart';
import 'package:mobile/ui/media/widgets/thumbnail_load_strategy.dart';

final thumbnailProvider =
    FutureProvider.family<ThumbnailLoadStrategy, UnifiedMediaEntity>((
      ref,
      entity,
    ) async {
      // 优先级 1: 本地相册资源 (通过 photo_manager)
      if (entity.localId != null && entity.localId!.isNotEmpty) {
        try {
          final assetEntity = await AssetEntity.fromId(entity.localId!);
          if (assetEntity != null) {
            // 直接获取缩略图的二进制数据 (Uint8List)
            final thumbData = await assetEntity.thumbnailDataWithSize(
              const ThumbnailSize(200, 200),
              quality: 85,
            );
            if (thumbData != null) {
              // 使用新的策略 LocalBytesStrategy
              return LocalBytesStrategy(thumbData);
            }
          }
        } catch (e) {
          // 错误处理逻辑保持不变
          if (e.toString().contains('permission')) {
            debugPrint("权限被拒绝，无法访问本地相册: $e");
          } else if (e.toString().contains('not found')) {
            debugPrint("本地资源不存在: $e");
          } else {
            debugPrint("PhotoManager 加载失败: $e");
          }
        }
      }

      // 优先级 2: 云端资源
      if ((entity.syncStatus == SyncStatus.cloudOnly ||
              entity.syncStatus == SyncStatus.synced) &&
          entity.cloudUuid != null) {
        try {
          final repository = ref.read(mediaRepositoryProvider);
          // 获取 URL 而不是下载数据
          final url = await repository.getThumbnailUrl(entity.cloudUuid!);
          return NetworkUrlStrategy(url);
        } catch (e) {
          debugPrint("获取云端缩略图URL失败: $e");
        }
      }

      // 优先级 3: 本地文件路径 (作为后备)
      // 注意: 这个逻辑现在不太可能被触发，因为优先级1已经处理了本地资源
      // 如果需要，这里也应该被修改为加载缩略图而不是整个文件
      if (entity.filePath != null && entity.filePath!.isNotEmpty) {
        // 这是一个低效的后备方案，应尽量避免使用
        final file = File(entity.filePath!);
        if (await file.exists()) {
          try {
            // 作为一个低效的回退，我们仍然可以从文件中读取字节
            final bytes = await file.readAsBytes();
            return LocalBytesStrategy(bytes);
          } catch (e) {
            debugPrint("后备方案：读取文件字节失败: $e");
          }
        }
      }

      // 如果以上都失败，则返回“无可用缩略图”策略
      return const NoThumbnailStrategy();
    });
