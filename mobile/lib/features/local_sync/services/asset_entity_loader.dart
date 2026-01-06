// lib/features/local_sync/services/asset_entity_loader.dart

import 'dart:collection';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/features/local_sync/services/timeline_provider_service.dart';

/// AssetEntity 加载器
/// 负责延迟获取和缓存 AssetEntity
class AssetEntityLoader {
  final Logger _logger = Logger('AssetEntityLoader');
  
  /// 最大缓存数量（LRU 缓存）
  static const int _maxCacheSize = 200;
  
  /// AssetEntity 缓存（LRU）
  final LinkedHashMap<String, AssetEntity> _cache = LinkedHashMap();
  
  /// 正在加载的 Future 缓存（避免重复请求）
  final Map<String, Future<AssetEntity?>> _loadingFutures = {};
  
  /// TimelineProviderService 引用（用于获取 AssetEntity）
  final TimelineProviderService _timelineProviderService;
  
  AssetEntityLoader({
    required TimelineProviderService timelineProviderService,
  }) : _timelineProviderService = timelineProviderService;
  
  /// 异步加载 AssetEntity
  /// 
  /// 策略：
  /// 1. 如果 LocalAsset 已有 assetEntity，直接返回
  /// 2. 检查缓存，命中则返回
  /// 3. 检查正在加载的 Future，避免重复请求
  /// 4. 调用 TimelineProviderService.getAssetEntityById() 获取
  /// 5. 缓存结果
  Future<AssetEntity?> loadAsync(LocalAsset asset) async {
    // 1. 如果已有 assetEntity，直接返回
    if (asset.assetEntity != null) {
      return asset.assetEntity;
    }
    
    final assetId = asset.id;
    
    // 2. 检查缓存
    if (_cache.containsKey(assetId)) {
      _logger.fine('AssetEntity cache hit: $assetId');
      // 更新 LRU 顺序
      final entity = _cache.remove(assetId);
      _cache[assetId] = entity!;
      return entity;
    }
    
    // 3. 检查正在加载的 Future
    if (_loadingFutures.containsKey(assetId)) {
      _logger.fine('AssetEntity loading in progress: $assetId');
      return await _loadingFutures[assetId];
    }
    
    // 4. 创建加载 Future
    final loadingFuture = _loadAssetEntity(assetId);
    _loadingFutures[assetId] = loadingFuture;
    
    try {
      final entity = await loadingFuture;
      
      // 5. 缓存结果
      if (entity != null) {
        _cacheAssetEntity(assetId, entity);
      }
      
      return entity;
    } finally {
      // 清理加载 Future
      _loadingFutures.remove(assetId);
    }
  }
  
  /// 批量加载 AssetEntity
  /// 
  /// 用于预加载场景，提升性能
  Future<Map<String, AssetEntity?>> loadBatch(List<LocalAsset> assets) async {
    final results = <String, AssetEntity?>{};
    
    // 过滤出需要加载的资产
    final assetsToLoad = assets.where((asset) => 
      asset.assetEntity == null && !_cache.containsKey(asset.id)
    ).toList();
    
    if (assetsToLoad.isEmpty) {
      // 所有资产都已缓存或已有 assetEntity
      for (final asset in assets) {
        if (asset.assetEntity != null) {
          results[asset.id] = asset.assetEntity;
        } else if (_cache.containsKey(asset.id)) {
          results[asset.id] = _cache[asset.id];
        }
      }
      return results;
    }
    
    // 批量加载
    final futures = assetsToLoad.map((asset) async {
      final entity = await loadAsync(asset);
      return MapEntry(asset.id, entity);
    });
    
    final batchResults = await Future.wait(futures);
    results.addEntries(batchResults);
    
    return results;
  }
  
  /// 实际加载 AssetEntity
  Future<AssetEntity?> _loadAssetEntity(String assetId) async {
    try {
      _logger.fine('Loading AssetEntity: $assetId');
      return await _timelineProviderService.getAssetEntityById(assetId);
    } catch (e) {
      _logger.warning('Failed to load AssetEntity: $assetId', e);
      return null;
    }
  }
  
  /// 缓存 AssetEntity（LRU 策略）
  void _cacheAssetEntity(String assetId, AssetEntity entity) {
    // 如果缓存已满，移除最久未使用的
    if (_cache.length >= _maxCacheSize && !_cache.containsKey(assetId)) {
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
      _logger.fine('Evicted AssetEntity from cache: $firstKey');
    }
    
    // 如果已存在，先移除（更新顺序）
    _cache.remove(assetId);
    
    // 添加到缓存末尾（最近使用）
    _cache[assetId] = entity;
  }
  
  /// 清除缓存
  void clearCache() {
    _cache.clear();
    _loadingFutures.clear();
    _logger.info('AssetEntity cache cleared');
  }
  
  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _cache.length,
      'maxCacheSize': _maxCacheSize,
      'loadingCount': _loadingFutures.length,
    };
  }
}

