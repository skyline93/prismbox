// lib/features/media_loading/strategies/resource_selection_strategy.dart

import 'package:flutter/material.dart';
import 'package:prismbox/core/cache/remote_image_cache_manager.dart';
import 'package:prismbox/core/cache/thumbnail_cache_manager.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/domain/entities/remote_asset.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/features/media_loading/providers/lazy_local_full_provider.dart';
import 'package:prismbox/features/media_loading/providers/local_full_provider.dart';
import 'package:prismbox/features/media_loading/providers/local_thumb_provider.dart';
import 'package:prismbox/features/media_loading/providers/remote_full_provider.dart';
import 'package:prismbox/features/media_loading/providers/remote_thumb_provider.dart';

/// 资源选择策略接口
/// 定义如何选择本地或远程资源提供者
abstract class ResourceSelectionStrategy {
  /// 判断是否应该使用本地资源
  bool shouldUseLocalAsset(BaseAsset asset);
  
  /// 选择缩略图提供者
  ImageProvider? selectThumbnailProvider(
    BaseAsset asset, {
    required Size size,
    String? serverUrl,
  });
  
  /// 选择原图提供者
  ImageProvider selectFullImageProvider(
    BaseAsset asset, {
    required Size size,
    bool loadOriginal = false,
    String? serverUrl,
    AssetEntityLoader? assetEntityLoader,
  });
  
  /// 异步选择缩略图提供者（新增）
  /// 
  /// 用于处理 assetEntity 为 null 的情况
  /// 返回 Future，支持异步获取 AssetEntity
  Future<ImageProvider?> selectThumbnailProviderAsync(
    BaseAsset asset, {
    required Size size,
    String? serverUrl,
    AssetEntityLoader? assetEntityLoader,
  });
}

/// 默认资源选择策略
/// 根据资源可用性和用户偏好选择提供者
class DefaultResourceSelectionStrategy implements ResourceSelectionStrategy {
  /// 用户 ID 获取函数（可选）
  final String? Function(BaseAsset asset)? userIdGetter;
  
  /// 是否优先使用远程图片（从 AppSetting 获取）
  final bool preferRemoteImage;
  
  /// 缓存管理器（可选）
  ThumbnailImageCacheManager? thumbnailCacheManager;
  RemoteImageCacheManager? remoteImageCacheManager;

  DefaultResourceSelectionStrategy({
    this.userIdGetter,
    this.preferRemoteImage = false,
    this.thumbnailCacheManager,
    this.remoteImageCacheManager,
  });

  @override
  bool shouldUseLocalAsset(BaseAsset asset) {
    // 检查本地资源可用性
    if (!asset.hasLocal) {
      return false;
    }

    // 检查用户偏好
    if (asset.hasRemote && preferRemoteImage) {
      return false;
    }

    return true;
  }

  @override
  ImageProvider? selectThumbnailProvider(
    BaseAsset asset, {
    required Size size,
    String? serverUrl,
  }) {
    if (shouldUseLocalAsset(asset)) {
      // 使用本地资源
      if (asset is LocalAsset && asset.assetEntity != null) {
        return LocalThumbProvider(
          asset: asset.assetEntity!,
          size: size,
          cacheManager: thumbnailCacheManager,
          userId: userIdGetter?.call(asset),
          checksum: asset.checksum,
        );
      }
      // 如果没有 AssetEntity，返回 null
      return null;
    } else {
      // 使用远程资源
      if (asset is RemoteAsset) {
        return RemoteThumbProvider(
          assetId: asset.id,
          size: size,
          serverUrl: serverUrl,
          cacheManager: thumbnailCacheManager,
        );
      }
    }
    return null;
  }

  @override
  ImageProvider selectFullImageProvider(
    BaseAsset asset, {
    required Size size,
    bool loadOriginal = false,
    String? serverUrl,
    AssetEntityLoader? assetEntityLoader,
  }) {
    if (shouldUseLocalAsset(asset)) {
      // 使用本地资源
      if (asset is LocalAsset) {
        if (asset.assetEntity != null) {
          // 有 assetEntity，直接使用 LocalFullImageProvider
          return LocalFullImageProvider(
            asset: asset.assetEntity!,
            targetSize: size,
            userId: userIdGetter?.call(asset),
            checksum: asset.checksum,
            cacheManager: thumbnailCacheManager,
            loadOriginal: loadOriginal,
          );
        } else if (assetEntityLoader != null) {
          // assetEntity 为 null，使用延迟加载的提供者
          return LazyLocalFullImageProvider(
            asset: asset,
            assetEntityLoader: assetEntityLoader,
            targetSize: size,
            userId: userIdGetter?.call(asset),
            cacheManager: thumbnailCacheManager,
            loadOriginal: loadOriginal,
          );
        }
        // 如果没有 AssetEntityLoader，无法加载本地资源
      }
      // LocalAsset 的 assetEntity 为 null 且没有 AssetEntityLoader，尝试回退到远程
      if (asset.hasRemote && asset is RemoteAsset) {
        return RemoteFullImageProvider(
          assetId: asset.id,
          targetSize: size,
          loadOriginal: loadOriginal,
          serverUrl: serverUrl,
          cacheManager: remoteImageCacheManager,
        );
      }
    } else {
      // 使用远程资源
      if (asset is RemoteAsset) {
        return RemoteFullImageProvider(
          assetId: asset.id,
          targetSize: size,
          loadOriginal: loadOriginal,
          serverUrl: serverUrl,
          cacheManager: remoteImageCacheManager,
        );
      }
    }
    
    // 如果既没有本地也没有远程，抛出异常（由调用方处理占位符）
    throw UnimplementedError('No provider available for asset: ${asset.id}');
  }

  @override
  Future<ImageProvider?> selectThumbnailProviderAsync(
    BaseAsset asset, {
    required Size size,
    String? serverUrl,
    AssetEntityLoader? assetEntityLoader,
  }) async {
    if (shouldUseLocalAsset(asset)) {
      if (asset is LocalAsset) {
        // 如果 assetEntity 为 null，尝试异步获取
        if (asset.assetEntity == null) {
          if (assetEntityLoader != null) {
            final entity = await assetEntityLoader.loadAsync(asset);
            if (entity != null) {
              return LocalThumbProvider(
                asset: entity,
                size: size,
                cacheManager: thumbnailCacheManager,
                userId: userIdGetter?.call(asset),
                checksum: asset.checksum,
              );
            }
          }
          // 获取失败，返回 null
          return null;
        } else {
          // 已有 assetEntity，直接使用
          return LocalThumbProvider(
            asset: asset.assetEntity!,
            size: size,
            cacheManager: thumbnailCacheManager,
            userId: userIdGetter?.call(asset),
            checksum: asset.checksum,
          );
        }
      }
      return null;
    } else {
      // 使用远程资源（同步）
      if (asset is RemoteAsset) {
        return RemoteThumbProvider(
          assetId: asset.id,
          size: size,
          serverUrl: serverUrl,
          cacheManager: thumbnailCacheManager,
        );
      }
    }
    return null;
  }
}

