// lib/infrastructure/asset/asset_path_resolver.dart

import 'dart:io';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart' as pm;
import 'package:prismbox/data/database/app_database.dart';

/// 资产路径解析器（基础设施层）
///
/// **职责**：
/// - 解析资产的文件路径
/// - 处理文件不存在的情况（通过 photo_manager 重新获取）
/// - 验证文件存在性
///
/// **职责边界**：
/// - ✅ **负责**：通用的资产路径解析功能
/// - ❌ **不负责**：业务逻辑编排（由业务模块负责）
class AssetPathResolver {
  final AppDatabase? _database;
  final Logger _logger = Logger('AssetPathResolver');

  AssetPathResolver({AppDatabase? database}) : _database = database;

  /// 解析资产的文件路径
  ///
  /// **参数**：
  /// - [asset] - 本地资产实体
  ///
  /// **返回**：
  /// - 文件路径（如果文件存在）
  /// - null（如果文件不存在且无法通过 photo_manager 获取）
  ///
  /// **实现逻辑**：
  /// 1. 首先检查 `asset.path` 是否存在
  /// 2. 如果不存在，通过 `photo_manager` 的 `AssetEntity.fromId` 重新获取
  /// 3. 使用 `originFile` 获取原始文件路径
  Future<String?> resolveAssetPath(LocalAssetEntityData asset) async {
    // 1. 首先检查 asset.path 是否存在
    final file = File(asset.path);
    if (await file.exists()) {
      return asset.path;
    }

    // 2. 文件不存在，尝试通过 photo_manager 重新获取
    _logger.warning(
      'File not found: ${asset.path}, trying to get from photo_manager',
    );

    try {
      final assetEntity = await pm.AssetEntity.fromId(asset.id);
      if (assetEntity != null) {
        // 使用 originFile 获取原始文件路径，确保获取的是永久文件
        final fileFromAsset = await assetEntity.originFile;
        if (fileFromAsset != null && await fileFromAsset.exists()) {
          final resolvedPath = fileFromAsset.path;
          _logger.info('Got file path from photo_manager: $resolvedPath');

          // 3. 如果路径已改变，更新数据库（如果提供了 database）
          if (resolvedPath != asset.path && _database != null) {
            try {
              final updatedAsset = asset.copyWith(
                path: resolvedPath,
                updatedAt: DateTime.now(),
              );
              await _database.localAssetDao.updateAsset(updatedAsset);
              _logger.info('Updated asset path in database: ${asset.id}');
            } catch (e) {
              _logger.warning(
                'Failed to update asset path in database: ${asset.id}',
                e,
              );
              // 继续返回路径，即使更新数据库失败
            }
          }

          return resolvedPath;
        } else {
          _logger.warning('File not found in photo_manager: ${asset.id}');
          return null;
        }
      } else {
        _logger.warning('AssetEntity not found: ${asset.id}');
        return null;
      }
    } catch (e) {
      _logger.warning(
        'Failed to get file from photo_manager for ${asset.id}: $e',
      );
      return null;
    }
  }

  /// 解析 Live Photo 主图资产对应的视频文件路径（motion 子类型）
  ///
  /// 本地模型下 Live Photo 只有一条主图资产，视频由同一 AssetEntity 提供。
  /// 通过 photo_manager 的 originFileWithSubtype / loadFile(withSubtype: true) 取视频文件。
  ///
  /// **参数**：
  /// - [imageAsset] - Live Photo 的主图本地资产（同一 AssetEntity 提供图片与视频）
  ///
  /// **返回**：
  /// - 视频文件路径；无法获取时返回 null
  Future<String?> resolveLivePhotoVideoPath(
    LocalAssetEntityData imageAsset,
  ) async {
    try {
      final assetEntity = await pm.AssetEntity.fromId(imageAsset.id);
      if (assetEntity == null) {
        _logger.warning(
          'AssetEntity not found for Live Photo video: ${imageAsset.id}',
        );
        return null;
      }
      // 与 video_provider 一致：优先 originFileWithSubtype，回退 loadFile(withSubtype: true)
      File? file = await assetEntity.originFileWithSubtype;
      file ??= await assetEntity.loadFile(withSubtype: true);
      if (file == null || !await file.exists()) {
        _logger.warning(
          'Live Photo video file not found for asset: ${imageAsset.id}',
        );
        return null;
      }
      final path = file.path;
      if (path.isEmpty) return null;
      _logger.info(
        'Resolved Live Photo video path for ${imageAsset.id}: ${path.split("/").last}',
      );
      return path;
    } catch (e) {
      _logger.warning(
        'Failed to resolve Live Photo video path for ${imageAsset.id}: $e',
      );
      return null;
    }
  }

  /// 验证文件是否存在
  ///
  /// **参数**：
  /// - [path] - 文件路径
  ///
  /// **返回**：
  /// - true（如果文件存在）
  /// - false（如果文件不存在）
  Future<bool> validateFileExists(String path) async {
    try {
      final file = File(path);
      return await file.exists();
    } catch (e) {
      _logger.warning('Failed to validate file existence: $path, error: $e');
      return false;
    }
  }
}

