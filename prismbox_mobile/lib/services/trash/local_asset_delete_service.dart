// lib/services/trash/local_asset_delete_service.dart

import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
import 'package:prismbox/services/trash/trash_storage_service.dart';

/// 本地资源删除服务
/// 负责本地资源的软删除操作
class LocalAssetDeleteService {
  final Logger _logger = Logger('LocalAssetDeleteService');
  final LocalAssetDao _dao;
  final TrashStorageService _trashStorage;

  LocalAssetDeleteService({
    required LocalAssetDao dao,
    required TrashStorageService trashStorage,
  }) : _dao = dao,
       _trashStorage = trashStorage;

  /// 软删除本地资源
  ///
  /// **参数**：
  /// - [assetId] - 资产 ID
  ///
  /// **行为**：
  /// 1. 通过 AssetEntity 获取实际文件路径（不依赖数据库路径）
  /// 2. 将文件复制到回收站
  /// 3. 删除系统相册中的原文件
  /// 4. 更新数据库软删除字段
  ///
  /// **返回**：是否成功
  Future<bool> softDeleteAsset(String assetId) async {
    try {
      // 1. 获取资产信息（仅用于检查是否已删除）
      final asset = await _dao.getAssetById(assetId);
      if (asset == null) {
        _logger.warning('资产不存在: $assetId');
        return false;
      }

      if (asset.deletedAt != null) {
        _logger.warning('资产已删除: $assetId');
        return false;
      }

      // 2. 通过 AssetEntity 获取实际文件路径（不依赖数据库路径）
      final assetEntity = await AssetEntity.fromId(assetId);
      if (assetEntity == null) {
        _logger.warning('无法获取 AssetEntity: $assetId');
        return false;
      }

      final originFile = await assetEntity.originFile;
      if (originFile == null || !await originFile.exists()) {
        _logger.warning('无法获取有效文件: $assetId');
        return false;
      }

      final actualPath = originFile.path;
      _logger.info('通过 AssetEntity 获取到实际路径: $actualPath');

      // 3. 将文件复制到回收站
      final trashPath = await _trashStorage.moveToTrash(
        sourceFile: actualPath,
        assetId: assetId,
      );

      // 4. 删除系统相册中的原文件
      await _trashStorage.deleteFromSystemAlbum(assetId);

      // 5. 更新数据库软删除字段（保存实际路径作为 originalPath）
      final success = await _dao.softDeleteAsset(
        id: assetId,
        originalPath: actualPath, // 保存从 AssetEntity 获取的实际路径
        trashPath: trashPath,
      );

      if (success) {
        _logger.info('本地资源已软删除: $assetId');
      } else {
        _logger.warning('更新数据库失败: $assetId');
      }

      return success;
    } catch (e, stackTrace) {
      _logger.severe('软删除本地资源失败: $assetId', e, stackTrace);
      return false;
    }
  }

  /// 批量软删除本地资源
  ///
  /// **参数**：
  /// - [assetIds] - 资产 ID 列表
  ///
  /// **返回**：成功删除的数量
  ///
  /// **行为**：
  /// 两阶段批量删除流程：
  /// 1. 阶段一：批量处理文件复制和数据库更新（不涉及系统相册删除）
  /// 2. 阶段二：统一批量删除系统相册资产（只弹出一次确认对话框）
  Future<int> softDeleteAssets(List<String> assetIds) async {
    if (assetIds.isEmpty) {
      return 0;
    }

    final processedIds = <String>[];
    final trashPaths = <String, String>{}; // assetId -> trashPath

    // 阶段一：批量处理文件复制和数据库更新（不涉及系统相册删除）
    for (final assetId in assetIds) {
      try {
        // 1. 检查资产
        final asset = await _dao.getAssetById(assetId);
        if (asset == null) {
          _logger.warning('资产不存在: $assetId');
          continue;
        }

        if (asset.deletedAt != null) {
          _logger.warning('资产已删除: $assetId');
          continue;
        }

        // 2. 获取实际文件路径
        final assetEntity = await AssetEntity.fromId(assetId);
        if (assetEntity == null) {
          _logger.warning('无法获取 AssetEntity: $assetId');
          continue;
        }

        final originFile = await assetEntity.originFile;
        if (originFile == null || !await originFile.exists()) {
          _logger.warning('无法获取有效文件: $assetId');
          continue;
        }

        final actualPath = originFile.path;
        _logger.info('通过 AssetEntity 获取到实际路径: $actualPath');

        // 3. 复制到回收站
        final trashPath = await _trashStorage.moveToTrash(
          sourceFile: actualPath,
          assetId: assetId,
        );
        trashPaths[assetId] = trashPath;

        // 4. 更新数据库
        final success = await _dao.softDeleteAsset(
          id: assetId,
          originalPath: actualPath,
          trashPath: trashPath,
        );

        if (success) {
          processedIds.add(assetId);
          _logger.info('本地资源已软删除（阶段一）: $assetId');
        } else {
          _logger.warning('更新数据库失败: $assetId');
        }
      } catch (e, stackTrace) {
        _logger.warning('处理资产失败: $assetId', e, stackTrace);
      }
    }

    // 阶段二：统一批量删除系统相册资产（只弹出一次确认对话框）
    if (processedIds.isNotEmpty) {
      try {
        final deletedIds = await _trashStorage.deleteMultipleFromSystemAlbum(
          processedIds,
        );

        // 记录删除结果
        final failedSystemDeletes = processedIds
            .where((id) => !deletedIds.contains(id))
            .toList();
        if (failedSystemDeletes.isNotEmpty) {
          _logger.warning(
            '以下资产系统相册删除失败（但已移入回收站）: $failedSystemDeletes',
          );
        }
      } catch (e, stackTrace) {
        _logger.warning(
          '批量删除系统相册文件失败（但文件已移入回收站）',
          e,
          stackTrace,
        );
        // 不抛出异常，因为文件已经复制到回收站，可以从回收站恢复
      }
    }

    _logger.info('批量软删除完成: ${processedIds.length}/${assetIds.length}');
    return processedIds.length;
  }
}
