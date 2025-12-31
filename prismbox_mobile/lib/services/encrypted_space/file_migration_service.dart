// lib/services/encrypted_space/file_migration_service.dart

import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart' as pm;
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/migration_status.dart';
import 'package:uuid/uuid.dart';

/// 文件迁移服务
/// 负责文件在系统相册和私有空间之间的迁移，使用事务保护
class FileMigrationService {
  final AppDatabase _database;
  final Logger _log = Logger('FileMigrationService');

  // 私有空间目录名称
  static const String _privateSpaceDirName = 'encrypted_space';

  FileMigrationService({required AppDatabase database}) : _database = database;

  /// 获取私有空间目录
  Future<Directory> _getPrivateSpaceDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final privateDir = Directory(p.join(appDir.path, _privateSpaceDirName));

    if (!await privateDir.exists()) {
      await privateDir.create(recursive: true);
    }

    return privateDir;
  }

  /// 迁移文件到私有空间
  /// 使用事务保护，确保文件操作和数据库操作的一致性
  ///
  /// [deleteFromSystemAlbum] 是否立即从系统相册删除文件（默认 true，保持向后兼容）
  /// 如果为 false，需要调用 batchDeleteFromSystemAlbum 批量删除
  Future<void> moveAssetToPrivateSpace({
    required String assetId,
    bool deleteFromSystemAlbum = true, // 新增参数，默认为 true
  }) async {
    // 保存原始 assetId，用于后续删除系统相册中的文件
    String? originalAssetIdForDeletion = deleteFromSystemAlbum ? assetId : null;

    await _database.transaction(() async {
      try {
        // 1. 获取资产信息
        final assetDao = _database.localAssetDao;
        final asset = await assetDao.getAssetById(assetId);
        if (asset == null) {
          throw Exception('Asset not found: $assetId');
        }

        // 2. 检查是否已在私有空间
        if (asset.isInPrivateSpace) {
          _log.info('Asset already in private space: $assetId');
          return;
        }

        // 3. 标记迁移状态为 pending
        await (_database.update(
          _database.localAssetEntity,
        )..where((t) => t.id.equals(assetId))).write(
          LocalAssetEntityCompanion(
            migrationStatus: Value(MigrationStatus.pending),
            updatedAt: Value(DateTime.now()),
          ),
        );

        // 4. 读取原始文件
        // 首先尝试使用数据库中的路径
        File sourceFile = File(asset.path);
        String sourcePath = asset.path;

        if (!await sourceFile.exists()) {
          // 数据库路径不存在，尝试通过 photo_manager 获取文件
          _log.warning(
            'File not found at database path: ${asset.path}, '
            'trying to get from photo_manager',
          );

          try {
            final assetEntity = await pm.AssetEntity.fromId(assetId);
            if (assetEntity != null) {
              final fileFromAsset = await assetEntity.originFile;
              if (fileFromAsset != null && await fileFromAsset.exists()) {
                sourcePath = fileFromAsset.path;
                sourceFile = fileFromAsset;
                _log.info('Got file path from photo_manager: $sourcePath');

                // 更新数据库中的路径
                await (_database.update(
                  _database.localAssetEntity,
                )..where((t) => t.id.equals(assetId))).write(
                  LocalAssetEntityCompanion(
                    path: Value(sourcePath),
                    updatedAt: Value(DateTime.now()),
                  ),
                );
              } else {
                throw Exception(
                  'File not found in photo_manager: $assetId. '
                  'Database path: ${asset.path}',
                );
              }
            } else {
              throw Exception(
                'AssetEntity not found: $assetId. '
                'Database path: ${asset.path}',
              );
            }
          } catch (e) {
            _log.severe('Failed to get file from photo_manager: $assetId', e);
            throw Exception(
              'Source file not found: ${asset.path}. '
              'Also failed to get from photo_manager: $e',
            );
          }
        }

        // 5. 创建临时文件路径
        final privateDir = await _getPrivateSpaceDirectory();
        final tempFileName = '${const Uuid().v4()}_${p.basename(sourcePath)}';
        final tempPath = p.join(privateDir.path, tempFileName);
        final tempFile = File(tempPath);

        // 6. 复制文件到临时路径
        await sourceFile.copy(tempPath);

        // 7. 验证文件完整性（计算校验和）
        final sourceChecksum = await _calculateFileChecksum(sourceFile);
        final tempChecksum = await _calculateFileChecksum(tempFile);
        if (sourceChecksum != tempChecksum) {
          await tempFile.delete();
          throw Exception('File integrity check failed');
        }

        // 8. 原子性重命名到最终路径
        // 使用原文件名（从源文件路径提取），保留原始文件名
        final originalFileName = p.basename(sourcePath);
        // 清理文件名中可能存在的路径分隔符（虽然 basename 已经处理，但为了安全起见）
        final safeFileName = originalFileName.replaceAll(RegExp(r'[/\\]'), '_');

        // 生成唯一的文件名（如果文件已存在，添加序号后缀）
        final finalPath = await _generateUniqueFilePath(
          privateDir,
          safeFileName,
        );

        await tempFile.rename(finalPath);

        // 9. 更新数据库（在事务中）
        await (_database.update(
          _database.localAssetEntity,
        )..where((t) => t.id.equals(assetId))).write(
          LocalAssetEntityCompanion(
            path: Value(finalPath),
            isInPrivateSpace: Value(true),
            migrationStatus: Value(MigrationStatus.success),
            updatedAt: Value(DateTime.now()),
          ),
        );

        _log.info('Asset migrated to private space: $assetId');
      } catch (e, stackTrace) {
        _log.severe(
          'Failed to migrate asset to private space: $assetId',
          e,
          stackTrace,
        );

        // 回滚：标记迁移状态为 failed
        try {
          await (_database.update(
            _database.localAssetEntity,
          )..where((t) => t.id.equals(assetId))).write(
            LocalAssetEntityCompanion(
              migrationStatus: Value(MigrationStatus.failed),
              updatedAt: Value(DateTime.now()),
            ),
          );
        } catch (updateError) {
          _log.warning('Failed to update migration status', updateError);
        }

        // 如果迁移失败，不需要删除系统相册中的文件
        originalAssetIdForDeletion = null;

        rethrow;
      }
    });

    // 10. 提交事务后从系统相册删除原始文件（仅在 deleteFromSystemAlbum 为 true 时执行）
    // 注意：删除操作在事务外执行，避免影响事务性能
    // 如果删除失败，记录错误但不影响已提交的数据库状态
    final assetIdToDelete = originalAssetIdForDeletion;
    if (assetIdToDelete != null) {
      try {
        // 验证资产是否存在于系统相册中
        final assetEntity = await pm.AssetEntity.fromId(assetIdToDelete);
        if (assetEntity != null) {
          // 使用 photo_manager 删除系统相册中的资产
          final deleteResult = await pm.PhotoManager.editor.deleteWithIds([
            assetIdToDelete,
          ]);
          if (deleteResult.isNotEmpty) {
            final success = deleteResult.first;
            if (success == true) {
              _log.info(
                'Original asset deleted from system album: $assetIdToDelete',
              );
            } else {
              _log.warning(
                'Failed to delete asset from system album: $assetIdToDelete (deleteWithIds returned false)',
              );
            }
          } else {
            _log.warning(
              'Failed to delete asset from system album: $assetIdToDelete (deleteWithIds returned empty list)',
            );
          }
        } else {
          _log.info(
            'AssetEntity not found in system album (may have been deleted already): $assetIdToDelete',
          );
        }
      } catch (deleteError) {
        _log.warning(
          'Failed to delete asset from system album: $assetIdToDelete',
          deleteError,
        );
        // 不抛出异常，数据库状态已成功更新
      }
    }
  }

  /// 批量从系统相册删除资产
  /// 用于批量迁移后统一删除系统相册中的原始文件
  ///
  /// 优势：
  /// 1. 批量删除比逐个删除更高效
  /// 2. 统一确认，避免多次系统确认弹窗
  /// 3. 错误处理更集中
  Future<void> batchDeleteFromSystemAlbum({
    required List<String> assetIds,
  }) async {
    if (assetIds.isEmpty) {
      return;
    }

    try {
      _log.info(
        'Starting batch delete from system album: ${assetIds.length} assets',
      );

      // 验证所有资产是否存在于系统相册中
      final validAssetIds = <String>[];
      for (final assetId in assetIds) {
        try {
          final assetEntity = await pm.AssetEntity.fromId(assetId);
          if (assetEntity != null) {
            validAssetIds.add(assetId);
          } else {
            _log.fine(
              'AssetEntity not found in system album (may have been deleted already): $assetId',
            );
          }
        } catch (e) {
          _log.warning('Failed to verify asset before deletion: $assetId', e);
        }
      }

      if (validAssetIds.isEmpty) {
        _log.info('No valid assets to delete from system album');
        return;
      }

      _log.info(
        'Valid assets to delete: ${validAssetIds.length} out of ${assetIds.length}',
      );

      // 批量删除系统相册中的资产
      final deleteResult = await pm.PhotoManager.editor.deleteWithIds(
        validAssetIds,
      );

      if (deleteResult.isNotEmpty) {
        int successCount = 0;
        int failCount = 0;

        for (
          int i = 0;
          i < deleteResult.length && i < validAssetIds.length;
          i++
        ) {
          final success = deleteResult[i];
          if (success == true) {
            successCount++;
            _log.fine('Asset deleted from system album: ${validAssetIds[i]}');
          } else {
            failCount++;
            _log.warning(
              'Failed to delete asset from system album: ${validAssetIds[i]}',
            );
          }
        }

        _log.info(
          'Batch delete completed: $successCount succeeded, $failCount failed '
          'out of ${validAssetIds.length} assets',
        );
      } else {
        _log.warning(
          'Batch delete returned empty result for ${validAssetIds.length} assets',
        );
      }
    } catch (deleteError) {
      _log.severe(
        'Failed to batch delete assets from system album: ${assetIds.length} assets',
        deleteError,
      );
      // 不抛出异常，允许部分成功的情况
    }
  }

  /// 从私有空间移回系统相册
  /// 使用事务保护，确保文件操作和数据库操作的一致性
  Future<void> moveAssetFromPrivateSpace({required String assetId}) async {
    await _database.transaction(() async {
      try {
        // 1. 获取资产信息
        final assetDao = _database.localAssetDao;
        final asset = await assetDao.getAssetById(assetId);
        if (asset == null) {
          throw Exception('Asset not found: $assetId');
        }

        // 2. 检查是否在私有空间
        if (!asset.isInPrivateSpace) {
          _log.info('Asset not in private space: $assetId');
          return;
        }

        // 3. 标记移除状态为 pending
        await (_database.update(
          _database.localAssetEntity,
        )..where((t) => t.id.equals(assetId))).write(
          LocalAssetEntityCompanion(
            migrationStatus: Value(MigrationStatus.pending),
            updatedAt: Value(DateTime.now()),
          ),
        );

        // 4. 读取私有空间中的文件
        final privateFile = File(asset.path);
        if (!await privateFile.exists()) {
          throw Exception('Private space file not found: ${asset.path}');
        }

        // 5. 保存到系统相册（通过 photo_manager）
        // 使用 photo_manager 的 Editor API 保存文件到系统相册
        final fileName = p.basename(asset.path);
        final fileTitle = p.withoutExtension(fileName);

        // Android 上可以指定相对路径，iOS 上为 null
        final relativePath = null; // 保存到默认相册

        pm.AssetEntity savedAsset;
        try {
          // 根据资产类型选择不同的保存方法
          if (asset.type == 0) {
            // 图片 - 使用文件路径保存（更高效，避免读取整个文件到内存）
            savedAsset = await pm.PhotoManager.editor.saveImageWithPath(
              asset.path,
              title: fileTitle,
              relativePath: relativePath,
            );
          } else if (asset.type == 1) {
            // 视频 - 使用文件对象
            savedAsset = await pm.PhotoManager.editor.saveVideo(
              privateFile,
              title: fileTitle,
              relativePath: relativePath,
            );
          } else {
            throw Exception('Unsupported asset type: ${asset.type}');
          }
        } catch (e, stackTrace) {
          _log.severe(
            'Failed to save asset to system album using photo_manager',
            e,
            stackTrace,
          );
          throw Exception('Failed to save asset to system album: $e');
        }

        // 6. 获取新系统文件路径和新的Asset ID
        final originFile = await savedAsset.originFile;
        final newPath = originFile?.path;
        if (newPath == null) {
          throw Exception('Failed to get origin file path from saved asset');
        }

        final newAssetId = savedAsset.id;

        // 7. 更新数据库（在事务中）
        // 如果新Asset ID与旧ID不同，需要更新所有关联表
        if (newAssetId != assetId) {
          // 更新LocalAlbumAssetEntity中的assetId引用
          await _database.customStatement(
            '''
            UPDATE local_album_asset_entity 
            SET asset_id = ? 
            WHERE asset_id = ?
          ''',
            [newAssetId, assetId],
          );

          // 更新UploadTaskEntity中的assetId引用（如果有）
          await _database.customStatement(
            '''
            UPDATE upload_task_entity 
            SET asset_id = ? 
            WHERE asset_id = ?
          ''',
            [newAssetId, assetId],
          );

          // 删除旧记录并插入新记录（因为主键不能直接更新）
          final oldAsset = asset;
          final newAsset = LocalAssetEntityData(
            id: newAssetId,
            name: oldAsset.name,
            checksum: oldAsset.checksum,
            path: newPath,
            type: oldAsset.type,
            createdAt: oldAsset.createdAt,
            updatedAt: DateTime.now(),
            width: oldAsset.width,
            height: oldAsset.height,
            durationInSeconds: oldAsset.durationInSeconds,
            isFavorite: oldAsset.isFavorite,
            orientation: oldAsset.orientation,
            isInPrivateSpace: false,
            migrationStatus: MigrationStatus.success,
          );

          // 删除旧记录
          await (_database.delete(
            _database.localAssetEntity,
          )..where((t) => t.id.equals(assetId))).go();

          // 插入新记录
          await _database.into(_database.localAssetEntity).insert(newAsset);

          _log.info('Asset ID updated from $assetId to $newAssetId');
        } else {
          // ID相同，直接更新
          await (_database.update(
            _database.localAssetEntity,
          )..where((t) => t.id.equals(assetId))).write(
            LocalAssetEntityCompanion(
              path: Value(newPath),
              isInPrivateSpace: Value(false),
              migrationStatus: Value(MigrationStatus.success),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }

        // 8. 提交事务后再删除私有文件
        // 注意：删除操作在事务外执行，避免影响事务性能
        // 如果删除失败，记录错误但不影响已提交的数据库状态
        try {
          await privateFile.delete();
          _log.info('Private space file deleted: ${asset.path}');
        } catch (deleteError) {
          _log.warning(
            'Failed to delete private space file: ${asset.path}',
            deleteError,
          );
          // 不抛出异常，数据库状态已成功更新
        }

        _log.info('Asset moved from private space to system album: $assetId');
      } catch (e, stackTrace) {
        _log.severe(
          'Failed to move asset from private space: $assetId',
          e,
          stackTrace,
        );

        // 回滚：标记迁移状态为 failed
        try {
          await (_database.update(
            _database.localAssetEntity,
          )..where((t) => t.id.equals(assetId))).write(
            LocalAssetEntityCompanion(
              migrationStatus: Value(MigrationStatus.failed),
              updatedAt: Value(DateTime.now()),
            ),
          );
        } catch (updateError) {
          _log.warning('Failed to update migration status', updateError);
        }

        rethrow;
      }
    });
  }

  /// 生成唯一的文件路径
  /// 如果文件已存在，添加序号后缀（如 filename_1.jpg, filename_2.jpg）
  Future<String> _generateUniqueFilePath(
    Directory directory,
    String fileName,
  ) async {
    final baseName = p.withoutExtension(fileName);
    final extension = p.extension(fileName);
    var finalFileName = fileName;
    var counter = 1;

    // 检查文件是否存在，如果存在则添加序号后缀
    var finalPath = p.join(directory.path, finalFileName);
    var finalFile = File(finalPath);

    while (await finalFile.exists()) {
      finalFileName = '${baseName}_$counter$extension';
      finalPath = p.join(directory.path, finalFileName);
      finalFile = File(finalPath);
      counter++;

      // 防止无限循环（理论上不应该有这么多同名文件）
      if (counter > 1000) {
        _log.warning(
          'Too many files with similar name, using timestamp suffix',
        );
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        finalFileName = '${baseName}_$timestamp$extension';
        finalPath = p.join(directory.path, finalFileName);
        break;
      }
    }

    if (counter > 1) {
      _log.info('File name conflict resolved: $fileName -> $finalFileName');
    }

    return finalPath;
  }

  /// 计算文件校验和（使用 SHA256）
  /// 使用 SHA256 而不是 MD5，因为 SHA256 更安全且性能足够好
  Future<String> _calculateFileChecksum(File file) async {
    try {
      // 使用流式读取，避免大文件占用过多内存
      final stream = file.openRead();
      final hash = await sha256.bind(stream).first;
      return hash.toString();
    } catch (e, stackTrace) {
      _log.warning('Failed to calculate file checksum', e, stackTrace);
      // 降级方案：使用文件大小和修改时间
      final stat = await file.stat();
      return '${stat.size}_${stat.modified.millisecondsSinceEpoch}';
    }
  }

  /// 清理失败的迁移任务
  /// 用于恢复失败状态的文件
  ///
  /// 策略：
  /// 1. 查询所有迁移状态为 failed 的资产
  /// 2. 对于每个失败的资产：
  ///    - 如果文件在私有空间但迁移失败，尝试清理临时文件
  ///    - 如果文件不在私有空间但迁移失败，重置状态为 none
  ///    - 如果文件路径不存在，标记为失败并记录错误
  Future<void> cleanupFailedMigrations() async {
    try {
      final assetDao = _database.localAssetDao;
      final failedAssets = await assetDao.getAssetsWithFailedMigration();

      if (failedAssets.isEmpty) {
        _log.info('No failed migrations to cleanup');
        return;
      }

      _log.info(
        'Found ${failedAssets.length} assets with failed migration status',
      );

      int cleaned = 0;
      int reset = 0;
      int errors = 0;

      for (final asset in failedAssets) {
        try {
          final file = File(asset.path);
          final fileExists = await file.exists();

          if (asset.isInPrivateSpace) {
            // 文件在私有空间但迁移失败
            // 检查文件是否存在
            if (fileExists) {
              // 文件存在，可能是迁移过程中断，重置状态为 none
              await (_database.update(
                _database.localAssetEntity,
              )..where((t) => t.id.equals(asset.id))).write(
                LocalAssetEntityCompanion(
                  migrationStatus: Value(MigrationStatus.none),
                  updatedAt: Value(DateTime.now()),
                ),
              );
              reset++;
              _log.info(
                'Reset migration status for asset in private space: ${asset.id}',
              );
            } else {
              // 文件不存在，可能是迁移失败后文件被删除
              // 重置状态并清除私有空间标志
              await (_database.update(
                _database.localAssetEntity,
              )..where((t) => t.id.equals(asset.id))).write(
                LocalAssetEntityCompanion(
                  isInPrivateSpace: Value(false),
                  migrationStatus: Value(MigrationStatus.none),
                  updatedAt: Value(DateTime.now()),
                ),
              );
              cleaned++;
              _log.info(
                'Cleaned up failed migration for missing file: ${asset.id}',
              );
            }
          } else {
            // 文件不在私有空间但迁移失败
            // 重置状态为 none
            await (_database.update(
              _database.localAssetEntity,
            )..where((t) => t.id.equals(asset.id))).write(
              LocalAssetEntityCompanion(
                migrationStatus: Value(MigrationStatus.none),
                updatedAt: Value(DateTime.now()),
              ),
            );
            reset++;
            _log.info(
              'Reset migration status for asset not in private space: ${asset.id}',
            );
          }
        } catch (e, stackTrace) {
          errors++;
          _log.warning('Failed to cleanup asset: ${asset.id}', e, stackTrace);
        }
      }

      _log.info(
        'Cleanup completed: $cleaned cleaned, $reset reset, $errors errors',
      );
    } catch (e, stackTrace) {
      _log.warning('Failed to cleanup failed migrations', e, stackTrace);
    }
  }

  /// 重试失败的迁移任务
  /// 对于迁移状态为 failed 的资产，尝试重新执行迁移
  Future<void> retryFailedMigrations() async {
    try {
      final assetDao = _database.localAssetDao;
      final failedAssets = await assetDao.getAssetsWithFailedMigration();

      if (failedAssets.isEmpty) {
        _log.info('No failed migrations to retry');
        return;
      }

      _log.info('Retrying ${failedAssets.length} failed migrations');

      int success = 0;
      int failed = 0;

      for (final asset in failedAssets) {
        try {
          if (asset.isInPrivateSpace) {
            // 已经在私有空间，重置状态即可
            await (_database.update(
              _database.localAssetEntity,
            )..where((t) => t.id.equals(asset.id))).write(
              LocalAssetEntityCompanion(
                migrationStatus: Value(MigrationStatus.success),
                updatedAt: Value(DateTime.now()),
              ),
            );
            success++;
          } else {
            // 重新尝试迁移到私有空间
            await moveAssetToPrivateSpace(assetId: asset.id);
            success++;
          }
        } catch (e, stackTrace) {
          failed++;
          _log.warning(
            'Failed to retry migration for asset: ${asset.id}',
            e,
            stackTrace,
          );
        }
      }

      _log.info('Retry completed: $success succeeded, $failed failed');
    } catch (e, stackTrace) {
      _log.warning('Failed to retry failed migrations', e, stackTrace);
    }
  }
}
