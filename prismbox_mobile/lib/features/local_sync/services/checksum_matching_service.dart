// lib/features/local_sync/services/checksum_matching_service.dart

import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
import 'package:prismbox/data/database/daos/remote_asset_dao.dart';
import 'package:prismbox/infrastructure/asset/asset_path_resolver.dart';
import 'package:prismbox/infrastructure/asset/checksum_service.dart';

/// Checksum 匹配服务
/// 
/// **职责**：
/// - 为本地资产计算 checksum
/// - 通过 checksum 匹配远程资产
/// - 更新本地数据库关联
/// 
/// **使用场景**：
/// - 本地同步完成后，在后台异步执行 checksum 计算和匹配
/// - 用于识别哪些本地资产已经在服务器上存在（通过 checksum 匹配）
class ChecksumMatchingService {
  final AppDatabase _database;
  final ChecksumService _checksumService;
  final AssetPathResolver _pathResolver;
  final Logger _logger = Logger('ChecksumMatchingService');

  ChecksumMatchingService({
    required AppDatabase database,
    required ChecksumService checksumService,
    required AssetPathResolver pathResolver,
  })  : _database = database,
        _checksumService = checksumService,
        _pathResolver = pathResolver;

  /// 启动后台任务：为没有 checksum 的本地资产计算 checksum 并匹配远程资产
  /// 
  /// **注意**：这是一个耗时的操作，在后台异步执行，不阻塞调用者
  /// 
  /// **返回**：匹配到的远程资产数量
  Future<int> startMatchingTask() async {
    try {
      _logger.info('启动后台任务：计算 checksum 并匹配远程资产');
      final localDao = LocalAssetDao(_database);
      final remoteDao = RemoteAssetDao(_database);

      // 获取所有没有 checksum 的本地资产
      final localAssets = await localDao.getAllAssets();
      final assetsWithoutChecksum = localAssets
          .where((asset) => asset.checksum == null || asset.checksum!.isEmpty)
          .toList();

      if (assetsWithoutChecksum.isEmpty) {
        _logger.info('所有本地资产都有 checksum，跳过匹配任务');
        return 0;
      }

      _logger.info(
        '找到 ${assetsWithoutChecksum.length} 个没有 checksum 的本地资产，开始计算并匹配',
      );

      int matchedCount = 0;
      int processedCount = 0;

      // 分批处理，避免一次性处理太多
      const batchSize = 10;
      for (int i = 0; i < assetsWithoutChecksum.length; i += batchSize) {
        final batch = assetsWithoutChecksum.skip(i).take(batchSize).toList();

        for (final localAsset in batch) {
          try {
            // 使用 AssetPathResolver 解析文件路径（与上传时保持一致）
            // 确保匹配时使用的文件路径与上传时相同
            final actualPath = await _pathResolver.resolveAssetPath(localAsset);
            if (actualPath == null) {
              _logger.warning(
                '无法解析文件路径: assetId=${localAsset.id}, path=${localAsset.path}',
              );
              processedCount++;
              continue;
            }

            // 计算 checksum（使用解析后的实际路径）
            final checksum = await _checksumService.getOrCalculateChecksum(
              assetId: localAsset.id,
              filePath: actualPath,
            );

            if (checksum != null && checksum.isNotEmpty) {
              // 查找匹配的远程资产
              final remoteAsset = await remoteDao.getAssetByChecksum(checksum);
              if (remoteAsset != null) {
                matchedCount++;
                _logger.fine(
                  '匹配到远程资产: localId=${localAsset.id}, '
                  'remoteId=${remoteAsset.id}, checksum=$checksum',
                );
              }
            }

            processedCount++;

            // 每处理 10 个资产记录一次日志
            if (processedCount % 10 == 0) {
              _logger.info(
                'Checksum 匹配进度: $processedCount/${assetsWithoutChecksum.length}, '
                '已匹配: $matchedCount',
              );
            }
          } catch (e) {
            _logger.warning(
              '处理资产失败: assetId=${localAsset.id}',
              e,
            );
          }
        }
      }

      _logger.info(
        'Checksum 匹配任务完成: 处理了 $processedCount 个资产，'
        '匹配到 $matchedCount 个远程资产',
      );

      return matchedCount;
    } catch (e, stackTrace) {
      _logger.warning('Checksum 匹配任务失败', e, stackTrace);
      return 0;
    }
  }
}

