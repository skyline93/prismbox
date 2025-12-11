// lib/features/media_loading/image_provider_factory.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/core/cache/remote_image_cache_manager.dart';
import 'package:prismbox/core/cache/thumbnail_cache_manager.dart';
import 'package:prismbox/core/settings/app_setting.dart';
import 'package:prismbox/core/storage/store_key.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/domain/entities/remote_asset.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/features/media_loading/strategies/resource_selection_strategy.dart';
import 'package:prismbox/features/media_loading/thumbhash/gradient_placeholder_provider.dart';
import 'package:prismbox/features/media_loading/thumbhash/thumbhash_provider.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';

final Logger _log = Logger('ImageProviderFactory');

/// 默认资源选择策略实例（单例）
DefaultResourceSelectionStrategy? _defaultStrategy;

/// 获取默认资源选择策略
DefaultResourceSelectionStrategy _getDefaultStrategy() {
  _defaultStrategy ??= DefaultResourceSelectionStrategy(
    preferRemoteImage: AppSetting.get(Setting.preferRemoteImage),
    userIdGetter: _getUserId,
  );
  return _defaultStrategy!;
}

/// 默认缩略图分辨率
const kThumbnailResolution = Size(200, 200);

/// 获取缩略图提供者
/// 根据资源类型和用户偏好自动选择本地或远程提供者
/// 
/// 使用策略模式进行资源选择
ImageProvider? getThumbnailImageProvider(
  BaseAsset asset, {
  Size size = kThumbnailResolution,
  String? serverUrl,
  ApiService? apiService,
  ThumbnailImageCacheManager? thumbnailCacheManager,
  ResourceSelectionStrategy? strategy,
}) {
  // 使用提供的策略或默认策略
  final selectedStrategy = strategy ?? _getDefaultStrategy();
  
  // 如果是默认策略，设置缓存管理器
  if (selectedStrategy is DefaultResourceSelectionStrategy) {
    selectedStrategy.thumbnailCacheManager = thumbnailCacheManager;
  }
  
  return selectedStrategy.selectThumbnailProvider(
    asset,
    size: size,
    serverUrl: serverUrl,
  );
}

/// 获取缩略图提供者（异步版本，支持延迟获取 AssetEntity）
/// 
/// 当 LocalAsset 的 assetEntity 为 null 时，会自动异步获取
/// 
/// 使用策略模式进行资源选择
Future<ImageProvider?> getThumbnailImageProviderAsync(
  BaseAsset asset, {
  Size size = kThumbnailResolution,
  String? serverUrl,
  ApiService? apiService,
  ThumbnailImageCacheManager? thumbnailCacheManager,
  ResourceSelectionStrategy? strategy,
  AssetEntityLoader? assetEntityLoader,
}) async {
  // 使用提供的策略或默认策略
  final selectedStrategy = strategy ?? _getDefaultStrategy();
  
  // 如果是默认策略，设置缓存管理器
  if (selectedStrategy is DefaultResourceSelectionStrategy) {
    selectedStrategy.thumbnailCacheManager = thumbnailCacheManager;
  }
  
  return await selectedStrategy.selectThumbnailProviderAsync(
    asset,
    size: size,
    serverUrl: serverUrl,
    assetEntityLoader: assetEntityLoader,
  );
}

