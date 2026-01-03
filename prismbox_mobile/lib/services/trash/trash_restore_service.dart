// lib/services/trash/trash_restore_service.dart

import 'dart:io';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart' hide AssetType;
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
import 'package:prismbox/data/database/daos/remote_asset_dao.dart';
import 'package:prismbox/data/database/enums/asset_type.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';

/// 回收站恢复服务
/// 负责从回收站恢复已删除的资源
class TrashRestoreService {
  final Logger _logger = Logger('TrashRestoreService');
  final LocalAssetDao _localDao;
  final RemoteAssetDao _remoteDao;
  final ApiService _apiService;

  TrashRestoreService({
    required LocalAssetDao localDao,
    required RemoteAssetDao remoteDao,
    required ApiService apiService,
  }) : _localDao = localDao,
       _remoteDao = remoteDao,
       _apiService = apiService;

  /// 恢复本地资源
  ///
  /// **参数**：
  /// - [assetId] - 资产 ID（旧的 assetId，恢复后会更新）
  ///
  /// **行为**：
  /// 1. 从回收站复制文件到临时位置
  /// 2. 使用 photo_manager 将文件添加回系统相册，获取新的 AssetEntity 和 assetId
  /// 3. 删除回收站文件和临时文件
  /// 4. 更新数据库：更新 assetId、path，清空软删除字段
  ///
  /// **返回**：是否成功
  Future<bool> restoreLocalAsset(String assetId) async {
    File? tempFile;
    try {
      // 1. 获取资产信息
      final asset = await _localDao.getAssetById(assetId);
      if (asset == null) {
        _logger.warning('资产不存在: $assetId');
        return false;
      }

      if (asset.deletedAt == null) {
        _logger.warning('资产未删除: $assetId');
        return false;
      }

      final trashPath = asset.trashPath;
      final originalPath = asset.originalPath;

      if (trashPath == null || trashPath.isEmpty) {
        _logger.warning('回收站路径为空: $assetId');
        return false;
      }

      if (originalPath == null || originalPath.isEmpty) {
        _logger.warning('原始路径为空: $assetId');
        return false;
      }

      // 2. 从回收站复制文件到临时位置（用于添加到系统相册）
      // 注意：不能直接恢复到原始路径，因为原始路径可能已被其他文件占用
      // 先复制到临时位置，添加到系统相册后，系统会管理文件位置
      final trashFile = File(trashPath);
      if (!await trashFile.exists()) {
        _logger.warning('回收站文件不存在: $trashPath');
        return false;
      }

      // 创建临时文件
      final tempDir = Directory.systemTemp;
      final tempFileName =
          'restore_${asset.id}_${DateTime.now().millisecondsSinceEpoch}${_getFileExtension(trashPath)}';
      tempFile = File('${tempDir.path}/$tempFileName');
      await trashFile.copy(tempFile.path);

      // 3. 使用 photo_manager 将文件添加回系统相册
      AssetEntity newAssetEntity;
      if (asset.type == AssetType.image) {
        // saveImage 接受 Uint8List（图片字节数据）和文件名
        final imageBytes = await tempFile.readAsBytes();
        newAssetEntity = await PhotoManager.editor.saveImage(
          imageBytes,
          title: asset.name,
          filename: asset.name,
        );
      } else if (asset.type == AssetType.video) {
        // saveVideo 接受 File 对象和文件名
        newAssetEntity = await PhotoManager.editor.saveVideo(
          tempFile,
          title: asset.name,
        );
      } else {
        _logger.warning('不支持的资产类型: ${asset.type}');
        return false;
      }

      // saveImage 和 saveVideo 返回的 AssetEntity 不会为 null（如果成功）
      // 如果失败会抛出异常

      // 获取新的 assetId 和文件路径
      final newAssetId = newAssetEntity.id;
      final newAssetFile = await newAssetEntity.originFile;
      final newPath = newAssetFile?.path ?? originalPath;

      _logger.info('文件已添加回系统相册: 旧 assetId=$assetId, 新 assetId=$newAssetId');

      // 4. 删除回收站文件
      try {
        await trashFile.delete();
        _logger.info('回收站文件已删除: $trashPath');
      } catch (e) {
        _logger.warning('删除回收站文件失败: $trashPath', e);
        // 继续执行，不影响恢复流程
      }

      // 5. 更新数据库：更新 assetId、path，清空软删除字段
      // 如果 assetId 发生变化，需要先删除旧记录，再插入新记录
      final success = await _localDao.restoreAssetWithNewId(
        oldId: assetId,
        newId: newAssetId,
        restoredPath: newPath,
      );

      if (success) {
        _logger.info('本地资源已恢复: 旧 assetId=$assetId, 新 assetId=$newAssetId');
      } else {
        _logger.warning('更新数据库失败: $assetId');
      }

      return success;
    } catch (e, stackTrace) {
      _logger.severe('恢复本地资源失败: $assetId', e, stackTrace);
      return false;
    } finally {
      // 清理临时文件
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (e) {
          _logger.warning('删除临时文件失败: ${tempFile.path}', e);
        }
      }
    }
  }

  /// 获取文件扩展名
  String _getFileExtension(String filePath) {
    final lastDot = filePath.lastIndexOf('.');
    if (lastDot == -1) {
      return '';
    }
    return filePath.substring(lastDot);
  }

  /// 恢复远程资源
  ///
  /// **参数**：
  /// - [assetId] - 资产 ID（UUID）
  ///
  /// **行为**：
  /// 1. 检查本地数据库中是否存在该记录
  /// 2. 调用后端 API `POST /api/v1/media/:uuid/restore` 恢复资源
  /// 3. 如果记录存在，更新本地数据库的 `deletedAt` 字段为 NULL
  /// 4. 如果记录不存在，说明该资产从未同步到本地，后端已恢复，等待下次同步即可
  ///
  /// **返回**：是否成功
  Future<bool> restoreRemoteAsset(String assetId) async {
    try {
      // 1. 检查本地数据库中是否存在该记录
      final existingAsset = await _remoteDao.getAssetById(assetId);
      _logger.info(
        '恢复前检查记录: assetId=$assetId, '
        'exists=${existingAsset != null}, '
        'deletedAt=${existingAsset?.deletedAt}',
      );

      // 2. 调用后端 API
      final endpoint = _apiService.endpoint;
      if (endpoint == null || endpoint.isEmpty) {
        _logger.warning('API endpoint 未配置');
        return false;
      }

      final url = '$endpoint/api/v1/media/$assetId/restore';
      final response = await _apiService.dio.post(url);

      if (response.statusCode != 200) {
        _logger.warning('后端 API 返回错误: ${response.statusCode}');
        return false;
      }

      _logger.info('后端 API 恢复成功: $assetId');

      // 3. 如果记录不存在，说明该资产从未同步到本地
      // 后端已恢复，等待下次远程同步即可，返回 true 表示后端操作成功
      if (existingAsset == null) {
        _logger.info(
          '本地数据库中不存在该远程资产记录: $assetId。'
          '后端已恢复，等待下次远程同步来补充数据。',
        );
        return true; // 后端已恢复，返回成功
      }

      // 4. 记录存在，更新本地数据库
      final success = await _remoteDao.restoreAsset(assetId);

      if (success) {
        _logger.info('远程资源已恢复: $assetId');
      } else {
        // 记录存在但更新失败，可能是 deletedAt 已经是 NULL
        // 再次检查记录状态
        final assetAfterUpdate = await _remoteDao.getAssetById(assetId);
        if (assetAfterUpdate != null && assetAfterUpdate.deletedAt == null) {
          _logger.info(
            '记录已恢复（deletedAt 已经是 NULL）: $assetId。'
            '可能是并发操作或远程同步已更新。',
          );
          return true; // 实际上已经恢复
        }
        _logger.warning(
          '更新本地数据库失败: $assetId。'
          '记录存在但更新操作返回 false。',
        );
      }

      return success;
    } catch (e, stackTrace) {
      _logger.severe('恢复远程资源失败: $assetId', e, stackTrace);
      return false;
    }
  }

  /// 批量恢复资源
  ///
  /// **参数**：
  /// - [localAssetIds] - 本地资产 ID 列表
  /// - [remoteAssetIds] - 远程资产 ID 列表
  ///
  /// **返回**：成功恢复的数量
  Future<int> restoreAssets({
    List<String>? localAssetIds,
    List<String>? remoteAssetIds,
  }) async {
    int successCount = 0;

    // 恢复本地资源
    if (localAssetIds != null && localAssetIds.isNotEmpty) {
      for (final assetId in localAssetIds) {
        final success = await restoreLocalAsset(assetId);
        if (success) {
          successCount++;
        }
      }
    }

    // 恢复远程资源
    if (remoteAssetIds != null && remoteAssetIds.isNotEmpty) {
      for (final assetId in remoteAssetIds) {
        final success = await restoreRemoteAsset(assetId);
        if (success) {
          successCount++;
        }
      }
    }

    _logger.info('批量恢复完成: $successCount');
    return successCount;
  }
}
