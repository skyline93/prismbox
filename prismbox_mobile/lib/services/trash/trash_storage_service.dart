// lib/services/trash/trash_storage_service.dart

import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';

/// 回收站存储服务
/// 负责管理回收站目录结构和文件操作
class TrashStorageService {
  final Logger _logger = Logger('TrashStorageService');
  static const String _trashDirName = 'trash';

  /// 获取回收站根目录
  Future<Directory> _getTrashDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final trashDir = Directory(p.join(appDir.path, _trashDirName));
    if (!await trashDir.exists()) {
      await trashDir.create(recursive: true);
    }
    return trashDir;
  }

  /// 获取指定日期的回收站目录
  /// 目录结构：trash/{YYYY-MM-DD}/
  Future<Directory> _getDateTrashDirectory(DateTime date) async {
    final trashDir = await _getTrashDirectory();
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final dateDir = Directory(p.join(trashDir.path, dateStr));
    if (!await dateDir.exists()) {
      await dateDir.create(recursive: true);
    }
    return dateDir;
  }

  /// 将文件移动到回收站
  ///
  /// **参数**：
  /// - [sourceFile] - 源文件路径
  /// - [assetId] - 资产 ID（用于日志和错误处理）
  /// - [originalFileName] - 原始文件名（用于生成回收站文件名，确保恢复时文件名不变）
  ///
  /// **返回**：回收站文件路径
  ///
  /// **行为**：
  /// 1. 清理原始文件名，移除非法字符和路径分隔符
  /// 2. 处理文件名长度限制（最大 200 字符，保留扩展名）
  /// 3. 处理文件名冲突（如果文件已存在，添加序号后缀）
  /// 4. 复制文件到回收站目录（按日期分组）
  /// 5. 返回回收站文件路径
  Future<String> moveToTrash({
    required String sourceFile,
    required String assetId,
    required String originalFileName,
  }) async {
    try {
      final source = File(sourceFile);
      if (!await source.exists()) {
        throw FileSystemException('源文件不存在', sourceFile);
      }

      // 获取文件扩展名（优先使用源文件的扩展名，如果原始文件名没有扩展名）
      var ext = p.extension(sourceFile);
      if (ext.isEmpty) {
        ext = p.extension(originalFileName);
      }
      if (ext.isEmpty) {
        _logger.warning('源文件和原始文件名都没有扩展名: $sourceFile, $originalFileName');
      }

      // 获取日期目录
      final dateDir = await _getDateTrashDirectory(DateTime.now());

      // 清理原始文件名，移除路径分隔符和非法字符
      // 这些字符在 Android 和 iOS 上都是非法的或可能导致问题
      var sanitizedFileName = originalFileName
          .replaceAll(RegExp(r'[/\\]'), '_') // 路径分隔符
          .replaceAll(RegExp(r'[:*?"<>|]'), '_'); // 其他非法字符

      // 如果清理后的文件名（不含扩展名）为空，使用 assetId 作为后备方案
      final nameWithoutExt = p.basenameWithoutExtension(sanitizedFileName);
      if (nameWithoutExt.isEmpty || nameWithoutExt.trim().isEmpty) {
        // 清理 assetId 中的路径分隔符
        final sanitizedAssetId = assetId.replaceAll(RegExp(r'[/\\]'), '_');
        final nameExt = p.extension(sanitizedFileName);
        sanitizedFileName = '$sanitizedAssetId$nameExt';
        _logger.warning(
          '原始文件名清理后为空，使用 assetId 作为文件名: '
          'originalFileName=$originalFileName, assetId=$assetId',
        );
      }

      // 处理文件名长度限制（保留扩展名）
      // Android 和 iOS 通常限制为 255 字节，我们使用 200 字符作为安全限制
      if (sanitizedFileName.length > 200) {
        final nameExt = p.extension(sanitizedFileName);
        final nameWithoutExt = p.basenameWithoutExtension(sanitizedFileName);
        final maxNameLength = 200 - nameExt.length;
        sanitizedFileName =
            '${nameWithoutExt.substring(0, maxNameLength)}$nameExt';
        _logger.info(
          '文件名过长已截断: 原始长度=${originalFileName.length}, '
          '截断后=${sanitizedFileName.length}',
        );
      }

      // 如果清理后的文件名没有扩展名，使用源文件的扩展名
      if (p.extension(sanitizedFileName).isEmpty && ext.isNotEmpty) {
        sanitizedFileName = '$sanitizedFileName$ext';
      }

      // 处理文件名冲突：如果文件已存在，添加序号后缀
      var trashFile = File(p.join(dateDir.path, sanitizedFileName));
      int counter = 1;
      while (await trashFile.exists()) {
        final nameWithoutExt = p.basenameWithoutExtension(sanitizedFileName);
        final nameExt = p.extension(sanitizedFileName);
        final newName = '${nameWithoutExt}_$counter$nameExt';
        trashFile = File(p.join(dateDir.path, newName));
        counter++;
        if (counter > 1000) {
          // 防止无限循环
          throw FileSystemException(
            '无法生成唯一的回收站文件名，已尝试 1000 次',
            sanitizedFileName,
          );
        }
      }

      if (counter > 1) {
        _logger.info(
          '文件名冲突已解决: 原始文件名=$sanitizedFileName, '
          '最终文件名=${p.basename(trashFile.path)}',
        );
      }

      // 确保目标文件的父目录存在（虽然应该已经存在，但为了安全起见）
      final trashFileDir = trashFile.parent;
      if (!await trashFileDir.exists()) {
        await trashFileDir.create(recursive: true);
      }

      // 复制文件到回收站
      await source.copy(trashFile.path);

      _logger.info('文件已移动到回收站: $sourceFile -> ${trashFile.path}');
      return trashFile.path;
    } catch (e, stackTrace) {
      _logger.severe('移动文件到回收站失败: $sourceFile', e, stackTrace);
      rethrow;
    }
  }

  /// 从回收站恢复文件
  ///
  /// **参数**：
  /// - [trashPath] - 回收站文件路径
  /// - [targetPath] - 目标路径（原始路径）
  ///
  /// **行为**：
  /// 1. 从回收站复制文件到目标路径
  /// 2. 删除回收站文件
  Future<void> restoreFromTrash({
    required String trashPath,
    required String targetPath,
  }) async {
    try {
      final trashFile = File(trashPath);
      if (!await trashFile.exists()) {
        throw FileSystemException('回收站文件不存在', trashPath);
      }

      final target = File(targetPath);

      // 确保目标目录存在
      final targetDir = target.parent;
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // 如果目标文件已存在，先删除
      if (await target.exists()) {
        await target.delete();
      }

      // 复制文件到目标路径
      await trashFile.copy(targetPath);

      // 删除回收站文件
      await trashFile.delete();

      _logger.info('文件已从回收站恢复: $trashPath -> $targetPath');
    } catch (e, stackTrace) {
      _logger.severe('从回收站恢复文件失败: $trashPath', e, stackTrace);
      rethrow;
    }
  }

  /// 从回收站永久删除文件
  ///
  /// **参数**：
  /// - [trashPath] - 回收站文件路径
  ///
  /// **行为**：
  /// 1. 删除回收站文件
  /// 2. 如果日期目录为空，删除日期目录
  Future<void> deleteFromTrash(String trashPath) async {
    try {
      final trashFile = File(trashPath);
      if (!await trashFile.exists()) {
        _logger.warning('回收站文件不存在，跳过删除: $trashPath');
        return;
      }

      // 删除文件
      await trashFile.delete();

      // 检查日期目录是否为空，如果为空则删除
      final dateDir = trashFile.parent;
      if (await dateDir.exists()) {
        final files = dateDir.listSync();
        if (files.isEmpty) {
          await dateDir.delete();
          _logger.info('已删除空的日期目录: ${dateDir.path}');
        }
      }

      _logger.info('回收站文件已永久删除: $trashPath');
    } catch (e, stackTrace) {
      _logger.severe('永久删除回收站文件失败: $trashPath', e, stackTrace);
      rethrow;
    }
  }

  /// 删除系统相册中的文件
  ///
  /// **参数**：
  /// - [assetId] - photo_manager 的资产 ID
  ///
  /// **行为**：
  /// 使用 photo_manager 的 deleteWithIO 方法删除系统相册中的文件
  /// 如果删除失败，只记录警告，不影响整个删除流程
  /// 因为文件已经复制到回收站，可以从回收站恢复
  Future<void> deleteFromSystemAlbum(String assetId) async {
    try {
      // 获取 AssetEntity
      final asset = await AssetEntity.fromId(assetId);
      if (asset == null) {
        _logger.warning('资产不存在，跳过删除系统相册文件: $assetId');
        return;
      }

      // 使用 photo_manager 的 deleteWithIds 方法删除系统相册文件
      // 这个方法会从系统相册中移除资产，而不仅仅是删除文件
      // deleteWithIds 返回 Future<List<String>>，表示成功删除的资产 ID 列表
      try {
        final deletedIds = await PhotoManager.editor.deleteWithIds([assetId]);

        if (deletedIds.contains(assetId)) {
          _logger.info('系统相册文件已删除: $assetId');
        } else {
          _logger.warning('删除系统相册文件失败: $assetId (未在返回的删除列表中)');
        }
      } catch (e) {
        _logger.warning('删除系统相册文件失败: $assetId, 错误: $e');
        // 不重新抛出异常，因为删除失败不应该阻止整个删除流程
      }
    } catch (e, stackTrace) {
      _logger.warning('删除系统相册文件失败: $assetId', e, stackTrace);
      // 不重新抛出异常，因为删除失败不应该阻止整个删除流程
      // 文件已经复制到回收站，即使系统相册删除失败，也可以从回收站恢复
    }
  }

  /// 批量删除系统相册中的文件
  ///
  /// **参数**：
  /// - [assetIds] - photo_manager 的资产 ID 列表
  ///
  /// **返回**：成功删除的资产 ID 列表
  ///
  /// **行为**：
  /// 使用 photo_manager 的 deleteWithIds 方法批量删除系统相册文件
  /// 系统只会弹出一次确认对话框
  /// 如果删除失败，只记录警告，不影响整个删除流程
  /// 因为文件已经复制到回收站，可以从回收站恢复
  Future<List<String>> deleteMultipleFromSystemAlbum(
    List<String> assetIds,
  ) async {
    if (assetIds.isEmpty) {
      return [];
    }

    try {
      // 验证所有 assetId 是否有效
      final validIds = <String>[];
      for (final assetId in assetIds) {
        try {
          final asset = await AssetEntity.fromId(assetId);
          if (asset != null) {
            validIds.add(assetId);
          } else {
            _logger.warning('资产不存在，跳过删除系统相册文件: $assetId');
          }
        } catch (e) {
          _logger.warning('验证资产失败: $assetId, 错误: $e');
        }
      }

      if (validIds.isEmpty) {
        _logger.warning('没有有效的资产 ID，跳过批量删除系统相册文件');
        return [];
      }

      // 一次性批量删除，系统只会弹出一次确认对话框
      try {
        final deletedIds = await PhotoManager.editor.deleteWithIds(validIds);

        _logger.info('批量删除系统相册文件: ${deletedIds.length}/${validIds.length} 成功');

        // 记录失败的资产
        final failedIds = validIds.where((id) => !deletedIds.contains(id)).toList();
        if (failedIds.isNotEmpty) {
          _logger.warning('以下资产删除失败: $failedIds');
        }

        return deletedIds;
      } catch (e, stackTrace) {
        _logger.severe('批量删除系统相册文件失败', e, stackTrace);
        return [];
      }
    } catch (e, stackTrace) {
      _logger.severe('批量删除系统相册文件失败', e, stackTrace);
      return [];
    }
  }
}
