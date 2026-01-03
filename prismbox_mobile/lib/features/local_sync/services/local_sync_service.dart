// lib/features/local_sync/services/local_sync_service.dart

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart' as pm;
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
import 'package:prismbox/data/database/enums/asset_type.dart';
import 'package:prismbox/data/database/enums/migration_status.dart';
import 'package:prismbox/features/local_sync/exceptions/sync_exception.dart';
import 'package:prismbox/features/local_sync/models/sync_result.dart';
import 'package:prismbox/utils/cancellation_token.dart';

/// 本地同步服务
/// 负责扫描系统相册并同步到数据库
class LocalSyncService {
  final AppDatabase _database;
  final Logger _logger = Logger('LocalSyncService');

  /// 批量处理大小
  static const int _batchSize = 100;

  /// 取消令牌
  CancellationToken? _cancellationToken;

  LocalSyncService({required AppDatabase database}) : _database = database;

  /// 同步本地媒体库到数据库
  ///
  /// [full] 是否全量同步（false 时尝试增量同步）
  /// [onProgress] 进度回调 (current, total)
  ///
  /// 返回同步结果
  Future<SyncResult> syncLocal({
    bool full = false,
    void Function(int current, int total)? onProgress,
  }) async {
    try {
      _cancellationToken = CancellationToken();

      // 检查权限
      final permission = await pm.PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        throw const PermissionException();
      }

      final dao = LocalAssetDao(_database);

      // 决定同步类型
      final shouldFullSync = full || await _shouldFullSync(dao);

      if (shouldFullSync) {
        return await _fullSync(dao, onProgress);
      } else {
        return await _incrementalSync(dao, onProgress);
      }
    } on SyncException {
      rethrow;
    } catch (e, stackTrace) {
      _logger.severe('同步失败', e, stackTrace);
      return SyncResult.failure('同步失败: ${e.toString()}');
    } finally {
      _cancellationToken = null;
    }
  }

  /// 取消同步
  void cancel() {
    _cancellationToken?.cancel();
    _cancellationToken = null;
  }

  /// 判断是否需要全量同步
  Future<bool> _shouldFullSync(LocalAssetDao dao) async {
    try {
      final assets = await dao.getAllAssets();
      return assets.isEmpty;
    } catch (e) {
      _logger.warning('检查数据库状态失败，执行全量同步', e);
      return true;
    }
  }

  /// 全量同步
  Future<SyncResult> _fullSync(
    LocalAssetDao dao,
    void Function(int current, int total)? onProgress,
  ) async {
    _logger.info('开始全量同步');

    try {
      // 获取所有相册
      final albums = await pm.PhotoManager.getAssetPathList(hasAll: true);

      if (albums.isEmpty) {
        _logger.warning('未找到相册');
        return SyncResult.success();
      }

      // 获取"所有照片"相册
      final allPhotosAlbum = albums.firstWhere(
        (album) => album.isAll,
        orElse: () => albums.first,
      );

      // 获取所有资产
      final totalCount = await allPhotosAlbum.assetCountAsync;
      _logger.info('找到 $totalCount 个资产');

      if (totalCount == 0) {
        return SyncResult.success();
      }

      int added = 0;
      int updated = 0;
      int processed = 0;

      // 分批处理
      for (int start = 0; start < totalCount; start += _batchSize) {
        // 检查取消
        if (_cancellationToken?.isCancelled ?? false) {
          _logger.info('同步已取消');
          break;
        }

        final end = (start + _batchSize).clamp(0, totalCount);
        final assets = await allPhotosAlbum.getAssetListRange(
          start: start,
          end: end,
        );

        // 转换为数据库实体
        final entities = <LocalAssetEntityData>[];
        for (final asset in assets) {
          try {
            final entity = await _convertToEntity(asset);
            entities.add(entity);
          } catch (e) {
            _logger.warning('转换资产失败: ${asset.id}', e);
            // 继续处理其他资产
          }
        }

        // 批量写入数据库
        if (entities.isNotEmpty) {
          try {
            await dao.insertAssets(entities);
            added += entities.length;
          } catch (e) {
            // 如果批量插入失败，使用 upsert 逐个处理
            _logger.warning('批量插入失败，使用 upsert 逐个处理', e);
            for (final entity in entities) {
              try {
                // 先检查是否存在，用于统计
                final existing = await dao.getAssetById(entity.id);

                // 如果资产已在私有空间，跳过更新（保护私有空间状态）
                if (existing != null && existing.isInPrivateSpace) {
                  _logger.fine(
                    'Skipping upsert for asset in private space: ${entity.id}',
                  );
                  continue;
                }

                await dao.insertOrUpdateAsset(entity);
                if (existing == null) {
                  added++;
                } else {
                  updated++;
                }
              } catch (e2) {
                // 检查是否是 UNIQUE constraint 错误
                if (e2.toString().contains('UNIQUE constraint') ||
                    e2.toString().contains('1555')) {
                  // 如果是唯一约束错误，说明记录已存在，尝试更新
                  try {
                    // 再次检查资产是否在私有空间（防止并发修改）
                    final existing = await dao.getAssetById(entity.id);
                    if (existing != null && existing.isInPrivateSpace) {
                      _logger.fine(
                        'Skipping update for asset in private space: ${entity.id}',
                      );
                      continue;
                    }

                    await dao.updateAsset(entity);
                    updated++;
                  } catch (e3) {
                    _logger.warning('更新资产失败: ${entity.id}', e3);
                  }
                } else {
                  _logger.warning('插入/更新资产失败: ${entity.id}', e2);
                }
              }
            }
          }
        }

        processed += entities.length;
        onProgress?.call(processed, totalCount);
      }

      // 检测已删除的资产
      final deleted = await _detectDeletedAssets(dao, allPhotosAlbum);

      _logger.info('全量同步完成: 新增 $added, 更新 $updated, 删除 $deleted');
      return SyncResult.success(
        added: added,
        updated: updated,
        deleted: deleted,
      );
    } catch (e, stackTrace) {
      _logger.severe('全量同步失败', e, stackTrace);
      throw DatabaseException('全量同步失败', e);
    }
  }

  /// 增量同步
  Future<SyncResult> _incrementalSync(
    LocalAssetDao dao,
    void Function(int current, int total)? onProgress,
  ) async {
    _logger.info('开始增量同步');

    try {
      // 获取数据库中的资产
      final existingAssets = await dao.getAllAssets();
      if (existingAssets.isEmpty) {
        // 如果没有数据，执行全量同步
        return await _fullSync(dao, onProgress);
      }

      // 获取数据库元数据
      final dbAssetCount = existingAssets.length;
      final dbLastModified = existingAssets
          .map((a) => a.updatedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);

      // 获取所有相册
      final albums = await pm.PhotoManager.getAssetPathList(hasAll: true);

      if (albums.isEmpty) {
        return SyncResult.success();
      }

      final allPhotosAlbum = albums.firstWhere(
        (album) => album.isAll,
        orElse: () => albums.first,
      );

      // 获取系统相册元数据
      final systemAssetCount = await allPhotosAlbum.assetCountAsync;

      // 快速路径：比较元数据
      // 如果资产数量相同且数据库最后修改时间较新，可能没有变化
      // 注意：这是一个优化，不能完全依赖，因为系统相册可能被外部修改
      if (systemAssetCount == dbAssetCount) {
        _logger.info('资产数量相同，进行详细对比');
      } else {
        _logger.info('资产数量变化: 数据库=$dbAssetCount, 系统=$systemAssetCount');
      }

      final totalCount = systemAssetCount;

      // 创建现有资产的 ID 集合（用于快速查找）
      final existingIds = <String>{};
      final existingMap = <String, LocalAssetEntityData>{};
      for (final asset in existingAssets) {
        existingIds.add(asset.id);
        existingMap[asset.id] = asset;
      }

      int added = 0;
      int updated = 0;
      int processed = 0;

      // 使用最后同步时间过滤（只处理修改时间在最后同步时间之后的资产）
      // 注意：photo_manager 可能不支持直接按修改时间过滤，所以我们需要获取所有资产后过滤
      final lastSyncTime = dbLastModified.subtract(
        const Duration(seconds: 1),
      ); // 稍微提前一点，避免边界问题

      // 分批处理
      for (int start = 0; start < totalCount; start += _batchSize) {
        // 检查取消
        if (_cancellationToken?.isCancelled ?? false) {
          _logger.info('同步已取消');
          break;
        }

        final end = (start + _batchSize).clamp(0, totalCount);
        final assets = await allPhotosAlbum.getAssetListRange(
          start: start,
          end: end,
        );

        final toInsert = <LocalAssetEntityData>[];
        final toUpdate = <LocalAssetEntityData>[];

        for (final asset in assets) {
          try {
            // 优化：只处理修改时间在最后同步时间之后的资产，或者是新资产
            final isNewAsset = !existingIds.contains(asset.id);
            final isModified = asset.modifiedDateTime.isAfter(lastSyncTime);

            if (!isNewAsset && !isModified) {
              // 跳过未修改的现有资产
              continue;
            }

            final entity = await _convertToEntity(asset);
            final existing = existingMap[entity.id];

            if (existing == null) {
              // 新增
              toInsert.add(entity);
            } else {
              // 如果资产已在私有空间，跳过更新（保护私有空间状态）
              if (existing.isInPrivateSpace) {
                _logger.fine(
                  'Skipping update for asset in private space: ${entity.id}',
                );
                continue;
              }

              // 检查是否需要更新（比较修改时间）
              if (entity.updatedAt.isAfter(existing.updatedAt)) {
                toUpdate.add(entity);
              }
            }
          } catch (e) {
            _logger.warning('转换资产失败: ${asset.id}', e);
          }
        }

        // 批量插入
        if (toInsert.isNotEmpty) {
          try {
            await dao.insertAssets(toInsert);
            added += toInsert.length;
          } catch (e) {
            _logger.warning('批量插入失败，使用 upsert 逐个处理', e);
            // 使用 upsert 逐个处理
            for (final entity in toInsert) {
              try {
                // 检查资产是否已在私有空间（防止并发修改）
                final existing = await dao.getAssetById(entity.id);
                if (existing != null && existing.isInPrivateSpace) {
                  _logger.fine(
                    'Skipping insert for asset in private space: ${entity.id}',
                  );
                  continue;
                }

                await dao.insertOrUpdateAsset(entity);
                added++;
              } catch (e2) {
                // 检查是否是 UNIQUE constraint 错误
                if (e2.toString().contains('UNIQUE constraint') ||
                    e2.toString().contains('1555')) {
                  // 如果是唯一约束错误，说明记录已存在，尝试更新
                  try {
                    // 再次检查资产是否在私有空间（防止并发修改）
                    final existing = await dao.getAssetById(entity.id);
                    if (existing != null && existing.isInPrivateSpace) {
                      _logger.fine(
                        'Skipping update for asset in private space: ${entity.id}',
                      );
                      continue;
                    }

                    await dao.updateAsset(entity);
                    updated++;
                  } catch (e3) {
                    _logger.warning('更新资产失败: ${entity.id}', e3);
                  }
                } else {
                  _logger.warning('插入/更新资产失败: ${entity.id}', e2);
                }
              }
            }
          }
        }

        // 批量更新
        for (final entity in toUpdate) {
          try {
            // 再次检查资产是否在私有空间（防止并发修改）
            final existing = await dao.getAssetById(entity.id);
            if (existing != null && existing.isInPrivateSpace) {
              _logger.fine(
                'Skipping update for asset in private space: ${entity.id}',
              );
              continue;
            }

            await dao.updateAsset(entity);
            updated++;
          } catch (e) {
            _logger.warning('更新资产失败: ${entity.id}', e);
          }
        }

        processed += assets.length;
        onProgress?.call(processed, totalCount);
      }

      // 检测已删除的资产
      final deleted = await _detectDeletedAssets(dao, allPhotosAlbum);

      _logger.info('增量同步完成: 新增 $added, 更新 $updated, 删除 $deleted');
      return SyncResult.success(
        added: added,
        updated: updated,
        deleted: deleted,
      );
    } catch (e, stackTrace) {
      _logger.severe('增量同步失败', e, stackTrace);
      throw DatabaseException('增量同步失败', e);
    }
  }

  /// 转换 AssetEntity 为 LocalAssetEntityData
  Future<LocalAssetEntityData> _convertToEntity(pm.AssetEntity asset) async {
    // 获取文件路径 - 使用 originFile 获取原始文件路径
    // 注意：originFile 返回原始文件的永久路径，不会被系统清理
    // file 可能返回处理后的临时文件（如应用 EXIF 旋转），路径可能包含 _exif.jpg 后缀
    final file = await asset.originFile;
    if (file == null) {
      throw Exception('无法获取文件对象: assetId=${asset.id}');
    }
    final path = file.path;
    if (path.isEmpty) {
      throw Exception('文件路径为空: assetId=${asset.id}');
    }

    // 获取原始文件名 - 使用 asset.title（推荐方式）
    // Android: asset.title 通常就是原始文件名
    // iOS 14+: asset.title 基本可靠
    // 注意：不要使用 originFile.path 来解析文件名，因为它在 iOS 上是临时文件，文件名是随机的
    final originalFileName = asset.title ?? '';

    // 转换资产类型
    // photo_manager 的 AssetType 是枚举，需要转换为我们的 AssetType
    // AssetEntity.type 返回的是 AssetType 枚举值，使用索引值判断
    AssetType assetType;
    // photo_manager AssetType 枚举值：image=1, video=2, audio=3
    final typeIndex = asset.type.index;
    if (typeIndex == 1) {
      assetType = AssetType.image;
    } else if (typeIndex == 2) {
      assetType = AssetType.video;
    } else if (typeIndex == 3) {
      assetType = AssetType.audio;
    } else {
      assetType = AssetType.other;
    }

    return LocalAssetEntityData(
      id: asset.id,
      name: originalFileName, // 使用 asset.title 获取的原始文件名
      isUploaded: false, // 新同步的资产默认未上传
      type: assetType,
      createdAt: asset.createDateTime,
      updatedAt: asset.modifiedDateTime,
      width: asset.width,
      height: asset.height,
      durationInSeconds: asset.duration,
      isFavorite: false,
      orientation: asset.orientation,
      path: path.isNotEmpty ? path : asset.id, // 如果路径为空，使用 ID 作为备用
      isInPrivateSpace: false, // 新同步的资产默认不在私有空间
      migrationStatus: MigrationStatus.none, // 新同步的资产默认无迁移状态
    );
  }

  /// 检测已删除的资产
  Future<int> _detectDeletedAssets(
    LocalAssetDao dao,
    pm.AssetPathEntity album,
  ) async {
    try {
      final existingAssets = await dao.getAllAssets();
      if (existingAssets.isEmpty) {
        return 0;
      }

      // 获取当前系统相册中的所有资产 ID
      final totalCount = await album.assetCountAsync;
      final systemAssetIds = <String>{};

      // 分批获取系统资产 ID
      for (int start = 0; start < totalCount; start += _batchSize) {
        final end = (start + _batchSize).clamp(0, totalCount);
        final assets = await album.getAssetListRange(start: start, end: end);
        for (final asset in assets) {
          systemAssetIds.add(asset.id);
        }
      }

      // 找出数据库中但系统相册中不存在的资产
      // 注意：如果资产在私有空间，即使系统相册中不存在，也不应该删除
      // 注意：已软删除的资产（deletedAt != null）不应该被硬删除，它们已经在回收站
      int deleted = 0;
      for (final existing in existingAssets) {
        // 跳过私有空间中的资产（它们已经从系统相册删除）
        if (existing.isInPrivateSpace) {
          continue;
        }

        // 跳过已软删除的资产（它们已经在回收站，不应该被硬删除）
        if (existing.deletedAt != null) {
          _logger.fine('跳过已软删除的资产: ${existing.id}');
          continue;
        }

        if (!systemAssetIds.contains(existing.id)) {
          try {
            await dao.deleteAsset(existing.id);
            deleted++;
          } catch (e) {
            _logger.warning('删除资产失败: ${existing.id}', e);
          }
        }
      }

      return deleted;
    } catch (e) {
      _logger.warning('检测已删除资产失败', e);
      return 0;
    }
  }
}
