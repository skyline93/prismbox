// lib/utils/file_hash_util.dart

import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';

/// 支持的哈希算法类型
enum HashAlgorithm {
  /// SHA256 算法（推荐用于安全场景）
  sha256,
  
  /// MD5 算法（默认，快速，但安全性较低，适用于非安全场景）
  md5,
}

/// 文件哈希计算工具类
/// 
/// 提供统一的文件哈希计算功能，包括：
/// - 支持多种哈希算法（SHA256、MD5）
/// - 流式读取（避免内存溢出）
/// - 文件大小检查
/// - 详细的错误处理
class FileHashUtil {
  static final Logger _logger = Logger('FileHashUtil');
  
  /// 大文件阈值（500MB），超过此大小会记录警告日志
  static const int maxRecommendedSize = 500 * 1024 * 1024;
  
  /// 计算文件 checksum（使用流式读取）
  /// 
  /// **性能优化**：
  /// - 使用流式读取替代一次性读取整个文件
  /// - 对于大文件（如视频），流式读取可以显著降低内存占用
  /// - 避免 Out of Memory 错误
  /// 
  /// **参数**：
  /// - [filePath] - 文件路径
  /// - [algorithm] - 哈希算法类型（默认：MD5）
  /// - [logContext] - 日志上下文信息（可选），用于记录日志时提供更多信息
  /// 
  /// **返回**：哈希值（十六进制字符串）
  /// 
  /// **异常**：
  /// - 如果文件不存在或无法读取，会抛出异常
  /// - 如果文件为空，会抛出异常
  /// 
  /// **示例**：
  /// ```dart
  /// // 使用默认 MD5 算法
  /// final md5Hash = await FileHashUtil.calculateFileChecksum('/path/to/file');
  /// 
  /// // 使用 SHA256 算法
  /// final sha256Hash = await FileHashUtil.calculateFileChecksum(
  ///   '/path/to/file',
  ///   algorithm: HashAlgorithm.sha256,
  /// );
  /// ```
  static Future<String> calculateFileChecksum(
    String filePath, {
    HashAlgorithm algorithm = HashAlgorithm.md5,
    String? logContext,
  }) async {
    final file = File(filePath);
    
    // 检查文件是否存在
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }
    
    // 检查文件大小
    final fileSize = await file.length();
    if (fileSize == 0) {
      throw FileSystemException('File is empty', filePath);
    }
    
    // 记录大文件警告
    if (fileSize > maxRecommendedSize) {
      final sizeMB = (fileSize / 1024 / 1024).toStringAsFixed(2);
      _logger.info(
        'Calculating ${algorithm.name} checksum for large file: ${logContext ?? 'file'}, '
        'filePath=$filePath, size: ${sizeMB}MB',
      );
    }
    
    // 性能优化：使用流式读取，避免大文件导致内存溢出
    // 对于大文件（如视频），流式读取可以显著降低内存占用
    final stream = file.openRead();
    final hash = await _getHashSink(algorithm).bind(stream).first;
    return hash.toString();
  }
  
  /// 安全计算文件 checksum（带错误处理）
  /// 
  /// **参数**：
  /// - [filePath] - 文件路径
  /// - [algorithm] - 哈希算法类型（默认：MD5）
  /// - [logContext] - 日志上下文信息（可选），用于记录日志时提供更多信息
  /// 
  /// **返回**：哈希值（十六进制字符串），如果失败返回 null
  /// 
  /// **错误处理**：
  /// - 自动处理文件不存在、文件为空、内存溢出等错误
  /// - 记录详细的错误日志
  /// 
  /// **示例**：
  /// ```dart
  /// // 使用默认 MD5 算法
  /// final md5Hash = await FileHashUtil.calculateFileChecksumSafe('/path/to/file');
  /// 
  /// // 使用 SHA256 算法
  /// final sha256Hash = await FileHashUtil.calculateFileChecksumSafe(
  ///   '/path/to/file',
  ///   algorithm: HashAlgorithm.sha256,
  /// );
  /// ```
  static Future<String?> calculateFileChecksumSafe(
    String filePath, {
    HashAlgorithm algorithm = HashAlgorithm.md5,
    String? logContext,
  }) async {
    try {
      return await calculateFileChecksum(
        filePath,
        algorithm: algorithm,
        logContext: logContext,
      );
    } catch (e, stackTrace) {
      final file = File(filePath);
      final fileSize = await file.exists() ? await file.length() : 0;
      final sizeMB = fileSize > 0 
          ? (fileSize / 1024 / 1024).toStringAsFixed(2) 
          : 'unknown';
      
      // 特殊处理内存溢出错误
      if (e.toString().contains('Out of Memory') || 
          e.toString().contains('OutOfMemoryError')) {
        _logger.severe(
          'Out of memory while calculating ${algorithm.name} checksum: ${logContext ?? 'file'}, '
          'filePath=$filePath, fileSize=${sizeMB}MB. '
          'This should not happen with streaming hash calculation.',
          e,
          stackTrace,
        );
        return null;
      }
      
      // 处理其他错误
      _logger.warning(
        'Failed to calculate ${algorithm.name} checksum: ${logContext ?? 'file'}, '
        'filePath=$filePath, fileSize=${sizeMB}MB, error=$e',
        e,
        stackTrace,
      );
      return null;
    }
  }
  
  /// 根据算法类型获取对应的 Hash 实例
  /// 
  /// **参数**：
  /// - [algorithm] - 哈希算法类型
  /// 
  /// **返回**：对应的 Hash 实例
  static Hash _getHashSink(HashAlgorithm algorithm) {
    switch (algorithm) {
      case HashAlgorithm.sha256:
        return sha256;
      case HashAlgorithm.md5:
        return md5;
    }
  }
  
  /// 验证文件是否适合计算哈希
  /// 
  /// **参数**：
  /// - [filePath] - 文件路径
  /// 
  /// **返回**：验证结果，包含是否有效和文件大小
  static Future<({bool isValid, int fileSize})> validateFileForHashing(
    String filePath,
  ) async {
    final file = File(filePath);
    
    if (!await file.exists()) {
      return (isValid: false, fileSize: 0);
    }
    
    final fileSize = await file.length();
    if (fileSize == 0) {
      return (isValid: false, fileSize: 0);
    }
    
    return (isValid: true, fileSize: fileSize);
  }
}