/// 获取原图提供者
/// 根据资源类型和用户偏好自动选择本地或远程提供者
/// 
/// 使用策略模式进行资源选择
ImageProvider getFullImageProvider(
  BaseAsset asset, {
  Size size = const Size(1080, 1920),
  bool loadOriginal = false,
  String? serverUrl,
  ApiService? apiService,
  RemoteImageCacheManager? remoteImageCacheManager,
  ResourceSelectionStrategy? strategy,
}) {
  try {
    // 使用提供的策略或默认策略
    final selectedStrategy = strategy ?? _getDefaultStrategy();
    
    // 如果是默认策略，设置缓存管理器
    if (selectedStrategy is DefaultResourceSelectionStrategy) {
      selectedStrategy.remoteImageCacheManager = remoteImageCacheManager;
    }
    
    return selectedStrategy.selectFullImageProvider(
      asset,
      size: size,
      loadOriginal: loadOriginal,
      serverUrl: serverUrl,
    );
  } catch (e) {
    // 如果策略无法提供提供者，回退到渐变占位符
    _log.warning('Failed to get full image provider, using placeholder', e);
    return GradientPlaceholderProvider(
      colorScheme: ThemeData.light().colorScheme,
      size: size,
    );
  }
}

/// 获取占位符提供者
/// 优先使用 ThumbHash，如果没有则使用渐变占位符
ImageProvider? getPlaceholderProvider(
  BaseAsset asset, {
  ColorScheme? colorScheme,
}) {
  // 远程资源且有 ThumbHash
  if (asset is RemoteAsset && asset.thumbHash != null) {
    try {
      // 将 ThumbHash 字符串转换为字节数组
      // 注意：这里假设 thumbHash 是 base64 编码的字符串
      // 实际实现需要根据后端返回的格式进行解析
      final thumbHashString = asset.thumbHash!;
      
      // 尝试解析为 base64
      Uint8List thumbHashBytes;
      try {
        thumbHashBytes = base64Decode(thumbHashString);
      } catch (e) {
        // 如果不是 base64，尝试作为十六进制字符串解析
        // 或者直接使用字符串的字节表示（简化处理）
        thumbHashBytes = Uint8List.fromList(thumbHashString.codeUnits);
      }
      
      // 导入 ThumbHashProvider
      return ThumbHashProvider(thumbHashBytes);
    } catch (e) {
      // ThumbHash 解码失败，回退到渐变占位符
      _log.warning('Failed to decode ThumbHash, using gradient placeholder', e);
    }
  }

  // 使用渐变占位符
  return GradientPlaceholderProvider(
    colorScheme: colorScheme ?? ThemeData.light().colorScheme,
  );
}

/// 获取用户 ID（从 asset 中获取，如果可用）
/// 
/// 优先级：
/// 1. 从 RemoteAsset 获取 ownerId（优先）
/// 2. 从 Store 获取当前登录用户的 ID
/// 3. 如果都无法获取，返回 null（使用 'unknown' 作为默认值）
String? _getUserId(BaseAsset asset) {
  // 方案 1：从 RemoteAsset 获取 ownerId（优先）
  if (asset is RemoteAsset) {
    return asset.ownerId;
  }
  
  // 方案 2：从 Store 获取当前登录用户的 ID
  return _getCurrentUserId();
}

/// 获取当前登录用户的 ID
/// 
/// 从 Store 中读取 currentUser（JSON 字符串），解析为 UserProfile，返回 id
String? _getCurrentUserId() {
  try {
    final store = StoreService();
    if (!store.isInitialized) {
      _log.warning('StoreService not initialized, cannot get current user ID');
      return null;
    }
    
    // 从 Store 获取当前用户 JSON 字符串
    final userJson = store.tryGet<String>(StoreKey.currentUser);
    if (userJson == null || userJson.isEmpty) {
      _log.fine('No current user found in Store');
      return null;
    }
    
    // 解析 JSON 为 UserProfile
    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      // 假设 JSON 格式包含 id 字段
      final userId = userMap['id'];
      if (userId != null) {
        return userId.toString();
      }
      
      // 如果 JSON 格式不包含 id，尝试使用 UserProfile.fromDto
      // 但需要先确认 JSON 格式
      _log.warning('User JSON does not contain id field');
      return null;
    } catch (e) {
      _log.warning('Failed to parse user JSON: $e');
      return null;
    }
  } catch (e) {
    _log.warning('Failed to get current user ID: $e');
    return null;
  }
}

