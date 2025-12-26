// lib/infrastructure/asset/checksum_service.dart

import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/utils/file_hash_util.dart';

/// Checksum 服务（基础设施层）
///
/// **职责**：
/// - 计算文件 checksum
/// - 更新本地资产的 checksum
///
/// **职责边界**：
/// - ✅ **负责**：checksum 计算和本地资产 checksum 更新（通用的基础设施功能）
/// - ❌ **不负责**：远程资产同步（由同步模块负责）
/// - ❌ **不负责**：业务逻辑编排（由业务模块负责）
class ChecksumService {
  final AppDatabase _database;
  final Logger _logger = Logger('ChecksumService');

  ChecksumService({required AppDatabase database}) : _database = database;

  /// 计算文件 checksum（委托给统一工具类）
  ///
  /// **参数**：
  /// - [filePath] - 文件路径
  ///
  /// **返回**：MD5 哈希值（十六进制字符串，默认算法）
  Future<String> calculateFileChecksum(String filePath) async {
    return FileHashUtil.calculateFileChecksum(filePath);
  }

  /// 更新本地资产的 checksum
  ///
  /// **参数**：
  /// - [assetId] - 本地资产 ID
  /// - [checksum] - checksum 值
  ///
  /// **返回**：是否更新成功
  Future<bool> updateLocalAssetChecksum({
    required String assetId,
    required String checksum,
  }) async {
    try {
      final localAsset = await _database.localAssetDao.getAssetById(assetId);
      if (localAsset == null) {
        _logger.warning('Local asset not found: assetId=$assetId');
        return false;
      }

      if (localAsset.checksum == checksum) {
        // checksum 已是最新，无需更新
        return true;
      }

      final updatedAsset = localAsset.copyWith(
        checksum: Value(checksum),
        updatedAt: DateTime.now(),
      );
      await _database.localAssetDao.updateAsset(updatedAsset);

      _logger.info('Updated local asset checksum: assetId=$assetId');
      return true;
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to update local asset checksum: assetId=$assetId, error=$e',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// 获取或计算本地资产的 checksum
  ///
  /// **参数**：
  /// - [assetId] - 本地资产 ID
  /// - [filePath] - 文件路径（如果本地资产没有 checksum，则计算）
  ///
  /// **返回**：checksum 值，如果失败返回 null
  ///
  /// **性能优化**：
  /// - 使用流式读取计算 checksum，避免大文件导致内存溢出
  /// - 添加文件大小检查，对大文件进行警告
  /// - 详细的错误处理和日志记录
  Future<String?> getOrCalculateChecksum({
    required String assetId,
    required String filePath,
  }) async {
    try {
      // 1. 尝试从本地资产获取 checksum
      final localAsset = await _database.localAssetDao.getAssetById(assetId);
      if (localAsset == null) {
        _logger.warning('Local asset not found: assetId=$assetId');
        return null;
      }

      if (localAsset.checksum != null && localAsset.checksum!.isNotEmpty) {
        return localAsset.checksum;
      }

      // 2. 验证文件
      final validation = await FileHashUtil.validateFileForHashing(filePath);
      if (!validation.isValid) {
        _logger.warning('File not valid for checksum calculation: $filePath');
        return null;
      }

      // 3. 使用统一工具类计算 checksum（带错误处理）
      final checksum = await FileHashUtil.calculateFileChecksumSafe(
        filePath,
        logContext: 'assetId=$assetId',
      );

      if (checksum == null) {
        return null;
      }

      // 4. 更新本地资产的 checksum
      await updateLocalAssetChecksum(assetId: assetId, checksum: checksum);

      return checksum;
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to get or calculate checksum: assetId=$assetId, error=$e',
        e,
        stackTrace,
      );
      return null;
    }
  }
}

