// lib/services/backup/file_metadata_extractor.dart

import 'dart:io';
import 'package:logging/logging.dart';

/// 文件元数据提取器
///
/// **职责**：
/// - 提取文件大小等元数据信息
class FileMetadataExtractor {
  final Logger _logger = Logger('FileMetadataExtractor');

  /// 提取文件大小
  ///
  /// **参数**：
  /// - [filePath] - 文件路径
  ///
  /// **返回**：
  /// - 文件大小（字节）
  /// - 0（如果文件不存在或获取失败）
  ///
  /// **注意**：如果文件不存在，返回 0，后续上传时会重新获取
  Future<int> extractFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      } else {
        _logger.warning('File not found: $filePath');
        return 0;
      }
    } catch (e) {
      _logger.warning('Failed to get file size for $filePath: $e');
      return 0;
    }
  }
}

