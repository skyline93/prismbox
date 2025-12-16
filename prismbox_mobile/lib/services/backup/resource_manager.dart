// lib/services/backup/resource_manager.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/services/backup/asset_path_resolver.dart';

/// 资源管理器
/// 
/// **职责**：
/// - 临时文件生命周期管理
/// - 及时释放资源
/// - 内存监控
/// - Engine 资源清理
/// 
/// **设计原则**：
/// - 任务完成后立即清理临时文件
/// - 定期清理孤立文件
/// - 监控内存使用，防止内存泄漏
class ResourceManager {
  final AppDatabase _database;
  final AssetPathResolver _pathResolver;
  final Logger _logger = Logger('ResourceManager');

  /// MethodChannel 名称
  static const MethodChannel _channel = MethodChannel('app.prismbox/storage');

  /// 临时文件目录
  static const String _tempDirName = 'upload_temp';

  /// 临时文件有效期（24 小时）
  static const Duration _tempFileValidityPeriod = Duration(hours: 24);

  ResourceManager({
    required AppDatabase database,
    required AssetPathResolver pathResolver,
  }) : _database = database,
       _pathResolver = pathResolver;

  /// 清理任务完成后的临时文件
  /// 
  /// **参数**：
  /// - [taskId] - 任务 ID
  /// 
  /// **职责**：
  /// - 删除任务对应的临时文件
  /// - 记录清理日志
  Future<void> cleanupAfterTaskComplete(String taskId) async {
    try {
      final tempFile = await _getTempFileForTask(taskId);
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
        _logger.fine('Cleaned up temp file for task: taskId=$taskId');
      }
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to cleanup temp file for task: taskId=$taskId',
        e,
        stackTrace,
      );
    }
  }

  /// 清理孤立临时文件
  /// 
  /// **职责**：
  /// - 查找所有临时文件
  /// - 检查对应的任务是否存在
  /// - 删除孤立文件（无对应任务的文件）
  Future<CleanupResult> cleanupOrphanedFiles() async {
    _logger.info('Starting orphaned file cleanup');

    final result = CleanupResult();

    try {
      final tempDir = await _getTempDirectory();
      if (!await tempDir.exists()) {
        _logger.info('Temp directory does not exist, skipping cleanup');
        return result;
      }

      final files = tempDir.listSync();
      int orphanedCount = 0;
      int expiredCount = 0;

      for (final file in files) {
        if (file is File) {
          try {
            // 提取任务 ID（从文件名）
            final taskId = _extractTaskIdFromFileName(file.path);
            if (taskId == null) {
              // 无法提取任务 ID，视为孤立文件
              await file.delete();
              orphanedCount++;
              continue;
            }

            // 检查任务是否存在
            final task = await _database.uploadTaskDao.getTaskById(taskId);
            if (task == null) {
              // 任务不存在，视为孤立文件
              await file.delete();
              orphanedCount++;
              continue;
            }

            // 检查文件是否过期
            final stat = await file.stat();
            final age = DateTime.now().difference(stat.modified);
            if (age > _tempFileValidityPeriod) {
              // 文件过期，删除
              await file.delete();
              expiredCount++;
            }
          } catch (e) {
            _logger.warning(
              'Failed to process temp file: ${file.path}, error=$e',
            );
            result.errorCount++;
          }
        }
      }

      result.orphanedDeleted = orphanedCount;
      result.expiredDeleted = expiredCount;

      _logger.info(
        'Orphaned file cleanup completed: orphaned=$orphanedCount, '
        'expired=$expiredCount, errors=${result.errorCount}',
      );

      return result;
    } catch (e, stackTrace) {
      _logger.severe('Orphaned file cleanup failed', e, stackTrace);
      return result;
    }
  }

  /// 清理所有临时文件
  /// 
  /// **职责**：
  /// - 删除所有临时文件（用于紧急清理）
  Future<int> cleanupAllTempFiles() async {
    _logger.info('Starting full temp file cleanup');

    try {
      final tempDir = await _getTempDirectory();
      if (!await tempDir.exists()) {
        return 0;
      }

      final files = tempDir.listSync();
      int deletedCount = 0;

      for (final file in files) {
        if (file is File) {
          try {
            await file.delete();
            deletedCount++;
          } catch (e) {
            _logger.warning('Failed to delete temp file: ${file.path}, error=$e');
          }
        }
      }

      _logger.info('Full temp file cleanup completed: deleted=$deletedCount');
      return deletedCount;
    } catch (e, stackTrace) {
      _logger.severe('Full temp file cleanup failed', e, stackTrace);
      return 0;
    }
  }

  /// 获取临时文件目录
  Future<Directory> _getTempDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/$_tempDirName');
  }

  /// 获取任务对应的临时文件
  /// 
  /// **参数**：
  /// - [taskId] - 任务 ID
  /// 
  /// **返回**：临时文件（如果存在）
  Future<File?> _getTempFileForTask(String taskId) async {
    try {
      final tempDir = await _getTempDirectory();
      final fileName = 'upload_${taskId}.tmp';
      final filePath = '${tempDir.path}/$fileName';
      
      if (await _pathResolver.validateFileExists(filePath)) {
        return File(filePath);
      }
      return null;
    } catch (e) {
      _logger.warning('Failed to get temp file for task: taskId=$taskId, error=$e');
      return null;
    }
  }

  /// 从文件名提取任务 ID
  /// 
  /// **参数**：
  /// - [filePath] - 文件路径
  /// 
  /// **返回**：任务 ID（如果可提取）
  String? _extractTaskIdFromFileName(String filePath) {
    try {
      final fileName = filePath.split('/').last;
      // 文件名格式：upload_<taskId>.tmp
      if (fileName.startsWith('upload_') && fileName.endsWith('.tmp')) {
        return fileName.substring(7, fileName.length - 4);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 检查存储空间
  /// 
  /// **返回**：可用空间（字节）
  Future<int> getAvailableSpace() async {
    try {
      final result = await _channel.invokeMethod<int>('getAvailableSpace');
      if (result != null) {
        return result;
      }
      _logger.warning('getAvailableSpace returned null');
      return 0;
    } on PlatformException catch (e) {
      _logger.warning(
        'Failed to get available space: ${e.message}',
        e,
        StackTrace.current,
      );
      return 0;
    } catch (e, stackTrace) {
      _logger.warning('Failed to get available space: $e', e, stackTrace);
      return 0;
    }
  }

  /// 检查是否有足够的存储空间
  /// 
  /// **参数**：
  /// - [requiredBytes] - 需要的空间（字节）
  /// 
  /// **返回**：是否有足够空间
  Future<bool> hasEnoughSpace(int requiredBytes) async {
    final available = await getAvailableSpace();
    return available >= requiredBytes;
  }
}

/// 清理结果
class CleanupResult {
  /// 删除的孤立文件数
  int orphanedDeleted = 0;

  /// 删除的过期文件数
  int expiredDeleted = 0;

  /// 错误数
  int errorCount = 0;
}

